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
    static var networkManager: Manager { set get }
    static var plugins: [PluginType] { set get }
    static func handleJingDataNetworkError(_ error: JingDataNetworkError)
}

