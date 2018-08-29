//
//  JingDataNetworkResponseBuilder.swift
//  JingDataNetwork_Example
//
//  Created by Tian on 2018/8/22.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import ObjectMapper

public struct JingDataNetworkResponseBuilder {
    
    public static func create<R: Mappable>(by JSONString: String) -> R? {
        let mapperModel = Mapper<R>()
        let object = mapperModel.map(JSONString: JSONString)
        return object
    }
    
    public static func create<R: Mappable>(by dic: [String: Any]) -> R? {
        let mapperModel = Mapper<R>()
        let object = mapperModel.map(JSON: dic)
        return object
    }
}

