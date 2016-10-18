//
//  ViewController.swift
//  AOSG
//
//  Created by Leda Daehler on 10/7/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController, UITextFieldDelegate {

    // MARK: Properties
    weak var destTextField: UITextField!
    var address: String! = ""
	var stepData = Steps()
	
	override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .blue
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	
        destTextField = createTextField(placeholder: "Enter travel destination")
        self.view.addSubview(destTextField)
		stepData.beginCollectingStepData()
		print(stepData.stepSize)
		
	}

//	override func didReceiveMemoryWarning() {
//		super.didReceiveMemoryWarning()
//		// Dispose of any resources that can be recreated.
//	}
	
	
    func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField(frame: CGRect(x: 20, y: 100, width: 370, height: 100))
        textField.placeholder = placeholder
        textField.backgroundColor = .white
        textField.borderStyle = UITextBorderStyle.roundedRect
        textField.textAlignment = .center
        textField.returnKeyType = .search
        textField.delegate = self
        textField.addTarget(self, action: #selector(ViewController.textFieldShouldReturn(_:)), for: .editingDidEnd)
        return textField
    }
    
    /*
     *  Extracts text when return key is pressed
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        address = textField.text?.replacingOccurrences(of: " ", with: "+")
        queryLocationFromAddress(address: address)
        return true
    }
    
    /*
     *  Creates HTTP GET request using extracted address and api key
     *
     *  NOTE: Google tracks api keys through IP address, so every user needs a separate api key. Not sure how we want to handle this.
     */
    func queryLocationFromAddress(address: String) {
        // let API_KEY = "AIzaSyB31P8Kjcf35xn2arXtpO-0l1HaldtF0k8"
        let API_KEY = "AIzaSyAcwEmSj5iETr1x4AyAGZ9ImsDPzAALEvk"
        let requestURL = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=" + address + "&key=" + API_KEY)
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) -> Void in
            
            // Translate potential errors
            if (error != nil) {
                print("ERROR: ", error)
                return
            }
            
            // Extract Latitude/Longitude from JSON
            let json = JSON(data: data!)
            guard let lat = json["results"][0]["geometry"]["location"]["lat"].float
            else {
                // TODO: Handle not having a latitude where expected
                return
            }
            guard let lng = json["results"][0]["geometry"]["location"]["lng"].float
            else {
                // TODO: Handle not having a longitude where expected
                return
            }
            guard let address = json["results"][0]["formatted_address"].string
            else {
                // TODO: Handle not having a longitude where expected
                return
            }
            self.address = address
            self.getMapFromLocation(lat: lat, long: lng, address: address)
        }
        task.resume()
    }
    
    /* TODO:
     *  Implement this method to call the Google Maps API and display a map of the given location.
     *
     *  There should be a text field in the top showing the formatted address of the location for re-querying.
     */
    func getMapFromLocation(lat: Float, long: Float, address: String) {
        print("Latitude is:", lat)
        print("Longitude is:", long)
        print("Address is", address)
    }
}




