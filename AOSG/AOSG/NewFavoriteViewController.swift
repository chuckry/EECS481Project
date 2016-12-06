//
//  NewFavoriteViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 11/6/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit

class NewFavoriteViewController: UIViewController {

    // MARK: Properties
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var cancelButtonObject: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var locationSearchStatusLabel: UILabel!
    @IBOutlet weak var locationAddressLabel: UILabel!
    @IBOutlet weak var useCurrentLocationSwitch: UISwitch!
    var favorite: Favorite?
    var currentAddress: String?
    let locationManager = LocationService.sharedInstance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        useCurrentLocationSwitch.addTarget(self, action: #selector(NewFavoriteViewController.useCurrentLocationSwitchToggled), for: UIControlEvents.allTouchEvents)
        nameTextField.delegate = self
        addressTextField.delegate = self
        
    }
    
    func enableUIElements() {
        nameTextField.isEnabled = true
        addressTextField.isEnabled = true
        useCurrentLocationSwitch.isEnabled = true
        addressTextField.isEnabled = true
        saveButton.isEnabled = true
        cancelButtonObject.isEnabled = true
    }
    
    func disableUIElements() {
        nameTextField.isEnabled = false
        addressTextField.isEnabled = false
        useCurrentLocationSwitch.isEnabled = false
        addressTextField.isEnabled = false
        saveButton.isEnabled = false
        cancelButtonObject.isEnabled = false
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        nameTextField.text = ""
        addressTextField.text = ""
        useCurrentLocationSwitch.isOn = false
        addressTextField.isEnabled = true
        saveButton.isEnabled = false
        favorite = nil
        currentAddress = nil
        locationSearchStatusLabel.isHidden = true
        locationSearchStatusLabel.text = "Searching for your location..."
        //locationManager.waitForAddressToBeAvailable(callback: addressAvailable)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if saveButton === sender as AnyObject? {
            let name = nameTextField.text!
            if useCurrentLocationSwitch.isOn {
                let address = currentAddress!
                favorite = Favorite(withName: name, withAddress: address)
            } else {
                let address = addressTextField.text!
                favorite = Favorite(withName: name, withAddress: address)
            }
        }
    }
    
    func useCurrentLocationSwitchToggled() {
        addressTextField.isEnabled = !useCurrentLocationSwitch.isOn
        if useCurrentLocationSwitch.isOn {
            locationSearchStatusLabel.isHidden = false
            locationSearchStatusLabel.text = "Searching for your location..."
            currentAddress = nil
            locationManager.waitForAddressToBeAvailable(callback: addressAvailable)
            updateSaveButton()
        } else {
            locationSearchStatusLabel.isHidden = true
        }
    }
    
    func addressAvailable(address: String?) {
        DispatchQueue.main.async {
            if address != nil {
                self.locationSearchStatusLabel.isHidden = true
                self.currentAddress = address!
                self.updateSaveButton()
            } else {
                self.locationSearchStatusLabel.text = "Location not found :("
            }
        }
    }
    
    func updateSaveButton() {
        let namePopulated = nameTextField.text != nil && nameTextField.text != ""
        let addressPopulated = addressTextField.text != nil && addressTextField.text != ""
        let useCurrentAddress = useCurrentLocationSwitch.isOn
        let currentAddressFound = currentAddress != nil && currentAddress != ""
        if  namePopulated && ((useCurrentAddress && currentAddressFound) || addressPopulated) {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
}

extension NewFavoriteViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButton()
    }
}
