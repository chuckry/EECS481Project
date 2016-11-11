//
//  SettingsViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation

class SettingsViewController: UIViewController, OEEventsObserverDelegate {
    
    //TODO: implement beep frequency and vibration switch
    // maybe beep frequency coorelates to signifigant change distance?
    
    var currentSettings: Settings = Settings(volumeIn: 1, voiceOnIn: true, voiceSpeedIn: 0.5, vibrationOnIn: true, beepFrequencyIn: 1)
    
    @IBOutlet weak var volumeChangeLabel: UITextField!
    @IBOutlet weak var volumeChange: UIStepper!
    
    @IBOutlet weak var voiceSwitchLabel: UITextField!
    @IBOutlet weak var voiceSwitch: UISwitch!
    
    @IBOutlet weak var voiceChangeLabel: UITextField!
    @IBOutlet weak var voiceChange: UIStepper!
    
    @IBOutlet weak var vibrationSwitchLabel: UITextField!
    @IBOutlet weak var vibrationSwitch: UISwitch!
    
    @IBOutlet weak var beepChangeLabel: UITextField!
    @IBOutlet weak var beepChange: UIStepper!
    
	//voice control variables
	var words: Array<String> = ["HELP"] //array of words to be recognized. Remove spaces in multiple word phrases.
	let openingStatement:String = "Settings. At the tone, speak the name of the setting you would like to edit. Or say, help, to read all available settings. Swipe down to cancel. "
	let helpStatement:String = "You said help. Do something with this"
	//keep adding prompts here
	var openEarsEventsObserver: OEEventsObserver?
	var startFailedDueToLackOfPermissions = Bool()
	var lmPath: String!
	var dicPath: String!
	var player: AVAudioPlayer?
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedSettings = loadSettings() {
            currentSettings = savedSettings
        }
        else {
            saveSettings()
        }
        
        Speech.shared.speechRate = currentSettings.voiceSpeed
        Speech.shared.voiceOn = currentSettings.voiceOn
        Speech.shared.volume = currentSettings.volume
        
        
        volumeChange.value = Double((currentSettings.volume)*10.0)
        volumeChangeLabel.text = "Volume: \(currentSettings.volume)"
        
        voiceSwitch.isOn = currentSettings.voiceOn
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice ON"
        } else {
            voiceSwitchLabel.text = "Voice OFF"
        }
        
        voiceChange.value = Double(currentSettings.voiceSpeed)
        voiceChangeLabel.text = "Voice Speed: \(currentSettings.voiceSpeed)"
        
        Stuff.things.vibrationOn = currentSettings.vibrationOn
        vibrationSwitch.isOn = currentSettings.vibrationOn
        if vibrationSwitch.isOn {
            vibrationSwitchLabel.text = "Vibration ON"
        } else {
            vibrationSwitchLabel.text = "Vibration OFF"
        }
        
        Stuff.things.beepFrequency = currentSettings.beepFrequency
        beepChange.value = Double(currentSettings.beepFrequency)
        beepChangeLabel.text = "Beep Frequency: \(currentSettings.beepFrequency)"

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		loadOpenEars()
		runOpeningSpeech() // what the page should repeatedly say at opening and after other events
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		Speech.shared.waitingForDoneSpeaking = false
		self.stopListening()
		self.openEarsEventsObserver = nil
	}
	
    func saveSettings() {
        let isSucessfulSave = NSKeyedArchiver.archiveRootObject(currentSettings, toFile: Settings.archiveURL.path)
        if !isSucessfulSave {
            print ("Settings were not successfully saved")
        } else {
            print("Setting saved!")
        }
        
    }
    
    func loadSettings() -> Settings? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Settings.archiveURL.path) as? Settings
    }
	
	func runOpeningSpeech(){
		print("running speech")
		Speech.shared.immediatelySay(utterance: self.openingStatement)
		Speech.shared.waitToFinishSpeaking(callback: self.listen)
	}
	
	func listen(){
		
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
	
	func stopListening() {
		print("Stopping listening")
		//Speech.shared.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
		if(OEPocketsphinxController.sharedInstance().isListening){
			let stopListeningError: Error! = OEPocketsphinxController.sharedInstance().stopListening() // React to it by telling Pocketsphinx to stop listening since there is no available input (but only if we are listening).
			if(stopListeningError != nil) {
				print("Error while stopping listening in audioInputDidBecomeUnavailable: \(stopListeningError)")
			}
		}
	}

    
    
    @IBAction func volumeChangeControl(_ sender: AnyObject) {
        currentSettings.volume = Float(volumeChange.value/10)
        volumeChangeLabel.text = "Volume: \(currentSettings.volume)"
        Speech.shared.volume = currentSettings.volume
        saveSettings()
    }
    
    @IBAction func voiceSwitchToggle(_ sender: AnyObject) {
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice ON"
        } else {
            voiceSwitchLabel.text = "Voice OFF"
        }
        
        currentSettings.voiceOn = voiceSwitch.isOn
        Speech.shared.voiceOn = voiceSwitch.isOn
        
        saveSettings()
    }
    
    
    @IBAction func voiceChangeController(_ sender: AnyObject) {
        currentSettings.voiceSpeed = Float(voiceChange.value)
        voiceChangeLabel.text = "Voice Speed: \(currentSettings.voiceSpeed)"
        Speech.shared.speechRate = currentSettings.voiceSpeed
        saveSettings()
        
    }
    
    @IBAction func vibrationSwitchToggle(_ sender: AnyObject) {
        if vibrationSwitch.isOn {
            Stuff.things.vibrationOn = true;
            currentSettings.vibrationOn = true;
            vibrationSwitchLabel.text = "Vibration ON"
        }
        else {
            Stuff.things.vibrationOn = false;
            currentSettings.vibrationOn = false;
            vibrationSwitchLabel.text = "Vibration OFF"
        }
        currentSettings.vibrationOn = vibrationSwitch.isOn
        Stuff.things.vibrationOn = vibrationSwitch.isOn
        
        saveSettings()
    }
    
    
    @IBAction func beepChangeControl(_ sender: AnyObject) {
        Stuff.things.beepFrequency = Float(beepChange.value)
        currentSettings.beepFrequency = Float(beepChange.value)
        beepChangeLabel.text = "Beep Frequency: \(currentSettings.beepFrequency)"
        
        saveSettings()
    }
	
	/////////////////////// openears interface functions///////////////////////
	
	//what happens when each phrase is heard
	func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!){ // Something was heard
		
		print("Local callback: The received hypothesis is \(hypothesis!) with a score of \(recognitionScore!) and an ID of \(utteranceID!)")
		
		/*
		STENCIL: Add if/else for every word in your words list. initially stop listening and make sure to use callback function when saying something
		*/
		if (hypothesis == "HELP"){
			print("HEARD HELP")
			self.stopListening()
			Speech.shared.immediatelySay(utterance: self.helpStatement)
			Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
		}
		
		
	}
	
	// An optional delegate method of OEEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
	// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
	func pocketsphinxRecognitionLoopDidStart() {
		print("Local callback: Pocketsphinx started.") // Log it.
	}
	
	// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
	func pocketsphinxDidStartListening() {
		print("in settings")
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

