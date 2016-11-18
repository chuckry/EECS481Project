//
//  InputViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class InputViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    @IBOutlet weak var inputDestinationTextField: UITextField!
    var mainViewController: MainViewController!
    var horizontalPageVC: HorizontalPageViewController!
    
    // Apple Speech Recognizer variables
    private let speechRecognizer: SFSpeechRecognizer! = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognizitionAuthorized: Bool = false // assume we don't have authorization
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var recognitionAuthorized: Bool!
    
    private lazy var notifySpeechRecognitionResultAvailable: (String) -> Void = {arg in}
    private var waitingForSpeechRecognitionResultAvailable: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        inputDestinationTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Speech.shared.voiceOn {
            getSpeechRecognitionPermissions()
            disableUIElements()
            "New Destination".say(andThen: startVoiceInteraction)
        } else {
            enableUIElements()
        }
        
    }
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
        Speech.shared.waitingForDoneSpeaking = false
        waitingForSpeechRecognitionResultAvailable = false
        stopRecording()
	}
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
        if(waitingForSpeechRecognitionResultAvailable && inputDestinationTextField?.text != nil) {
            stopRecording()
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        inputDestinationTextField.isUserInteractionEnabled = false
        if inputDestinationTextField?.text != nil && inputDestinationTextField?.text! != "" {
            startNavigation(destination: (inputDestinationTextField?.text)!)
        }
        inputDestinationTextField.isUserInteractionEnabled = true
    }
    
    func startNavigation(destination: String) {
        mainViewController.destinationText = destination
        inputDestinationTextField?.text = nil
        if Speech.shared.voiceOn {
            "Ok, please wait...".say {
                self.horizontalPageVC.moveToMainScreen()
                LocationService.sharedInstance.waitForLocationToBeAvailable(callback: self.mainViewController.initialLocationKnown)
            }
        } else {
            self.horizontalPageVC.moveToMainScreen()
            LocationService.sharedInstance.waitForLocationToBeAvailable(callback: self.mainViewController.initialLocationKnown)
        }
    }
    
    func disableUIElements() {
        inputDestinationTextField.isUserInteractionEnabled = false
    }
    func enableUIElements() {
        inputDestinationTextField.isUserInteractionEnabled = true
    }
    
    func startVoiceInteraction() {
        waitingForSpeechRecognitionResultAvailable = true
        notifySpeechRecognitionResultAvailable = startNavigation
        "Tell me the address you'd like go to.".say(andThen: startRecording)
    }
    
    
    private func startRecording() {
        print("setup for startRecording()")
        inputDestinationTextField?.text = nil
        // cancel the last task if any
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
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
        
        // create an recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("audioEngine has no inputNode!!") // lol
        }
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        // set some options on the request
        recognitionRequest.taskHint = .dictation
        recognitionRequest.shouldReportPartialResults = true
        
        //recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, delegate: self)
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            print("speech recognizer callback called")
            var isFinal = false
            
            if result != nil {
                isFinal = (result?.isFinal)!
                self.inputDestinationTextField?.text = result!.bestTranscription.formattedString
                print("set transcription to: \(self.inputDestinationTextField?.text)")
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if error != nil {
                    print(error?.localizedDescription as Any)
                    do {
                        try audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
                        try audioSession.setMode(AVAudioSessionModeDefault)
                    } catch {
                        print("failed to set audioSession properties")
                    }
                    "I couldn't understand what you said. Returning to Navigation Screen".say(andThen: self.horizontalPageVC.moveToMainScreen)
                }
            }
        })
        
        // set up a tap so output goes to the recognition request buffer
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (AVAudioPCMBuffer, AVAudioTime) in
            self.recognitionRequest?.append(AVAudioPCMBuffer)
        }
        
        // start up the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("error starting audio engine! Have you checked the oil recently?")
        }
        
        // play the Beep
        // playDaBeep()
    }
    
    private func stopRecording() {
        if audioEngine.isRunning {
            print("stopping recording")
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.recognitionTask!.finish()
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
                try audioSession.setMode(AVAudioSessionModeDefault)
            } catch {
                print("failed to set audioSession properties")
            }
            recognitionTask = nil
            if self.waitingForSpeechRecognitionResultAvailable && self.inputDestinationTextField?.text != nil {
                self.waitingForSpeechRecognitionResultAvailable = false
                self.notifySpeechRecognitionResultAvailable((inputDestinationTextField?.text)!)
            }
        }
    }
    
    private func getSpeechRecognitionPermissions() {
        if SFSpeechRecognizer.authorizationStatus() != SFSpeechRecognizerAuthorizationStatus.authorized {
            SFSpeechRecognizer.requestAuthorization { (SFSpeechRecognizerAuthorizationStatus) in
                switch SFSpeechRecognizerAuthorizationStatus {
                case .authorized:
                    self.recognizitionAuthorized = true
                case .denied, .notDetermined, .restricted:
                    self.recognizitionAuthorized = false
                }
            }
        }
    }
}
