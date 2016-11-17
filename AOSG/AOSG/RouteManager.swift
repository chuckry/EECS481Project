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
    var route: NavigationPath?
    let locManager = LocationService.sharedInstance
    var lastPoint: CLLocation
    var nextPoint = 0
    var snappedPoints: [CLLocation]
    var nearestIntersection: String = ""
    
    init() {
        self.lastPoint = CLLocation()
        self.snappedPoints = []
        self.route = nil
    }

    convenience init(path: NavigationPath) {
        self.init()
        self.lastPoint = locManager.lastLocation!
        self.route = path
        self.getSnapPoints()
    }

    /*
     *  Get "snap points," or intermediary checkpoints, to tailor sound output to
     *  complex geography.
     */
    func getSnapPoints() {
        var isGettingSnapPoints = false
        let currLat = self.lastPoint.coordinate.latitude
        let currLong = self.lastPoint.coordinate.longitude
        
        var path = "\(currLat),\(currLong)"
        for step in (self.route?.path)! {
            path += "|\(step.goal.coordinate.latitude),\(step.goal.coordinate.longitude)"
        }
        
        let URLEndPoint = "https://roads.googleapis.com/v1/snapToRoads?"
        let params = "path=\(path)&interpolate=true".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let URLString = "\(URLEndPoint)\(params!)&key=\(GoogleAPI.sharedInstance.API_KEY)"
        let requestURL = URL(string: URLString)
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"
        
        DispatchQueue.main.async {
            while !isGettingSnapPoints {
                isGettingSnapPoints = true
                let task = URLSession.shared.dataTask(with: request) {
                    (data, response, error) -> Void in
                    if error != nil {
                        print("ERROR: \(error)")
                        return
                    }
                    
                    let json = JSON(data: data!)
                    guard let points = json["snappedPoints"].array else {
                        print(response!)
                        print("Could not get Snapped Points.")
                        return
                    }
                    
                    // Extract location data from snap point
                    self.snappedPoints = []
                    for point in points {
                        let loc = self.getLocationFromJSON(lat: point["location"]["latitude"], long: point["location"]["longitude"])
                        self.snappedPoints.append(loc)
                    }
                    self.nextPoint = 0
                }
                task.resume()
            }
        }
    }
    
    /*
     *  Checks whether we're at the last point
     */
    func outsideSnapPointBounds() -> Bool {
        return self.nextPoint >= self.snappedPoints.count
    }
    
    /*
     *  Returns distance between current location and next snap point.
     */
    func distanceFromSnapPoint(loc: CLLocation) -> Double {
        return loc.distance(from: self.snappedPoints[self.nextPoint])
    }
    
    /*
     *  If you've reached the goal, move to next step
     *
     *  Otherwise, gather snap points and move to next one if we're within
     *  a 3 meter radius
     */
    func moveToNextSnapPointIfClose(loc: CLLocation) {
        if (self.route?.currentStep().achievedGoal(location: loc))! {
            self.moveToNextStep(loc: loc)
        } else {
            if self.outsideSnapPointBounds() {
                print("Outside Bounds!")
                self.lastPoint = loc
                self.getSnapPoints()
            }
            if self.snappedPoints[self.nextPoint].distance(from: loc) <= 15 {
                self.nextPoint += 1
                Speech.shared.immediatelySay(utterance: "Moving to next snap point!")
            }
        }
    }
    
    /*
     *  Set user's current location to the end of the last step
     *  Increment to next step
     *  Gather new snap points
     */
    func moveToNextStep(loc: CLLocation) {
        Speech.shared.immediatelySay(utterance: "Moving to next step!")
        self.lastPoint = loc
        self.nextPoint = 0
        self.route?.nextStep()
        self.getSnapPoints()
    }
    
    /*
     *  Use the user's location and heading to get sound balance ratio.
     *
     *  TODO: Upon moving navigationDriver to RouteManager, will no longer need userLocation param.
     */
    func calculateSoundRatio(userLocation: CLLocation, userHeading: Double) -> Float {
        let trig = getTrig(userLocation, userHeading)
        return Float(getSoundScore(angle: trig!.0, directionVector: trig!.1, userVector: trig!.2))
    }
    
    /*
     *  Calculates the angle between where the user is facing and where they should be facing.
     *
     *  TODO: Upon moving navigationDriver to RouteManager, will no longer need userLocation param.
     */
    func getTrig(_ userLocation: CLLocation, _ userHeading: Double) -> (Double, Vector2, Vector2)? {
        let goal: CLLocation
        while self.outsideSnapPointBounds() {
            print("Using direction instead of snap point!")
            self.lastPoint = LocationService.sharedInstance.lastLocation!
            self.getSnapPoints()
        }
        
        goal = self.snappedPoints[self.nextPoint]
        
        let userVector = Vector2(cos(Float(userHeading) * Scalar.radiansPerDegree), sin(Float(userHeading) * Scalar.radiansPerDegree))
        let directionVector = getVectorFromPoints(start: userLocation, end: goal)
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
        print("SCORE: \(score)")
        
        return score > 0 ? min(1.0, score) : max(-1.0, score)
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
    
    /*
     *  Prints snap points in list of latitude longitude pairs
     */
    func printSnapPoints() {
        for point in self.snappedPoints {
            print("\(point.coordinate.latitude),\(point.coordinate.longitude)")
        }
    }
}
