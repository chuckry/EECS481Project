//
//  SettingsViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation

class SettingsViewController: UIViewController, OEEventsObserverDelegate  {
    
    //TODO: implement beep frequency and vibration switch
    // maybe beep frequency coorelates to signifigant change distance?
    
    var currentSettings: Settings = Settings(volumeIn: 1, voiceOnIn: true, voiceSpeedIn: 0.6, beepOnIn: true)
    var settingToChange : String = ""
    
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    @IBOutlet weak var volumeChangeLabel: UITextField!
    @IBOutlet weak var volumeChange: UIStepper!
    
    @IBOutlet weak var voiceSwitchLabel: UITextField!
    @IBOutlet weak var voiceSwitch: UISwitch!
    
    @IBOutlet weak var voiceChangeLabel: UITextField!
    @IBOutlet weak var voiceChange: UIStepper!
    
    @IBOutlet weak var beepSwitchLabel: UITextField!
    @IBOutlet weak var beepSwitch: UISwitch!
    
    
	//voice control variables
    //array of words to be recognized. Remove spaces in multiple word phrases.
	var words: Array<String> = ["VOLUME","VOICE", "VOICEON", "VOICEOFF", "SPEECHRATE", "SPEECHSPEED", "RATE", "BEEP"]
    
	let openingStatement:String = "Settings. For instructions say, help."
	let helpStatement:String = "You are on the Settings Page. On this page you can change the following settings: volume, voice controls, voice speed. To adjust one of these settings, please say the desired setting name after the tone."

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
        print ("Saved voice speed = ", currentSettings.voiceSpeed)
        
        if (Speech.shared.voiceChanged == true) {
            currentSettings.voiceOn = Speech.shared.voiceOn
        }
        
        
        // Initilize Speech Settings
        Speech.shared.volume = currentSettings.volume
        Speech.shared.voiceOn = currentSettings.voiceOn
        Speech.shared.speechRate = currentSettings.voiceSpeed
        
        if (currentSettings.voiceOn) {
            toggleButtons(on_off : false)
        }
        else {
            toggleButtons(on_off : true)
        }
        
        // Load Volume
        volumeChange.value = Double((currentSettings.volume)*10.0)
        volumeChangeLabel.text = "Volume: \(Int(volumeChange.value))"
        
        // Load Voice On / Off
        voiceSwitch.isOn = currentSettings.voiceOn
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice: ON"
        } else {
            voiceSwitchLabel.text = "Voice: OFF"
        }
        
        // Load Speech Rate
        voiceChange.value = Double(currentSettings.voiceSpeed*10.0)
        voiceChangeLabel.text = "Speech Rate: \(Int(voiceChange.value))"
        
        // Load Beep On / Off
        Stuff.things.beepOn = currentSettings.beepOn
        beepSwitch.isOn = currentSettings.beepOn
        if beepSwitch.isOn {
            beepSwitchLabel.text = "Sound: ON"
            Stuff.things.beepOn = true
        } else {
            beepSwitchLabel.text = "Sound: OFF"
            Stuff.things.beepOn = false
        }

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (Speech.shared.voiceChanged == true) {
            currentSettings.voiceOn = Speech.shared.voiceOn
            voiceSwitch.isOn = currentSettings.voiceOn
            if voiceSwitch.isOn {
                voiceSwitchLabel.text = "Voice: ON"
                toggleButtons(on_off: false)
            }
            else {
                voiceSwitchLabel.text = "Voice: OFF"
                toggleButtons(on_off: true)
            }
        }
        
        Speech.shared.voiceChanged = false
        
        if (!currentSettings.voiceOn) {
            Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Settings")
        }
        else {
            loadOpenEars()
            runOpeningSpeech() // what the page should repeatedly say at opening and after other events
        }
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		Speech.shared.waitingForDoneSpeaking = false
		self.stopListening()
		self.openEarsEventsObserver = nil
	}
	
    func saveSettings() {
        Speech.shared.speechRate = currentSettings.voiceSpeed
        Speech.shared.voiceOn = currentSettings.voiceOn
        Speech.shared.volume = currentSettings.volume
        
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
		Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
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
		// create a audio session
		let audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession.setCategory(AVAudioSessionCategoryRecord)
			try audioSession.setMode(AVAudioSessionModeMeasurement)
			//try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
		} catch {
			print("failed to set audioSession properties")
		}

		print("Starting listening")
		OEPocketsphinxController.sharedInstance().startListeningWithLanguageModel(atPath: lmPath, dictionaryAtPath: dicPath, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: false)
	}
	
	func stopListening() {
		let audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
			try audioSession.setMode(AVAudioSessionModeDefault)
		} catch {
			print("failed to set audioSession properties")
		}

		print("Stopping listening")
		//Speech.shared.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
		if(OEPocketsphinxController.sharedInstance().isListening){
			let stopListeningError: Error! = OEPocketsphinxController.sharedInstance().stopListening() // React to it by telling Pocketsphinx to stop listening since there is no available input (but only if we are listening).
			if(stopListeningError != nil) {
				print("Error while stopping listening in audioInputDidBecomeUnavailable: \(stopListeningError)")
			}
		}
	}

    
    @IBOutlet var toggleVoiceOnOff: UILongPressGestureRecognizer!
    @IBAction func toggleVoiceAction(_ sender: Any) {
        if (toggleVoiceOnOff.state == UIGestureRecognizerState.began) {
            print ("tap toggled voice on/off")
            
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            if Speech.shared.voiceOn {
                stopListening()
                Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Voice Off")
                Speech.shared.voiceOn = false
                Speech.shared.voiceChanged = true
                voiceSwitchLabel.text = "Voice: OFF"
                voiceSwitch.isOn = false
                currentSettings.voiceOn = false
                toggleButtons(on_off: true)
            }
            else {
                Speech.shared.voiceOn = true
                Speech.shared.voiceChanged = true
                voiceSwitchLabel.text = "Voice: ON"
                voiceSwitch.isOn = true
                currentSettings.voiceOn = true
                toggleButtons(on_off: false)
                //loadOpenEars()
                Speech.shared.say(utterance: "Voice On")
                Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
                // what the page should repeatedly say at opening and after other events
            }
            saveSettings()
        }
    }
    
    @IBAction func volumeChangeControl(_ sender: AnyObject) {
        currentSettings.volume = Float(volumeChange.value/10)
        Speech.shared.volume = Float(volumeChange.value)
        volumeChangeLabel.text = "Volume: \(Int(volumeChange.value))"
        saveSettings()
    }
    
    @IBAction func voiceSwitchToggle(_ sender: AnyObject) {
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice: ON"
            toggleButtons(on_off : false)
            currentSettings.voiceOn = true
            Speech.shared.voiceOn = true
            saveSettings()
            runOpeningSpeech()

        } else {
            voiceSwitchLabel.text = "Voice: OFF"
            toggleButtons(on_off : true)
            currentSettings.voiceOn = false
            Speech.shared.voiceOn = false
            saveSettings()
        }
    }
    
    
    @IBAction func voiceChangeController(_ sender: AnyObject) {
        currentSettings.voiceSpeed = Float(voiceChange.value/10)
        Speech.shared.speechRate = Float(voiceChange.value)
        voiceChangeLabel.text = "Speech Rate: \(Int(voiceChange.value))"
        saveSettings()
    }
    
    @IBAction func beepSwitchToggle(_ sender: Any) {
        if beepSwitch.isOn {
            Stuff.things.beepOn = true;
            currentSettings.beepOn = true;
            beepSwitchLabel.text = "Sound: ON"
            Stuff.things.beepOn = true
            Stuff.things.routeManager.soundManager.audioPlayer.play()
        }
        else {
            Stuff.things.beepOn = false;
            currentSettings.beepOn = false;
            beepSwitchLabel.text = "Sound: OFF"
            Stuff.things.beepOn = false
            Stuff.things.routeManager.soundManager.audioPlayer.stop()
        }
        currentSettings.beepOn = beepSwitch.isOn
        Stuff.things.beepOn = beepSwitch.isOn
        
        saveSettings()
    }
	
	/////////////////////// openears interface functions///////////////////////
    func boolToOnOff(on_off : Bool) -> String {
        if on_off {
            return "on"
        }
        return "off"
    }
	//what happens when each phrase is heard
	func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!){ // Something was heard
		
		print("Local callback: The received hypothesis is \(hypothesis!) with a score of \(recognitionScore!) and an ID of \(utteranceID!)")
		
        let volumeHelpStatement:String = "You have selected the volume setting. To increase the volume, tap the top half of the screen. To decrease the volume, tap the bottom half of the screen."
        let voiceHelpStatement:String = "You have selected the voice on/off setting. Voice is " + boolToOnOff(on_off : self.voiceSwitch.isOn) + ". To toggle this, please tap the screen once."
        let voiceSpeedHelpStatement:String = "You have selected the voice speed setting. To increase the voice speed, tap the top half of the screen. To decrease the voice speed, tap the bottom half of the screen."
        let beepHelpStatement:String = "You have selected the beep on/off setting. Beeping is " + boolToOnOff(on_off : self.beepSwitch.isOn) + ". To toggle this, please tap the screen once."

        
		/*
		STENCIL: Add if/else for every word in your words list. initially stop listening and make sure to use callback function when saying something
		*/
        
		if (hypothesis == "VOLUME"){
			print("HEARD VOLUME")
			self.stopListening()
			Speech.shared.immediatelySay(utterance: volumeHelpStatement)
            self.settingToChange = "VOLUME"
		}
        else if (hypothesis == "VOICE" || hypothesis == "VOICEON" || hypothesis == "VOICEOFF"){
            print("HEARD VOICE")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: voiceHelpStatement)
            self.settingToChange = "VOICE"
        }
        else if (hypothesis == "SPEECHSPEED" || hypothesis == "SPEECHRATE" || hypothesis == "RATE"){
            print("HEARD SPEECHRATE")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: voiceSpeedHelpStatement)
            self.settingToChange = "SPEECHSPEED"
        }
        else if (hypothesis == "BEEP"){
            print("HEARD BEEP")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: beepHelpStatement)
            self.settingToChange = "BEEP"
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
	
    @IBAction func tapToChangeSettings(_ sender: Any) {
        if (settingToChange == "VOLUME") {
            if (tapGesture.location(in: self.inputView).y < (UIScreen.main.bounds.maxY / 2)) {
                if (volumeChange.value < 10) {
                    volumeChange.value += 1
                    Speech.shared.say(utterance: "Volume up")
                    print ("volume++")
                }
                else {
                    Speech.shared.say(utterance: "Volume is already at max")
                }
            }
            else if (tapGesture.location(in: self.inputView).y >= (UIScreen.main.bounds.maxY / 2)) {
                if (volumeChange.value > 0) {
                    volumeChange.value -= 1
                    Speech.shared.say(utterance: "Volume down")
                    print ("volume--")
                }
                else {
                    Speech.shared.say(utterance: "Volume is already at min")
                }
            }
            volumeChangeLabel.text = "Volume: \(Int(volumeChange.value))"
            currentSettings.volume = Float(volumeChange.value/10)
            settingToChange = ""
            Speech.shared.volume = Float(volumeChange.value/10)
            saveSettings()
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
        }
        else if (settingToChange == "VOICE") {
            if voiceSwitch.isOn {
                voiceSwitch.isOn = false
                voiceSwitchLabel.text = "Voice: OFF"
                Speech.shared.say(utterance: "Voice Off")
                Speech.shared.voiceOn = false
                currentSettings.voiceOn = false
                toggleButtons(on_off : true)
            }
            else {
                voiceSwitch.isOn = true
                voiceSwitchLabel.text = "Voice: ON"
                Speech.shared.say(utterance: "Voice On")
                Speech.shared.voiceOn = true
                currentSettings.voiceOn = true
                toggleButtons(on_off : false)

            }
            print ("wait for speech to finish speaking then call opening speech")
            settingToChange = ""
            saveSettings()
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
        }
            
        else if (settingToChange == "SPEECHSPEED") {
            if (tapGesture.location(in: self.inputView).y < (UIScreen.main.bounds.maxY / 2)) {
                if (voiceChange.value < 10) {
                    voiceChange.value += 1
                    Speech.shared.say(utterance: "Speech Rate up")
                    print ("voice++")
                }
                else {
                    Speech.shared.say(utterance: "Speech is already at max rate")
                }
            }
            else if (tapGesture.location(in: self.inputView).y >= (UIScreen.main.bounds.maxY / 2)){
                if (voiceChange.value > 1) {
                    voiceChange.value -= 1
                    Speech.shared.say(utterance: "Speech Rate down")
                    print ("voice--")
                }
                else {
                    Speech.shared.say(utterance: "Speech is already at min rate")
                }
            }
            voiceChangeLabel.text = "Speech Rate: \(Int(voiceChange.value))"
            currentSettings.voiceSpeed = Float(voiceChange.value/10)
            Speech.shared.speechRate = Float(voiceChange.value/10)
            settingToChange = ""
            saveSettings()
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
        }
        else if (settingToChange == "BEEP") {
            currentSettings.beepOn = !currentSettings.beepOn
            if (currentSettings.beepOn == true) {
                beepSwitchLabel.text = "Sound: ON"
                beepSwitch.isOn = true
                Speech.shared.say(utterance: "Sound On")
                Stuff.things.beepOn = true
                Stuff.things.routeManager.soundManager.audioPlayer.play()
            }
            else {
                beepSwitchLabel.text = "Sound: OFF"
                beepSwitch.isOn = false
                Speech.shared.say(utterance: "Sound Off")
                Stuff.things.beepOn = false
                Stuff.things.routeManager.soundManager.audioPlayer.stop()
            }
            Stuff.things.beepOn = beepSwitch.isOn
            settingToChange = ""
            saveSettings()
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
        }
    }
	
    func toggleButtons(on_off : Bool) {
        volumeChange.isEnabled = on_off
        voiceSwitch.isEnabled = on_off
        voiceChange.isEnabled = on_off
        beepSwitch.isEnabled = on_off
    }
	
}

