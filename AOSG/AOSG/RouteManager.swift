//
//  RouteManager.swift
//  AOSG
//
//  Created by Chuckry Vengadam on 10/18/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreLocation
import Dispatch
import UIKit


class RouteManager {
    let locManager = LocationService.sharedInstance
    let soundManager: SoundManager = SoundManager(fileName: "hum", ext: "mp3")
    var route: NavigationPath?
    var lastPoint: CLLocation
    var nextPoint = 0
    var nearestIntersection: String = ""
	var mainViewController: MainViewController!

	
    init() {
        self.lastPoint = CLLocation()
        self.route = nil
    }

    convenience init(path: NavigationPath) {
        self.init()
        self.lastPoint = locManager.lastLocation!
        self.route = path
        self.soundManager.beginPlayingSound()
    }

    
    
    /*
     *  Set user's current location to the end of the last step
     *  Increment to next step
     */
    func moveToNextStep(loc: CLLocation) {
        Speech.shared.immediatelySay(utterance: "Moving to next step!")
        self.lastPoint = loc
        self.nextPoint = 0
        self.route?.nextStep()
    }

    /*
     *  Calculates the angle between where the user is facing and where they should be facing.
     */
    func getTrig(_ userLocation: CLLocation, _ userHeading: Double) -> (Double, Vector2, Vector2)? {
        
        let goal = (self.route?.currentStep().goal)!
        
        let userVector = Vector2(cos(Float(userHeading) * Scalar.radiansPerDegree), sin(Float(userHeading) * Scalar.radiansPerDegree))
        let directionVector = getVectorFromPoints(start: userLocation, end: goal)
        
        return (Double(acos(userVector.dot(directionVector) / directionVector.length) * Scalar.degreesPerRadian), directionVector, userVector)
    }
    
    /*
     *  Takes user's start point and end point and converts it into a vector.
     */
    func getVectorFromPoints(start: CLLocation, end: CLLocation) -> Vector2 {
        return Vector2(Float(end.coordinate.longitude) - Float(start.coordinate.longitude), Float(end.coordinate.latitude) - Float(start.coordinate.latitude))
    }
    
    /*
     *  Forms a CLLocation instance using extracted longitude and latitude JSON values
     */
    func getLocationFromJSON(lat: JSON, long: JSON) -> CLLocation {
        let newLat = CLLocationDegrees(Double(String(describing: lat))!)
        let newLong = CLLocationDegrees(Double(String(describing: long))!)
        return CLLocation(latitude: newLat, longitude: newLong)
    }
    
    // Reads direction and announcing upcoming direction
    func navigationDriver(loc: CLLocation?, heading: CLHeading?) {
        DispatchQueue.main.async {
            
            if loc == nil || heading == nil {
                return
            }

            // Pause significant location changes while we compute/send user output
            self.locManager.stopWaitingForSignificantLocationChanges()
            
            Stuff.things.stepSizeEst = (self.route?.pedometer.stepSize)!
            Stuff.things.currentStepLabel.text = (self.route?.currentStep().createCurrentFormattedString(currentLocation: loc!, stepSizeEst: (self.route?.pedometer.stepSize)!))!
            
            
            Stuff.things.currentStepDescription = Stuff.things.currentStepLabel.text!
            Stuff.things.stepPace = (self.route?.pedometer.stepPaceEst)!
            
            if ((self.route?.arrivedAtDestination())!) {
                Speech.shared.say(utterance: "You have arrived at destination")
                print ("You have arrived at destination")
                return
            }
            
            if ((self.route?.cancelledNavigation())!) {
                Speech.shared.immediatelySay(utterance: "You have cancelled navigation")
                print("You have cancelled navigation ")
				Stuff.things.showArrowsHideLabels()
				
                Stuff.things.currentStepLabel.text = "--"
                Stuff.things.currentLocationLabel.text = "--"
                Stuff.things.destinationLocationLabel.text = "--"
                Stuff.things.directionList.text = ""
				
				Stuff.things.resetPromptInfo()
				self.soundManager.stopPlayingSound()
				
                return
            }
            
            if (self.route?.currentStep().achievedGoal(location: loc!))! {
                self.moveToNextStep(loc: loc!)
                Stuff.things.currentStepDescription = (self.route?.currentStep().currentFormattedDescription!)!
                Speech.shared.say(utterance: (self.route?.currentStep().readingDescription)!)
                print((self.route?.currentStep().currentFormattedDescription!)!)
            } else {
                let trig = self.getTrig(loc!, heading!.trueHeading)
                self.soundManager.changeFeedback(angle: trig!.0, directionVector: trig!.1, userVector: trig!.2)
            }
            
            self.locManager.waitForSignificantLocationChanges(callback: self.navigationDriver)
        }
    }
}
