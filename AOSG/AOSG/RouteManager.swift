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
    var currentVector: Vector2
    
    var previousStep: CGPoint
    var currentStep: CGPoint
    
    init(path: NavigationPath) {
        self.route = path
        let startPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
        self.route.nextStep()
        let nextPoint = CGPoint(x: self.route.currentStep().goal.coordinate.longitude, y: self.route.currentStep().goal.coordinate.latitude)
        self.currentVector = self.getVector(start: startPoint, end: nextPoint)
    }
    
    func getVector(start: CGPoint, end: CGPoint) -> Vector2 {
        return Vector2(Float(currentStep.x) - Float(previousStep.x), Float(currentStep.y) - Float(previousStep.y))
    }
    
    func getAngle(userHeading: Double) -> Double {
        
        return 0
    }
}
