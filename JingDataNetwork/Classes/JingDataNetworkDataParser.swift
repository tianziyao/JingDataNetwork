//
//  JingDataNetWorkDataParser.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import ObjectMapper

public struct JingDataNetWorkDataParser {
    
    public static func handle<R: JingDataNetworkBaseResponseProtocol>(data: Data) throws -> R {
        guard let JSONString = String.init(data: data, encoding: .utf8) else { throw JingDataNetworkError.data(.decodeJSONFail)}
        guard let response: R = JingDataNetworkResponseBuilder.objectFrom(JSONString: JSONString) else { throw JingDataNetworkError.data(.toModelFail) }
        if let customError = response.throwCustomJingDataNetworkError() { throw customError }
        return response
    }
    
    public static func handle<R: JingDataNetworkBaseResponseProtocol>(JSONString: String) throws -> R {
        guard let response: R = JingDataNetworkResponseBuilder.objectFrom(JSONString: JSONString) else { throw JingDataNetworkError.data(.toModelFail) }
        if let customError = response.throwCustomJingDataNetworkError() { throw customError }
        return response
    }
    
    public static func handle<R: JingDataNetworkBaseResponseProtocol>(dic: [String: Any]) throws -> R {
        guard let response: R = JingDataNetworkResponseBuilder.objectFromDic(dic: dic) else { throw JingDataNetworkError.data(.toModelFail) }
        if let customError = response.throwCustomJingDataNetworkError() { throw customError }
        return response
    }
}
