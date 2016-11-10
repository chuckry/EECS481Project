//
//  Stuff.swift
//  AOSG
//
//  Created by Leda Daehler on 11/2/16.
//  Copyright © 2016 EECS481. All rights reserved.
//
//Data that needs to be shared between each screen.

import Foundation

class Stuff{
	
	static let things = Stuff()
	//add your stuff here!
	public var message:String!
	public var cancelled:Bool = false //true if route has been cancelled
	public var currentStepID:Int = 0
	public var currentStepDescription: String = "" //current navigation step
	public var currentStepDist:Double = 0 //distance remaining in step
	public var stepLengths: Array<Double> = [] // length of each step in the path
	
	public var totalDistance: Double = 0 //dist from start to finish
    public var favoriteSelected: Bool = false
    public var favoriteAddress: String = ""
	public var stepSizeEst: Double = 0
	public var stepPace: Double = 0
    
	private init(){

	}

	func sumDists() -> Double{
		let slice: Array<Double> = Array(stepLengths[currentStepID+1..<stepLengths.count])
		var dist:Double = 0
		//add distance remaining in current step
		dist += currentStepDist
		//add distance remaining in future steps
		for i in slice{
			dist += i
		}
		return dist
	}
	
	func getPace() -> Double{
		//default to 3 mi/hour in seconds/meter
		if (stepPace == 0){
			stepPace = 0.745647284
		}
		return stepPace
	}
	
	
}
