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
   // static let locationService = LocationService()
    
    // MARK: Properties
    var user_location: CLLocation?
    var timestamp: NSDate?
    var isUpdating: Bool = false
    var locationManager: CLLocationManager!
    var delegateView: ViewController?
    var waitingForLocation: Bool = false
    lazy var notifyLocationAvailable: ()->Void = {arg in}
    // MARK: Delegate Functions
    
    // Receieves a location update from the OS and handles updating the user_location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("updating location!")
        let mostRecentLocation = locations.last
        // synchronize access to user_location
        user_location = mostRecentLocation
        timestamp = mostRecentLocation!.timestamp as NSDate?
        if waitingForLocation {
            print("someone is waiting for this location")
            waitingForLocation = false
            notifyLocationAvailable()
        }
    }
    
    // If location updates fail, print to let us know (add a signal here?)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed location update!")
       user_location = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Changed authorization status!!")
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
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            print("starting location updates")
            locationManager.startUpdatingLocation()
            isUpdating = true
            return true
        } else {
            print("Need to request access!")
            return false
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isUpdating = false
    }
    
    func waitForLocationToBeAvailable(callback: @escaping () -> () ) {
        // using a busy wait move here.
        // semaphores are causing application to block...
        notifyLocationAvailable = callback
        waitingForLocation = true
        print("set a handler for when location is updated")
    }
    
    func requestAccess() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse: break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("attempting to request access again!")
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
    
    private func doNoHarm() {
        
    }
    
    // MARK: Initialization
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        // immediately start updating our location
        print("initialized location manager")
        // This is supposed to be default:
        // locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
}
