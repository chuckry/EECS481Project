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

class Speech: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
	
    // singleton pattern
    static let shared = Speech()
    let synthesizer = AVSpeechSynthesizer()
	private var isSpeaking:Bool = false
	private var isListening:Bool = false
	var waitingForDoneSpeaking:Bool = false
	lazy var notifyDoneSpeaking: () -> Void = {arg in}
	lazy var notifyDoneSpeakingB: (@escaping() -> Void) -> Void = {arg in}
	var player: AVAudioPlayer?
	var waitingForDoneBeeping:Bool = false
	lazy var notifyDoneBeeping: () -> Void = {arg in}
	var askedForBeepAfterSpeech:Bool = true
	
	
    public var speechRate : Float = 0.5
    public var voiceOn : Bool = true
    public var volume : Float = 1
    public var voiceChanged : Bool = false
	
	override init() {
		super.init()
		synthesizer.delegate = self
		self.initBeep()
		player?.delegate = self
	}
	
    func say(utterance text: String) {
        if (!voiceOn) {
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }
    
    func immediatelySay(utterance text: String) {
        if (!voiceOn) {
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        synthesizer.speak(utterance)
    }
	
	func immediatelySayEvenIfVoiceIsOff(utterance text: String) {
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
		askedForBeepAfterSpeech = false
	}
	
	//version for beep that takes a callback that takes a callback...yeah
	func waitToFinishSpeakingB(callback: @escaping (_ callbackB: @escaping() -> Void  ) -> Void){
		print("setting the callback")
		notifyDoneSpeakingB = callback
		waitingForDoneSpeaking = true
	}
	
	func waitToFinishSpeakingThenBeep(callback: @escaping () -> Void){
		print("setting the callback")
		notifyDoneSpeakingB = waitToFinishBeeping
		notifyDoneBeeping = callback
		waitingForDoneSpeaking = true
		waitingForDoneBeeping = false
		askedForBeepAfterSpeech = true
	}
	
	func waitToFinishBeeping(callback: @escaping () -> Void){
		print("setting the callback beep")
		waitingForDoneBeeping = true
	}
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		if (self.waitingForDoneBeeping == true){
			self.waitingForDoneBeeping = false
			print("notify that we're done beeping")
			notifyDoneBeeping()
		}
	}
	
	func speechSynthesizer(_ synth: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		if (Speech.shared.waitingForDoneSpeaking == true){
			Speech.shared.waitingForDoneSpeaking = false
			if (!askedForBeepAfterSpeech){
				notifyDoneSpeaking()
			}
			else {
				player?.play()
				notifyDoneSpeakingB(self.notifyDoneBeeping)
			}
		}
	}
	
	func initBeep(){
		//play beep
		let url = Bundle.main.url(forResource: "beep", withExtension: "wav")!
		
		do {
			self.player = try AVAudioPlayer(contentsOf: url)
			guard let player = self.player else { return }
			player.prepareToPlay()
		} catch let error {
			print(error.localizedDescription)
		}
	}
}






