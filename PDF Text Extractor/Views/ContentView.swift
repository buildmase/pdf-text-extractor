//
//  ContentView.swift
//  PDF Text Extractor
//
//  Created by Mason Earl on 10/20/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var pdfService = PDFExtractorService()
    @State private var selectedPDF: URL?
    @State private var extractedText: String = ""
    @State private var showFilePicker = false
    @State private var showSavePanel = false
    @State private var isDragOver = false
    @State private var wordCount = 0
    @State private var characterCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PDF Text Extractor")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Drag and drop area
            VStack(spacing: 20) {
                if selectedPDF == nil {
                    // Drag and drop zone
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(isDragOver ? .green : .blue)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDragOver ? Color.green.opacity(0.1) : Color.clear)
                        )
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 15) {
                                Image(systemName: isDragOver ? "doc.badge.plus.fill" : "doc.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(isDragOver ? .green : .blue)
                                    .animation(.easeInOut(duration: 0.2), value: isDragOver)
                                
                                Text(isDragOver ? "Drop PDF Here" : "Drag & Drop PDF Here")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(isDragOver ? .green : .primary)
                                    .animation(.easeInOut(duration: 0.2), value: isDragOver)
                                
                                Text("or")
                                    .foregroundColor(.secondary)
                                
                                Button("Choose PDF File") {
                                    showFilePicker = true
                                }
                                .buttonStyle(.bordered)
                            }
                        )
                        .onDrop(of: [UTType.pdf], isTargeted: $isDragOver) { providers in
                            handleDrop(providers: providers)
                        }
                } else {
                    // Selected file display
                    VStack(spacing: 15) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Selected: \(selectedPDF!.lastPathComponent)")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Button("Choose Different PDF") {
                            showFilePicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Extract button and progress
            if selectedPDF != nil {
                VStack(spacing: 15) {
                    Button("Extract Text") {
                        Task {
                            await extractTextFromPDF()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pdfService.isProcessing)
                    .controlSize(.large)
                    
                    if pdfService.isProcessing {
                        VStack(spacing: 12) {
                            // Enhanced progress bar
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Progress")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(Int(pdfService.progress * 100))%")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                
                                ProgressView(value: pdfService.progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(height: 8)
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                            Text(pdfService.statusMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 400)
                        }
                        .frame(maxWidth: 500)
                    }
                }
            }
            
            // Status message
            Text(pdfService.statusMessage)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 20)
            
            // Extracted text area
            if !extractedText.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Extracted Text:")
                                .font(.headline)
                            Text("\(wordCount) words • \(characterCount) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Button("Save as Markdown") {
                                showSavePanel = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Extract Another PDF") {
                                resetApp()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    ScrollView {
                        Text(extractedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 300)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedPDF = url
                    pdfService.statusMessage = "PDF selected. Click 'Extract Text' to begin."
                    extractedText = "" // Clear previous text
                }
            case .failure(let error):
                pdfService.statusMessage = "Error selecting file: \(error.localizedDescription)"
            }
        }
        .fileExporter(
            isPresented: $showSavePanel,
            document: MarkdownDocument(text: formatTextForExport()),
            contentType: .plainText,
            defaultFilename: selectedPDF?.deletingPathExtension().lastPathComponent ?? "extracted_text"
        ) { result in
            switch result {
            case .success:
                pdfService.statusMessage = "Text saved as markdown file!"
            case .failure(let error):
                pdfService.statusMessage = "Error saving file: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.pdfService.statusMessage = "Error loading PDF: \(error.localizedDescription)"
                    }
                    return
                }
                
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        self.selectedPDF = url
                        self.pdfService.statusMessage = "PDF selected. Click 'Extract Text' to begin."
                        self.extractedText = "" // Clear previous text
                    }
                }
            }
            return true
        }
        return false
    }
    
    private func extractTextFromPDF() async {
        guard let pdfURL = selectedPDF else { return }
        
        // Check file size and warn user if it's very large
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: pdfURL.path)
            if let fileSize = fileAttributes[.size] as? Int64 {
                let fileSizeMB = Double(fileSize) / (1024 * 1024)
                if fileSizeMB > 50 {
                    await MainActor.run {
                        self.pdfService.statusMessage = "Large file detected (\(String(format: "%.1f", fileSizeMB)) MB). This may take a while..."
                    }
                }
            }
        } catch {
            // Continue if we can't get file size
        }
        
        do {
            let rawText = try await pdfService.extractText(from: pdfURL)
            let pdfName = pdfURL.deletingPathExtension().lastPathComponent
            let formattedText = MarkdownFormatter.formatText(rawText, from: pdfName)
            
            await MainActor.run {
                self.extractedText = formattedText
                self.wordCount = MarkdownFormatter.getWordCount(formattedText)
                self.characterCount = MarkdownFormatter.getCharacterCount(formattedText)
            }
        } catch {
            await MainActor.run {
                self.pdfService.statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func formatTextForExport() -> String {
        return extractedText
    }
    
    private func resetApp() {
        selectedPDF = nil
        extractedText = ""
        wordCount = 0
        characterCount = 0
        pdfService.statusMessage = "Select a PDF file to extract text"
    }
}

#Preview {
    ContentView()
}