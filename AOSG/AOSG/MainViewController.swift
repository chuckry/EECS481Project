//
//  ViewController.swift
//  AOSG
//
//  Created by Leda Daehler on 10/7/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import CoreLocation
import Dispatch
import GoogleMaps
import GooglePlaces
import AVFoundation


class MainViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    var destinationText: String?
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var destinationLocationLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var directionList: UITextView!
	@IBOutlet weak var currentStepLabel: UILabel!
    
	var sound: AVAudioPlayer!
    var settingsViewController : SettingsViewController!
    var loadedSettings = true
	
	@IBOutlet var upArrow: UIImageView!
	@IBOutlet var rightArrow: UIImageView!
	@IBOutlet var downArrow: UIImageView!
	@IBOutlet var leftArrow: UIImageView!
	@IBOutlet var settingsLabel: UILabel!
	@IBOutlet var inputLabel: UILabel!
	@IBOutlet var favoritesLabel: UILabel!
	@IBOutlet var voiceCommandLabel: UILabel!
    // shared instances for interfaces
    let locationService = LocationService.sharedInstance
    let googleAPI = GoogleAPI.sharedInstance
    
    // navigation state properties
    var route: NavigationPath!

	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        locationService.delegateView = self
        locationService.waitForHeadingToBeAvailable(callback: { _ in } )
        
        // Start up location services, or ask user for these permissions as soon as
        // possible to ensure the device has enough time to actually determine location
        // using GPS
        if !locationService.startUpdatingLocation() {
            locationService.requestAccess()
        }
        
        // Wait for a location to be available and save it
        locationService.waitForLocationToBeAvailable(callback: self.initialLocationKnown)
            if let savedSettings = loadSettings() {
                print ("successfully loaded settings")
                Speech.shared.volume = savedSettings.volume
                Speech.shared.voiceOn = savedSettings.voiceOn
                Speech.shared.speechRate = savedSettings.voiceSpeed
                Stuff.things.beepFrequency = savedSettings.beepFrequency
                Stuff.things.beepOn = savedSettings.beepOn
                Stuff.things.vibrationOn = savedSettings.vibrationOn
            }
            else {
                print("didnt grab past settings")
            }
		
		let mainStatement: String = "Welcome to Steereo. This application works best with headphones and when your phone is held face up at a 90 degree angle to your body. Swipe right to input a new destination. Swipe left to route to a favorite destination. Swipe up to adjust settings. Swipe down to access voice commands. "
		Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: mainStatement)

	}
    
    func loadSettings() -> Settings? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Settings.archiveURL.path) as? Settings
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Navigation")
        
        if Stuff.things.favoriteSelected {
            Stuff.things.favoriteSelected = false
            destinationText = Stuff.things.favoriteAddress
            locationService.waitForLocationToBeAvailable(callback: self.initialLocationKnown)
            //destinationTextField.text = Stuff.things.favoriteAddress
            //locationService.waitForLocationToBeAvailable(callback: self.initialLocationKnown)
        }
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
    
    @IBOutlet var toggleVoiceOnOff: UILongPressGestureRecognizer!
    @IBAction func toggleVoiceAction(_ sender: Any) {
        if (toggleVoiceOnOff.state == UIGestureRecognizerState.began) {
            print ("tap toggled voice on/off")
            if Speech.shared.voiceOn {
                Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Voice Off")
                Speech.shared.voiceOn = false
                Speech.shared.voiceChanged = true
            }
            else {
                Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Voice On")
                Speech.shared.voiceOn = false
                Speech.shared.voiceChanged = true
            }
        }
    }
    
    
    
    // MARK: UITextFieldDelegate Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    // Executes when user hits the return key

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // when user hits the search button, hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    // Executes when keyboard is hidden and textfield value is constant
    // This triggers the routeGuidance workflow
    func textFieldDidEndEditing(_ textField: UITextField) {
        // if the textField is non-empty, start a navigation
        if !textField.text!.isEmpty {
            
            // don't let the user modify location while we are working... (need constant)
            // this prevents entering an unexpected user state
            
            // show a spinner to show user we are searching...
            spinner.startAnimating()
            
            // wait for a location to be available
            //locationService.waitForLocationToBeAvailable(callback: self.initialLocationKnown)
        }
    }
    
    // Should execute as a handler for when location services is able
    // to return a known address
    func initialLocationKnown(location: CLLocation) {
        
        // retrieve the destination as an address
        guard let destinationAddress = destinationText else {
            print("ERROR: destinationTextField value is unavailable")
            // TODO: Have some remidiation for the user to retry. Currently no feedback is sent
            return
        }
        if Speech.shared.voiceOn {
            "Navigating to \(destinationAddress)".say()
        }
        spinner.startAnimating()
        print("ASKING GOOGLE API")
        
        // ask the google API to compute a route. handle response in a callback
        self.googleAPI.addressFromKeywords(from: "\(location.coordinate.latitude),\(location.coordinate.longitude)", to: destinationAddress, callback: self.initializeRouteGuidance)
    }
    
    // Should execute as a handler when the Google API responds with a route
    // to a user-entered destination.
    func initializeRouteGuidance(withPath: NavigationPath?) -> Void {
        
        // if navigation path was not found, deal with it first
        guard withPath != nil else {
            
            // UIKit is NOT thread safe. Therefore, the UI can't
            // be updated from anything else besides the main thread.
            // see: http://stackoverflow.com/questions/27841228/ios-label-does-not-update-text-with-function-in-swift
            // start a dispatch to the main thread to update UI
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            return
        }
        
        self.route = withPath!
        Stuff.things.routeManager = RouteManager(path: self.route)
        
        // Start playing sound now
        
        // Start a dispatch to the main thread (see link above)
        DispatchQueue.main.async {
			
			//show/hide UI features
			self.settingsLabel.isHidden = true
			self.voiceCommandLabel.isHidden = true
			self.inputLabel.isHidden = true
			self.favoritesLabel.isHidden = true
			self.upArrow.isHidden = true
			self.downArrow.isHidden = true
			self.rightArrow.isHidden = true
			self.leftArrow.isHidden = true
			
			self.currentLocationLabel.isHidden = false
			self.destinationLocationLabel.isHidden = false
			self.directionList.isHidden = false
			self.currentStepLabel.isHidden = false
			
            // update the UI with the current address:
            self.currentLocationLabel.text = self.route.startLocation.formatForDisplay()
            
            // update the UI with the destination address:
            self.destinationLocationLabel.text = self.route.endLocation.formatForDisplay()
            
            let directions = self.route.getDirectionsAsStringArray()
            self.directionList.text = directions.joined(separator: "\n\n")
            
            // Hide the spinner
            self.spinner.stopAnimating()
            
            // Re-enable the destinationTextField
            // MARK: Do we really want to do this?
            
            
            // Beging naviation and read first direction outloud
            // TODO: give capability to change rate in settings
            print ("old heading filter = ", self.locationService.headingFilter)
            self.locationService.headingFilter = Stuff.things.getHeaderFilterValue()
            self.locationService.distanceFilter = Stuff.things.getDistanceFilterValue()
            print ("new heading filter = ", self.locationService.headingFilter)
            
            let start_text = "All set with direction to " + self.route.endLocation.formatForReading() + ". To begin,  " + self.route.currentStep().readingDescription
            Speech.shared.say(utterance: start_text)
            
            
            // FOR TESTING ONLY
            self.locationService.waitForSignificantLocationChanges(callback: self.navigationDriver)
        }
    }

    func playFeedback(balance: Float, volume: Float, numLoops: Int) {

		let soundURL: NSURL = Bundle.main.url(forResource: "alert", withExtension: "mp3")! as NSURL
        do {
            if (Stuff.things.vibrationOn) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
            
            self.sound = try! AVAudioPlayer(contentsOf: soundURL as URL)
            if self.sound != nil {
                self.sound.pan = balance
                self.sound.volume = volume
                self.sound.numberOfLoops = numLoops
                if (Stuff.things.beepOn) {
                    self.sound.prepareToPlay()
                    self.sound.play()
                }
                print("playing sound")
            }
        }
    }

    // Reads direction and announcing upcoming direction
    func navigationDriver(loc: CLLocation?, heading: CLHeading?) {
        DispatchQueue.main.async {
            
            if loc == nil || heading == nil {
                return
            }
            let routeManager = Stuff.things.routeManager
            
            if routeManager.snappedPoints.isEmpty {
                self.navigationDriver(loc: loc, heading: heading)
                return
            }

            // Pause significant location changes while we compute/send user output
            self.locationService.stopWaitingForSignificantLocationChanges()
            
            // Handle relation to next snap point
            routeManager.moveToNextSnapPointIfClose(loc: loc!)
            Stuff.things.stepSizeEst = self.route.pedometer.stepSize
            self.currentStepLabel.text = self.route.currentStep().createCurrentFormattedString(currentLocation: self.locationService.lastLocation!, stepSizeEst: self.route.pedometer.stepSize)
            
            
            Stuff.things.currentStepDescription = self.currentStepLabel.text!
            Stuff.things.stepPace = self.route.pedometer.stepPaceEst
            
            if (self.route.arrivedAtDestination()) {
                Speech.shared.say(utterance: "You have arrived at destination")
                print ("You have arrived at destination")
                return; // Returning here permanently stops loaction change updates
            }

            if (self.route.cancelledNavigation()) {
                Speech.shared.immediatelySay(utterance: "You have cancelled navigation")
                print ("You have cancelled navigation ")
                self.currentStepLabel.text = "--"
               // self.destinationText.text = ""
                self.currentLocationLabel.text = "--"
                self.destinationLocationLabel.text = "--"
                self.directionList.text = ""
                
                return // Returning here permanently stops location change updates
            }
            

            if ((self.route.currentStep().achievedGoal(location: loc!))) {
                routeManager.moveToNextStep(loc: loc!)
                Stuff.things.currentStepDescription = self.route.currentStep().currentFormattedDescription!
                Speech.shared.say(utterance: self.route.currentStep().readingDescription)
                print(self.route.currentStep().currentFormattedDescription!)
            } else {
                self.playFeedback(balance: routeManager.calculateSoundRatio(userLocation: loc!, userHeading: heading!.trueHeading), volume: 1, numLoops: 1)
            }

            self.locationService.waitForSignificantLocationChanges(callback: self.navigationDriver)
        }
    }
}


