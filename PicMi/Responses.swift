//
//  Responses.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-04-23.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation
class Responses{
    var request_dict = Dictionary<String, String>()
    var requests_pics_urls : NSMutableArray! = NSMutableArray() // List of Urls of All the media
    
    init(request : Dictionary<String,String>, urlsArray: NSMutableArray){
        self.request_dict = request;
        for x in urlsArray{
            if let mediaUrl = x as? Url {
                var data : Url = Url(temptype: mediaUrl.type, tempurl: mediaUrl.urlpath)
                self.requests_pics_urls.addObject(data)
            }
        }
    }
}