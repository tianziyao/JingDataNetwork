//
//  JingDataNetworkBaseResponse.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import ObjectMapper
import Moya

public protocol JingDataNetworkBaseResponseProtocol: Mappable {
    associatedtype DataSource
    func makeCustomJingDataError() -> JingDataNetworkError?
}

public protocol JingDataConfigProtocol {
    static var networkManager: Manager { set get }
    static var plugins: [PluginType] { set get }
    static func handleJingDataNetworkError(_ error: JingDataNetworkError)
}
