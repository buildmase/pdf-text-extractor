# PDF Text Extractor

A simple and elegant macOS app for extracting text from PDF documents and saving them as clean markdown files.

## Features

- **Drag & Drop Interface**: Simply drag PDF files onto the app for instant processing
- **File Picker**: Traditional file selection as an alternative
- **Smart Text Extraction**: Extracts text from all PDF page types with proper formatting
- **Markdown Export**: Saves extracted text as clean, formatted markdown files
- **Progress Tracking**: Visual progress indicator for large PDFs
- **Error Handling**: Clear error messages for encrypted or invalid PDFs
- **Word/Character Count**: Shows statistics about extracted content

## How to Use

1. **Launch the app** - The main interface will show a drag & drop zone
2. **Add a PDF** - Either drag a PDF file onto the app or click "Choose PDF File"
3. **Extract Text** - Click "Extract Text" to process the PDF
4. **Save as Markdown** - Click "Save as Markdown" to export the text

## Requirements

- macOS 12.0 or later
- Xcode 14.0 or later (for building from source)

## Building from Source

1. Clone this repository
2. Open `PDF Text Extractor.xcodeproj` in Xcode
3. Build and run the project

## Technical Details

- Built with SwiftUI for modern macOS interface
- Uses PDFKit for robust PDF text extraction
- Async/await for smooth user experience
- Proper error handling for encrypted PDFs
- Clean markdown formatting with headers and lists

## License

This project is open source and available under the MIT License.
