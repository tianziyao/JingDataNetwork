//
//  BaseDataResponseHandler.swift
//  JingDataNetwork_Example
//
//  Created by Tian on 2018/9/29.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import JingDataNetwork
import Moya

struct BaseDataResponse: JingDataNetworkDataResponse {

    var data: String = ""
    var code: Int = 0
    
    init?(_ data: Data) {
        self.data = "str"
        self.code = 0
    }
    
    func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        switch code {
        case 0:
            return nil
        default:
            return JingDataNetworkError.custom(code: code)
        }
    }
}

struct BaseDataResponseHandler<R: JingDataNetworkDataResponse>: JingDataNetworkDataResponseHandler {
    var response: R?
}











