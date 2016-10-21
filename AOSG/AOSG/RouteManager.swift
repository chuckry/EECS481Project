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

class RouteManager {
    let route: NavigationPath
    let northVector = Vector2(0, 1)
    //var startPoint = CGPoint()
    var nextPoint: CLLocation!
    
    init(path: NavigationPath) {
        self.route = path
        //self.startPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
        self.route.nextStep()
        self.nextPoint = self.route.currentStep().goal
        //self.nextPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
    }
    
    func calculateSoundRatio(userLocation: CLLocation, userHeading: Double) -> Float {
        let trig = getTrig(userLocation, userHeading)
        return Float(getSoundScore(angle: trig.0, directionVector: trig.1))
    }
    
    func getTrig(_ userLocation: CLLocation, _ userHeading: Double) -> (Double, Vector2) {
        
        // Unit vector that India is facing
        let userVector = Vector2(cos(Float(userHeading)), sin(Float(userHeading)))
        
        // Direction from passed userLocation to known nextPoint
        let directionVector = getVectorFromPoint(start: userLocation, end: nextPoint)
        
        // returns angle alpha and direction vector
        return (Double(acos(userVector.dot(directionVector) / (directionVector.length)) * Scalar.degreesPerRadian), directionVector)
    }
    
    func getSoundScore(angle: Double, directionVector: Vector2) -> Double {
       // let directionVector = getVectorFromPoint(start: startPoint, end: nextPoint)
        let sigma = directionVector.x * Float(sin(angle)) - directionVector.y * Float(cos(angle))
        
        let score = Float(angle) * (sigma < 0 ? -1 : 1)
        
        print("ANGLE: \(angle)")
        print("SCORE: \(score)")
        
        if (score > 0) {
            return min(1.0, Double(angle) / 90)
        } else {
            return max(-1.0, Double(angle) / 90)
        }
    }
    
    func moveToNextStep() {
        self.route.nextStep()
        self.nextPoint = self.route.currentStep().goal
        //self.nextPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
    }
    
    func getVectorFromPoint(start: CLLocation, end: CLLocation) -> Vector2 {
        return Vector2(Float(end.coordinate.latitude) - Float(start.coordinate.latitude), Float(end.coordinate.longitude) - Float(start.coordinate.longitude))
    }
}
