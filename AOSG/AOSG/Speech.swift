//
//  File.swift
//  AOSG
//
//  Created by Apoorva Gupta on 11/2/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import AVFoundation

// Extension makes strings sayable using speech class
extension String {
    func say() {
        Speech.shared.immediatelySay(utterance: self)
    }
    func say(andThen callback: @escaping ()->Void) {
        Speech.shared.waitToFinishSpeaking(callback: callback)
        Speech.shared.immediatelySay(utterance: self)
    }
}

class Speech: NSObject, AVSpeechSynthesizerDelegate {
    
    // singleton pattern
    static let shared = Speech()
    let synthesizer = AVSpeechSynthesizer()
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
        utterance.rate = 0.6
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }
    
    func immediatelySay(utterance text: String) {
        print("saying \(text) now");
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.6
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        synthesizer.speak(utterance)
    }
    
    func interruptPolitely() {
        synthesizer.stopSpeaking(at: .word)
    }
    
    func interruptRudely() {
        synthesizer.stopSpeaking(at: .immediate)
    }
	

	func waitToFinishSpeaking(callback: @escaping () -> Void){
        print("setting the callback")
		notifyDoneSpeaking = callback
		waitingForDoneSpeaking = true
		//print("done speaking 3")
	}
    
	func speechSynthesizer(_ synth: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		//print("done speaking 1")
		if (Speech.shared.waitingForDoneSpeaking == true){
			//print("done speaking 2")
			Speech.shared.waitingForDoneSpeaking = false
            print("notifying that we're done speaking")
			notifyDoneSpeaking()
		}
	}
}





