//
//  session.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-03-24.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class User{
    var username : String = ""
    var ID : String = ""
    var device_token : String = ""
    var status : String = "loggedout"
    
    func login(username : String, password : String){
        Alamofire.request(.POST, server_cfg.server_url+"/sessions", parameters: ["email": username, "passwd": password, "device_token": self.device_token])
            .responseJSON { (request, response, data, error) in
                if (error != nil){
                    println(error)
                    NSNotificationCenter.defaultCenter().postNotificationName("LoginFailure", object: nil)
                    return
                }
                if (data == nil){
                    NSNotificationCenter.defaultCenter().postNotificationName("LoginFailure", object: nil)
                }else{
                    let json = JSON(data!)
                    let data = json["data"]
                    let account = data["account"]
                    self.username = account["username"].string!
                    self.ID = data["_id"].string!
                    println("Username: \(self.username) ID: \(self.ID)")
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setObject(username, forKey: "Email")
                    defaults.setObject(password, forKey: "Password")
                    NSNotificationCenter.defaultCenter().postNotificationName("LoginSuccess", object: nil)
                    self.status = "loggedin"
                }
        }
    }
    
    
    
    func signup(username : String, password : String, firstname : String, lastname :String, mobile_number : String, card_number : String, cvv : String, exp_date : String, postal_code : String, isUser : Bool, isDriver : Bool){
        Alamofire.request(.POST, server_cfg.server_url+"/users", parameters: ["email": username, "passwd": password, "firstname": firstname, "lastname": lastname, "mobile_number": mobile_number, "card_number": card_number, "cvv": cvv, "exp_date": exp_date, "postal_code": postal_code, "isUser" : isUser, "isDriver": isDriver])
            .responseJSON { (request, response, data, error) in
                if (error != nil){
                    println(error)
                    NSNotificationCenter.defaultCenter().postNotificationName("SignupFailure", object: nil)
                    return
                }
                if (data == nil){
                    NSNotificationCenter.defaultCenter().postNotificationName("SignupFailure", object: nil)
                }else{
                    let json = JSON(data!)
                    let data = json["data"]
                    let account = data["account"]
                    self.username = account["username"].string!
                    self.ID = data["_id"].string!
                    println("Username: \(self.username) ID: \(self.ID)")
                    self.status = "loggedin"
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setObject(username, forKey: "Email")
                    defaults.setObject(password, forKey: "Password")
                    NSNotificationCenter.defaultCenter().postNotificationName("SignupSuccess", object: nil)
                }
        }
    }
    
    func get_user(uid: String){
        Alamofire.request(.GET, server_cfg.server_url+"/users", parameters: ["uid": uid])
            .responseJSON { (request, response, data, error) in
                if (data == nil){
                    NSNotificationCenter.defaultCenter().postNotificationName("GetUserFailure", object: nil)
                }else{
                    let json = JSON(data!)
                    let data = json["data"]
                    if (data == nil){
                        NSNotificationCenter.defaultCenter().postNotificationName("GetUserFailure", object: nil)
                    }else{
                        var dict = Dictionary<String, String>()
                        for (key, subJson) in data {
                            let key_attr : String! = "\(key)"
                            let val_attr : String! = "\(subJson)"
                            dict[key_attr]=val_attr
                        }
                        NSNotificationCenter.defaultCenter().postNotificationName("GetUserSuccess", object: self, userInfo: dict)
                        //NSNotificationCenter.defaultCenter().postNotificationName("RequestPicMiSuccess", object: nil)
                    }
                }
        }
    }
    
    func get_profile(uid: String){
        Alamofire.request(.GET, server_cfg.server_url+"/users/profile", parameters: ["uid": uid])
            .responseJSON { (request, response, data, error) in
                if (data == nil){
                    NSNotificationCenter.defaultCenter().postNotificationName("GetProfileFailure", object: nil)
                }else{
                    let json = JSON(data!)
                    let data = json["data"]
                    if (data == nil){
                        NSNotificationCenter.defaultCenter().postNotificationName("GetProfileFailure", object: nil)
                    }else{
                        var dict = Dictionary<String, String>()
                        for (key, subJson) in data {
                            let key_attr : String! = "\(key)"
                            let val_attr : String! = "\(subJson)"
                            dict[key_attr]=val_attr
                        }
                        NSNotificationCenter.defaultCenter().postNotificationName("GetProfileSuccess", object: self, userInfo: dict)
                        //NSNotificationCenter.defaultCenter().postNotificationName("RequestPicMiSuccess", object: nil)
                    }
                }
        }
    }
}