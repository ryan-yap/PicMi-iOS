//
//  Picture.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-10.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// :param: string       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}

class Picture{
    var key_url : String = ""
    var uploader : String = ""
    var recipient : String = ""
    var data : NSData = NSData()
    
    func reset(){
        self.key_url = ""
        self.uploader = ""
        self.recipient = ""
        self.data = NSData()
    }
    
    func upload_picture(recipient_id : String, imagedata : NSData, count : Int, dictionary : Dictionary<String, String>, notification : String){
        println("Getting image upload url")
        var upload_url : String = ""
        Alamofire.request(.GET, server_cfg.server_url+"/photos/upload", parameters: ["RID": recipient_id])
            .responseJSON { (request, response, data, error) in
                if (error != nil){
                    println(error)
                    //NSNotificationCenter.defaultCenter().postNotificationName("LoginFailure", object: nil)
                    return
                }
                if (data == nil){
                    //NSNotificationCenter.defaultCenter().postNotificationName("LoginFailure", object: nil)
                }else{
                    println(response)
                    let json = JSON(data!)
                    let data = json["data"]
                    upload_url = data["upload_url"].string!
                    var timestamp = data["timestamp"].string!
                    self.upload_to_s3(UploadURL: upload_url, Imagedata: imagedata, recipient_id : recipient_id, uploader_id : app_user.ID, timestamp : timestamp, count : count, dictionary : dictionary, notification : notification)
                    //NSNotificationCenter.defaultCenter().postNotificationName("LoginSuccess", object: nil)
                }
        }
    }
    
    func upload_to_s3(#UploadURL: String, Imagedata: NSData, recipient_id : String, uploader_id : String, timestamp : String, count :Int, dictionary : Dictionary<String, String>, notification: String){
        var request = NSMutableURLRequest(URL: NSURL(string: UploadURL)!)
        request.HTTPMethod = "PUT"

        let contentType = "image/jpeg"
        //NSURLProtocol.setProperty(contentType, forKey: "Content-Type", inRequest: request)
        
        request.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
        request.addValue("\(Imagedata.length)", forHTTPHeaderField: "Content-Length")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue("public-read", forHTTPHeaderField: "x-amz-acl")
        request.HTTPShouldHandleCookies = true
        
        var param = [
            "file" : "profilepic.jpg"
        ]
        
        request.HTTPBody = Imagedata
        println(request)
        var task = session.dataTaskWithRequest(request, completionHandler: {responsedata, response, error -> Void in
            var strData = NSString(data: responsedata, encoding: NSUTF8StringEncoding)! as String
            var parseError : NSError?
            let parsedObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(responsedata,
                options: NSJSONReadingOptions.AllowFragments,
                error:&parseError)
            dispatch_async(dispatch_get_main_queue(), {
                dispatch.image_urls.addObject("/photo/\(recipient_id)/\(uploader_id)/\(timestamp)")
                if (dispatch.image_urls.count == count){
                    println("Image")
                    println(count)
                    println(dispatch.image_urls.count)
                    var imagesurls : String = dispatch.image_urls.componentsJoinedByString(",")
                    var dict = Dictionary<String, String>()
                    dict["image_urls"] = imagesurls
                    for (key, value) in dictionary {
                        let key_attr : String! = key
                        let val_attr : String! = value
                        dict[key_attr]=val_attr
                    }
                    dispatch.image_urls.removeAllObjects()
                    NSNotificationCenter.defaultCenter().postNotificationName(notification, object: self, userInfo: dict)
                }
            })
        })
        task.resume()
    }
}