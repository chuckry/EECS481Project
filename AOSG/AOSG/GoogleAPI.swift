//
//  GoogleAPI.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/13/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation
import CoreLocation

var abbreviationsToText: [String : String] = ["St" : "Street", "Ave": "Avenue", "Dr" : "Drive", "Blvd" : "Boulevard", "Rd" : "Road", "Ln" : "Lane", "Mt" : "Mount" , "N" : "North", "S" : "South", "E" : "East", "W" : "West", "Rte" : "Route", "Ct" : "Court"]
var setOfAbbreviations = ["St", "Ave", "Dr", "Blvd", "Rd", "Ln", "Mt", "N", "S", "E", "W", "Rte", "Ct"]
var statesDictionary: [String : String]
    = ["AL":"Alabama",
       "AK":"Alaska",
       "AZ":"Arizona",
       "AR":"Arkansas",
       "CA":"California",
       "CO":"Colorado",
       "CT":"Connecticut",
       "DE":"Delaware",
       "FL":"Florida",
       "GA":"Georgia",
       "HI":"Hawaii",
       "ID":"Idaho",
       "IL":"Illinois",
       "IN":"Indiana",
       "IA":"Iowa",
       "KS":"Kansas",
       "KY":"Kentucky",
       "LA":"Louisiana",
       "ME":"Maine",
       "MD":"Maryland",
       "MA":"Massachusetts",
       "MI":"Michigan",
       "MN":"Minnesota",
       "MS":"Mississippi",
       "MO":"Missouri",
       "MT":"Montana",
       "NE":"Nebraska",
       "NV":"Nevada",
       "NH":"New Hampshire",
       "NJ":"New Jersey",
       "NM":"New Mexico",
       "NY":"New York",
       "NC":"North Carolina",
       "ND":"North Dakota",
       "OH":"Ohio",
       "OK":"Oklahoma",
       "OR":"Oregon",
       "PA":"Pennsylvania",
       "RI":"Rhode Island",
       "SC":"South Carolina",
       "SD":"South Dakota",
       "TN":"Tennessee",
       "TX":"Texas",
       "UT":"Utah",
       "VT":"Vermont",
       "VA":"Virginia",
       "WA":"Washington",
       "WV":"West Virginia",
       "WI":"Wisconsin",
       "WY":"Wyoming"]

/// Describes a Navigation path consisting Navigation Steps. Manages step completion
class NavigationPath {
    // MARK : Properties
    var startLocation: GeocodingResponse
    var endLocation: GeocodingResponse
    var totalPathDistance: Double
    var totalPathDuration: Double
    var path: [NavigationStep] = []
    private var step: Int = 0
	var pedometer: Steps
	
    // initialization
    init (startAt: GeocodingResponse, endAt: GeocodingResponse, dist: Double, dur: Double, steps: [NavigationStep]) {
		pedometer = Steps() //NOTE: this isn't running until after the entire initialization finishes, because threads.
        startLocation = startAt
        endLocation = endAt
        totalPathDistance = dist
        totalPathDuration = dur
		Stuff.things.totalDistance = dist
        path = steps
        step = 0
		Stuff.things.cancelled = false;
        pedometer.beginCollectingStepData()//NOTE: this isn't running until after the entire initialization finishes, because threads.
		if pedometer.stepSize == 0.0{
			pedometer.stepSize = 0.6; //2 feet
		}
		print("PEDO:\(pedometer.stepSize)")
    }
    
    func getDirectionsAsStringArray() -> [String] {
        var directions: [String] = []
        for step in path {
			Stuff.things.stepLengths.append(step.totalDistance)
            if step.formattedNote != nil {
				let text = step.formattedDescription + "\nNote: " + step.formattedNote! + " \nDistance: \(step.totalDistance) Time: \(step.totalDuration), \nSteps: \(Int(step.totalDistance/Double(pedometer.stepSize)))"
                directions.append(text)
				print(text)
			} else {
				let text = step.formattedDescription + " \nDistance: \(step.totalDistance) Time: \(step.totalDuration), \nSteps: \(Int(step.totalDistance/Double(pedometer.stepSize)))"
				directions.append(text)
				print(text)
            }
        }
        return directions
    }
	
    // navigation complete?
    func arrivedAtDestination() -> Bool {
        return step >= path.count
    }
	
	// navigation cancelled?
	func cancelledNavigation() -> Bool {
		return Stuff.things.cancelled
	}
	
    // get current step
    func currentStep() -> NavigationStep {
        if step >= path.count {
            return path.last!
        }
        return path[step]
    }
    
    // go to the next step
    func nextStep() {
        step += 1
		Stuff.things.currentStepID = Stuff.things.currentStepID+1
    }
	

}


/// Describes a step in a NavigationPath. Provides methods to check progress to completing the step.
struct NavigationStep {
    // MARK: Properties
    var goal: CLLocation
    var totalHumanSteps: Int
    var totalDistance: Double
    /*
     DISCUSSION ON DURATION TIMES:
     
     Google seems to calculate distances based on the assumption that the normal
     human will walk 3 miles per hours (3 miles in 1 hour).
     
     Since our client could potential walk slower than this, her "slowness" would
     have to be determined in relation to this benchmark to make the duration
     estimation much more accurate. Slowness is calculated as follows:
     
     let speed = 3.0
     let userSpeed = GetUsersSpeed()
     let slowness = 1.0 + (speed - userSpeed)/userSpeed
     
     "slowness" is regarded as an optional parameter. If it is ommited in calculations,
     it will be assumed to be 1.0 (userSpeed == speed). GetUsersSpeed() should ideally
     be our best guess at India's speed, and should eventually take into account
     elevation.
     */
    var totalDuration: Double
    // What should be printed on the string
    var formattedDescription: String
    // What should be read aloud
    var readingDescription: String
    // Optional note (default is empty)
    var formattedNote: String?
    var rawDescription: String
    // radius of "error" considered to be within the goal location
    static var GOAL_ACHIEVED_DISTANCE: Double = 10.0 // (in meters)
	var currentFormattedDescription: String? //for current location label and read aloud

    // initialize a Navigation Step
    init (goal_lat: CLLocationDegrees, goal_lng: CLLocationDegrees, dist: Double, dur: Double, desc: String) {
        goal = CLLocation(latitude: goal_lat, longitude: goal_lng)
        totalDistance = dist
        totalDuration = dur
        rawDescription = desc

        formattedDescription = desc.replacingOccurrences(of: "<b>", with: " ").replacingOccurrences(of: "</b>", with: " ")
        
        let regex : NSRegularExpression = try! NSRegularExpression(pattern: "<.*?>", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, rawDescription.characters.count)
        formattedDescription = regex.stringByReplacingMatches(in: rawDescription, options: .withoutAnchoringBounds, range: range, withTemplate: " ")
        totalHumanSteps = 0
        
        var myArray : [String] = formattedDescription.components(separatedBy:" ")
        
        for (index, word) in myArray.enumerated() {
            if setOfAbbreviations.contains(word) {
                myArray[index] = abbreviationsToText[word]!
            }
        }
        
        readingDescription = myArray.joined(separator: " ")
    }
	
	func createCurrentFormattedString(currentLocation: CLLocation, stepSizeEst: Double) -> String{
		var dist = estimatedDistanceRemaining(from: currentLocation)
		Stuff.things.currentStepDist = dist
		let stepEst = Int(round(1*dist/stepSizeEst)/1)
		dist = Double(round(100*dist)/100)
		let text: String = formattedDescription + " in \(stepEst) steps"// (\(dist) meters) "
		return text
	}
    
    /*
     returns if the passed location is permissibly within a radius
     where the route guidance can assume the user has arrived at the goal
     for this step
     */
    func achievedGoal(location: CLLocation) -> Bool {
        return estimatedDistanceRemaining(from: location) < NavigationStep.GOAL_ACHIEVED_DISTANCE
    }

    /*
     returns the total seconds duration for this trip as a Double
     Accounts for "slowness" in the user's speed. Values in [0.0, 1.0] indicate
     the user travels just as fast or faster than 3 miles/hr on average.
     Values in (1.0, infinity) will indicate the user travels slower than 3 mph.
     */
    func getAdjustedDuration(slowness: Double) -> Double {
        return totalDuration * slowness
    }
    
    /*
     returns the estimated distance remaining as a function of a given location
     and a bird's eye view of the distance between two points
     */
    func estimatedDistanceRemaining(from: CLLocation) -> Double {
        return goal.distance(from: from)
    }
    
    func estimatedDistanceRemaining(traveled: Double) -> Double {
        return abs(totalDistance - traveled)
    }
    
    /*
     returns a ratio from [0.0, infinity] that describes how close the current
     location is to the goal location, where 0.0 is considered "at the goal".
     For locations within the radius of totalDistance from the goal, the ratio
     will be in [0.0, 1.0]
     */
    func estimatedGoalCompletion(from: CLLocation) -> Double {
        return estimatedDistanceRemaining(from: from) / totalDistance
    }
    
    /*
     returns the estimated travel time remaining to the goal. Adjusts for slowness
     and bases the estimation from travelling time from the passed location.
     */
    func estimatedDurationRemaining(from: CLLocation, slowness: Double = 1.0) -> Double {
        return (1 - estimatedGoalCompletion(from: from)) * getAdjustedDuration(slowness: slowness)
    }
}


/// Describes Geocode data from google including a location, a address string, and a Google place_id
struct GeocodingResponse {
    // MARK: Properties
    var location: CLLocation
    var address: String
    var place_id: String
    // MARK: Construction
    init(location loc: CLLocation, address addr: String, place_id id: String) {
        location = loc
        address = addr
        place_id = id
    }
    // Unwraps and formats coordinates stored
    func locationDescription() -> String {
        return "(\(location.coordinate.latitude), \(location.coordinate.longitude))"
    }

    // Sends back a formatted String
    func formatForDisplay() -> String {
        return address
    }
    
    func formatForReading() -> String {
        print ("Address before: ", address)
        var wholeAddress : [String] = address.components(separatedBy:", ")
        
        var streetIndex : Int = -1
        if wholeAddress.count == 4 { streetIndex = 0 }
        else if wholeAddress.count == 5 { streetIndex = 1 }
        else { return address }
        
        var streetAddress : [String] = wholeAddress[streetIndex].components(separatedBy:" ")

        wholeAddress.remove(at: wholeAddress.count-1)
        
        for (index, word) in streetAddress.enumerated() {
            if setOfAbbreviations.contains(word) {
                streetAddress[index] = abbreviationsToText[word]!
            }
        }
        wholeAddress[streetIndex] = streetAddress.joined(separator: " ")
        
        var token : [String] = wholeAddress[2].components(separatedBy:" ")
        
        for (abbr, state) in statesDictionary {
            for (index, component) in wholeAddress.enumerated() {
                if component.contains(abbr) {
                    wholeAddress[index] = component.replacingOccurrences(of: abbr, with: state)
                }
            }
        }
        return wholeAddress.joined(separator: " ")
    }
}


/// Describes a Google API client that sends requests using the Google API and returns responses via callbacks
class GoogleAPI: NSObject {
    // Singleton Pattern
    static let sharedInstance = GoogleAPI()
    
    // MARK: Properties
    // API_KEY for Google Directions (Apoorva Debug): AIzaSyCWTn5M2mMymn-iFSLSzz3FYts4xeQwHzQ
    let API_KEY = "AIzaSyCWTn5M2mMymn-iFSLSzz3FYts4xeQwHzQ"
    let geocodeEnpoint = "https://maps.googleapis.com/maps/api/geocode/json?"
    let reverseGeocodeEndpoint = "https://maps.googleapis.com/maps/api/geocode/json?"
    let directionsEndpoint = "https://maps.googleapis.com/maps/api/directions/json?mode=walking&"
    
    // Handles places input
    let placesEndpoint = "https://maps.googleapis.com/maps/api/place/textsearch/json?"

    // Querys the Google directions API to extract direction from an origin to a destination
    func directionsFromAddress(from: String, place_id: String?, address: String, callback: @escaping (NavigationPath?) -> Void) {
        
        // call the directions API, and create a Navigation path to send back.
        let to = place_id != nil ? "place_id:\(place_id!)" : address

        let urlEncodedFrom = from.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let urlEncodedTo = to.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let fullURL = "\(directionsEndpoint)origin=\(urlEncodedFrom!)&destination=\(urlEncodedTo!)&key=\(API_KEY)"
        let requestURL = URL(string: fullURL)
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"
        
        print(fullURL)

        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) -> Void in
            // Translate potential errors
            if error != nil {
                print("ERROR: \(error)")
                callback(nil)
                return
            }
            
            let json = JSON(data: data!)
            // Check the status
            guard let status = json["status"].string else {
                print("status string was unavailable")
                callback(nil)
                return
            }
            // If status isn't ok, we can't keep going
            guard status == "OK" else {
                print("status was not ok: \(status)")
                callback(nil)
                return
            }
            // Get the geocode status. If there was an issue in location, we'd know
            guard let originGeocodeStatus = json["geocoded_waypoints"][0]["geocoder_status"].string else {
                print("origin geocode status is unavailable")
                callback(nil)
                return
            }
            // Check status
            guard originGeocodeStatus == "OK" else {
                print("origin geocode status is non-OK \(originGeocodeStatus)")
                callback(nil)
                return
            }
            // Get the geocode status. If there was an issue in location, we'd know
            guard let destinationGeocodeStatus = json["geocoded_waypoints"][1]["geocoder_status"].string else {
                print("destination geocode status is unavailable")
                callback(nil)
                return
            }
            // Check status
            guard destinationGeocodeStatus == "OK" else {
                print("destination geocode status is non-OK \(destinationGeocodeStatus)")
                callback(nil)
                return
            }
            // Get the place id for origin
            guard let originPlaceID = json["geocoded_waypoints"][0]["place_id"].string else {
                print("origin place_id is unavailable")
                callback(nil)
                return
            }
            // get the place id for destination
            guard let destinationPlaceID = json["geocoded_waypoints"][1]["place_id"].string else {
                print("destination place_if is unavailable")
                callback(nil)
                return
            }
            // get the path duration
            guard let pathDuration = json["routes"][0]["legs"][0]["duration"]["value"].double else {
                print("path duration is unavailable")
                callback(nil)
                return
            }
            // get the path distance
            guard let pathDistance = json["routes"][0]["legs"][0]["distance"]["value"].double else {
                print("path distance is unavailable")
                callback(nil)
                return
            }
            // get the origin address string
            guard let originAddress = json["routes"][0]["legs"][0]["start_address"].string else {
                print("origin address is unavailable")
                callback(nil)
                return
            }
            // get the destination address string
            guard let destinationAddress = json["routes"][0]["legs"][0]["end_address"].string else {
                print("destination address is unavailable")
                callback(nil)
                return
            }
            // get origin coordinates
            guard let originLatitude = json["routes"][0]["legs"][0]["start_location"]["lat"].double else {
                print("origin latitude is unavailable")
                callback(nil)
                return
            }
            guard let originLongitude = json["routes"][0]["legs"][0]["start_location"]["lng"].double else {
                print("origin longitude is unavailable")
                callback(nil)
                return
            }
            // get destination coordinates
            guard let destinationLatitude = json["routes"][0]["legs"][0]["end_location"]["lat"].double else {
                print("destination latitude is unavailable")
                callback(nil)
                return
            }
            guard let destinationLongitude = json["routes"][0]["legs"][0]["end_location"]["lng"].double else {
                print("destination longitude is unavailable")
                callback(nil)
                return
            }
            // construct origin and destination Geocode points
            let originLocation = CLLocation(latitude: originLatitude, longitude: originLongitude)
            let destinationLocation = CLLocation(latitude: destinationLatitude, longitude: destinationLongitude)
            let originGeocodingResponse = GeocodingResponse(location: originLocation, address: originAddress, place_id: originPlaceID)
            let destinationGeocodingResponse = GeocodingResponse(location: destinationLocation, address: destinationAddress, place_id: destinationPlaceID)
            var navigationSteps: [NavigationStep] = []
            // Parse the navigation steps
            for (index, step):(String, JSON) in json["routes"][0]["legs"][0]["steps"] {
                // get the goal location for this step
                guard let stepGoalLatitude = step["end_location"]["lat"].double  else {
                    print("steps[\(index)]: destination latitude is unavailable")
                    callback(nil)
                    return
                }
                guard let stepGoalLongitude = step["end_location"]["lng"].double else {
                    print("steps[\(index): destination latitude is unavailable")
                    callback(nil)
                    return
                }
                // get the duration for this step
                guard let stepDuration = step["duration"]["value"].double else {
                    print("steps[\(index)]: duration is unavailable")
                    callback(nil)
                    return
                }
                // get the distance for this step
                guard let stepDistance = step["distance"]["value"].double else {
                    print("steps[\(index)]: distance is unavailable")
                    callback(nil)
                    return
                }
                // get the description of this step
                guard let stepDescription = step["html_instructions"].string else {
                    print("steps[\(index)]: html_instructions are unavailable")
                    callback(nil)
                    return
                }
                // create and append a navigation step
                let navStep = NavigationStep(goal_lat: stepGoalLatitude, goal_lng: stepGoalLongitude, dist: stepDistance, dur: stepDuration, desc: stepDescription)
                navigationSteps.append(navStep)
            }
            // create a navigation path
            let path = NavigationPath(startAt: originGeocodingResponse, endAt: destinationGeocodingResponse, dist: pathDistance, dur: pathDuration, steps: navigationSteps)
            // call the callback with a fully processed, correct path object
            print("finished parsing API response")
            callback(path)
        }
        task.resume()
    }
    
    /*
     *  Takes an input location and converts it to a formatted address via API call
     */
    func addressFromKeywords(from: CLLocation, to: String, callback: @escaping (NavigationPath?) -> Void) {
        let API_KEY = "AIzaSyBLbvnLoXYu1ypBpqrdp0lLu9K_t1R0mZQ"
        let address = to.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let url = "\(placesEndpoint)key=\(API_KEY)&query=\(address!)&location=\(from.coordinate.latitude),\(from.coordinate.longitude)"
        let requestURL = URL(string: url)
        var request = URLRequest(url: requestURL!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) -> Void in
            if error != nil {
                print("ERROR: \(error)")
                return
            }
            
            let json = JSON(data: data!)
            let place = json["results"][0]["place_id"].string!
            let result = json["results"][0]["formatted_address"].string!
            print("RESULT: \(result)")
            
            let fromStr = "\(from.coordinate.latitude),\(from.coordinate.longitude)"
            self.directionsFromAddress(from: fromStr, place_id: place, address: result, callback: callback)
        }
        task.resume()
    }

    // Singleton pattern for private constructor
    private override init() {}
}








