//
//  LocationManager.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/11/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreLocation
import Dispatch
import UIKit

class LocationService: NSObject, CLLocationManagerDelegate {
    
    // singleton pattern
   static let sharedInstance = LocationService()
    
    // MARK: Properties
    // these public filters can be overriden with more suitable values...
    public var headingFilter: CLLocationDegrees = 5.0
    public var distanceFilter: CLLocationDistance = 5.0
    
    
	var lastLocation: CLLocation?
    private var lastHeading: CLHeading?
    
    private var locationManager: CLLocationManager!
    
    var delegateView: UIViewController?
    
    private var isUpdating: Bool = false
    private var waitingForLocation: Bool = false
    private var waitingForHeading: Bool = false
    private var waitingForSignificantLocation: Bool = false
    
    lazy var notifyLocationAvailable: (CLLocation) -> Void = {arg in}
    lazy var notifyHeadingAvailable: (CLHeading) -> Void = {arg in}
    lazy var notifySignificantLocationChange: (CLLocation?, CLHeading?) -> Void = {arg in}
    
    // MARK: Delegate Functions
    
    // Executes when OS provides new location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if waitingForLocation && locations.count > 0 {
            lastLocation = locations.last!
            waitingForLocation = false
            notifyLocationAvailable(lastLocation!)
        }
        if waitingForSignificantLocation && locations.count > 0 {
            if lastLocation == nil {
                lastLocation = locations.last!
                self.notifySignificantLocationChange(self.lastLocation, self.lastHeading)
            } else if lastLocation!.distance(from: locations.last!) > distanceFilter {
                lastLocation = locations.last!
                self.notifySignificantLocationChange(self.lastLocation, self.lastHeading)
            }
        }
    }
    
    // Executes when OS provides new heading
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if waitingForHeading {
            lastHeading = newHeading
            waitingForHeading = false
            notifyHeadingAvailable(lastHeading!)
        }
        if waitingForSignificantLocation {
            if lastHeading == nil {
                lastHeading = newHeading
                self.notifySignificantLocationChange(self.lastLocation, self.lastHeading)
            } else if abs(lastHeading!.trueHeading - newHeading.trueHeading) > headingFilter  {
                lastHeading = newHeading
                self.notifySignificantLocationChange(self.lastLocation, self.lastHeading)
            }
        }
    }
    
    // If location updates fail, print to let us know (add a signal here?)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed location update: \(error)")
        lastLocation = nil
        lastHeading = nil
    }
    
    // Executes when OS notifies us of a change in user permissions
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // try to start updating location now
        if !self.startUpdatingLocation() {
            self.stopUpdatingLocation()
            self.requestAccess()
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        // TODO: Need to implement - what happens when app goes into background?
        print("location updates paused")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        // TODO: Need to implement - what happens when app comes into foreground?
    }
    
    // MARK: Interface Functions
    
    func startUpdatingLocation() -> Bool {
        if CLLocationManager.authorizationStatus() == .authorizedAlways
            || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            isUpdating = true
            return true
        } else {
            return false
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isUpdating = false
    }
    
    func waitForLocationToBeAvailable(callback: @escaping (CLLocation) -> Void) {
        notifyLocationAvailable = callback
        waitingForLocation = true
    }
    
    func waitForHeadingToBeAvailable(callback: @escaping (CLHeading) -> Void) {
        if CLLocationManager.headingAvailable() {
            notifyHeadingAvailable = callback
            waitingForHeading = true
        }
        print("Heading services not available!")
    }
    
    func waitForSignificantLocationChanges(callback: @escaping (CLLocation?, CLHeading?) -> Void) {
        notifySignificantLocationChange = callback
        waitingForSignificantLocation = true
    }
    
    func stopWaitingForSignificantLocationChanges() {
        waitingForSignificantLocation = false
    }
    
    func requestAccess() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse: break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            if delegateView == nil {
                print("ERROR: Need to set up a delegateView for this locationManager instance!")
                return
            }
            let alertController = UIAlertController (title: "Title", message: "ASOG Requires location data to locate your position and detect obstacles near you. Allow ASOG to find your location in settings", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            delegateView!.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: Initialization
    private override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
}
