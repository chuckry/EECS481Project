//
//  File.swift
//  AOSG
//
//  Created by Apoorva Gupta on 11/2/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import AVFoundation

class Speech: NSObject, AVSpeechSynthesizerDelegate {
    
    // singleton pattern
    static let shared = Speech()
    public let synthesizer = AVSpeechSynthesizer()
    public var speechRate : Float = 0.5
    public var voiceOn : Bool = true
    public var volume : Float = 1
	private var isSpeaking:Bool = false
	private var isListening:Bool = false
	var waitingForDoneSpeaking:Bool = false
	lazy var notifyDoneSpeaking: () -> Void = {arg in}

	override init() {
		super.init()
		synthesizer.delegate = self
	}
	
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
	

	func waitToFinishSpeaking(callback: @escaping () -> Void){
		notifyDoneSpeaking = callback
		waitingForDoneSpeaking = true
		print("done speaking 3")
	}
	
	func speechSynthesizer(_ synth: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		print("done speaking 1")
		if (Speech.shared.waitingForDoneSpeaking == true){
			print("done speaking 2")
			Speech.shared.waitingForDoneSpeaking = false
			notifyDoneSpeaking()
		}
	}
}





