//
//  BaseResponse.swift
//  JingDataNetwork_Example
//
//  Created by Tian on 2018/8/29.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import JingDataNetwork
import ObjectMapper
import Moya

class BaseResp<T: Mappable>: JingDataNetworkBaseResponse {
    
    typealias DataSource = T
    
    var data: T?
    var code: Int?
    
    required init?(map: Map) {}
    
    public func mapping(map: Map) {
        code <- map["code"]
        data <- map["data"]
    }
    
    func makeCustomJingDataError() -> JingDataNetworkError? {
        guard let c = code else { return nil }
        guard c != 0 else { return nil }
        return JingDataNetworkError.custom(code: c)
    }
}


extension BaseResp {
    
    static var plugins: [PluginType] {
        set {
            
        }
        get {
            // let logger = NetworkLoggerPlugin(verbose: true, output: BaseResp.reversedPrint)
            return []
        }
    }
    
    static func reversedPrint(_ separator: String, terminator: String, items: Any...) {
        for item in items {
            print(item, separator: separator, terminator: terminator)
        }
    }
    
    static var networkManager: Manager {
        set {
            
        }
        get {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 60
            let manager = Manager(configuration: configuration)
            manager.startRequestsImmediately = false
            return manager
        }
    }
    
    static func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        //print(error.description)
    }
}

class Empty: Mappable {
    required init?(map: Map) {}
    func mapping(map: Map) {}
}

class EmptyResp: BaseResp<Empty> {}
