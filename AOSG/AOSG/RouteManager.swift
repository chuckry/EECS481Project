//
//  RouteManager.swift
//  AOSG
//
//  Created by Chuckry Vengadam on 10/18/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

/*
 *  For Speech class:
 *      - readText            : (String) -> (Void)
 *      - playFeedback        : (Float, Float, Int) -> (Void)
 *
 *
 */
class RouteManager {
    let route: NavigationPath
    var lastPoint: CLLocation
    var nextPoint = 0
    var snappedPoints: [CLLocation]
    
    // CurrentStepLabel should be returned
    var currentStepLabel: UILabel
    
    init(currentLocation: CLLocation, path: NavigationPath, label: UILabel) {
        self.lastPoint = currentLocation
        self.route = path
        self.currentStepLabel = label
        self.route.nextStep()
        self.snappedPoints = []
        self.getSnapPoints()
    }
    
    /*
     *  Get "snap points," or intermediary checkpoints, to tailor sound output to
     *  complex movement.
     */
    func getSnapPoints() {
        let currLat = self.lastPoint.coordinate.latitude
        let currLong = self.lastPoint.coordinate.longitude
        let lat = self.route.currentStep().goal.coordinate.latitude
        let long = self.route.currentStep().goal.coordinate.longitude
        
        let path = "\(currLat),\(currLong)|\(lat),\(long)"
        
        let URLEndPoint = "https://roads.googleapis.com/v1/snapToRoads?"
        let params = "path=\(path)&interpolate=true".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let URLString = "\(URLEndPoint)\(params!)&key=\(GoogleAPI.sharedInstance.API_KEY)"
        let requestURL = URL(string: URLString)
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) -> Void in
            if error != nil {
                print("ERROR: \(error)")
                return
            }
            
            let json = JSON(data: data!)
            guard let snappedPoints = json["snappedPoints"].array else {
                print("Could not get Snapped Points.")
                return
            }
            
            // Extract location data from snap point. Corrects for identical adjacent snap points.
            self.snappedPoints = []
            for point in snappedPoints {
                let loc = self.getLocationFromJSON(lat: point["location"]["latitude"], long: point["location"]["longitude"])
                if loc != self.snappedPoints.last {
                    self.snappedPoints.append(loc)
                }
            }
            print(self.snappedPoints)
            self.nextPoint += 1
        }
        task.resume()
    }
    
    /*
     *  Check whether you've moved within a 2 meter radius of the next point
     */
    func checkLocToSnapPoint(location: CLLocation) {
        if self.outsideSnapPointBounds() {
            print("Outside Bounds!")
            return
        }
        if self.snappedPoints[self.nextPoint].distance(from: location) <= 2 {
            self.moveToNextSnapPoint(loc: location)
        }
    }
    
    /*
     *  Increment to next snap point in the array.
     */
    func moveToNextSnapPoint(loc: CLLocation) {
        self.nextPoint += 1
        if self.route.currentStep().achievedGoal(location: loc) {
            self.moveToNextStep()
        }
        if self.outsideSnapPointBounds() {
            print("Outside Bounds!")
            return
        }
    }
    
    /*
     *  Set user's current location to the end of the last step
     *  Increment to next step
     *  Gather new snap points
     */
    func moveToNextStep() {
        self.lastPoint = self.route.currentStep().goal
        self.nextPoint = 0
        self.route.nextStep()
        self.getSnapPoints()
    }
    
    /*
     *  Checks whether we're at the last point
     */
    func outsideSnapPointBounds() -> Bool {
        return self.nextPoint >= self.snappedPoints.count
    }

    /*
     *  Use the user's location and heading to get sound balance ratio.
     *
     *  TODO: Upon moving navigationDriver to RouteManager, will no longer need userLocation param.
     */
    func calculateSoundRatio(userLocation: CLLocation, userHeading: Double) -> Float {
		print ("\(userHeading)")
        let trig = getTrig(userLocation, userHeading)
        return Float(getSoundScore(angle: trig.0, directionVector: trig.1, userVector: trig.2))
    }
    
    /*
     *  Calculates the angle between where the user is facing and where they should be facing.
     *
     *  TODO: Upon moving navigationDriver to RouteManager, will no longer need userLocation param.
     */
    func getTrig(_ userLocation: CLLocation, _ userHeading: Double) -> (Double, Vector2, Vector2) {
        let userVector = Vector2(cos(Float(userHeading) * Scalar.radiansPerDegree), sin(Float(userHeading) * Scalar.radiansPerDegree))
        let directionVector = getVectorFromPoints(start: userLocation, end: self.snappedPoints[nextPoint])
        return (Double(acos(userVector.dot(directionVector) / directionVector.length) * Scalar.degreesPerRadian), directionVector, userVector)
    }
    
    /*  
     *  Calculates sound ratio based on angle between current position and expected position
     *  Inspired by: http://stackoverflow.com/questions/13221873/determining-if-one-2d-vector-is-to-the-right-or-left-of-another
     */
    func getSoundScore(angle: Double, directionVector: Vector2, userVector: Vector2) -> Double {
        let rotatedUserVector = Vector2(-userVector.y, userVector.x)
        let sigma = directionVector.dot(rotatedUserVector) * -1.0
        let signOfSigma = (sigma < 0 ? -1.0 : 1.0)
        
        let score = (angle * signOfSigma) / (-90.0)
        
        print("ANGLE: \(angle)")
        print("SIGN: \(signOfSigma)")
        print("SCORE: \(score)")
        
        if (score > 0) {
            return min(1.0, score)
        } else {
            return max(-1.0, score)
        }
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
}
