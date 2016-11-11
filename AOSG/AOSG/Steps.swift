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
	var started = false
	let nowDate = Date()
	let cal = NSCalendar.current
	var weekAgo = Date()
	var stepSize: Double = 0 //weighted based on current and historical
	var historicalStepCount: Int = 0 //step count available on phone previous to using app
	var historicalStepDistance: Double = 0 //step distance available on phone previous to using app
	var historicalStepPace: Double = 0 //pace previous to opening app
	var currentStepCount: Int = 0 //step count since opening app
	var currentStepDistance: Double = 0 //step count since opening app
	var currentStepPace: Double = 0 //time for user to travel a meter
	var stepPaceEst: Double = 0 //weighted based on current and historical
	
	init(){
		weekAgo = cal.date(byAdding: .day, value: -8, to: Date())!
		self.getPreviousStepData()
	}

	//This function will not do anything if using simulator
	func getPreviousStepData() {
		guard !started else {return}
		started = true
	
		pedometer.queryPedometerData(from: weekAgo, to: nowDate) {
			(data: CMPedometerData?, error: Error?) -> Void in
			print("Looking for step data");
			if let data = data {
				self.historicalStepCount = data.numberOfSteps as Int
				self.historicalStepDistance = data.distance as! Double // in meters
				self.stepSize = self.historicalStepDistance / Double(self.historicalStepCount) as Double
				if CMPedometer.isPaceAvailable(){
					if let pace = data.currentPace {
						self.historicalStepPace = pace as Double
					}
				}
				
				let text = "Historical Data: Number of steps: \(self.historicalStepCount) \r Distance: \(self.historicalStepDistance) meters \r Average Step Size: \(self.stepSize) meters \r Pace: \(self.historicalStepPace) seconds/meter. "
				print(text)
			}
		}
	}
	
	//This function will not do anything if using simulator
	func beginCollectingStepData(){
		if CMPedometer.isStepCountingAvailable() {
			self.pedometer.startUpdates(from: nowDate, withHandler: { (data:CMPedometerData?, error:Error?) -> Void in
				
				DispatchQueue.main.async(execute: { () -> Void in
					
					if let data = data {
						
						self.currentStepCount = data.numberOfSteps as Int
						self.currentStepDistance = data.distance as! Double

						if CMPedometer.isPaceAvailable(){
							if let pace = data.currentPace {
								self.currentStepPace = pace as Double
							}
						}
						let w = 10.0 //how much is current weighted over historical
						
						//weighting current steps by a factor of 10 for now
						let num = self.currentStepDistance*w + self.historicalStepDistance
						let den = Double(self.currentStepCount)*w + Double(self.historicalStepCount)
						self.stepSize = (num/den)/(w+1) as Double
						
						self.stepPaceEst = (self.currentStepPace*w + self.historicalStepPace)/(w+1)
						
						let text = "Current Data: Number of steps: \(self.currentStepCount) \r Distance: \(self.currentStepDistance) meters \r Average Step Size: \(self.stepSize) meters \r Average Pace: \(self.stepPaceEst) seconds/meter"
						print(text)
						
					}
				})
			})
		}
	}
	
}
