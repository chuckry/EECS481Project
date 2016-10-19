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
    var startPoint = CGPoint()
    var nextPoint = CGPoint()
    
    init(path: NavigationPath) {
        self.route = path
        self.startPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
        self.route.nextStep()
        self.nextPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
    }
    
    func calculateSoundRatio(userHeading: Double) -> Float {
        print("CALCULATING")
        return Float(getSoundScore(angle: getAngle(userHeading: userHeading)))
    }
    
    func getAngle(userHeading: Double) -> Double {
        print("GETTING ANGLE")
        let userVector = Vector2(cos(Float(userHeading)), sin(Float(userHeading)))
        
        let directionVector = getVectorFromPoint(start: startPoint, end: nextPoint)
        return Double(acos(userVector.dot(directionVector) / (userVector.length * directionVector.length)) * Scalar.degreesPerRadian)
    }
    
    func getSoundScore(angle: Double) -> Double {
        print("GETTING SOUND SCORE")
        let directionVector = getVectorFromPoint(start: startPoint, end: nextPoint)
        let sigma = directionVector.x * Float(sin(angle)) - directionVector.y * Float(cos(angle))
        
        let g = Float(angle) * sigma < 0 ? -1 : 1
        
        print("ANGLE: \(angle)")
        print("G: \(g)")
        
        if (g > 0) {
            return min(1.0, Double(g) / 90)
        } else {
            return max(-1.0, Double(g) / 90)
        }
    }
    
    func moveToNextStep() {
        self.startPoint = self.nextPoint
        self.route.nextStep()
        self.nextPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
    }
    
    func getVectorFromPoint(start: CGPoint, end: CGPoint) -> Vector2 {
        return Vector2(Float(end.x) - Float(start.x), Float(end.y) - Float(start.y))
    }
}
