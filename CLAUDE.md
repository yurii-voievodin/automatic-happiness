# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DocumentsApp is a SwiftUI-based iOS application for document management with scanning and security features. The app uses SwiftData for persistence and implements PDF generation from scanned documents using VisionKit.

## Architecture

### Core Components
- **SwiftData Model**: `Document` class in `Models/Document.swift` handles document persistence with thumbnail generation
- **MVVM Pattern**: `DocumentViewModel` manages document operations and security checks
- **Services Layer**: 
  - `PDFGenerationService` handles PDF creation from scanned images
  - `SecurityService` provides jailbreak detection and security recommendations
- **SwiftUI Views**: Organized in `Views/` directory with main navigation in `ContentView`

### Key Features
- Document scanning using VisionKit (`VNDocumentCameraScan`)
- File import from system document picker
- Automatic PDF thumbnail generation using PDFKit
- Security monitoring with jailbreak detection
- Document grouping by creation date
- SwiftData integration for local persistence

## Development Commands

### Building and Testing
```bash
# Build the project
xcodebuild -project DocumentsApp.xcodeproj -scheme DocumentsApp

# Run tests
xcodebuild test -project DocumentsApp.xcodeproj -scheme DocumentsApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project DocumentsApp.xcodeproj -scheme DocumentsApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:DocumentsAppTests/DocumentsAppTests
```

### Code Quality
- The project uses Swift Testing framework (not XCTest)
- No specific linting configuration detected - follow Swift standard conventions
- Tests are located in `DocumentsAppTests/DocumentsAppTests.swift`

## Data Flow

1. **Document Input**: Via scanner (`VNDocumentCameraScan`) or file picker (`DocumentPicker`)
2. **Processing**: PDF generation through `PDFGenerationService`, thumbnail creation via PDFKit
3. **Storage**: Document metadata and data stored via SwiftData, files saved to app's documents directory
4. **Display**: Documents grouped by date and shown in SwiftUI list with navigation to detail views

## Key Files to Understand

- `DocumentsAppApp.swift`: App entry point with SwiftData container setup and scene phase handling
- `Models/Document.swift`: Core data model with file operations and thumbnail generation
- `ViewModels/DocumentViewModel.swift`: Business logic for document operations and security
- `Services/SecurityService.swift`: Jailbreak detection and security recommendations
- `Views/ContentView.swift`: Main UI with document list and floating action button

## Testing Strategy

Tests focus on core document behaviors including:
- Document creation from URLs
- Data persistence and retrieval
- File size formatting
- Basic model validation

Use the existing test structure in `DocumentsAppTests.swift` as a template for new tests.