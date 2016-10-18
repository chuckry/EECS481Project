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
    
    // navigation state properties
    var route: NavigationPath!
    
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        locationService.delegateView = self
        destinationTextField.delegate = self
        
        // Start up location services, or ask user for these permissions as soon as
        // possible to ensure the device has enough time to actually determine location
        // using GPS
        if !locationService.startUpdatingLocation() {
            locationService.requestAccess()
        }
		directionList.text = "--";
	}
	
    // MARK: UITextFieldDelegate Handlers
    
    // Executes when user taps the input to start entering a destination
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Implement anything that should be done when the textField begins editing

        // May implement a "cancel route guidance" feature here at some point...
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
            destinationTextField.isUserInteractionEnabled = false
            
            // show a spinner to show user we are searching...
            spinner.startAnimating()
            
            // wait for a location to be available
            locationService.waitForLocationToBeAvailable(callback: self.initialLocationKnown)
        }
    }
    

    
    // Should execute as a handler for when location services is able
    // to return a known address
    func initialLocationKnown(location: CLLocation) {
        
        // retrieve the destination as an address
        guard let destinationAddress = destinationTextField.text else {
            print("ERROR: destinationTextField value is unavailable")
            // TODO: Have some remidiation for the user to retry. Currently no feedback is sent
            return
        }
        
        // ask the google API to compute a route. handle response in a callback
        googleAPI.directions(from: "\(location.coordinate.latitude),\(location.coordinate.longitude)", to: destinationAddress, callback: self.initializeRouteGuidance)
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
                // deal with the fact that this route was not found.
                // TODO: Implement an error enum pattern that can be used to
                // provide feedback to the user
                
                // Clean up
                // Hide the spinner
                self.spinner.stopAnimating()
                
                // Clear the destinationTextField
                self.destinationTextField.text = ""
                
                // Re-enable the text field for editing
                self.destinationTextField.isUserInteractionEnabled = true
            }
            return
        }
        
        // save the Navigation Path returned as an internal state
        route = withPath!
        
        // Start a dispatch to the main thread (see link above)
        DispatchQueue.main.async {
            // update the UI with the current address:
            self.currentLocationLabel.text = self.route.startLocation.formatForDisplay()
            
            // update the UI with the destination address:
            self.destinationLocationLabel.text = self.route.endLocation.formatForDisplay()
            
            // TODO: insert the list of directions into a UI list
            // use route.getDirectionsAsStringArray
            
            let directions = self.route.getDirectionsAsStringArray()
            self.directionList.text = directions.joined(separator: "\n\n")
            
            // Hide the spinner
            self.spinner.stopAnimating()
            
            // Re-enable the destinationTextField
            // MARK: Do we really want to do this?
            self.destinationTextField.isUserInteractionEnabled = true
            
            // TODO: notify the location manager that we want updates on
            // significant changes now, and provide a driver callback that
            // does the route management
        }
    }

}




