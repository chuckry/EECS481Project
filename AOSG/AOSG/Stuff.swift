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
	public var cancelled:Bool //true if route has been cancelled
	public var currentStepDescription: String //current navigation step
	
	private init(){
		cancelled = false
		currentStepDescription = ""
	}

	
	
}
