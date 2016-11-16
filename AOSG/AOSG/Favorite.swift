//
//  Favorite.swift
//  AOSG
//
//  Created by Apoorva Gupta on 11/6/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import Foundation

class Favorite: NSObject, NSCoding {
    // MARK: Properties
    var name: String
    var address: String
    
    // MARK: Types
    struct PropertyKey {
        static let nameKey = "name"
        static let addressKey = "address"
    }
    
    // Mark: Archiving Paths
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let archiveURL = documentDirectory.appendingPathComponent("favorites")
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(address, forKey: PropertyKey.addressKey)
    }
    
    init(withName: String, withAddress: String) {
        self.name = withName
        self.address = withAddress
        super.init()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        let address = aDecoder.decodeObject(forKey: PropertyKey.addressKey) as! String
        self.init(withName: name, withAddress: address)
    }
}
