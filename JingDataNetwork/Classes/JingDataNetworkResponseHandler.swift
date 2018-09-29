//
//  JingDataNetworkResponseHandler.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import Moya

public protocol JingDataNetworkResponseHandler {
    associatedtype Response
    var response: Response? { set get }
    var networkManager: Manager { get }
    var plugins: [PluginType] { get }
    func makeResponse(_ data: Data) throws -> Response
    func makeCustomJingDataNetworkError() -> JingDataNetworkError?
    func handleJingDataNetworkError(_ error: JingDataNetworkError)
    init()
}

public extension JingDataNetworkResponseHandler {
    var networkManager: Manager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60
        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        return manager
    }
    var plugins: [PluginType] {
        return []
    }
}

public protocol JingDataNetworkDataResponse {
    associatedtype DataSource
    var data: DataSource { set get }
    func makeCustomJingDataNetworkError() -> JingDataNetworkError?
    func handleJingDataNetworkError(_ error: JingDataNetworkError)
    init?(_ data: Data)
}

public extension JingDataNetworkDataResponse {
    public func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        return nil
    }
    public func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        
    }
}

public protocol JingDataNetworkDataResponseHandler: JingDataNetworkResponseHandler where Response: JingDataNetworkDataResponse {}
public extension JingDataNetworkDataResponseHandler {
    public func makeResponse(_ data: Data) throws -> Response {
        guard let response = Response.init(data) else { throw JingDataNetworkError.parser(type: "\(Response.Type.self)") }
        return response
    }
    public func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        guard let response = response else { return JingDataNetworkError.parser(type: "\(Response.Type.self)") }
        return response.makeCustomJingDataNetworkError()
    }
    public func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        debugPrint(error.description)
        response?.handleJingDataNetworkError(error)
    }
}

public protocol JingDataNetworkListDataResponse {
    associatedtype ItemData
    var listData: [ItemData] { set get }
    func makeCustomJingDataNetworkError() -> JingDataNetworkError?
    func handleJingDataNetworkError(_ error: JingDataNetworkError)
    init?(_ data: Data)
}

public extension JingDataNetworkListDataResponse {
    public func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        return nil
    }
    public func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        
    }
}

public protocol JingDataNetworkListDataResponseHandler: JingDataNetworkResponseHandler where Response: JingDataNetworkListDataResponse {}
public extension JingDataNetworkListDataResponseHandler {
    public func makeResponse(_ data: Data) throws -> Response {
        guard let response = Response.init(data) else { throw JingDataNetworkError.parser(type: "\(Response.Type.self)") }
        return response
    }
    public func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        guard let response = response else { return JingDataNetworkError.parser(type: "\(Response.Type.self)") }
        return response.makeCustomJingDataNetworkError()
    }
    public func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        debugPrint(error.description)
        response?.handleJingDataNetworkError(error)
    }
}
