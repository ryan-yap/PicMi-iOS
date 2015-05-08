//
//  Server.swift
//  PicMi
//
//  Created by Kang Shiang Yap on 2015-03-24.
//  Copyright (c) 2015 PicMi. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation
import Socket_IO_Client_Swift

class Server {
    var server_url : String = ""
    var socket_server_url : String = ""
    var messaging_server_url : String = ""
    init()
    {
        self.server_url = "http://picmi-dev.elasticbeanstalk.com"
        self.socket_server_url = "http://54.67.18.228:8080"
        self.messaging_server_url = "http://54.153.17.93:8080"
    }
}
let jobs_list : NSMutableArray = NSMutableArray()
let requests_list : NSMutableArray = NSMutableArray()
let submissions_list : NSMutableArray = NSMutableArray()
let responses_list : NSMutableArray = NSMutableArray()

//let storyboard = UIStoryboard(name: "MainStoryboard", bundle: nil)
let server_cfg : Server = Server()
let app_user : User = User()
let location : Location = Location()
var dispatch : Dispatch = Dispatch()
var picture : Picture = Picture()
var video : Video = Video()

var did_submit_photo : String = ""

let ping_socket = SocketIOClient(socketURL: server_cfg.socket_server_url, options: [
    "reconnects": true,
    "reconnectAttempts": -1,
    "reconnectWait": 1,
    //"nsp": "swift",
    ])

let dispatch_socket = SocketIOClient(socketURL: server_cfg.messaging_server_url, options: [
    "reconnects": true,
    "reconnectAttempts": -1,
    "reconnectWait": 1,
    //"nsp": "swift",
    ])

var session = NSURLSession.sharedSession()

let doc_dir = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
    .UserDomainMask, true))[0] as! String

