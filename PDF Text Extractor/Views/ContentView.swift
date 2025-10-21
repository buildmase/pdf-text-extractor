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
    @State private var showStats = false
    @State private var isDarkMode = true
    
    var body: some View {
        VStack(spacing: 25) {
            // Header with theme toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PDF Text Extractor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Extract text from PDF documents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isDarkMode.toggle() }) {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.bordered)
                .help("Toggle theme")
            }
            
            // Drag and drop area
            VStack(spacing: 20) {
                if selectedPDF == nil {
                    // Enhanced drag and drop zone
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [12, 8]))
                        .foregroundColor(isDragOver ? .green : .blue)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isDragOver ? Color.green.opacity(0.15) : Color.blue.opacity(0.05))
                        )
                        .frame(height: 220)
                        .overlay(
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(isDragOver ? Color.green.opacity(0.2) : Color.blue.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: isDragOver ? "doc.badge.plus" : "doc.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(isDragOver ? .green : .blue)
                                        .animation(.easeInOut(duration: 0.3), value: isDragOver)
                                }
                                .scaleEffect(isDragOver ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: isDragOver)
                                
                                VStack(spacing: 8) {
                                    Text(isDragOver ? "Drop PDF Here!" : "Drag & Drop PDF Here")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(isDragOver ? .green : .primary)
                                        .animation(.easeInOut(duration: 0.3), value: isDragOver)
                                    
                                    Text("Supports all PDF formats")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Text("or")
                                        .foregroundColor(.secondary)
                                    
                                    Button("Choose PDF File") {
                                        showFilePicker = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.regular)
                                }
                            }
                        )
                        .onDrop(of: [UTType.pdf], isTargeted: $isDragOver) { providers in
                            handleDrop(providers: providers)
                        }
                } else {
                    // Enhanced selected file display
                    VStack(spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PDF Selected")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(selectedPDF!.lastPathComponent)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Button("Change") {
                                showFilePicker = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        // File info
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Ready to extract text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            // Extract button and progress
            if selectedPDF != nil {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await extractTextFromPDF()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if pdfService.isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "text.magnifyingglass")
                                }
                                Text(pdfService.isProcessing ? "Extracting..." : "Extract Text")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(pdfService.isProcessing)
                        .controlSize(.large)
                        
                        if !extractedText.isEmpty {
                            Button("Show Stats") {
                                showStats.toggle()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                    }
                    
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
            
            // Enhanced extracted text area
            if !extractedText.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with stats and actions
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                Text("Extracted Text")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "textformat.abc")
                                        .foregroundColor(.secondary)
                                    Text("\(wordCount) words")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "character")
                                        .foregroundColor(.secondary)
                                    Text("\(characterCount) characters")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if showStats {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .foregroundColor(.secondary)
                                        Text("~\(Int(Double(wordCount) / 200)) min read")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button("Save as Markdown") {
                                showSavePanel = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            
                            Button("New PDF") {
                                resetApp()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                    }
                    
                    // Enhanced text display
                    ScrollView {
                        Text(extractedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 500)
                    .overlay(
                        // Scroll indicator
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .opacity(0.6)
                                Spacer()
                            }
                            .padding(.bottom, 8)
                        }
                    )
                }
            }
            
            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Ready to extract")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("PDF Text Extractor v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
        }
        .padding(24)
        .frame(minWidth: 900, minHeight: 750)
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