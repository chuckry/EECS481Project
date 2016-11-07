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
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.6
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        synthesizer.speak(utterance)
    }
	

	func waitToFinishSpeaking(callback: @escaping () -> Void){
		notifyDoneSpeaking = callback
		waitingForDoneSpeaking = true
		
		/*if (Speech.shared.synthesizer.isSpeaking == true){
			isSpeaking = true
			print("speaking")
		}
		else{
			isSpeaking = false
			print("not speaking")
			notifyDoneSpeaking = callback
		}*/
	}
	
	func speechSynthesizer(_ synth: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		print("all done")
		if (Speech.shared.waitingForDoneSpeaking == true){
			Speech.shared.waitingForDoneSpeaking = false
			notifyDoneSpeaking()
		}
	}
}





