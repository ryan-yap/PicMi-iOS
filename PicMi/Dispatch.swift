//
//  dispatch.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-07.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

class Dispatch{
    var message : String! = ""
    var location_name : String! = ""
    var objecttype : String = ""
    var image_urls : NSMutableArray! = NSMutableArray() //image url on S3 to be sent out as a Push Notification
    var video_urls : NSMutableArray! = NSMutableArray() // video url on S3 to be sent out as a Push Notification
    
    
    var jobs_buff : NSMutableArray! = NSMutableArray()
    var request = Dictionary<String, String>() //information about a request
    var requests_pics_urls : NSMutableArray! = NSMutableArray() //image url received from a request
    
    var requests_media_list : NSMutableArray! = NSMutableArray() //List of UIImage to be displayed in Summary
    
    
    var response_buff : NSMutableArray = NSMutableArray()
    
    var response = Dictionary<String, String>()
    var responses_pics_urls : NSMutableArray = NSMutableArray()//image url submitted by a driver
    var responses_media_list : NSMutableArray! = NSMutableArray() //List of UIImage to be displayed in Review
    
    func reset(){
        self.image_urls.removeAllObjects()
        self.requests_media_list.removeAllObjects()
        self.request.removeAll(keepCapacity: false)
        self.requests_pics_urls.removeAllObjects()
    }
    
    func done_submitting_media(){
        self.responses_media_list.removeAllObjects()
    }
    
    func done_reviewing_media(){
        self.response.removeAll(keepCapacity: false)
        self.responses_pics_urls.removeAllObjects()
    }
    
    func request_picmi(#pin_longitude: Double, pin_latitude : Double, range : Double, filter : String){
        Alamofire.request(.GET, server_cfg.server_url+"/locations/neighbor", parameters: ["longitude":pin_longitude , "latitude": pin_latitude, "range": range, "exception" : filter])
            .responseJSON { (request, response, data, error) in
                if (data == nil){
                    println("failed 1")
                    NSNotificationCenter.defaultCenter().postNotificationName("RequestPicMiDriverFailure", object: nil)
                }else{
                    let json = JSON(data!)
                    let data = json["data"]
                    if (data == nil){
                        println("failed 2")
                        NSNotificationCenter.defaultCenter().postNotificationName("RequestPicMiDriverFailure", object: nil)
                    }else{
                        println(data)
                        var dict = Dictionary<String, String>()
                        for (key, subJson) in data {
                            let key_attr : String! = "\(key)"
                            let val_attr : String! = "\(subJson)"
                            dict[key_attr]=val_attr
                        }
                        dict["requester_id"] = app_user.ID
                        NSNotificationCenter.defaultCenter().postNotificationName("RequestPicDriverMiSuccess", object: self, userInfo: dict)
                    }
                }
        }
    }
    
    func request_picmi_with_exception(#index : Int){
        var temp_request = (requests_list[index] as! Requests)
        println(temp_request.request_dict)
        println(temp_request.requests_pics_urls)
        var pin_longitude = ((temp_request.request_dict["longitude"]!) as NSString).doubleValue
        var pin_latitude = ((temp_request.request_dict["latitude"]!) as NSString).doubleValue
        var range = 2000
        var filter = temp_request.request_dict["filter"]!
        
        Alamofire.request(.GET, server_cfg.server_url+"/locations/neighbor", parameters: ["longitude":pin_longitude , "latitude": pin_latitude, "range": range, "exception" : filter])
            .responseJSON { (request, response, data, error) in
                if (data == nil){
                    println("failed 1")
                     NSNotificationCenter.defaultCenter().postNotificationName("NewRequest", object: nil)
                    NSNotificationCenter.defaultCenter().postNotificationName("RequestPicMiDriverFailure", object: self, userInfo: (requests_list[index] as! Requests).request_dict)
                    requests_list.removeObjectAtIndex(index)
                }else{
                    let json = JSON(data!)
                    let data = json["data"]
                    if (data == nil){
                        println("failed 2")
                         NSNotificationCenter.defaultCenter().postNotificationName("NewRequest", object: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName("RequestPicMiDriverFailure", object: self, userInfo: (requests_list[index] as! Requests).request_dict)
                        requests_list.removeObjectAtIndex(index)
                    }else{
                        println(data)
                        var dict = Dictionary<String, String>()
                        for (key, subJson) in data {
                            let key_attr : String! = "\(key)"
                            let val_attr : String! = "\(subJson)"
                            dict[key_attr]=val_attr
                        }
                        println(dict)
                        (requests_list[index] as! Requests).request_dict["key"] = dict["key"]!
                        NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationToDriver", object: self, userInfo: (requests_list[index] as! Requests).request_dict)
                    }
                }
        }
    }
}