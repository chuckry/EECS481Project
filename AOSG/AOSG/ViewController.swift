//
//  ViewController.swift
//  AOSG
//
//  Created by Leda Daehler on 10/7/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var destinationLocationLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var directionList:UITextView!
	var stepData = Steps()
	
    // shared instances for interfaces
    let locationService = LocationService.sharedInstance
    
    let googleAPI = GoogleAPI.sharedInstance
    
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        locationService.delegateView = self
        destinationTextField.delegate = self
        
        if !locationService.startUpdatingLocation() {
            locationService.requestAccess()
        }
		directionList.text = "--";
	}
	
    // MARK: UITextFieldDelegate Handlers
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Implement anything that should be done when the textField begins editing
		
	}
	
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // if you hit the search button, then hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // if the textField is non-empty, start a navigation
        if !textField.text!.isEmpty {
            // get current location then update the UI
            let currentLocation = locationService.user_location!
            googleAPI.reverseGeocode(location: currentLocation, callback: self.updateCurrentLocationLabel)
            // find the target location, then update the UI
            googleAPI.geocode(address: textField.text!, callback: self.updateDestinationLocationLabel)
            
            // show a spinner to show user we are searching...
            spinner.startAnimating()
            // make a Directions API call to get a list of legs/steps to reach a destination.
            // On return, start a route guidance.
        }
    }
    
    // MARK: UILabel Actuators
    func updateCurrentLocationLabel(withData: GeocodingResponse) -> Void {
        currentLocationLabel.text = withData.formatForDisplay()
    }
    
    func updateDestinationLocationLabel(withData: GeocodingResponse) -> Void {
        destinationLocationLabel.text = withData.formatForDisplay()
        spinner.stopAnimating()
    }
    
}




