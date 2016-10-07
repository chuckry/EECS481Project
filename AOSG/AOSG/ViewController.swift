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

class ViewController: UIViewController {

	override func loadView() {
		// Create a GMSCameraPosition that tells the map to display the
		// coordinate -33.86,151.20 at zoom level 6.
		let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
		let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
		mapView.isMyLocationEnabled = true
		view = mapView
		
		// Creates a marker in the center of the map.
		let marker = GMSMarker()
		marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
		marker.title = "Sydney"
		marker.snippet = "Australia"
		marker.map = mapView
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

