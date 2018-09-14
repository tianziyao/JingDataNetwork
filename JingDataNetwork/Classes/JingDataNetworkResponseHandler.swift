//
//  JingDataNetworkResponseHandler.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import ObjectMapper
import Moya

public protocol JingDataNetworkResponseHandler {
    associatedtype Response
    static var response: Response { get }
    static var networkManager: Manager { get }
    static var plugins: [PluginType] { get }
    static func makeCustomJingDataNetworkError(_ respose: Response) -> JingDataNetworkError?
    static func makeInstance(_ data: Data) throws -> Response
    static func handleJingDataNetworkError(_ error: JingDataNetworkError)
}


