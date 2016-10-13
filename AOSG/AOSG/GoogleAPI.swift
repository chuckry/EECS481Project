//
//  GoogleAPI.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/13/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreLocation

class GoogleAPI: NSObject {
    // Singleton Pattern
    static let sharedInstance = GoogleAPI()
    
    // MARK: Properties
    let API_KEY = "AIzaSyAcwEmSj5iETr1x4AyAGZ9ImsDPzAALEvk"
    let geocodeEnpoint = "https://maps.googleapis.com/maps/api/geocode/json?"
    let reverseGeocodeEndpoint = "https://maps.googleapis.com/maps/api/geocode/json?"
    
    // handles the conversion from a human-readable address to a CLLocation type.
    // calls the callback passed with both the address string and the CLLocation found.
    func geocode(address: String, callback: @escaping (GeocodingResponse) -> Void) {
        // set up request
        let urlEncodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let requestURL = URL(string: "\(geocodeEnpoint)address=\(urlEncodedAddress!)&key=\(API_KEY)")
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) -> Void in
            // Translate potential errors
            if (error != nil) {
                print("ERROR: ", error)
                callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                return
            }
            
            // Extract Latitude/Longitude from JSON
            let json = JSON(data: data!)
            guard let lat = json["results"][0]["geometry"]["location"]["lat"].float else {
                    callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                    return
            }
            guard let lng = json["results"][0]["geometry"]["location"]["lng"].float else {
                    callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                    return
            }
            // use the address in the response since this may be more precise
            guard let formatAddress = json["results"][0]["formatted_address"].string else {
                    callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                    return
            }
            guard let place_id = json["results"][0]["place_id"].string else {
                callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                return
            }
            // return to the callback with the data we needed
            let location = CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
            callback(GeocodingResponse(location: location, address: formatAddress, place_id: place_id))
        }
        task.resume()
    }
    
    func reverseGeocode(location: CLLocation, callback: @escaping (GeocodingResponse) -> Void) {
        // set up request
        let requestURL = URL(string: "\(reverseGeocodeEndpoint)latlng=\(location.coordinate.latitude),\(location.coordinate.longitude)&key=\(API_KEY)")
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) -> Void in
            // Translate potential errors
            if (error != nil) {
                print("ERROR: ", error)
                callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                return
            }
            let json = JSON(data: data!)
            // extract the address from JSON
            guard let address = json["results"][0]["formatted_address"].string else {
                callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                return
            }
            guard let place_id = json["results"][0]["place_id"].string else {
                callback(GeocodingResponse(location: nil, address: nil, place_id: nil))
                return
            }
            // return to the callback with the data we needed
            callback(GeocodingResponse(location: location, address: address, place_id: place_id))
        }
        task.resume()

    }
    
    private override init() {
        
    }
}

class GeocodingResponse {
    // MARK: Properties
    var location: CLLocation?
    var address: String?
    var place_id: String?
    // MARK: Construction
    init(location loc: CLLocation?, address addr: String?, place_id id: String?) {
        location = loc
        address = addr
        place_id = id
    }
    // MARK: Convenience Methods
    // Unwraps and formats address stored
    func addressDescription() -> String{
        if address != nil {
            return address!
        }
        return "unknown address"
    }
    // Unwraps and formats coordinates stored
    func locationDescription() -> String {
        if location != nil {
            return "(\(location!.coordinate.latitude), \(location!.coordinate.longitude))"
        }
        return "(?, ?)"
    }
    // Unwraps and return place_id stored
    func getPlaceID() -> String{
        if address != nil {
            return place_id!
        }
        return "unknown place_id"
    }
    // Sends back a formatted String
    func formatForDisplay() -> String {
        return "\(self.addressDescription())\n\(self.locationDescription())"
    }
}









