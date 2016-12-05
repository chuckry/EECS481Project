//
//  Stuff.swift
//  AOSG
//
//  Created by Leda Daehler on 11/2/16.
//  Copyright © 2016 EECS481. All rights reserved.
//
//Data that needs to be shared between each screen.

import Foundation

class Stuff {
	static let things = Stuff()

	public var message: String! = ""
	public var cancelled: Bool = false //true if route has been cancelled
	public var routeManager: RouteManager = RouteManager()
	public var currentStepID: Int = 0
	public var currentStepDescription: String = "" //current navigation step
	public var currentStepDist:Double = 0 //distance remaining in step
	public var stepLengths: Array<Double> = [] // length of each step in the path
	
	public var totalDistance: Double = 0 //dist from start to finish
    public var favoriteSelected: Bool = false
    public var favoriteAddress: String = ""
	public var stepSizeEst: Double = 0
	public var stepPace: Double = 0
    
    public var vibrationOn:Bool = true
    public var beepFrequency:Float = 1
    public var beepOn:Bool = true
    
    public var currentStepLabel = UILabel()
    public var currentLocationLabel = UILabel()
    public var destinationLocationLabel = UILabel()
    public var directionList = UITextView()
	
	public var upArrow = UIImageView()
	public var rightArrow = UIImageView()
	public var downArrow = UIImageView()
	public var leftArrow = UIImageView()
	public var settingsLabel = UILabel()
	public var inputLabel = UILabel()
	public var favoritesLabel = UILabel()
	public var voiceCommandLabel = UILabel()

	

	private init(){

	}
    
    func getHeaderFilterValue() -> Double {
        return 10 - Double(beepFrequency)
    }
    
    func getDistanceFilterValue() -> Double {
        return 10 - Double(beepFrequency)
    }

	func sumDists() -> Double{
		let slice: Array<Double> = Array(stepLengths[currentStepID + 1..<stepLengths.count])
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
	
	func showLabelsHideArrows(){
		self.settingsLabel.isHidden = true
		self.voiceCommandLabel.isHidden = true
		self.inputLabel.isHidden = true
		self.favoritesLabel.isHidden = true
		self.upArrow.isHidden = true
		self.downArrow.isHidden = true
		self.rightArrow.isHidden = true
		self.leftArrow.isHidden = true
		
		self.currentLocationLabel.isHidden = false
		self.destinationLocationLabel.isHidden = false
		self.directionList.isHidden = false
		self.currentStepLabel.isHidden = false
	}
	
	func showArrowsHideLabels(){
		self.settingsLabel.isHidden = false
		self.voiceCommandLabel.isHidden = false
		self.inputLabel.isHidden = false
		self.favoritesLabel.isHidden = false
		self.upArrow.isHidden = false
		self.downArrow.isHidden = false
		self.rightArrow.isHidden = false
		self.leftArrow.isHidden = false
		
		self.currentLocationLabel.isHidden = true
		self.destinationLocationLabel.isHidden = true
		self.directionList.isHidden = true
		self.currentStepLabel.isHidden = true
	}
	
	func resetPromptInfo(){
		Stuff.things.currentStepDescription = ""
	}
	
}
