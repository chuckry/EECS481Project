//
//  PromptViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import AVFoundation


class PromptViewController: UIViewController, OEEventsObserverDelegate,  UIGestureRecognizerDelegate{
	
	static let shared = PromptViewController()
    let locationManager = LocationService.sharedInstance
	var words: Array<String> = ["CANCEL", "REPEAT", "HELP", "WHEREAMI", "HOWFAR"]
	let openingStatement:String = "Voice Commands. At the tone, speak your voice command. Or say ,help, to read all available prompts. Swipe down to cancel. "
	let helpStatement:String = "Help. Say , Where am I, to tell you the current city and nearest intersection. Say, How far, to tell distance and time to final destination. Say, repeat, to repeat the last navigation direction. Say, cancel, to stop navigation. "
	let verifyCancelStatement:String = "Are you sure you would like to cancel your route? Double tap the screen to confirm or swipe right to continue navigation. "
	let navErrorStatement: String = "Navigation has not yet begun. "
	let cancelDeclinedStatement: String = "Not cancelling route. "
	var howFarStatement: String = ""
	
	var player: AVAudioPlayer?
	var wordGuess:String = ""
	var openEarsEventsObserver: OEEventsObserver?
	var startFailedDueToLackOfPermissions = Bool()
	var lmPath: String!
	var dicPath: String!
	var previouslyHeardCancel:Bool = false;

	
	public var verticalPageVC:VerticalPageViewController!
	
	override func viewDidLoad() {
        super.viewDidLoad()
	}
	@IBAction func tapDetected(_ sender: UITapGestureRecognizer) {
		print("tapped")
		if (previouslyHeardCancel == true){
			Stuff.things.cancelled = true
			verticalPageVC.returnToMainScreen()
		}
	}
	@IBAction func swipeDetected(_ sender: UISwipeGestureRecognizer) {
		print("swiped")
		if (previouslyHeardCancel == true){
			self.previouslyHeardCancel = false
			Speech.shared.immediatelySay(utterance: self.cancelDeclinedStatement)
			Speech.shared.waitToFinishSpeaking(callback: self.runSpeech)
		}
	}

	
	//play opening message everytime page is opened
	override func viewDidAppear(_ animated: Bool) {
		previouslyHeardCancel = false;
		super.viewDidAppear(animated)
		loadOpenEars()
		runSpeech()
	}
	
	//stop listening and cancel callback when we leave the view
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		Speech.shared.waitingForDoneSpeaking = false
		self.stopListening()
		self.openEarsEventsObserver = nil
	}
	
	func runSpeech(){
		print("running speech")
		Speech.shared.immediatelySay(utterance: self.openingStatement)
		Speech.shared.waitToFinishSpeaking(callback: self.speechFinished)
	}
	
	//runs when initial speech is finished
	func speechFinished(){

		//plap beep
		let url = Bundle.main.url(forResource: "beep", withExtension: "wav")!

		do {
			self.player = try AVAudioPlayer(contentsOf: url)
			guard let player = self.player else { return }
			player.prepareToPlay()
			player.play()
		} catch let error {
			print(error.localizedDescription)
		}
		self.startListening()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func loadOpenEars() {
		openEarsEventsObserver = OEEventsObserver()
		openEarsEventsObserver?.delegate = self;
		
		let lmGenerator: OELanguageModelGenerator = OELanguageModelGenerator()
		
		let name = "LanguageModelFileStarSaver"
		lmGenerator.generateLanguageModel(from: words, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
		
		lmPath = lmGenerator.pathToSuccessfullyGeneratedLanguageModel(withRequestedName: name)
		dicPath = lmGenerator.pathToSuccessfullyGeneratedDictionary(withRequestedName: name)
  
	}
	
	func startListening() {
		do {
			try	OEPocketsphinxController.sharedInstance().setActive(true)
		}
		catch{
			print ("fail")
		}
		print("Starting listening")
		OEPocketsphinxController.sharedInstance().startListeningWithLanguageModel(atPath: lmPath, dictionaryAtPath: dicPath, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: false)
	}

    /*
     *  Upon entering a location, we tell the user what the nearest location is
     */
    func whereAmI() -> String? {
        if locationManager.lastLocation != nil {
            let intersection = locationManager.getNearestIntersection()
            return intersection
        } else {
            print("Couldn't get current location!")
            return nil
        }
    }

	func stopListening() {
		print("Stopping listening")
		//Speech.shared.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
		if (OEPocketsphinxController.sharedInstance().isListening){
			let stopListeningError: Error! = OEPocketsphinxController.sharedInstance().stopListening() // React to it by telling Pocketsphinx to stop listening since there is no available input (but only if we are listening).
			if (stopListeningError != nil) {
				print("Error while stopping listening in audioInputDidBecomeUnavailable: \(stopListeningError)")
			}
		}
		
	}
	
	func noop() {
		print("noop")
	}
	
/////////////////////// openears interface functions///////////////////////
	
	//what happens when each phrase is heard
	func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!){ // Something was heard
		
		print("Local callback: The received hypothesis is \(hypothesis!) with a score of \(recognitionScore!) and an ID of \(utteranceID!)")
		
		if (hypothesis != "CANCEL") {
			self.previouslyHeardCancel = false;
		}
		
		if (hypothesis == "HELP") {
			print("HEARD HELP")
			self.stopListening()
			Speech.shared.immediatelySay(utterance: self.helpStatement)
			Speech.shared.waitToFinishSpeaking(callback: self.runSpeech)
		}
            
        if (hypothesis == "WHEREAMI") {
            print("HEARD WHEREAMI")
            self.stopListening()
            let intersection = self.whereAmI()
            Speech.shared.immediatelySay(utterance: (intersection != nil) ? intersection! : "Sorry. I could not find the nearest intersection.")
            print("Intersection: \(intersection!)")
            Speech.shared.waitToFinishSpeaking(callback: self.runSpeech)
        }
		
		else if (hypothesis == "CANCEL") {
			print("HEARD CANCEL")
			self.stopListening()
			//verify that the user wanted to cancel
			if (Stuff.things.currentStepDescription == ""){
				Speech.shared.immediatelySay(utterance: self.navErrorStatement)
				Speech.shared.waitToFinishSpeaking(callback: self.runSpeech)
			}
			else {
				Speech.shared.immediatelySay(utterance: self.verifyCancelStatement)
				Speech.shared.waitToFinishSpeaking(callback: self.noop)
			
				self.previouslyHeardCancel = true;
				//allows gesture recognizers to be triggered
			}
		}

		else if (hypothesis == "REPEAT"){
			print("HEARD REPEAT")
			self.stopListening()
			if (Stuff.things.currentStepDescription == ""){
				Speech.shared.immediatelySay(utterance: self.navErrorStatement)
			}
			else{
				Speech.shared.immediatelySay(utterance: Stuff.things.currentStepDescription)
			}
			Speech.shared.waitToFinishSpeaking(callback: self.runSpeech)
		}
			
		else if (hypothesis == "HOWFAR"){
			print("HEARD HOW FAR")
			self.stopListening()
			if (Stuff.things.currentStepDescription == ""){
				Speech.shared.immediatelySay(utterance: self.navErrorStatement)
			}
			else {
				var dist = Stuff.things.sumDists() //m
				let pace = Stuff.things.getPace() //s/m
				var timeEst = dist*pace //s
				dist = dist * 0.000621371 //miles
				
				var arrivalTime = Date()
				let cal = NSCalendar.current
				arrivalTime = cal.date(byAdding: .second, value:Int(timeEst), to: Date())!
				let formatter = DateFormatter()
				formatter.dateFormat = "h:mm a"
				formatter.amSymbol = "AM"
				formatter.pmSymbol = "PM"
				
				timeEst = timeEst/60 //minutes
				self.howFarStatement = "You will arrive at your destination in \(Double(round(10*dist)/10)) miles at \(formatter.string(from: arrivalTime)) in \(Int(round(1*timeEst)/1)) minutes"
				print(howFarStatement)
				Speech.shared.immediatelySay(utterance: self.howFarStatement)
			}
			Speech.shared.waitToFinishSpeaking(callback: self.runSpeech)
			
		}
		//keep adding prompts
	}
	
	// An optional delegate method of OEEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
	// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
	func pocketsphinxRecognitionLoopDidStart() {
		print("Local callback: Pocketsphinx started.") // Log it.
	}
	
	// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
	func pocketsphinxDidStartListening() {
		print("in prompt")
		print("Local callback: Pocketsphinx is now listening.") // Log it.
	}
	
	// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
	func pocketsphinxDidDetectSpeech() {
		print("Local callback: Pocketsphinx has detected speech.") // Log it.
	}
	
	// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance.
	func pocketsphinxDidDetectFinishedSpeech() {
		print("Local callback: Pocketsphinx has detected a second of silence, concluding an utterance.") // Log it.
	}
	
	// An optional delegate method of OEEventsObserver which informs that Pocketsphinx has exited its recognition loop, most
	// likely in response to the OEPocketsphinxController being told to stop listening via the stopListening method.
	func pocketsphinxDidStopListening() {
		print("Local callback: Pocketsphinx has stopped listening.") // Log it.
	}
	
	// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
	// Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
	// in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
	// or as a result of the OEPocketsphinxController being told to suspend recognition via the suspendRecognition method.
	func pocketsphinxDidSuspendRecognition() {
		print("Local callback: Pocketsphinx has suspended recognition.") // Log it.
	}
	
	// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
	// having been suspended it is now resuming.  This can happen as a result of Flite speech completing
	// on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
	// or as a result of the OEPocketsphinxController being told to resume recognition via the resumeRecognition method.
	func pocketsphinxDidResumeRecognition() {
		print("Local callback: Pocketsphinx has resumed recognition.") // Log it.
	}
	
	// An optional delegate method which informs that Pocketsphinx switched over to a new language model at the given URL in the course of
	// recognition. This does not imply that it is a valid file or that recognition will be successful using the file.
	func pocketsphinxDidChangeLanguageModel(toFile newLanguageModelPathAsString: String!, andDictionary newDictionaryPathAsString: String!) {
		
		print("Local callback: Pocketsphinx is now using the following language model: \n\(newLanguageModelPathAsString!) and the following dictionary: \(newDictionaryPathAsString!)")
	}
	
	
	func pocketSphinxContinuousSetupDidFail(withReason reasonForFailure: String!) { // This can let you know that something went wrong with the recognition loop startup. Turn on [OELogging startOpenEarsLogging] to learn why.
		print("Local callback: Setting up the continuous recognition loop has failed for the reason \(reasonForFailure), please turn on OELogging.startOpenEarsLogging() to learn more.") // Log it.
	}
	
	func pocketSphinxContinuousTeardownDidFail(withReason reasonForFailure: String!) { // This can let you know that something went wrong with the recognition loop startup. Turn on OELogging.startOpenEarsLogging() to learn why.
		print("Local callback: Tearing down the continuous recognition loop has failed for the reason \(reasonForFailure)") // Log it.
	}
	
	/** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
	func pocketsphinxFailedNoMicPermissions() {
		print("Local callback: The user has never set mic permissions or denied permission to this app's mic, so listening will not start.")
	}
	
	/** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a true or a false result  (will only be returned on iOS7 or later).*/
	
	func micPermissionCheckCompleted(withResult: Bool) {
		print("Local callback: mic check completed.")
	}
}
