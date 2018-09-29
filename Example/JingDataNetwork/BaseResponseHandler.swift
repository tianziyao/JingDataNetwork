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
        // return String.init(data: data, encoding: .utf8) ?? "unknow"
        return "data"
    }
    
    func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        return nil
    }
    
    func handleJingDataNetworkError(_ error: JingDataNetworkError) {

    }
}

