//
//  AppDelegate.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-03-18.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import Stripe
import AudioToolbox

let StripePublishableKey : NSString = "pk_test_LkSAoCriBT1JAZRoqu3eQzFa";
var isLocationReady : Bool = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var window: UIWindow?
    var timer : NSTimer = NSTimer()
    
    //=====================Notification Handling=========================================
    
    func SetDispatchID(notification: NSNotification){
        if (dispatch_socket.connected == true){
            println("setting ID")
            dispatch_socket.emit("setID", app_user.ID)
        }else{
            println("connecting")
            dispatch_socket.connect()
        }
    }
    
    func PushNotificationToDriver(notification: NSNotification){
        let data = notification.userInfo as Dictionary!
        assert((data.count > 0), "Data from push should contain some payload")
        var urls : String = ""
        var distance = data["distance"] as! String!
        var driver_id = data["key"] as! String!
        var requester_id = data["requester_id"] as! String!
        var message = data["message"] as! String!
        var longitude = data["longitude"] as! String!
        var latitude = data["latitude"] as! String!
        var objecttype = data["objecttype"] as! String!
        var location_name = data["location_name"] as! String!
        if (data["image_urls"] != nil){
            urls = data["image_urls"] as! String!
        }
        var job_id = data["jobID"] as! String!
        
        var socket_message : String = "\(driver_id):!$)$@)!$:\(requester_id):!$)$@)!$:\(message):!$)$@)!$:\(objecttype):!$)$@)!$:\(job_id):!$)$@)!$:\(distance):!$)$@)!$:\(longitude):!$)$@)!$:\(latitude):!$)$@)!$:\(urls):!$)$@)!$:\(location_name)"
        dispatch_socket.emit("driverrequest", socket_message)
    }
    
    func PushNotificationToUser(notification: NSNotification){
        let data = notification.userInfo as Dictionary!
        var urls : String = ""
        var driver_id = data["driver_id"] as! String!
        var requester_id = data["requester_id"] as! String!
        var objecttype = data["objecttype"] as! String!
        if (data["image_urls"] != nil){
            urls = data["image_urls"] as! String!
        }
        var message = data["message"] as! String!
        var job_id = data["jobID"] as! String!
        var location_name = data["location_name"] as! String!
        var socket_message : String = "\(requester_id):!$)$@)!$:\(driver_id):!$)$@)!$:\(message):!$)$@)!$:\(objecttype):!$)$@)!$:\(job_id):!$)$@)!$:\(urls):!$)$@)!$:\(location_name)"
        println(socket_message)
        dispatch_socket.emit("driverresponse", socket_message)
    }
    
    func OnCompletedTransaction(notification: NSNotification){
        let data = notification.userInfo as Dictionary!
        var jobID = data["jobID"] as! String
        var i : Int = Int()
        for i = 0; i < requests_list.count; ++i {
            if ((requests_list[i] as! Requests).request_dict["jobID"]! == jobID){
                (requests_list[i] as! Requests).isCompleted = true
                var dict = Dictionary<String, String>()
                dict["type"] = "completetransaction"
                (requests_list[i] as! Requests).message.addObject(dict)
            }
        }
    }
    
    func OnLoginSuccess(notification: NSNotification){
        NSNotificationCenter.defaultCenter().postNotificationName("starttimedstask", object: nil)
        self.addHandlers();
        ping_socket.connect();
        dispatch_socket.connect();
    }
    
    func OnLoginFailure(notification: NSNotification){
        println("login failed")
    }
    
    //===========================Sockets Initialization===========================
    
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
    
    //==============================Location Pingin=================================================
    
    func starttimedstask(notification: NSNotification){
        self.timer.invalidate();
        self.timer = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: "ping_location", userInfo: nil, repeats: true)
    }
    
    func ping_location(){
        var message : String = "\(app_user.ID):\(location.latitude):\(location.longitude)"
        if (ping_socket.connected == true){
            ping_socket.emit("ping", message)
        }else{
            ping_socket.connect()
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.stopUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func ping_signification_location_changes(){
        var message : String = "\(app_user.ID):\(location.latitude):\(location.longitude)"
        if (ping_socket.connected == true){
            ping_socket.emit("ping", message)
        }else{
            ping_socket.connect()
        }
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: {(placemarks, error)->Void in
            if (error != nil) {
                println("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0 {
                let pm = placemarks[0] as! CLPlacemark
                self.displayLocationInfo(pm)
            } else {
                println("Problem with the data received from geocoder")
            }
        })
    }
    
    func displayLocationInfo(placemark: CLPlacemark?) {
        if let containsPlacemark = placemark {
            //stop updating location to save battery life
            location.longitude = containsPlacemark.location.coordinate.longitude
            location.latitude = containsPlacemark.location.coordinate.latitude
            location.name = containsPlacemark.name
            if (isLocationReady == false){
                NSNotificationCenter.defaultCenter().postNotificationName("GPSActivated", object: nil)
                isLocationReady = true
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("Error while updating location " + error.localizedDescription)
    }

    //============================App Delegate====================================================
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Stripe.setDefaultPublishableKey(StripePublishableKey as String)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "starttimedstask:", name: "starttimedstask", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SetDispatchID:", name: "SetDispatchID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnCompletedTransaction:", name: "CompletedTransaction", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "PushNotificationToDriver:", name: "PushNotificationToDriver", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "PushNotificationToUser:", name: "PushNotificationToUser", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnLoginSuccess:", name: "LoginSuccess", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "OnLoginFailure:", name: "LoginFailure", object: nil)
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))
        let defaults = NSUserDefaults.standardUserDefaults()
        if let email = defaults.stringForKey("Email"){
            if let password = defaults.stringForKey("Password"){
                if (email != "" && password != ""){
                    app_user.login(email, password: password)
                    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                    var storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    var viewController : UIViewController = storyboard.instantiateViewControllerWithIdentifier("Loader") as! LoadingViewController
                    self.window?.rootViewController = viewController
                    self.window?.makeKeyAndVisible()
                    return true;
                }else{
                    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                    var storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    var viewController : UIViewController = storyboard.instantiateViewControllerWithIdentifier("CoverPage") as! CoverPageViewController
                    self.window?.rootViewController = viewController
                    self.window?.makeKeyAndVisible()
                    return true;
                }
            }
        }
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        println("Resign Active")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))
        ping_socket.connect();
        dispatch_socket.connect();
        self.timer.invalidate();
        self.timer = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: "ping_signification_location_changes", userInfo: nil, repeats: true)
        println("DidEnterbackground")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        println("Will enter foreground")
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if (app_user.status == "loggedin"){
            println("did become active with loggedin")
            self.timer.invalidate();
            self.timer = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: "ping_location", userInfo: nil, repeats: true)
        }
        
        
        println("did become active")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(jobs_list, forKey: "jobs_list")
        defaults.setObject(requests_list, forKey: "requests_list")
        println("will terminate")
    }
    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.PicMi.PicMi" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("PicMi", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PicMi.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}

