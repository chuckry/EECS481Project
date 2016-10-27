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
		print ("\(userHeading)")
        let trig = getTrig(userLocation, userHeading)
        return Float(getSoundScore(angle: trig.0, directionVector: trig.1, userVector: trig.2))
    }
    
    func getTrig(_ userLocation: CLLocation, _ userHeading: Double) -> (Double, Vector2, Vector2) {
        
        // Unit vector that India is facing
        let userVector = Vector2(cos(Float(userHeading)*Scalar.radiansPerDegree), sin(Float(userHeading)*Scalar.radiansPerDegree))
        
        // Direction from passed userLocation to known nextPoint
        let directionVector = getVectorFromPoint(start: userLocation, end: nextPoint)
        
        // returns angle alpha and direction vector
        return (Double(acos(userVector.dot(directionVector) / directionVector.length) * Scalar.degreesPerRadian), directionVector, userVector)
    }
    
    func getSoundScore(angle: Double, directionVector: Vector2, userVector: Vector2) -> Double {
       // let directionVector = getVectorFromPoint(start: startPoint, end: nextPoint)
        
        /*
         The following link describes a solution to determine if a vector A is to the right or to the
         left of a vector B in a 2D space.
         http://stackoverflow.com/questions/13221873/determining-if-one-2d-vector-is-to-the-right-or-left-of-another
         
         According to the solution, sigma can be calculated as follows:
         
         sigma = -DOT(A, ROT90CCW(B))
         signOfSigma = (sigma < 0 ? -1.0 : 1.0)
         
         score = angle * signOfSigma
         
         For our use, we will substitute A for directionVector and B for userVector
         
        */
        let rotatedUserVector = Vector2(-userVector.y, userVector.x)
        
        let sigma = directionVector.dot(rotatedUserVector) * -1.0
        let signOfSigma = (sigma < 0 ? -1.0 : 1.0)
        
        //let sigma = directionVector.x * Float(sin(angle)) - directionVector.y * Float(cos(angle))
        
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
    
    func moveToNextStep() {
        self.route.nextStep()
        self.nextPoint = self.route.currentStep().goal
        //self.nextPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
    }
    
    func getVectorFromPoint(start: CLLocation, end: CLLocation) -> Vector2 {
        return Vector2(Float(end.coordinate.longitude) - Float(start.coordinate.longitude), Float(end.coordinate.latitude) - Float(start.coordinate.latitude))
    }
}
