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
    var beepOn : Bool

    struct PropertyKey {
        static let volumeKey = "volume"
        static let voiceOnKey = "voiceOn"
        static let voiceSpeedKey = "voiceSpeed"
        static let beepOnKey = "beepOn"
    }
    
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let archiveURL = documentDirectory.appendingPathComponent("settings")
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(volume, forKey: PropertyKey.volumeKey)
        aCoder.encode(voiceOn, forKey: PropertyKey.voiceOnKey)
        aCoder.encode(voiceSpeed, forKey: PropertyKey.voiceSpeedKey)
        aCoder.encode(beepOn, forKey: PropertyKey.beepOnKey)
    }
    
    init (volumeIn : Float, voiceOnIn: Bool, voiceSpeedIn : Float, beepOnIn : Bool) {
        self.volume = volumeIn
        self.voiceOn = voiceOnIn
        self.voiceSpeed = voiceSpeedIn
        self.beepOn = beepOnIn
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let volume = aDecoder.decodeFloat(forKey: PropertyKey.volumeKey)
        let voiceOn = aDecoder.decodeBool(forKey: PropertyKey.voiceOnKey)
        let voiceSpeed = aDecoder.decodeFloat(forKey: PropertyKey.voiceSpeedKey)
        let beepOn = aDecoder.decodeBool(forKey: PropertyKey.beepOnKey)
        self.init(volumeIn : volume, voiceOnIn: voiceOn, voiceSpeedIn : voiceSpeed, beepOnIn : beepOn)
    }
    

    

    
    
}

