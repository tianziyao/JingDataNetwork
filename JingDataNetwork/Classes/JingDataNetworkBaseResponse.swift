//
//  JingDataNetworkBaseResponse.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import ObjectMapper
import Moya

public protocol JingDataNetworkBaseResponse: Mappable {
    associatedtype DataSource
    func makeCustomJingDataNetworkError() -> JingDataNetworkError?
}

public protocol JingDataNetworkConfig {
    static var networkManager: Manager { get }
    static var plugins: [PluginType] { get }
    static func handleJingDataNetworkError(_ error: JingDataNetworkError)
}

