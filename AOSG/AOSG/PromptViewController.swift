//
//  PromptViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation

class PromptViewController: UIViewController, OEEventsObserverDelegate {
	
	static let shared = PromptViewController()
	var words: Array<String> = ["CANCEL", "REPEAT", "HELP", "WHEREAMI", "HOWFAR"]
	//var functionArray<(()->())> = []
	let openingStatement:String = "Voice Commands. At the tone, speak your voice command. Or say ,list, to read all available prompts. Swipe up to cancel. "
	let helpStatement:String = "Say , Where am I, to tell you the current city and nearest intersection. Say, How far, to tell distance and time to dfinal destination. Say, repeat, to repeat the last navigation direction. Say, cancel, to stop navigation. "
	
	var player: AVAudioPlayer?
	var listener:openEarsManager!
	
	public var message:String!
    override func viewDidLoad() {
        super.viewDidLoad()
		
		print(Stuff.things.message)

		listener = openEarsManager(wordListIn:words)
		listener.loadOpenEars()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		openingSpeech()
	}
	
	func openingSpeech(){
		Speech.shared.immediatelySay(utterance: openingStatement)
		
		while(Speech.shared.synthesizer.isSpeaking){
		}
		
		//play a system sound -- cleaner if you can find a sound you like
		//AudioServicesPlaySystemSound (1070)
		
		let url = Bundle.main.url(forResource: "beep", withExtension: "wav")!
		
		do {
			player = try AVAudioPlayer(contentsOf: url)
			guard let player = player else { return }
			player.prepareToPlay()
			player.play()
		} catch let error as Error {
			print(error.localizedDescription)
		}
		listener.wordGuess = ""
		listener.startListening()
	}
	
	func helpFunction(){
		listener.stopListening()
		Speech.shared.immediatelySay(utterance: helpStatement)
		self.openingSpeech()
	}
	
	func cancelFunction(){
		
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	
	


}
