//
//  Steps.swift
//  AOSG
//
//	Contains functions to access past pedometer data, collect current pedometer 
//	data, and continuously convert direction distances into a number of steps.
//
//  Created by Leda Daehler on 10/17/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreMotion
import UIKit

public typealias CMPedometerHandler = (CMPedometerData?, NSError?) -> Void

class Steps {
	
	let pedometer = CMPedometer()
	let activityManager = CMMotionActivityManager()
	let nowDate = Date()
	let cal = NSCalendar.current
	var weekAgo = Date()
	var stepSize: Float = 0
	var historicalStepCount: Int = 0 //step count available on phone previous to using app
	var historicalStepDistance: Float = 0 //step count available on phone previous to using app
	var currentStepCount: Int = 0 //step count since opening app
	var currentStepDistance: Float = 0 //step count since opening app

	
	init(){
		weekAgo = cal.date(byAdding: .day, value: -8, to: Date())!
		self.getPreviousStepData()
	}

	//This function will not do anything if using simulator
	func getPreviousStepData() {
		pedometer.queryPedometerData(from: weekAgo, to: nowDate) {
			(data: CMPedometerData?, error: Error?) -> Void in
			print("Looking for step data");
			if let data = data {
				self.historicalStepCount = data.numberOfSteps as Int
				self.historicalStepDistance = data.distance as! Float // in meters
				self.stepSize = self.historicalStepDistance / Float(self.historicalStepCount) as Float
	
				let text = "Historical Data: Number of steps: \(self.historicalStepCount) \r Distance: \(self.historicalStepDistance) meters \r Average Step Size: \(self.stepSize) meters"
				print(text)
			}
		}
	}
	
	//This function will not do anything if using simulator
	func beginCollectingStepData(){
		if CMPedometer.isStepCountingAvailable() {
			self.pedometer.startUpdates(from: weekAgo, withHandler: { (data:CMPedometerData?, error:Error?) -> Void in
				
				DispatchQueue.main.async(execute: { () -> Void in
					
					if let data = data {
						
						self.currentStepCount = (data.numberOfSteps as Int) - self.historicalStepCount
						self.currentStepDistance = (data.distance as! Float) - self.historicalStepDistance
						
						self.stepSize = (self.currentStepDistance + self.historicalStepDistance) / Float(self.currentStepCount + self.historicalStepCount) as Float
						
						let text = "Current Data: Number of steps: \(self.currentStepCount) \r Distance: \(self.currentStepDistance) meters \r Average Step Size: \(self.stepSize) meters"
						print(text)
						
					}
				})
			})
		}
	}
	
}
