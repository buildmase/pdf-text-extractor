//
//  MarkdownFormatter.swift
//  PDF Text Extractor
//
//  Created by Mason Earl on 10/20/25.
//

import Foundation

class MarkdownFormatter {
    
    static func formatText(_ text: String, from pdfName: String) -> String {
        var formattedText = text
        
        // Add header with PDF name and timestamp
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        let header = "# Text Extracted from: \(pdfName)\n\n*Extracted on: \(timestamp)*\n\n---\n\n"
        
        // Clean up the text
        formattedText = cleanUpText(formattedText)
        
        // Detect and format potential headings
        formattedText = formatHeadings(formattedText)
        
        // Format lists
        formattedText = formatLists(formattedText)
        
        // Ensure proper paragraph spacing
        formattedText = formatParagraphs(formattedText)
        
        return header + formattedText
    }
    
    private static func cleanUpText(_ text: String) -> String {
        var cleaned = text
        
        // Remove excessive whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Fix common PDF extraction issues
        cleaned = cleaned.replacingOccurrences(of: "\\s+\\n", with: "\n", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\n\\s+", with: "\n", options: .regularExpression)
        
        // Remove page break markers if they exist
        cleaned = cleaned.replacingOccurrences(of: "---", with: "")
        
        return cleaned
    }
    
    private static func formatHeadings(_ text: String) -> String {
        var formatted = text
        let lines = formatted.components(separatedBy: .newlines)
        var result: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detect potential headings (short lines, all caps, or ending with colon)
            if trimmed.count < 50 && 
               (trimmed.uppercased() == trimmed || 
                trimmed.hasSuffix(":") || 
                trimmed.hasSuffix(".")) && 
               !trimmed.isEmpty {
                
                // Check if it's not already a heading
                if !trimmed.hasPrefix("#") {
                    result.append("## \(trimmed)")
                } else {
                    result.append(trimmed)
                }
            } else {
                result.append(trimmed)
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func formatLists(_ text: String) -> String {
        var formatted = text
        let lines = formatted.components(separatedBy: .newlines)
        var result: [String] = []
        var inList = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detect list items (starting with numbers, bullets, or dashes)
            if trimmed.range(of: "^\\d+\\.|^[•·▪▫]|^-", options: .regularExpression) != nil {
                if !inList {
                    result.append("") // Add spacing before list
                    inList = true
                }
                result.append("- \(trimmed.replacingOccurrences(of: "^\\d+\\.|^[•·▪▫]|^-\\s*", with: "", options: .regularExpression))")
            } else {
                if inList && !trimmed.isEmpty {
                    result.append("") // Add spacing after list
                    inList = false
                }
                result.append(trimmed)
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func formatParagraphs(_ text: String) -> String {
        var formatted = text
        
        // Ensure proper paragraph spacing
        formatted = formatted.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Remove trailing whitespace from lines
        let lines = formatted.components(separatedBy: .newlines)
        let cleanedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        
        return cleanedLines.joined(separator: "\n")
    }
    
    static func getWordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    static func getCharacterCount(_ text: String) -> Int {
        return text.count
    }
}
