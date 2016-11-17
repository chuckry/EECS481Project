//
//  InputViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation

class InputViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    @IBOutlet weak var inputDestinationTextField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
   // let mainViewController: MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Speech.shared.voiceOn {
            disableUIElements()
            "New Destination".say()
        } else {
            enableUIElements()
        }
        
    }
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        inputDestinationTextField.isUserInteractionEnabled = false
        spinner.startAnimating()
       // LocationService.sharedInstance.waitForLocationToBeAvailable(callback: MainViewController.initialLocationKnown)
    }
    
    //func startNavigation
    
    func disableUIElements() {
        inputDestinationTextField.isUserInteractionEnabled = false
        spinner.isUserInteractionEnabled = false
    }
    func enableUIElements() {
        inputDestinationTextField.isUserInteractionEnabled = true
        spinner.isUserInteractionEnabled = true
    }
    
    
}
