//
//  Requests.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-15.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation
class Requests{
    var request_dict = Dictionary<String, String>()
    var requests_pics_urls : NSMutableArray! = NSMutableArray()
    var message : NSMutableArray! = NSMutableArray()
    var unread : Bool = false
    var isNotified : Bool = false
    var isCompleted : Bool = false
    
    init(request : Dictionary<String,String>, imageArray: NSMutableArray){
        self.request_dict = request;
        for x in imageArray{
            if let imagedata = x as? Media {
                var data : Media = imagedata
                self.requests_pics_urls.addObject(data)
            }
        }
    }
}
