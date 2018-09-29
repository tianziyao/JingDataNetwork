//
//  Api.swift
//  JingDataNetwork_Example
//
//  Created by Tian on 2018/8/29.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

//struct UserInfo: Mappable {
//    
//    var age: Int?
//    var name: String?
//    
//    init?(map: Map) {}
//    
//    mutating func mapping(map: Map) {
//        age <- map["age"]
//        name <- map["name"]
//    }
//}


enum Test2Api: TargetType {
    
    case n
    
    var baseURL: URL {
        return URL.init(string: "https://segmentfault.com/a/1190000003822838")!
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        let dict: [String : Any] = [
            "code": 0,
            "data": ["age": 19, "name": "tian"]
        ]
        let json = JSON.init(dict).description
        return json.data(using: .utf8)!
    }
    
    var task: Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return nil
    }
    
}

enum TestApi: TargetType {
    
    case m
    case n
    
    var baseURL: URL {
        return URL.init(string: "https://segmentfault.com/a/1190000003822838")!
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        var dict: [String : Any] = [:]
        switch self {
        case .m:
            dict = [
                "code": 0,
                "data": ["age": 19, "name": "tian"]
            ]
        default:
            dict = [
                "code": 30,
                "data": ["age": 88, "name": "li"]
            ]
        }
        let json = JSON.init(dict).description
        return json.data(using: .utf8)!
    }
    
    var task: Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return nil
    }
    
}
