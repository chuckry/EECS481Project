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
    
    var currentSettings: Settings = Settings(volumeIn: 10, voiceOnIn: true, voiceSpeedIn: 5, vibrationOnIn: true, beepFrequencyIn: 5)
    var settingToChange : String = ""
    
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
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
	var words: Array<String> = ["VOLUME","VOICE", "VOICEON", "VOICEOFF", "SPEECHRATE", "RATE", "VIBRATIONON", "VIBRATION", "VIBRATIONOFF", "BEEPFREQUENCY"] //array of words to be recognized. Remove spaces in multiple word phrases.
	let openingStatement:String = "Settings. At the tone, speak the name of the setting you would like to edit. Or say, help, to read all available settings. Swipe down to cancel. "
	let helpStatement:String = "You said help. You are on the Settings Page. On this page you can change the following settings: volume, voice on/off, voice speed, vibration on/off, beep frequency. To adjust one of these settings please say the desired setting name after the tone then wait for further instructions."

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
        
        Speech.shared.volume = currentSettings.volume
        Speech.shared.voiceOn = currentSettings.voiceOn
        Speech.shared.speechRate = currentSettings.voiceSpeed
        
        
        volumeChange.value = Double((currentSettings.volume)*10.0)
        volumeChangeLabel.text = "Volume: \(volumeChange.value)"
        
        voiceSwitch.isOn = currentSettings.voiceOn
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice: ON"
        } else {
            voiceSwitchLabel.text = "Voice: OFF"
        }
        
        voiceChange.value = Double(currentSettings.voiceSpeed*10.0)
        voiceChangeLabel.text = "Speech Rate: \(voiceChange.value)"
        
        Stuff.things.vibrationOn = currentSettings.vibrationOn
        vibrationSwitch.isOn = currentSettings.vibrationOn
        if vibrationSwitch.isOn {
            vibrationSwitchLabel.text = "Vibration: ON"
        } else {
            vibrationSwitchLabel.text = "Vibration: OFF"
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
		Speech.shared.waitToFinishSpeaking(callback: self.listen)
	}
	
	func listen(){
		
		//play beep
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
        Speech.shared.volume = Float(volumeChange.value)
        volumeChangeLabel.text = "Volume: \(volumeChange.value)"
        saveSettings()
    }
    
    @IBAction func voiceSwitchToggle(_ sender: AnyObject) {
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice: ON"
        } else {
            voiceSwitchLabel.text = "Voice: OFF"
        }
        
        currentSettings.voiceOn = voiceSwitch.isOn
        Speech.shared.voiceOn = voiceSwitch.isOn
        
        saveSettings()
    }
    
    
    @IBAction func voiceChangeController(_ sender: AnyObject) {
        currentSettings.voiceSpeed = Float(voiceChange.value/10)
        Speech.shared.speechRate = Float(voiceChange.value)
        voiceChangeLabel.text = "Speech Rate: \(voiceChange.value)"
        saveSettings()
    }
    
    @IBAction func vibrationSwitchToggle(_ sender: AnyObject) {
        if vibrationSwitch.isOn {
            Stuff.things.vibrationOn = true;
            currentSettings.vibrationOn = true;
            vibrationSwitchLabel.text = "Vibration: ON"
        }
        else {
            Stuff.things.vibrationOn = false;
            currentSettings.vibrationOn = false;
            vibrationSwitchLabel.text = "Vibration: OFF"
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
		
        let volumeHelpStatement:String = "You have selected the volume setting. To increase the volume, tap the top half of the screen. To decrease the volume, tap the bottom half of the screen."
        let voiceHelpStatement:String = "You have selected the voice on/off setting. Voice is currently" + String(self.voiceSwitch.isOn) + ". To toggle this, please tap the screen once."
        let voiceSpeedHelpStatement:String = "You have selected the voice speed setting. To increase the voice speed, tap the top half of the screen. To decrease the voice speed, tap the bottom half of the screen."
        let vibrationHelpStatement:String = "You have selected the vibration on/off setting. Voice is currently" + String(self.vibrationSwitch.isOn) + ". To toggle this, please tap the screen once."
        let beepFrequencyHelpStatement:String = "You have selected the beep frequency setting. To increase the beep frequency, tap the top half of the screen. To decrease the voice speed, tap the bottom half of the screen."
        
		/*
		STENCIL: Add if/else for every word in your words list. initially stop listening and make sure to use callback function when saying something
		*/
        
		if (hypothesis == "VOLUME"){
			print("HEARD VOLUME")
			self.stopListening()
			Speech.shared.immediatelySay(utterance: volumeHelpStatement)
            self.settingToChange = "VOLUME"
            toggleButtons(on_off: false)

            //Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)

		}
        else if (hypothesis == "VOICE" || hypothesis == "VOICEON" || hypothesis == "VOICEOFF"){
            print("HEARD VOICE HELP")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: voiceHelpStatement)
            self.settingToChange = "VOICE"
            toggleButtons(on_off: false)

            //Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
        }
        else if (hypothesis == "SPEECHSPEED" || hypothesis == "RATE"){
            print("HEARD SPEECHSPEED")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: voiceSpeedHelpStatement)
            self.settingToChange = "SPEECHSPEED"
            toggleButtons(on_off: false)

            //Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)

        }
        else if (hypothesis == "VIBRATION" || hypothesis == "VIBRATIONON" || hypothesis == "VIBRATIONOFF"){
            print("HEARD VIBRATION")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: vibrationHelpStatement)
            self.settingToChange = "VIBRATION"
            toggleButtons(on_off: false)

            //Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)

        }
        else if (hypothesis == "BEEPFREQUENCY"){
            print("HEARD BEEPFREQUENCY")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: beepFrequencyHelpStatement)
            self.settingToChange = "BEEPFREQUENCY"
            toggleButtons(on_off: false)

            //Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
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
    
    func withinBounds(setting: Float, upper: Bool) -> Bool{
        if (upper && setting <= 0.9) {return true}
        if (!upper && setting >= 0.2) {return true}
        
        return false
    }
	
    @IBAction func tapToChangeSettings(_ sender: Any) {
        if (settingToChange == "VOLUME") {
            if tapGesture.location(in: self.inputView).y < (UIScreen.main.bounds.maxY / 2)  && withinBounds(setting: currentSettings.volume, upper: true){
                currentSettings.volume += 0.1
                Speech.shared.say(utterance: "Volume up")
                print ("volume++")
            }
            else if withinBounds(setting: currentSettings.volume, upper: false) {
                currentSettings.volume -= 0.1
                Speech.shared.say(utterance: "Volume down")
                print ("volume--")
            }
            volumeChangeLabel.text = "Volume: \(currentSettings.volume*10)"
            volumeChange.value = Double (currentSettings.volume*10)
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
            toggleButtons(on_off: true)
            settingToChange = ""
        }
        else if (settingToChange == "VOICE") {
            if voiceSwitch.isOn {
                voiceSwitch.isOn = false
                voiceSwitchLabel.text = "Voice: OFF"
                Speech.shared.say(utterance: "Voice Off")

                currentSettings.voiceOn = false
            }
            else {
                voiceSwitch.isOn = true
                voiceSwitchLabel.text = "Voice: ON"
                Speech.shared.say(utterance: "Voice On")

                currentSettings.voiceOn = true
            }
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
            toggleButtons(on_off: true)
            settingToChange = ""
            
        }
        else if (settingToChange == "SPEECHRATE") {
            if tapGesture.location(in: self.inputView).y < (UIScreen.main.bounds.maxY / 2) && withinBounds(setting: currentSettings.voiceSpeed, upper: true){
                currentSettings.voiceSpeed += 0.1
                Speech.shared.say(utterance: "Speech Rate up")
                print ("voice++")
            }
            else if withinBounds(setting: currentSettings.voiceSpeed, upper: false){
                currentSettings.voiceSpeed -= 0.1
                Speech.shared.say(utterance: "Speech Rate down")
                print ("voice--")
            }
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
            voiceChangeLabel.text = "Speech Rate: \(currentSettings.beepFrequency*10)"
            toggleButtons(on_off: true)
            settingToChange = ""
        }
        else if (settingToChange == "VIBRATION") {
            currentSettings.vibrationOn = !currentSettings.vibrationOn
            if (currentSettings.vibrationOn == true) {
                vibrationSwitchLabel.text = "Vibration: ON"
                vibrationSwitch.isOn = true
                Speech.shared.say(utterance: "Vibration On")
            }
            else {
                vibrationSwitchLabel.text = "Vibration: OFF"
                vibrationSwitch.isOn = false
                Speech.shared.say(utterance: "Vibration Off")
            }
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
            toggleButtons(on_off: true)
            settingToChange = ""
        }
        else if (settingToChange == "BEEPFREQUENCY") {
            print("Mid point of screen is: ",UIScreen.main.bounds.maxY / 2)
            print("User taped at: ", tapGesture.location(in: self.inputView).y)
            if tapGesture.location(in: self.inputView).y < (UIScreen.main.bounds.maxY / 2) && withinBounds(setting: currentSettings.beepFrequency, upper: true){
                currentSettings.beepFrequency += 0.1
                Speech.shared.say(utterance: "Beep Frequency up")

                print ("beep++")
            }
            else if withinBounds(setting: currentSettings.beepFrequency, upper: false){
                currentSettings.beepFrequency -= 0.1
                Speech.shared.say(utterance: "Beep Frequency Down")
                print ("beep--")
            }
            beepChangeLabel.text = "Beep Frequency: \(currentSettings.beepFrequency*10)"
            Speech.shared.waitToFinishSpeaking(callback: self.runOpeningSpeech)
            toggleButtons(on_off: true)
            settingToChange = ""
        }
    }
	
    func toggleButtons(on_off : Bool) {
        volumeChange.isEnabled = on_off
        voiceSwitch.isEnabled = on_off
        voiceChange.isEnabled = on_off
        vibrationSwitch.isEnabled = on_off
        beepChange.isEnabled = on_off
    }
	
}

