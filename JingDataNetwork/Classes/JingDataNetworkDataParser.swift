//
//  JingDataNetworkDataParser.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import ObjectMapper
import SwiftyJSON
import Moya

public struct JingDataNetworkDataParser {
    
    public static func handle<R: JingDataNetworkBaseResponse>(data: Data) throws -> R {
        guard let JSONString = String.init(data: data, encoding: .utf8) else {
            throw JingDataNetworkError.parser(.string)
        }
        guard let response: R = JingDataNetworkResponseBuilder.create(by: JSONString) else {
            throw JingDataNetworkError.parser(.model)
        }
        if let customError = response.makeCustomJingDataError() {
            throw customError
        }
        return response
    }
    
    public static func handle<R: JingDataNetworkBaseResponse>(JSONString: String) throws -> R {
        guard let response: R = JingDataNetworkResponseBuilder.create(by: JSONString) else {
            throw JingDataNetworkError.parser(.model)
        }
        if let customError = response.makeCustomJingDataError() {
            throw customError
        }
        return response
    }
    
    public static func handle<R: JingDataNetworkBaseResponse>(dic: [String: Any]) throws -> R {
        guard let response: R = JingDataNetworkResponseBuilder.create(by: dic) else {
            throw JingDataNetworkError.parser(.model)
        }
        if let customError = response.makeCustomJingDataError() {
            throw customError
        }
        return response
    }
    
    public static func handle(data: Data) throws -> JSON {
        guard let response = try? JSON(data: data) else { throw JingDataNetworkError.parser(.json)}
        return response
    }
    
    public static func handle(resp: Response) throws -> String {
        guard let response = try? resp.mapString() else { throw JingDataNetworkError.parser(.json)}
        return response
    }
    
    public static func handle(resp: Response) throws -> UIImage {
        guard let response = try? resp.mapImage() else { throw JingDataNetworkError.parser(.image)}
        return response
    }
}
