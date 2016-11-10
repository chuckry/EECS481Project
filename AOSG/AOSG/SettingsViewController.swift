//
//  SettingsViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation

class SettingsViewController: UIViewController {
    
    //TODO: implement beep frequency and vibration switch
    // maybe beep frequency coorelates to signifigant change distance?
    
    var currentSettings : Settings = Settings.init(volumeIn: 1.0, voiceOnIn: true, voiceSpeedIn: 0.5, vibrationOnIn: true, beepFrequencyIn: 1)
    
    
    
    
    @IBOutlet weak var volumeChangeLabel: UITextField!
    @IBOutlet weak var volumeChange: UIStepper!
    
    @IBOutlet weak var voiceSwitchLabel: UITextField!
    @IBOutlet weak var voiceSwitch: UISwitch!
    
    @IBOutlet weak var voiceChangeLabel: UITextField!
    @IBOutlet weak var voiceChange: UIStepper!
    
    @IBOutlet weak var vibrationSwitchLabel: UITextField!
    @IBOutlet weak var vibrationSwitch: UISwitch!
    
    @IBOutlet weak var beepChangeLabel: UITextField!
    @IBOutlet weak var beepChange: UIStepper!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*if let savedSettings = loadSettings() {
            currentSettings = savedSettings
        }
        else {
            saveSettings()
        }*/
        
        Speech.shared.speechRate = currentSettings.voiceSpeed
        Speech.shared.voiceOn = currentSettings.voiceOn
        Speech.shared.volume = currentSettings.volume
        
        
        volumeChange.value = (Stuff.things.volume)*10
        volumeChangeLabel.text = "Volume: " + String(volumeChange.value)
        
        voiceSwitch.isOn = Stuff.things.voiceOn
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice ON"
        }
        else {
            voiceSwitchLabel.text = "Voice OFF"
        }
        
        voiceChange.value = Stuff.things.voiceSpeed
        voiceChangeLabel.text = "Voice Speed: " + String(voiceChange.value)
        
        vibrationSwitch.isOn = Stuff.things.vibrationOn
        if vibrationSwitch.isOn {
            vibrationSwitchLabel.text = "Vibration ON"
        }
        else {
            vibrationSwitchLabel.text = "Vibration OFF"
        }
        
        beepChange.value = Stuff.things.beepFrequency
        beepChangeLabel.text = "Beep Frequency: " + String(beepChange.value)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Speech.shared.immediatelySay(utterance: "Settings")
    }
    
    
    func saveSettings() {
        let isSucessfulSave = NSKeyedArchiver.archiveRootObject(currentSettings, toFile: Settings.archiveURL.path)
        if !isSucessfulSave {
            print ("Settings were not successfully saved")
        }
        
    }
    
    func loadSettings() -> Settings? {
        return (NSKeyedUnarchiver.unarchiveObject(withFile: Settings.archiveURL.path) as! Settings)
    }
    
    
    
    @IBAction func volumeChangeControl(_ sender: AnyObject) {
        Stuff.things.volume = volumeChange.value/10
        currentSettings.volume = Float(volumeChange.value/10)
        volumeChangeLabel.text = "Volume: " + String(volumeChange.value)
        Speech.shared.volume = currentSettings.volume
        //saveSettings()
    }
    
    @IBAction func voiceSwitchToggle(_ sender: AnyObject) {
        if voiceSwitch.isOn {
            Stuff.things.voiceOn = true;
            currentSettings.voiceOn = true;
            voiceSwitchLabel.text = "Voice ON"
        }
        else {
            Stuff.things.voiceOn = false;
            currentSettings.voiceOn = false;
            voiceSwitchLabel.text = "Voice OFF"
        }
        Speech.shared.voiceOn = currentSettings.voiceOn
        //saveSettings()
    }
    
    
    @IBAction func voiceChangeController(_ sender: AnyObject) {
        Stuff.things.voiceSpeed = voiceChange.value
        currentSettings.voiceSpeed = Float(voiceChange.value)
        //print ("Voice speed = ", voiceChange.value)
        voiceChangeLabel.text = "Voice Speed: " + String(voiceChange.value)
        Speech.shared.speechRate = currentSettings.voiceSpeed
        //saveSettings()
        
    }
    
    @IBAction func vibrationSwitchToggle(_ sender: AnyObject) {
        if vibrationSwitch.isOn {
            Stuff.things.vibrationOn = true;
            currentSettings.vibrationOn = true;
            vibrationSwitchLabel.text = "Vibration ON"
        }
        else {
            Stuff.things.vibrationOn = false;
            currentSettings.vibrationOn = false;
            vibrationSwitchLabel.text = "Vibration OFF"
        }
        //saveSettings()
    }
    
    
    @IBAction func beepChangeControl(_ sender: AnyObject) {
        Stuff.things.beepFrequency = beepChange.value
        currentSettings.beepFrequency = Float(beepChange.value)
        beepChangeLabel.text = "Beep Frequency: " + String(beepChange.value)
        //saveSettings()
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
