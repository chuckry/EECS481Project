//
//  File.swift
//  AOSG
//
//  Created by Apoorva Gupta on 11/2/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import AVFoundation

class Speech: NSObject {
    
    // singleton pattern
    static let shared = Speech()
    public let synthesizer = AVSpeechSynthesizer()
    public var speechRate : Float = 0.5
    public var voiceOn : Bool = true
    public var volume : Float = 1

    
    func say(utterance text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }
    
    func immediatelySay(utterance text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        synthesizer.speak(utterance)
    }
    
    private override init() {}
}
