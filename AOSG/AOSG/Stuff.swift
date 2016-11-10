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
	
	static let things = Stuff();
	//add your stuff here!
	public var message:String!
    
    public var favoriteSelected: Bool = false
    public var favoriteAddress: String = ""
    
    // for settings
    public var volume:Double = 1
    public var voiceOn:Bool = true
    public var voiceSpeed:Double = 0.5
    public var vibrationOn:Bool = true
    public var beepFrequency:Double = 1
    
	private init(){
		
	}

	
	
}
