//
//  SoundManager.swift
//  AOSG
//
//  Created by Chuckry Vengadam on 11/18/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreLocation
import Dispatch
import UIKit

class SoundManager {
    var audioPlayer: AVAudioPlayer = AVAudioPlayer()
    var audioEngine: AVAudioEngine = AVAudioEngine()
    let soundURL: NSURL
    
    init(fileName: String, ext: String) {
        self.soundURL = Bundle.main.url(forResource: fileName, withExtension: ext)! as NSURL
        do {
            self.audioPlayer = try! AVAudioPlayer(contentsOf: soundURL as URL)
            self.audioPlayer.pan = 0
            self.audioPlayer.volume = 1
            self.audioPlayer.numberOfLoops = -1
        }
    }
    
    func beginPlayingSound() {
        if (Stuff.things.beepOn) {
            self.audioPlayer.prepareToPlay()
            self.audioPlayer.play()
            print("Starting to play!")
        }
    }
    
    /*
     *  Update sound balance and volume
     */
    func changeFeedback(balance: Float, volume: Float, numLoops: Int) {
        print("BALANCE: \(balance)")
        print("VOLUME: \(volume)")
        self.audioPlayer.pan = balance
        self.audioPlayer.volume = volume
        print("playing sound")
    }
    
    /*
     *  Calculates sound ratio based on angle between current position and expected position
     *  Inspired by: http://stackoverflow.com/questions/13221873/determining-if-one-2d-vector-is-to-the-right-or-left-of-another
     */
    func getSoundBalance(angle: Double, directionVector: Vector2, userVector: Vector2) -> Double {
        let rotatedUserVector = Vector2(-userVector.y, userVector.x)
        let sigma = directionVector.dot(rotatedUserVector) * -1.0
        let signOfSigma = (sigma < 0 ? -1.0 : 1.0)
        
        var score = (angle * signOfSigma) / (-90.0)
        
        return score > 0 ? min(1.0, score) : max(-1.0, score)
    }
}
