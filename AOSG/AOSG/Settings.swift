//
//  Settings.swift
//  AOSG
//
//  Created by Caroline Gluck on 11/9/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreData

class Settings: NSObject, NSCoding {
    var volume : Float
    var voiceOn : Bool
    var voiceSpeed : Float
    var vibrationOn : Bool
    var beepFrequency : Float
    
    
    struct PropertyKey {
        static let volumeKey = "volume"
        static let voiceOnKey = "voiceKey"
        static let voiceSpeedKey = "voiceSpeed"
        static let vibrationOnKey = "vibrationOn"
        static let beepFrequencyKey = "beepFrequency"
    }
    
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let archiveURL = documentDirectory.appendingPathComponent("settings")
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(volume, forKey: PropertyKey.volumeKey)
        aCoder.encode(voiceOn, forKey: PropertyKey.voiceOnKey)
        aCoder.encode(voiceSpeed, forKey: PropertyKey.voiceSpeedKey)
        aCoder.encode(vibrationOn, forKey: PropertyKey.vibrationOnKey)
        aCoder.encode(beepFrequency, forKey: PropertyKey.beepFrequencyKey)
    }
    
    init (volumeIn : Float, voiceOnIn: Bool, voiceSpeedIn : Float, vibrationOnIn : Bool, beepFrequencyIn : Float) {
        self.volume = volumeIn
        self.voiceOn = voiceOnIn
        self.voiceSpeed = voiceSpeedIn
        self.vibrationOn = vibrationOnIn
        self.beepFrequency = beepFrequencyIn
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let volume = aDecoder.decodeObject(forKey: PropertyKey.volumeKey) as! Float
        let voiceOn = aDecoder.decodeObject(forKey: PropertyKey.voiceOnKey) as! Bool
        let voiceSpeed = aDecoder.decodeObject(forKey: PropertyKey.voiceSpeedKey) as! Float
        let vibrationOn = aDecoder.decodeObject(forKey: PropertyKey.vibrationOnKey) as! Bool
        let beepFrequency = aDecoder.decodeObject(forKey: PropertyKey.beepFrequencyKey) as! Float
        self.init(volumeIn : volume, voiceOnIn: voiceOn, voiceSpeedIn : voiceSpeed, vibrationOnIn : vibrationOn, beepFrequencyIn : beepFrequency)
    }
    

    

    
    
}

