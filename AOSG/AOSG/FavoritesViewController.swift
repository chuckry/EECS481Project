//
//  FavoritesViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation

class FavoritesViewController: UIViewController, OEEventsObserverDelegate {

    // MARK: Properties
    @IBOutlet weak var favorites: UITableView!
    @IBOutlet weak var tableEditButton: UIBarButtonItem!
    @IBAction func unwindToFavoritesList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NewFavoriteViewController {
            let newIndexPath = IndexPath(row: favs.count, section: 0)
            guard let f = sourceViewController.favorite else {
                return
            }
            favs.append(f)
            favorites.insertRows(at: [newIndexPath], with: .bottom)
            
            saveFavorites()
        }
    }
    @IBAction func editOptionPressed(_ sender: UIBarButtonItem) {
        if tableEditButton == sender {
            if favorites.isEditing {
                favorites.setEditing(false, animated: true)
                tableEditButton.title = "Edit"
            } else {
                favorites.setEditing(true, animated: true)
                tableEditButton.title = "Done"
            }
        }
    }
	
	//voice control variables
	var words: Array<String> = ["LIST", "EDIT, ADD, DELETE"] //array of words to be recognized. Remove spaces in multiple word phrases.
	let openingStatement:String = "Favorites"
    let rootMenuOptions:String = "At the tone, speak the name of your favorite destination or Say, list, to read saved favorite destinations. Or say, edit, to add or delete saved favorites. Swipe right to cancel."
	let listConfirmation:String = "Listing all favorites."
    let editStatement:String = "Editing Favorites."
    let editMenuOptions:String = "At the tone Say, add, to add a new favorite. Or say, delete, to delete a saved favorite."
	//keep adding prompts here
	var openEarsEventsObserver = OEEventsObserver()
	var startFailedDueToLackOfPermissions = Bool()
	var lmPath: String!
	var dicPath: String!
	var player: AVAudioPlayer?

    var isAdding: Bool = false
    var isDeleting: Bool = false
	
    var favs = [Favorite]()
    public var horizontalPageVC: HorizontalPageViewController!
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // populate favs here from persistent storage
        //favs.append(Favorite(withName:"College Apartment", withAddress: "1320 South University Ave, Ann Arbor MI 48104"))
        favorites.dataSource = self
        favorites.delegate = self
        if let savedFavorites = loadFavorites() {
            favs += savedFavorites
        }
        // Add to dictionary of words
		loadOpenEars()
		
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		runOpeningSpeech() // what the page should repeatedly say at opening and after other events
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		Speech.shared.waitingForDoneSpeaking = false
		self.stopListening()
	}
    
    // MARK: Favorites Methods
    
    func saveFavorites() {
        let isSucessfulSave = NSKeyedArchiver.archiveRootObject(favs, toFile: Favorite.archiveURL.path)
        if !isSucessfulSave {
            print("Error Saving!!")
        }
    }
    func loadFavorites() -> [Favorite]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Favorite.archiveURL.path) as? [Favorite]
    }
    
    // MARK: Custom Speach Methods
    
    // Runs a one-time openning speech
	func runOpeningSpeech(){
		print("running openning speech")
		Speech.shared.immediatelySay(utterance: self.openingStatement)
        runRootMenuSpeech()
	}
    
    // Runs the root menu speech
    func runRootMenuSpeech() {
        print("running root menu speech")
        Speech.shared.immediatelySay(utterance: self.rootMenuOptions)
        Speech.shared.waitToFinishSpeaking(callback: self.listen)
    }
    
    // Lists all favorites currently avaliable.
    func runListFavorites() {
        print("listing favorites")
        var listString: String = ""
        for f in favs {
            listString += "\(f.name), "
        }
        Speech.shared.immediatelySay(utterance: listString)
        Speech.shared.waitToFinishSpeaking(callback: self.runRootMenuSpeech)
    }
    
    // Runs the edit menu speech
    func runEditMenuSpeech() {
        print("running edit menu speech")
        Speech.shared.immediatelySay(utterance: self.editStatement)
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
		openEarsEventsObserver.delegate = self;
		
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
	
	/////////////////////// openears interface functions///////////////////////
	
	//what happens when each phrase is heard
	func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!){ // Something was heard
		
		print("Local callback: The received hypothesis is \(hypothesis!) with a score of \(recognitionScore!) and an ID of \(utteranceID!)")

		/*
		STENCIL: Add if/else for every word in your words list. initially stop listening and make sure to use callback function when saying something
		*/
		if (hypothesis == "LIST") {
			print("HEARD LIST")
			self.stopListening()
			Speech.shared.immediatelySay(utterance: self.listConfirmation)
            Speech.shared.waitToFinishSpeaking(callback: self.runListFavorites)
        } else if hypothesis == "EDIT" {
            print("HEARD EDIT")
            self.stopListening()
            Speech.shared.immediatelySay(utterance: self.editStatement)
            Speech.shared.waitToFinishSpeaking(callback: self.runEditMenuSpeech)
        } else if hypothesis == "ADD" {
            print("HEARD ADD")
        } else if hypothesis == "DELETE" {
            
        }
	
		
	}
	
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

extension FavoritesViewController: UITableViewDataSource {
    // returns number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    // gets cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteLocationTableViewCell", for: indexPath) as! FavoriteLocationTableViewCell
        let favorite = favs[indexPath.row]
        cell.nameLabel.text = favorite.name
        cell.addressLabel.text = favorite.address
        return cell
    }
    // returns how many cells there are
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favs.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleting")
            favs.remove(at: indexPath.row)
            favorites.deleteRows(at: [indexPath], with: .fade)
            saveFavorites()
        }
    }
}

extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! FavoriteLocationTableViewCell
        
        Stuff.things.favoriteSelected = true
        Stuff.things.favoriteAddress = cell.addressLabel.text!
        
        horizontalPageVC.returnToMainScreen()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


