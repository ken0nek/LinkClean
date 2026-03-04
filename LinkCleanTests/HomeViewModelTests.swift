//
//  HomeViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanKit

@MainActor
struct HomeViewModelTests {

    @Test func isInputEmptyWhenBlank() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = ""

        #expect(vm.isInputEmpty == true)
    }

    @Test func isInputEmptyWhenWhitespace() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "   "

        #expect(vm.isInputEmpty == true)
    }

    @Test func isInputNotEmpty() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "https://example.com"

        #expect(vm.isInputEmpty == false)
    }

    @Test func isInputValidURLDelegatesToService() {
        var mock = MockURLCleaningService()
        mock.isValidURLHandler = { $0.contains("valid") }
        let vm = HomeViewModel(service: mock)

        vm.inputText = "valid-url"
        #expect(vm.isInputValidURL == true)

        vm.inputText = "nope"
        #expect(vm.isInputValidURL == false)
    }

    @Test func shouldShowInvalidWhenNotEmptyAndInvalid() {
        var mock = MockURLCleaningService()
        mock.isValidURLHandler = { _ in false }
        let vm = HomeViewModel(service: mock)

        vm.inputText = "not-a-url"

        #expect(vm.shouldShowInvalidInputMessage == true)
    }

    @Test func shouldNotShowInvalidWhenEmpty() {
        var mock = MockURLCleaningService()
        mock.isValidURLHandler = { _ in false }
        let vm = HomeViewModel(service: mock)

        vm.inputText = ""

        #expect(vm.shouldShowInvalidInputMessage == false)
    }

    @Test func cleanedTextEmptyByDefault() {
        let vm = HomeViewModel(service: MockURLCleaningService())

        #expect(vm.cleanedText == "")
    }

    @Test func clearInputResets() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "https://example.com"
        vm.clearInput()

        #expect(vm.inputText == "")
        #expect(vm.isInputEmpty == true)
    }

    @Test func inputSanitizesNewlines() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "https://example\n.com"

        #expect(!vm.inputText.contains("\n"))
    }
}
