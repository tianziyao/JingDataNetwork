//
//  JingDataNetworkManager.swift
//  JingDataNetwork
//
//  Created by Tian on 2018/8/23.
//

import Foundation
import Moya
import RxSwift
import RxCocoa
import Alamofire
import SwiftyJSON

public typealias JingDataNetworkErrorCallback = (JingDataNetworkError) -> Void

class NetworkCancelWraper {
    var cancellable: Cancellable?
    init(_ cancellable: Cancellable) { self.cancellable = cancellable }
    func cancel() { cancellable?.cancel() }
}

public enum JingDataNetworkManager {
    
    case base(api: TargetType)
    
    public func bind<Handler: JingDataNetworkResponseHandler>(_ type: Handler.Type) -> JingDataNetworkResponseObserver<Handler> {
        switch self {
        case .base(let api):
            return JingDataNetworkResponseObserver<Handler>(api: api)
        }
    }
    
    public func bind<Handler: JingDataNetworkDataResponseHandler>(_ type: Handler.Type) -> JingDataNetworkDataObserver<Handler> {
        switch self {
        case .base(let api):
            return JingDataNetworkDataObserver<Handler>(api: api)
        }
    }

    public func bind<Handler: JingDataNetworkListDataResponseHandler>(_ type: Handler.Type) -> JingDataNetworkListDataObserver<Handler> {
        switch self {
        case .base(let api):
            return JingDataNetworkListDataObserver<Handler>(api: api)
        }
    }
}

public struct JingDataNetworkListDataObserver<Handler: JingDataNetworkListDataResponseHandler> {
    
    var api: TargetType
    
    public func single(progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, [Handler.Response.ItemData]> {
        return createSingle(api: api, progress: progress, test: test)
    }
    
    func createSingle(api: TargetType, progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, [Handler.Response.ItemData]> {
        let single = Single<[Handler.Response.ItemData]>.create { (single) -> Disposable in
            var responseHandle = Handler.init()
            let cancellableToken: NetworkCancelWraper = api.createRequest(networkManager: responseHandle.networkManager, plugins: responseHandle.plugins, progress: progress, success: { (resp) in
                do {
                    let response = try responseHandle.makeResponse(resp.data)
                    responseHandle.response = response
                    if let error = responseHandle.makeCustomJingDataNetworkError() {
                        single(.error(error))
                    }
                    else {
                        single(.success(response.listData))
                    }
                }
                catch let error as JingDataNetworkError {
                    single(.error(error))
                    responseHandle.handleJingDataNetworkError(error)
                }
                catch {}
            }, error: { (error) in
                responseHandle.handleJingDataNetworkError(error)
            }, test: test)
            return Disposables.create {
                cancellableToken.cancel()
            }
        }
        return single
    }
}

public struct JingDataNetworkDataObserver<Handler: JingDataNetworkDataResponseHandler> {

    var api: TargetType

    public func single(progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, Handler.Response.DataSource> {
        return createSingle(api: api, progress: progress, test: test)
    }

    func createSingle(api: TargetType, progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, Handler.Response.DataSource> {
        let single = Single<Handler.Response.DataSource>.create { (single) -> Disposable in
            var responseHandle = Handler.init()
            let cancellableToken: NetworkCancelWraper = api.createRequest(networkManager: responseHandle.networkManager, plugins: responseHandle.plugins, progress: progress, success: { (resp) in
                do {
                    let response = try responseHandle.makeResponse(resp.data)
                    responseHandle.response = response
                    if let error = responseHandle.makeCustomJingDataNetworkError() {
                        single(.error(error))
                    }
                    else {
                        single(.success(response.data))
                    }
                }
                catch let error as JingDataNetworkError {
                    single(.error(error))
                    responseHandle.handleJingDataNetworkError(error)
                }
                catch {}
            }, error: { (error) in
                responseHandle.handleJingDataNetworkError(error)
            }, test: test)
            return Disposables.create {
                cancellableToken.cancel()
            }
        }
        return single
    }
}

public struct JingDataNetworkResponseObserver<Handler: JingDataNetworkResponseHandler> {
    
    var api: TargetType

    public func single(progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, Handler.Response> {
        return createSingle(api: api, progress: progress, test: test)
    }
    
    func createSingle(api: TargetType, progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, Handler.Response> {
        let single = Single<Handler.Response>.create { (single) -> Disposable in
            var responseHandle = Handler.init()
            let cancellableToken: NetworkCancelWraper = api.createRequest(networkManager: responseHandle.networkManager, plugins: responseHandle.plugins, progress: progress, success: { (resp) in
                do {
                    let response = try responseHandle.makeResponse(resp.data)
                    responseHandle.response = response
                    if let error = responseHandle.makeCustomJingDataNetworkError() {
                        single(.error(error))
                    }
                    else {
                        single(.success(response))
                    }
                }
                catch let error as JingDataNetworkError {
                    single(.error(error))
                    responseHandle.handleJingDataNetworkError(error)
                }
                catch {}
            }, error: { (error) in
                responseHandle.handleJingDataNetworkError(error)
            }, test: test)
            return Disposables.create {
                cancellableToken.cancel()
            }
        }
        return single
    }
}

extension TargetType {
    
    func createRequest(networkManager: Manager, plugins: [PluginType], progress: ProgressBlock? = nil, success: @escaping (Response) -> (), error: JingDataNetworkErrorCallback? = nil, test: Bool = false) -> NetworkCancelWraper {
        let provider: MoyaProvider<Self> = createProvider(networkManager: networkManager, plugins: plugins, test: test)
        let request = provider.request(self, callbackQueue: .global(), progress: progress) { (result) in
            switch result {
            case .failure(let e):
                error?(.default(error: e))
            case .success(let d):
                do {
                    let r = try d.filterSuccessfulStatusCodes()
                    success(r)
                }
                catch let e as MoyaError {
                    switch e {
                    case .statusCode(let r):
                        error?(.status(code: r.statusCode))
                    default:
                        ()
                    }
                }
                catch {}
            }
        }
        return NetworkCancelWraper(request)
    }
    
    func createProvider(networkManager: Manager, plugins: [PluginType], test: Bool) -> MoyaProvider<Self> {
        let endpointClosure = { (target: TargetType) -> Endpoint in
            let url = target.baseURL.appendingPathComponent(target.path).absoluteString
            let endpoint = Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
            return endpoint
        }
        if test {
            return MoyaProvider<Self>(endpointClosure: endpointClosure, stubClosure: { (target) -> StubBehavior in
                return StubBehavior.immediate
            }, manager: networkManager, plugins: plugins)
        }
        else {
            return MoyaProvider<Self>.init(endpointClosure: endpointClosure, manager: networkManager, plugins: plugins)
        }
    }
}


