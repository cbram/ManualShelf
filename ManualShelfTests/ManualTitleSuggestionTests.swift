//
//  ManualTitleSuggestionTests.swift
//  ManualShelfTests
//

import Testing
@testable import ManualShelf

struct ManualTitleSuggestionTests {

    @Test func firstFileFillsEmptyTitleWithoutExtension() {
        #expect(ManualTitleSuggestion.title(current: "", addedFileName: "Kaffeemaschine EQ6.pdf", isFirstFile: true) == "Kaffeemaschine EQ6")
    }

    @Test func whitespaceOnlyTitleCountsAsEmpty() {
        #expect(ManualTitleSuggestion.title(current: "   ", addedFileName: "tv_manual.jpeg", isFirstFile: true) == "tv_manual")
    }

    @Test func typedTitleIsNeverOverwritten() {
        #expect(ManualTitleSuggestion.title(current: "My TV", addedFileName: "tv.pdf", isFirstFile: true) == "My TV")
    }

    @Test func laterFilesDoNotChangeTheTitle() {
        #expect(ManualTitleSuggestion.title(current: "", addedFileName: "second.pdf", isFirstFile: false) == "")
    }

    @Test func onlyTheLastExtensionIsRemoved() {
        #expect(ManualTitleSuggestion.title(current: "", addedFileName: "manual.v2.pdf", isFirstFile: true) == "manual.v2")
    }
}
