//
//  FavoritesVoiceController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 11/12/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import Speech
import Dispatch

protocol FavoritesVoiceControllerDelegate {
    // add protocol definition in here
    func favoritesVoiceController(addNewFavorite: Favorite)
    func favoritesVoiceController(deleteFavorite: Favorite)
    func favoritesVoiceController(selectFavorite: Favorite)
}



class FavoritesVoiceController: NSObject, OEEventsObserverDelegate, SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate  {
    
    // MARK: Properties
    
    var delegate: FavoritesVoiceControllerDelegate?
    
    struct Confirmations {
        static let opening: String  = "Say, back to go back at any time. Say, repeat to repeat the actions you can take. Swipe left at any time to leave this menu."
        static let edit: String = "Editing"
        static let list: String = "Listing all favorites"
        static let add: String = "Adding a favorite"
        static let addName: String = "This favorite will be named "
        static let useCurrentLocation: String = "Finding and using your current location"
        static let useDictatedAddress: String = "Using a dictated address"
        static let favoriteSaved: String = "Saved this favorite"
        static let delete: String = "Delete a favorite"
        static let selected: String = "Favorite selected"
        static let deleteExecuted: String = "Deleted this favorite"
        static let notAuthorized: String = "Steereo is unable to use speech recognition. Make sure you have a good internet connection and that you've granted Steereo the ability to use speech recognition in your iPhone settings."
        static let currentLocationUnknown: String = "Steereo was unable to find your current location. Make sure location services are enabled."
        static let canceledLastAction: String = "Canceled this action."
        static let back: String = "Going back"
        static let couldYouRepeatThat: String = "I'm sorry. Could you repeat that?"
    }
    
    struct MenuOptions {
        static let root: String = "At the tone, say the name of a favorite destination, or say, list, to read saved favorites. Say, edit, to add or delete saved favorites."
        static let edit: String = "At the tone say, add, to add a new favorite. Or say, delete, to delete a saved favorite"
        static let addStepOne: String = "First, At the tone, say a short, unique name for your favorite location. When you're done, tap the screen."
        static let addStepTwo: String = "Next, at the tone, say, here, if you want to save your current address. Say, dictate, if you want to save another address."
        static let addStepThree: String = "Next, at the tone, say the address you'd like to save. Including the city, state and zip code. When you're done, tap the screen."
        static let addConfirmPre: String = "Finally confirm the details of this favorite."
        static let addConfirmPost: String = "At the tone, Say, save, to save this favorite. Say, back, to start over."
        static let delete: String = "At the tone say the name of a saved favorite to select it."
        static let deleteConfirmPre: String = "You're about to delete a favorite"
        static let deleteConfirmPost: String = "At the tone, say, confirm, to delete this favorite. Say, back, to start over"
    }
    // Base commands
    private var words: [String] = ["LIST", "EDIT", "ADD", "DELETE", "HERE", "DICTATE", "SAVE", "BACK", "CONFIRM", "REPEAT"]
    
    // Saved Favorites as commands
    private var favoritesDictionary: [String:Favorite] = [:]
    
    // Openears variables
    private var openEarsEventsObserver: OEEventsObserver?
    private let languageModelFileName: String = "LanguageModelFileStarSaver"
    private var languageModelPath: String!
    private var dictionaryPath: String!
    private var player: AVAudioPlayer?
    
    // Apple Speech Recognizer variables
    private let speechRecognizer: SFSpeechRecognizer! = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognizitionAuthorized: Bool = false // assume we don't have authorization
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var transcription: String!
    
    private lazy var notifySpeechRecognitionResultAvailable: (String) -> Void = {arg in}
    private var waitingForSpeechRecognitionResultAvailable: Bool = false
	
	public var openingStatement = "Favorites" + Confirmations.opening + MenuOptions.root
    
//    private lazy var notifyTapOccurred: () -> Void = {arg in}
//    private var waitingForTapOccurred: Bool = false
    
    // State maintainance
    enum states {
        case root
        case edit
        case add1
        case add2
        case add3
        case addConfirm
        case del
        case delConfirm
    }
    var state = states.root
    var favoriteTemplate: Favorite?
    
    // MARK: Initializers
    override init() {
        super.init()
        reloadOpenEars()
        speechRecognizer.delegate = self
        getSpeechRecognitionPermissions()
        recognizitionAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    init(withFavorites favorites: [Favorite]) {
        super.init()
        addToDictionary(favorites: favorites)
        speechRecognizer.delegate = self
        getSpeechRecognitionPermissions()
        recognizitionAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    // MARK: Public Methods
    
    public func addToDictionary(favorites items: [Favorite]) {
        // only append the elements in items and not in words (ignores the intersection)
        for item in items {
            let recognizableWord = makeRecognizableWord(phrase: item.name)
            if words.index(of: recognizableWord) == nil {
                words.append(recognizableWord)
                favoritesDictionary[recognizableWord] = item
            }
        }
        reloadOpenEars()
    }
    
    public func removeFromDictionary(favorite item: Favorite) {
        let recognizableWord = makeRecognizableWord(phrase: item.name)
        if favoritesDictionary[recognizableWord] != nil {
            favoritesDictionary.removeValue(forKey: recognizableWord)
            words.remove(at: words.index(of: recognizableWord)!)
        }
        reloadOpenEars()
    }

    
    public func stopUsingVoiceControlMenu() {
        // clean up the controls
        Speech.shared.waitingForDoneSpeaking = false
        waitingForSpeechRecognitionResultAvailable = false
        state = .root
        stopListening()
        stopRecording()
    }
    
    public func tapRegistered() {
        switch state {
        case .add1, .add3:
            // Tapped to stop dictation
            print("voiceController tapRegistered() called")
            if waitingForSpeechRecognitionResultAvailable && self.transcription != nil {
                self.stopRecording()
            }
        default: break
        }
    }
    
    // MARK: Private Voice Controller Logic
    
    private func playListFavorites() {
        var statement = ""
        if favoritesDictionary.count == 0 {
            statement = "You don't have any saved favorites"
        } else {
            var count = 1
            for command in favoritesDictionary {
                statement += " \(count). \(command.value.name), "
                count += 1
            }
        }
        statement.say {
			Speech.shared.immediatelySay(utterance: MenuOptions.root)
			Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
        }
    }
    
    private func handleDictatedFavoriteName(name: String) {
        print("handling dictated name: \(name)")
        reloadOpenEars()
        favoriteTemplate = Favorite(withName: name, withAddress: "")
        state = .add2
        (Confirmations.addName + name).say {
			Speech.shared.immediatelySay(utterance: MenuOptions.addStepTwo)
			Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
        }
    }
    
    private func handleCurrentAddressIsAvailable(address: String?) {
        if favoriteTemplate != nil && address != nil {
            favoriteTemplate!.address = address!
            state = .addConfirm
			Speech.shared.immediatelySay(utterance: (MenuOptions.addConfirmPre + "\(favoriteTemplate!.name) is at \(favoriteTemplate!.address). " + MenuOptions.addConfirmPost))
			Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
        }
        if address == nil {
            state = .root
            Confirmations.currentLocationUnknown.say {
				Speech.shared.immediatelySay(utterance: MenuOptions.root)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            }
        }
    }
    
    private func handleDictatedFavoriteAddress(address: String) {
        print("handling dictated address: \(address)")
        reloadOpenEars()
        if favoriteTemplate != nil {
            favoriteTemplate!.address = address
            state = .addConfirm
			Speech.shared.immediatelySay(utterance: (MenuOptions.addConfirmPre + "\(favoriteTemplate!.name) is at \(favoriteTemplate!.address). " + MenuOptions.addConfirmPost))
			Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
			
        }
    }
    
    // MARK: Openears hypothesis detection

    func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!) {
        // Something was heard
        print("Local callback: The received hypothesis is \(hypothesis!) with a score of \(recognitionScore!) and an ID of \(utteranceID!)")
        
        /*
         STENCIL: Add if/else for every word in your words list. initially stop listening and make sure to use callback function when saying something
         */
        switch state {
        // root menu options
        case .root:
            if hypothesis! == "LIST"{
                self.stopListening()
                Confirmations.list.say(andThen: self.playListFavorites)
            } else if hypothesis! == "EDIT"{
                self.stopListening()
                state = .edit
                Confirmations.edit.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.edit)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else if hypothesis! == "REPEAT" {
                self.stopListening()
				Speech.shared.immediatelySay(utterance: MenuOptions.root)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            } else {
                guard let possibleFavoriteName = hypothesis else { return }
                if let favorite = favoritesDictionary[possibleFavoriteName] {
                    if self.delegate != nil {
                        Confirmations.selected.say {
                            self.delegate?.favoritesVoiceController(selectFavorite: favorite)
                        }
                    }
                    state = .root
                } else {
                    // pocketsphinx can be hard of hearing sometimes
                    self.stopListening()
					Speech.shared.immediatelySay(utterance: Confirmations.couldYouRepeatThat)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            }
        // edit menu options
        case .edit:
            if hypothesis! == "ADD" {
                self.stopListening()
                state = .add1
                waitingForSpeechRecognitionResultAvailable = true
                notifySpeechRecognitionResultAvailable = handleDictatedFavoriteName
                openEarsEventsObserver = nil
                print("set up handler for recognition result")
                Confirmations.add.say {
                    if !self.recognizitionAuthorized {
                        self.state = .root
                        Confirmations.notAuthorized.say {
							Speech.shared.immediatelySay(utterance: MenuOptions.root)
							Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                        }
                    } else {
						Speech.shared.immediatelySay(utterance: MenuOptions.addStepOne)
						Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startRecording)
						
                    }
                }
            } else if hypothesis! == "DELETE" {
                self.stopListening()
                state = .del
                Confirmations.delete.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.delete)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else if hypothesis! == "BACK" {
                self.stopListening()
                state = .root
                Confirmations.back.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.root)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else if hypothesis! == "REPEAT" {
                self.stopListening()
				Speech.shared.immediatelySay(utterance: MenuOptions.edit)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            } else {
                // pocketsphinx can be hard of hearing sometimes
                self.stopListening()
				Speech.shared.immediatelySay(utterance: Confirmations.couldYouRepeatThat)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            }
        // trying to add, selecting current location or dictated location
        case .add2:
            if hypothesis! == "HERE" {
                self.stopListening()
                Confirmations.useCurrentLocation.say()
                LocationService.sharedInstance.waitForAddressToBeAvailable(callback: self.handleCurrentAddressIsAvailable)
            } else if hypothesis! == "DICTATE" {
                self.stopListening()
                state = .add3
                waitingForSpeechRecognitionResultAvailable = true
                notifySpeechRecognitionResultAvailable = handleDictatedFavoriteAddress
                openEarsEventsObserver = nil
                Confirmations.useDictatedAddress.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.addStepThree)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startRecording)
                }
            } else if hypothesis! == "BACK" {
                self.stopListening()
                state = .add1
                waitingForSpeechRecognitionResultAvailable = true
                notifySpeechRecognitionResultAvailable = handleDictatedFavoriteName
                openEarsEventsObserver = nil
                Confirmations.back.say {
                    if !self.recognizitionAuthorized {
                        self.state = .root
                        Confirmations.notAuthorized.say {
							Speech.shared.immediatelySay(utterance: MenuOptions.root)
							Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                        }
                    } else {
						Speech.shared.immediatelySay(utterance: MenuOptions.addStepOne)
						Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                    }
                }
            } else if hypothesis! == "REPEAT" {
                self.stopListening()
				Speech.shared.immediatelySay(utterance: MenuOptions.addStepTwo)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            } else {
                // pocketsphinx can be hard of hearing sometimes
                self.stopListening()
				Speech.shared.immediatelySay(utterance: Confirmations.couldYouRepeatThat)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            }
        // trying to confirm add
        case .addConfirm:
            if hypothesis! == "SAVE" {
                self.stopListening()
                if self.delegate != nil {
                    self.delegate?.favoritesVoiceController(addNewFavorite: favoriteTemplate!)
                }
                self.addToDictionary(favorites: [favoriteTemplate!])
                state = .root
                Confirmations.favoriteSaved.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.root)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else if hypothesis! == "BACK" { // go back to main menu cause there's multiple ways to get here
                self.stopListening()
                favoriteTemplate = nil
                state = .root
                Confirmations.canceledLastAction.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.root)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else if hypothesis! == "REPEAT" {
                self.stopListening()
				Speech.shared.immediatelySay(utterance: MenuOptions.addConfirmPost)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            } else {
                // pocketsphinx can be hard of hearing sometimes
                self.stopListening()
				Speech.shared.immediatelySay(utterance: Confirmations.couldYouRepeatThat)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            }
        // selected delete
        case .del:
            if hypothesis! == "BACK" {
                self.stopListening()
                state = .edit
                Confirmations.back.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.root)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else {
                guard let command = hypothesis else { return }
                let recognizableWord = self.makeRecognizableWord(phrase: command)
                if favoritesDictionary[recognizableWord] != nil {
                    self.stopListening()
                    state = .delConfirm
                    favoriteTemplate = favoritesDictionary[recognizableWord]
					Speech.shared.immediatelySay(utterance: (MenuOptions.deleteConfirmPre + " \(favoriteTemplate!.name). " + MenuOptions.deleteConfirmPost))
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                } else if hypothesis! == "REPEAT" {
                    self.stopListening()
					Speech.shared.immediatelySay(utterance: MenuOptions.delete)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                } else {
                    // pocketsphinx can be hard of hearing sometimes
                    self.stopListening()
					Speech.shared.immediatelySay(utterance: Confirmations.couldYouRepeatThat)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            }
            
        case .delConfirm:
            if hypothesis! == "CONFIRM" {
                self.stopListening()
                if self.delegate != nil {
                    self.delegate?.favoritesVoiceController(deleteFavorite: favoriteTemplate!)
                }
                // Call delegate method to delete
                self.removeFromDictionary(favorite: favoriteTemplate!)
                state = .root
                Confirmations.deleteExecuted.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.root)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else if hypothesis! == "BACK" {
                self.stopListening()
                favoriteTemplate = nil
                state = .root
                Confirmations.canceledLastAction.say {
					Speech.shared.immediatelySay(utterance: MenuOptions.root)
					Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                }
            } else if hypothesis! == "REPEAT" {
                self.stopListening()
				Speech.shared.immediatelySay(utterance: MenuOptions.delete)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            } else {
                // pocketsphinx can be hard of hearing sometimes
                self.stopListening()
				Speech.shared.immediatelySay(utterance: Confirmations.couldYouRepeatThat)
				Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
            }
        
        default: break
        }
    }
    
    
    // MARK: Public SpeechRecognizer Delegate Functions
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        recognizitionAuthorized = available
    }
    
    // MARK: Private SpeechRecognizer Controls
    
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
    
    private func startRecording() {
        print("setup for startRecording()")
        transcription = nil
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
                self.transcription = result!.bestTranscription.formattedString
                print("set transcription to: \(self.transcription)")
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
                    self.reloadOpenEars()
                    self.state = .root
                    Confirmations.back.say {
						Speech.shared.immediatelySay(utterance: MenuOptions.root)
						Speech.shared.waitToFinishSpeakingThenBeep(callback: self.startListening)
                    }
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
            if self.waitingForSpeechRecognitionResultAvailable {
                self.waitingForSpeechRecognitionResultAvailable = false
                self.notifySpeechRecognitionResultAvailable(self.transcription)
            }
        }
    }
    
    // MARK: Private Helpers
    
    private func makeRecognizableWord(phrase: String) -> String {
        return phrase.replacingOccurrences(of: " ", with: "").uppercased()
    }
    
    private func playDaBeep() {
        let url = Bundle.main.url(forResource: "beep", withExtension: "wav")!
    
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            guard let player = self.player else { return }
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    private func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    // MARK: Private Openears Controls
	private func reloadOpenEars() {
        openEarsEventsObserver = OEEventsObserver()
        openEarsEventsObserver?.delegate = self
        let filename = languageModelFileName + "_\(self.randomString(length: 20))"
        let openEarsLanguageModelGenerator: OELanguageModelGenerator = OELanguageModelGenerator()
        openEarsLanguageModelGenerator.generateLanguageModel(from: words, withFilesNamed: filename, forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
        languageModelPath = openEarsLanguageModelGenerator.pathToSuccessfullyGeneratedLanguageModel(withRequestedName: filename)
        dictionaryPath = openEarsLanguageModelGenerator.pathToSuccessfullyGeneratedDictionary(withRequestedName: filename)
    }
    
    func startListening() {
        do {
            try	OEPocketsphinxController.sharedInstance().setActive(true)
        } catch{
            print ("fail")
        }
        print("Starting listening")
        OEPocketsphinxController.sharedInstance().startListeningWithLanguageModel(atPath: languageModelPath, dictionaryAtPath: dictionaryPath, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: false)
    }
    
    private func stopListening() {
        print("Stopping listening")
        if(OEPocketsphinxController.sharedInstance().isListening){
            let stopListeningError: Error! = OEPocketsphinxController.sharedInstance().stopListening() // React to it by telling Pocketsphinx to stop listening since there is no available input (but only if we are listening).
            if(stopListeningError != nil) {
                print("Error while stopping listening in audioInputDidBecomeUnavailable: \(stopListeningError)")
            }
        }
    }

    /////////////////////// MARK: Openears Interface Functions///////////////////////
    
    
    // An optional delegate method of OEEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
    // This might be useful in debugging a conflict between another sound class and Pocketsphinx.
    func pocketsphinxRecognitionLoopDidStart() {
        print("Local callback: Pocketsphinx started.") // Log it.
    }
    
    // An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
    func pocketsphinxDidStartListening() {
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
