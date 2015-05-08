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


class Video{
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
    
    func upload_video(recipient_id : String, imagedata : NSData, count : Int, dictionary : Dictionary<String, String>, notification : String){
        var upload_url : String = ""
        Alamofire.request(.GET, server_cfg.server_url+"/videos/upload", parameters: ["RID": recipient_id])
            .responseJSON { (request, response, data, error) in
                if (error != nil){
                    println(error)
                    //NSNotificationCenter.defaultCenter().postNotificationName("LoginFailure", object: nil)
                    return
                }
                if (data == nil){
                    //NSNotificationCenter.defaultCenter().postNotificationName("LoginFailure", object: nil)
                }else{
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
        
        let contentType = "video/quicktime"
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
        var task = session.dataTaskWithRequest(request, completionHandler: {responsedata, response, error -> Void in
            var strData = NSString(data: responsedata, encoding: NSUTF8StringEncoding)! as String
            var parseError : NSError?
            let parsedObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(responsedata,
                options: NSJSONReadingOptions.AllowFragments,
                error:&parseError)
            dispatch_async(dispatch_get_main_queue(), {
                dispatch.image_urls.addObject("/video/\(recipient_id)/\(uploader_id)/\(timestamp)")
                
                if (dispatch.image_urls.count == count){
                    println("Video")
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
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(notification, object: self, userInfo: dict)
                }
            })
        })
        task.resume()
    }
}