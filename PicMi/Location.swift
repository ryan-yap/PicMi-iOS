//
//  Location.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-03-24.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

class Location{
    var longitude : Double = 0
    var latitude : Double = 0
    var name : String = ""
    var ID : String = ""
    var pin_latitude : Double = 0
    var pin_longitude : Double = 0
    var pin_name : String = ""
    func update_location(){
        println("Updating Locations")
    }
}