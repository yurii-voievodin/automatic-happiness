//
//  DocumentsAppTests.swift
//  DocumentsAppTests
//
//  Created by Yurii Voievodin on 05/06/2025.
//

import Foundation
import Testing
@testable import DocumentsApp

struct DocumentsAppTests {

    @Test func documentBehaviors() async throws {
        // Prepare known data
        let data = Data(repeating: 0xFF, count: 2048)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Test.pdf")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let document = Document(url: tempURL)

        // Verify basic properties
        #expect(document.name == "Test.pdf")
        #expect(document.fileSize == 2048)
        #expect(document.formattedFileSize == "2 KB")

        // Verify data retrieval
        let retrieved = try document.getData()
        #expect(retrieved == data)
    }

}
