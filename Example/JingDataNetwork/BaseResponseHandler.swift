//
//  BaseResponse.swift
//  JingDataNetwork_Example
//
//  Created by Tian on 2018/8/29.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import JingDataNetwork
import Moya

struct BaseResponseHandler: JingDataNetworkResponseHandler {
    
    var response: String?
    
    func makeResponse(_ data: Data) throws -> String {
         return String.init(data: data, encoding: .utf8) ?? "unknow"
    }
    
    func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        return nil
    }
    
    func handleJingDataNetworkError(_ error: JingDataNetworkError) {

    }
}

struct BaseTypeResponseHandler<R>: JingDataNetworkResponseHandler {
    
    var response: R?
    
    func makeResponse(_ data: Data) throws -> R {
        if R.Type.self == String.Type.self {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
        else if R.Type.self == Data.Type.self {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
        else if R.Type.self == UIImage.Type.self {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
        else {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
    }
    
    func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        return nil
    }
    
    func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        
    }
}
