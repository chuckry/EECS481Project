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
    
    var currentSettings: Settings = Settings(volumeIn: 1, voiceOnIn: true, voiceSpeedIn: 0.5, vibrationOnIn: true, beepFrequencyIn: 1)
    
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
        
        if let savedSettings = loadSettings() {
            currentSettings = savedSettings
        }
        else {
            saveSettings()
        }
        
        Speech.shared.speechRate = currentSettings.voiceSpeed
        Speech.shared.voiceOn = currentSettings.voiceOn
        Speech.shared.volume = currentSettings.volume

        
        volumeChange.value = Double((currentSettings.volume)*10.0)
        volumeChangeLabel.text = "Volume: \(currentSettings.volume)"
        
        voiceSwitch.isOn = currentSettings.voiceOn
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice ON"
        } else {
            voiceSwitchLabel.text = "Voice OFF"
        }
        
        voiceChange.value = Double(currentSettings.voiceSpeed)
        voiceChangeLabel.text = "Voice Speed: \(currentSettings.voiceSpeed)"
        
        Stuff.things.vibrationOn = currentSettings.vibrationOn
        vibrationSwitch.isOn = currentSettings.vibrationOn
        if vibrationSwitch.isOn {
            vibrationSwitchLabel.text = "Vibration ON"
        } else {
            vibrationSwitchLabel.text = "Vibration OFF"
        }
        
        Stuff.things.beepFrequency = currentSettings.beepFrequency
        beepChange.value = Double(currentSettings.beepFrequency)
        beepChangeLabel.text = "Beep Frequency: \(currentSettings.beepFrequency)"
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
        } else {
            print("Setting saved!")
        }
        
    }
    
    func loadSettings() -> Settings? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Settings.archiveURL.path) as? Settings
    }
    
    
    
    @IBAction func volumeChangeControl(_ sender: AnyObject) {
        currentSettings.volume = Float(volumeChange.value/10)
        volumeChangeLabel.text = "Volume: \(currentSettings.volume)"
        Speech.shared.volume = currentSettings.volume
        saveSettings()
    }
    
    @IBAction func voiceSwitchToggle(_ sender: AnyObject) {
        if voiceSwitch.isOn {
            voiceSwitchLabel.text = "Voice ON"
        } else {
            voiceSwitchLabel.text = "Voice OFF"
        }
        
        currentSettings.voiceOn = voiceSwitch.isOn
        Speech.shared.voiceOn = voiceSwitch.isOn

        saveSettings()
    }
    
    
    @IBAction func voiceChangeController(_ sender: AnyObject) {
        currentSettings.voiceSpeed = Float(voiceChange.value)
        voiceChangeLabel.text = "Voice Speed: \(currentSettings.voiceSpeed)"
        Speech.shared.speechRate = currentSettings.voiceSpeed
        saveSettings()

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
        currentSettings.vibrationOn = vibrationSwitch.isOn
        Stuff.things.vibrationOn = vibrationSwitch.isOn

        saveSettings()
    }
    
    
    @IBAction func beepChangeControl(_ sender: AnyObject) {
        Stuff.things.beepFrequency = Float(beepChange.value)
        currentSettings.beepFrequency = Float(beepChange.value)
        beepChangeLabel.text = "Beep Frequency: \(currentSettings.beepFrequency)"

        saveSettings()
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
