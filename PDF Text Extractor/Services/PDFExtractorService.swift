//
//  PDFExtractorService.swift
//  PDF Text Extractor
//
//  Created by Mason Earl on 10/20/25.
//

import Foundation
import PDFKit

class PDFExtractorService: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    
    func extractText(from url: URL) async throws -> String {
        await MainActor.run {
            isProcessing = true
            progress = 0.0
            statusMessage = "Loading PDF..."
        }
        
        guard let pdfDocument = PDFDocument(url: url) else {
            await MainActor.run {
                isProcessing = false
                statusMessage = "Error: Could not load PDF file"
            }
            throw PDFExtractionError.invalidPDF
        }
        
        // Check if PDF is encrypted
        if pdfDocument.isEncrypted {
            await MainActor.run {
                isProcessing = false
                statusMessage = "Error: PDF is password protected"
            }
            throw PDFExtractionError.encryptedPDF
        }
        
        let pageCount = pdfDocument.pageCount
        var fullText = ""
        
        await MainActor.run {
            statusMessage = "Extracting text from \(pageCount) pages..."
        }
        
        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            
            if let pageText = page.string {
                // Clean up the text while preserving structure
                let cleanedText = cleanText(pageText)
                fullText += cleanedText
                
                // Add page break if not the last page
                if i < pageCount - 1 {
                    fullText += "\n\n---\n\n"
                }
            }
            
            // Update progress
            let currentProgress = Double(i + 1) / Double(pageCount)
            await MainActor.run {
                progress = currentProgress
                statusMessage = "Processing page \(i + 1) of \(pageCount)..."
            }
        }
        
        await MainActor.run {
            isProcessing = false
            progress = 1.0
            statusMessage = "Text extracted successfully! \(pageCount) pages processed."
        }
        
        return fullText
    }
    
    private func cleanText(_ text: String) -> String {
        // Remove excessive whitespace while preserving paragraph structure
        let lines = text.components(separatedBy: .newlines)
        var cleanedLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                cleanedLines.append(trimmed)
            } else if !cleanedLines.isEmpty && cleanedLines.last != "" {
                // Preserve empty lines between paragraphs
                cleanedLines.append("")
            }
        }
        
        return cleanedLines.joined(separator: "\n")
    }
}

enum PDFExtractionError: LocalizedError {
    case invalidPDF
    case encryptedPDF
    case extractionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "Invalid PDF file or file could not be opened"
        case .encryptedPDF:
            return "PDF is password protected and cannot be processed"
        case .extractionFailed:
            return "Failed to extract text from PDF"
        }
    }
}