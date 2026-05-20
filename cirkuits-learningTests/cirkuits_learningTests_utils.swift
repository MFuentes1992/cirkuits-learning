//
//  cirkuits_learningTests.swift
//  cirkuits-learningTests
//
//  Created by Marco Fuentes Jiménez on 04/06/25.
//

import Testing
@testable import cirkuits_learning

struct cirkuits_learningTests_utils {
    
    let testBank: [String] = [
        "I", "am",
        "You", "are",
        "He", "is",
        "She", "is",
        "It", "is",
        "We", "are",
        "They", "are",
        "We", "won",
        "I", "see",
        "She", "is",
        "He", "is",
        "I", "am",
        "You", "kind",
        "We", "are",
        "They", "are"
    ]
    
    
    //TODO: Fix unit test
    @Test func sentenceCreation() async throws {
        // -- Test 2 words sentences
        for i in stride(from: 1, to: 4, by: 1) {
            let sentenceLength = i
            let wordFoos = createSentenceArray(bank: testBank, words: sentenceLength)
            let foo = wordFoos[Int.random(in: 0...wordFoos.count - 1)]
            let words = foo.Word.split(separator: stringUtils.whiteSpace.rawValue).count
            #expect(words == sentenceLength)
        }
    }
}
