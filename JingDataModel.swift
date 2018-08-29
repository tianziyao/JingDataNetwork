//
//  JingDataModel.swift
//  JingDataNetwork_Example
//
//  Created by Tian on 2018/8/22.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import ObjectMapper

struct JingDataModel {
    static func objectFromJSONString<T>(jsonString: String) -> T? where T: Mappable {
        let mapperModel = Mapper<T>()
        let object = mapperModel.map(JSONString: jsonString)
        return object
    }
    static func objectFromDic<T>(dic: [String: Any]) -> T? where T: Mappable {
        let mapperModel = Mapper<T>()
        let object = mapperModel.map(JSON: dic)
        return object
    }
}

