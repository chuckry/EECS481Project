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
 *  PROPERTIES TO ADD FROM navigationDriver():
 *
 *  currentStepLabel    : UILabel
 *  locationService     : LocationService.sharedInstance
 *  pedometer           : Steps
 *
 *  readText            : (String) -> (Void)
 *  playFeedback        : (Float, Float, Int) -> (Void)
 *
 *
 *  CODE TO CHANGE:
 *
 *  Handle how to increment to next snap point upon reaching
 *  Create SoundManager class
 */
class RouteManager {
    let route: NavigationPath
    var currentLocation: CLLocation
    var nextPoint = 0
    var snappedPoints: [JSON]
    
    init(currentLocation: CLLocation, path: NavigationPath) {
        self.currentLocation = currentLocation
        self.route = path
        self.route.nextStep()
        self.snappedPoints = []
        self.getSnapPoints()
    }
    
    /*
     *  Get "snap points," or intermediary checkpoints, to tailor sound output to
     *  complex movement.
     */
    func getSnapPoints() {
        let currLat = self.currentLocation.coordinate.latitude
        let currLong = self.currentLocation.coordinate.longitude
        let lat = self.route.currentStep().goal.coordinate.latitude
        let long = self.route.currentStep().goal.coordinate.longitude
        
        let path = "\(currLat),\(currLong)|\(lat),\(long)"
        
        let URLEndPoint = "https://roads.googleapis.com/v1/snapToRoads?"
        let params = "path=\(path)&interpolate=true".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let URLString = "\(URLEndPoint)\(params!)&key=\(GoogleAPI.sharedInstance.API_KEY)"
        let requestURL = URL(string: URLString)
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"
        
        print(request)
        
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
            print(snappedPoints)
            for point in snappedPoints {
                if point["location"] != self.snappedPoints.last {
                    self.snappedPoints.append(point["location"])
                }
            }
            print(self.snappedPoints)
        }
        task.resume()
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
        print(self.snappedPoints)
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
        
        let score = (angle * signOfSigma) / 90.0
        
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
     *  Set user's current location to the end of the last step
     *  Increment to next step
     *  Gather new snap points
     */
    func moveToNextStep() {
        self.currentLocation = self.route.currentStep().goal
        self.route.nextStep()
        self.getSnapPoints()
    }
    
    /*
     *  Increment to next snap point in the array.
     */
    func moveToNextSnapPoint() {
        self.nextPoint += 1
    }
    
    /*
     *  Takes user's start point and end point and converts it into a vector.
     */
    func getVectorFromPoints(start: CLLocation, end: JSON) -> Vector2 {
        return Vector2(end["longitude"].floatValue - Float(start.coordinate.longitude), end["latitude"].floatValue - Float(start.coordinate.latitude))
    }
}
