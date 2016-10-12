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
    weak var locationEnableButton: UIButton!
    var address: String! = ""
    let locationService = LocationService()
    
	override func loadView() {
        self.view = UIView()
        //self.view.backgroundColor = .blue
        locationService.delegateView = self
        if !locationService.startUpdatingLocation() {
            locationService.requestAccess()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.viewDidAppear(_:)), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

        
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.viewDidAppear(_:)), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        if !locationService.startUpdatingLocation() {
            locationService.requestAccess()
        } else {
            locationService.waitForLocationToBeAvailable(callback: self.loadGoogleMapDisplay)
        }
    }
    
    func loadGoogleMapDisplay() -> Void {
        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.
//        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
//        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
//        mapView.isMyLocationEnabled = true
//        self.view.addSubview(mapView)
//        
//        // Creates a marker in the center of the map.
//        let marker = GMSMarker()
//        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
//        marker.title = "Sydney"
//        marker.snippet = "Australia"
//        marker.map = mapView
//
        
        
        // use userLocation to create a pin. First check it tho
        let coord = locationService.user_location!.coordinate
        print("I'm at coordinates:", coord.latitude, coord.longitude)
        let camera = GMSCameraPosition.camera(
            withLatitude: coord.latitude,
            longitude: coord.longitude,
            zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        view = mapView
            
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        marker.map = mapView
        
        // create the text field and paint it
        destTextField = buildSearchBar(placeholder: "Enter travel destination")
        self.view.addSubview(destTextField)

    }

//	override func didReceiveMemoryWarning() {
//		super.didReceiveMemoryWarning()
//		// Dispose of any resources that can be recreated.
//	}
    
    func buildSearchBar(placeholder: String) -> UITextField {
        let screenSize: CGRect = UIScreen.main.bounds
        let textField = UITextField(frame: CGRect(x: 20, y: 100, width: screenSize.width - 40, height: 80))
        textField.placeholder = placeholder
        textField.backgroundColor = .white
        textField.borderStyle = UITextBorderStyle.roundedRect
        textField.textAlignment = .center
        textField.returnKeyType = .search
        textField.delegate = self
        textField.addTarget(self, action: #selector(ViewController.searchBarShouldReturn(_:)), for: .editingDidEnd)
        return textField
    }
    /*
     *  Extracts text when return key is pressed
     */
    func searchBarShouldReturn(_ textField: UITextField) -> Bool {
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




