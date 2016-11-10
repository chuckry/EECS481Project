//
//  PromptViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import AVFoundation

class PromptViewController: UIViewController {

	public var message: String!
    let locationManager = LocationService.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
		//if message != nil{
		print(Stuff.things.message);
		//}
		//message = "I was here";
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Speech.shared.immediatelySay(utterance: "Commands")
    }

    /*
     *  Upon entering a location, we tell the user what the nearest location is
     */
    func whereAmI() {
        if Stuff.things.routeManager.route != nil {
            if let currentLocation = locationManager.lastLocation {
                let intersection = Stuff.things.routeManager.getNearestIntersection(loc: currentLocation)
                Speech.shared.immediatelySay(utterance: intersection!)
            } else {
                print("Couldn't get current location!")
            }
        } else {
            print("Route not initialized!")
        }
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
