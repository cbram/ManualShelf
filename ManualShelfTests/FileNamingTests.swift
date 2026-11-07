//
//  FileNamingTests.swift
//  ManualShelfTests
//

import Testing
@testable import ManualShelf

struct FileNamingTests {

    @Test func keepsExtensionOfCurrentName() {
        #expect(FileNaming.renamed(currentFileName: "x8a7f.pdf", newBaseName: "Dishwasher", fallbackExtension: "pdf") == "Dishwasher.pdf")
    }

    @Test func trimsAndReplacesForbiddenCharacters() {
        #expect(FileNaming.renamed(currentFileName: "a.png", newBaseName: "  TV 2/3: Remote  ", fallbackExtension: nil) == "TV 2-3- Remote.png")
    }

    @Test func emptyNameKeepsCurrentName() {
        #expect(FileNaming.renamed(currentFileName: "server-name.pdf", newBaseName: "   ", fallbackExtension: "pdf") == "server-name.pdf")
    }

    @Test func typedExtensionIsNotDoubled() {
        #expect(FileNaming.renamed(currentFileName: "a.pdf", newBaseName: "Manual.PDF", fallbackExtension: nil) == "Manual.pdf")
        #expect(FileNaming.renamed(currentFileName: "a.pdf", newBaseName: ".pdf", fallbackExtension: nil) == "a.pdf")
    }

    @Test func usesFallbackExtensionWhenNameHasNone() {
        #expect(FileNaming.renamed(currentFileName: "download", newBaseName: "Oven", fallbackExtension: "jpeg") == "Oven.jpeg")
    }

    @Test func otherDotsInTheNameStay() {
        #expect(FileNaming.renamed(currentFileName: "a.pdf", newBaseName: "Manual v2.1", fallbackExtension: nil) == "Manual v2.1.pdf")
    }

    @Test func baseNameDropsOnlyTheLastExtension() {
        #expect(FileNaming.baseName(of: "manual.v2.pdf") == "manual.v2")
    }

    @Test func titleFollowsRenamedFirstFileWhileUntouched() {
        #expect(ManualTitleSuggestion.titleAfterRenaming(current: "x8a7f", oldFileName: "x8a7f.pdf", newFileName: "Oven.pdf", isFirstFile: true) == "Oven")
        #expect(ManualTitleSuggestion.titleAfterRenaming(current: "My oven", oldFileName: "x8a7f.pdf", newFileName: "Oven.pdf", isFirstFile: true) == "My oven")
        #expect(ManualTitleSuggestion.titleAfterRenaming(current: "x8a7f", oldFileName: "x8a7f.pdf", newFileName: "Oven.pdf", isFirstFile: false) == "x8a7f")
    }
}
