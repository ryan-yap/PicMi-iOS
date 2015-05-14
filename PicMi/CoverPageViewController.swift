//
//  ViewController.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-03-18.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import Socket_IO_Client_Swift
import AudioToolbox

class CoverPageViewController: UIViewController{

    //===========================IBOUTLETs===========================
    
    @IBOutlet var applogoimageview: UIImageView!
    @IBOutlet var quoteimageview: UIImageView!
    @IBOutlet var apptitleimageview : UIImageView!
    @IBOutlet var flashview : UIView!
    @IBOutlet var loginview : UIView!
    @IBOutlet var presentationview : UIView!
    @IBOutlet var password: UITextField!
    @IBOutlet var username: UITextField!
    
    //===========================Constant variables===========================
    
    var isLoggedin : Bool! = false
    var capturesound = AVAudioPlayer()
    
    func addHandlers(){
        ping_socket.on("connect") {[weak self] data, ack in
            println(data)
            println(ack)
            return
        }
        
        ping_socket.on("ackEvent") {data, ack in
            if let str = data?[0] as? String {
                println("Got ackEvent")
            }
            
            // data is an array
            if let int = data?[1] as? Int {
                println("Got int")
            }
            
            // You can specify a custom timeout interval. 0 means no timeout.
            
            ack?("Got your event", "dude")
        }
        
        ping_socket.on("error"){[weak self] data, ack in
            println("Socket IO Error")
        }
        
        dispatch_socket.on("connect") {[weak self] data, ack in
            NSNotificationCenter.defaultCenter().postNotificationName("SetDispatchID", object: data)
            return
        }
        
        dispatch_socket.on("ackEvent") {data, ack in
            if let str = data?[0] as? String {
                println("Got ackEvent")
            }
            
            // data is an array
            if let int = data?[1] as? Int {
                println("Got int")
            }
            
            ack?("Got your event", "dude")
        }
        
        dispatch_socket.on("photorequest") {data, ack in
            if let message = data?[0] as! NSString!{
                self.driver_notification(message)
            }
            return
        }
        
        dispatch_socket.on("requestconfirmation") {data, ack in
            if let message = data?[0] as! NSString!{
                self.requestconfirmation(message)
            }
            return
        }
        
        dispatch_socket.on("transactionended") {data, ack in
            if let message = data?[0] as! NSString!{
                self.transactionended(message)
            }
            return
        }
        
        dispatch_socket.on("jobcancelled") {data, ack in
            if let message = data?[0] as! NSString!{
                self.jobcancelled(message)
            }
            return
        }
        
        dispatch_socket.on("requestdeclined") {data, ack in
            if let message = data?[0] as! NSString!{
                self.requestdeclined(message)
            }
            return
        }
        
        dispatch_socket.on("photoready") {data, ack in
            if let message = data?[0] as! NSString!{
                self.user_notification(message)
                println("you photo is ready!")
            }
            return
        }
        
        dispatch_socket.on("receive") {data, ack in
            if let message = data?[0] as! NSString!{
                self.messagenotification(message)
            }
            return
        }
        
    }
    
    //=======================Push Notifications==============================================
    
    func driver_notification(message: NSString){
        var obj : Array = message.componentsSeparatedByString(":!$)$@)!$:") as Array!
        var localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertAction = "Accept Request"
        localNotification.alertBody = "\(obj[2])"
        var dict = Dictionary<String, String>()
        dict["driver_id"] = "\(obj[0])"
        dict["requester_id"] = "\(obj[1])"
        dict["message"] = "\(obj[2])"
        dict["objecttype"] = "\(obj[3])"
        dict["jobID"] = "\(obj[4])"
        dict["distance"] = "\(obj[5])"
        dict["longitude"] = "\(obj[6])"
        dict["latitude"] = "\(obj[7])"
        dict["image_urls"] = "\(obj[8])"
        dict["location_name"] = "\(obj[9])"
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        
        var media_obj : Array = dict["image_urls"]!.componentsSeparatedByString(",") as Array!
        if (media_obj[0] != ""){
            for url in media_obj{
                var urlParse : Array = url.componentsSeparatedByString("/") as Array!
                println(url)
                if(urlParse[1] as String == "photo"){
                    var media_url = Url(temptype: "image", tempurl: url as String)
                    dispatch.requests_pics_urls.addObject(media_url)
                }else if(urlParse[1] as String == "video"){
                    var media_url = Url(temptype: "video", tempurl: url as String)
                    dispatch.requests_pics_urls.addObject(media_url)
                }
            }
        }
        
        var new_request = Jobs(request: dict, urlsArray: dispatch.requests_pics_urls)
        dispatch.jobs_buff.addObject(new_request);
        dispatch.requests_pics_urls.removeAllObjects()
        var data = Dictionary<String, Int>()
        data["index"] = dispatch.jobs_buff.count - 1
        NSNotificationCenter.defaultCenter().postNotificationName("PhotoRequest", object: self, userInfo: data)
    }
    
    func user_notification(message: NSString){
        var obj : Array = message.componentsSeparatedByString(":!$)$@)!$:") as Array!
        var localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertAction = "View Response"
        localNotification.alertBody = "\(obj[2])"
        var dict = Dictionary<String, String>()
        var ifexist : Bool = false
        dict["requester_id"] = "\(obj[0])"
        dict["driver_id"] = "\(obj[1])"
        dict["message"] = "\(obj[2])"
        dict["objecttype"] = "\(obj[3])"
        dict["jobID"] = "\(obj[4])"
        dict["image_urls"] = "\(obj[5])"
        dict["location_name"] = "\(obj[6])"
        
        var i = Int()
        for i = 0; i < requests_list.count; ++i {
            if ((requests_list[i] as! Requests).request_dict["jobID"]! == dict["jobID"]!){
                localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
                UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                
                var image_obj : Array = dict["image_urls"]!.componentsSeparatedByString(",") as Array!
                if (image_obj[0] != ""){
                    for url in image_obj{
                        var urlParse : Array = url.componentsSeparatedByString("/") as Array!
                        
                        if(urlParse[1] == "photo"){
                            var media_url = Url(temptype: "image", tempurl: url)
                            dispatch.responses_pics_urls.addObject(media_url)
                        }else if(urlParse[1] == "video"){
                            var media_url = Url(temptype: "video", tempurl: url)
                            dispatch.responses_pics_urls.addObject(media_url)
                        }
                    }
                }
                
                var new_request = Jobs(request: dict, urlsArray: dispatch.responses_pics_urls)
                dispatch.response_buff.addObject(new_request);
                dispatch.responses_pics_urls.removeAllObjects()
                
                var data = Dictionary<String, Int>()
                data["index"] = dispatch.response_buff.count - 1
                
                NSNotificationCenter.defaultCenter().postNotificationName("PhotoResponse", object: self, userInfo: data)
            }
        }
    }
    
    
    func messagenotification(message : NSString){
        var obj : Array = message.componentsSeparatedByString(":!$)$@)!$:") as Array!
        var localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertAction = "Reply"
        localNotification.alertBody = "\(obj[4])"
        var dict = Dictionary<String, String>()
        var ifexist : Bool = false
        dict["target_id"] = "\(obj[0])"
        dict["jobID"] = "\(obj[1])"
        dict["type"] = "\(obj[2])"
        dict["username"] = "\(obj[3])"
        dict["message"] = "\(obj[4])"
        
        println(dict["target_id"])
        println(dict["jobID"])
        println(dict["type"])
        println(dict["message"])
        
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        var data : Dictionary<String, String> = Dictionary<String, String>()
        if (dict["type"] == "request"){
            var i = Int()
            for i = 0; i < requests_list.count; ++i {
                if ((requests_list[i] as! Requests).request_dict["jobID"]! == dict["jobID"]!){
                    println(dict["jobID"]!)
                    (requests_list[i] as! Requests).message.addObject(dict)
                    (requests_list[i] as! Requests).unread = true
                    data["index"] = "\(i)"
                    data["type"] = dict["type"]
                    data["message"] = dict["message"]
                    data["username"] = dict["username"]
                    ifexist = true
                }
                
            }
        }else if(dict["type"] == "job"){
            var i = Int()
            for i = 0; i < jobs_list.count; ++i {
                if ((jobs_list[i] as! Jobs).request_dict["jobID"]! == dict["jobID"]!){
                    println(dict["jobID"]!)
                    (jobs_list[i] as! Jobs).message.addObject(dict)
                    (jobs_list[i] as! Jobs).unread = true
                    data["index"] = "\(i)"
                    data["type"] = dict["type"]
                    data["message"] = dict["message"]
                    data["username"] = dict["username"]
                    ifexist = true
                }
            }
        }
        
        if (ifexist == true){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            NSNotificationCenter.defaultCenter().postNotificationName("MessageReceiveNotification", object: self, userInfo: data)
        }
    }
    
    func requestconfirmation(message : NSString){
        var obj : Array = message.componentsSeparatedByString(":!$)$@)!$:") as Array!
        var requester_id = "\(obj[0])"
        var driver_id = "\(obj[1])"
        var jobID = "\(obj[2])"
        
        if (requester_id != app_user.ID){
            return
        }else{
            NSNotificationCenter.defaultCenter().postNotificationName("RequestConfirmed", object: nil)
        }
    }
    
    func transactionended(message : NSString){
        var obj : Array = message.componentsSeparatedByString(":!$)$@)!$:") as Array!
        var requester_id = "\(obj[0])"
        var driver_id = "\(obj[1])"
        var jobID = "\(obj[2])"
        
        println("Ending Transaction")
        println(obj)
        
        var data : Dictionary<String, String> = Dictionary<String, String>()
        if (driver_id != app_user.ID){
            return
        }else{
            var i = Int()
            for i = 0; i < jobs_list.count; ++i {
                if ((jobs_list[i] as! Jobs).request_dict["jobID"]! == jobID){
                    NSNotificationCenter.defaultCenter().postNotificationName("transactionended", object: self, userInfo: (jobs_list[i] as! Jobs).request_dict)
                    var dict = Dictionary<String, String>()
                    dict["type"] = "completetransaction"
                    (jobs_list[i] as! Jobs).message.addObject(dict)
                    (jobs_list[i] as! Jobs).isCompleted = true
                }
            }
        }
    }
    
    func requestdeclined(message : NSString){
        var obj : Array = message.componentsSeparatedByString(":!$)$@)!$:") as Array!
        var requester_id = "\(obj[0])"
        var driver_id = "\(obj[1])"
        var jobID = "\(obj[2])"
        
        var data : Dictionary<String, String> = Dictionary<String, String>()
        if (requester_id != app_user.ID){
            return
        }else{
            var i = Int()
            for i = 0; i < requests_list.count; ++i {
                if ((requests_list[i] as! Requests).request_dict["jobID"]! == jobID){
                    if ((requests_list[i] as! Requests).request_dict["filter"] != nil){
                        var filters : Array = (requests_list[i] as! Requests).request_dict["filter"]?.componentsSeparatedByString(",") as Array!
                        filters.append(driver_id)
                        var filterString : String = ",".join(filters)
                        (requests_list[i] as! Requests).request_dict["filter"] = filterString
                    }else{
                        (requests_list[i] as! Requests).request_dict["filter"] = driver_id
                    }
                    dispatch.request_picmi_with_exception(index: i)
                }
            }
        }
    }
    
    func jobcancelled(message : NSString){
        var obj : Array = message.componentsSeparatedByString(":!$)$@)!$:") as Array!
        var driver_id = "\(obj[0])"
        var requester_id = "\(obj[1])"
        var jobID = "\(obj[2])"
        var data : Dictionary<String, String> = Dictionary<String, String>()
        if (driver_id != app_user.ID){
            return
        }else{
            var dictionary : Dictionary = Dictionary<String, String>()
            var i = Int()
            for i = 0; i < jobs_list.count; ++i {
                if ((jobs_list[i] as! Jobs).request_dict["jobID"]! == jobID){
                    dictionary = (jobs_list[i] as! Jobs).request_dict
                    jobs_list.removeObjectAtIndex(i)
                    NSNotificationCenter.defaultCenter().postNotificationName("JobCancelled", object: self, userInfo: dictionary)
                    NSNotificationCenter.defaultCenter().postNotificationName("RemoveLocation", object: self, userInfo: dictionary)
                }
            }
        }
    }
    
    //===========================IBACTIONs===========================
    @IBAction func hide_keyboard(){
        username.resignFirstResponder();
        password.resignFirstResponder();
    }
    
    @IBAction func perform_login(){
        app_user.login(self.username.text, password: self.password.text)
    }
    
    //=======================Notification Handling=============================================
    func OnLoginSuccess(notification: NSNotification){
        self.performSegueWithIdentifier("toLoaderSegue", sender: nil)
    }
    
    func OnLoginFailure(notification: NSNotification){
        println("login failed")
        let alertController = UIAlertController(title: "Invalid Username or Password!" as String!, message: nil,   preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //=======================Audio on Startup==============================================
    
    func setupAudioPlayerWithFile(file:NSString, type:NSString) -> AVAudioPlayer  {
        var path = NSBundle.mainBundle().pathForResource(file as String, ofType:type as String)
        var url = NSURL.fileURLWithPath(path!)

        var error: NSError?
   
        var audioPlayer:AVAudioPlayer?
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)

        return audioPlayer!
    }
    
    
    // ======================= Delegates' Methods ==============================================
    
    override func viewDidLoad(){
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnLoginSuccess:", name: "LoginSuccess", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnLoginFailure:", name: "LoginFailure", object: nil)
        
        self.loginview.hidden = true;
        self.capturesound = self.setupAudioPlayerWithFile("capture", type:"mp3")
        
        NSThread.sleepForTimeInterval(1);
        
        if ((self.isLoggedin) == true){
            UIView.animateWithDuration(0.01, delay: 0.1, options: UIViewAnimationOptions.Autoreverse, animations: {
                self.capturesound.play();
                self.flashview.alpha = 1;
                }, completion: { finished in
                    self.flashview.alpha = 0;
                    self.addHandlers();
                    ping_socket.connect();
                    dispatch_socket.connect();
                    NSNotificationCenter.defaultCenter().postNotificationName("starttimedstask", object: nil)
                    self.performSegueWithIdentifier("toMainSegue", sender: nil)
            })
        }else{
            UIView.animateWithDuration(4, animations: {
                self.applogoimageview.hidden = true
                self.presentationview.hidden = true;
                //self.apptitleimageview.frame = CGRect(x: 125, y: 69, width: 149, height: 34)
                self.loginview.hidden = false;
            })
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

