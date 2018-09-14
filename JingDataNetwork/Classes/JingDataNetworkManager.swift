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
import ObjectMapper
import Alamofire
import SwiftyJSON

public typealias JingDataNetworkErrorCallback = (JingDataNetworkError) -> Void

class NetworkCancelWraper<C: JingDataNetworkResponseHandler> {
    var cancellable: Cancellable?
    init(_ cancellable: Cancellable) { self.cancellable = cancellable }
    func cancel() { cancellable?.cancel() }
}

public enum JingDataNetworkManager {
    
    case base(api: TargetType)
    
    public func bind<C: JingDataNetworkResponseHandler>(_ type: C.Type) -> JingDataNetworkObserver<C> {
        switch self {
        case .base(let api):
            return JingDataNetworkObserver<C>(api: api)
        }
    }
}

public struct JingDataNetworkObserver<C: JingDataNetworkResponseHandler> {
    
    var api: TargetType

    public func single(progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, C.Response> {
        return createSingle(api: api, progress: progress, test: test)
    }
    
    func createSingle(api: TargetType, progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, C.Response> {
        let single = Single<C.Response>.create { (single) -> Disposable in
            let cancellableToken: NetworkCancelWraper<C> = api.createRequest(progress: progress, success: { (resp) in
                do {
                    let data: C.Response = try C.makeInstance(resp.data)
                    if let error = C.makeCustomJingDataNetworkError(data) {
                        single(.error(error))
                    }
                    else {
                        single(.success(data))
                    }
                }
                catch let error as JingDataNetworkError {
                    single(.error(error))
                    C.handleJingDataNetworkError(error)
                }
                catch {}
            }, error: { (error) in
                C.handleJingDataNetworkError(error)
            }, test: test)
            return Disposables.create {
                cancellableToken.cancel()
            }
        }
        return single
    }

//    func createRequest<T: TargetType>(api: T, test: Bool = false, progress: ProgressBlock? = nil, success: @escaping (Response) -> (), error: JingDataNetworkErrorCallback? = nil) -> NetworkCancelWraper {
//        let provider: MoyaProvider<T> = createProvider(test: test, networkManager: C.networkManager, plugins: C.plugins)
//        let request = provider.request(api, callbackQueue: .global(), progress: progress) { (result) in
//            switch result {
//            case .failure(let e):
//                error?(.default(error: e))
//            case .success(let d):
//                do {
//                    let r = try d.filterSuccessfulStatusCodes()
//                    success(r)
//                }
//                catch let e as MoyaError {
//                    switch e {
//                    case .statusCode(let r):
//                        error?(.status(code: r.statusCode))
//                    default:
//                        ()
//                    }
//                }
//                catch {}
//            }
//        }
//        return NetworkCancelWraper(request)
//    }
//
//    func createProvider<T: TargetType>(test: Bool, networkManager: Manager, plugins: [PluginType]) -> MoyaProvider<T> {
//        let endpointClosure = { (target: TargetType) -> Endpoint in
//            let url = target.baseURL.appendingPathComponent(target.path).absoluteString
//            let endpoint = Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
//            return endpoint
//        }
//        if test {
//            return MoyaProvider<T>(endpointClosure: endpointClosure, stubClosure: { (target) -> StubBehavior in
//                return StubBehavior.immediate
//            }, manager: networkManager, plugins: plugins)
//        }
//        else {
//            return MoyaProvider<T>.init(endpointClosure: endpointClosure, manager: networkManager, plugins: plugins)
//        }
//    }
}

extension TargetType {
    
    func createRequest<C: JingDataNetworkResponseHandler>(progress: ProgressBlock? = nil, success: @escaping (Response) -> (), error: JingDataNetworkErrorCallback? = nil, test: Bool = false) -> NetworkCancelWraper<C> {
        let provider: MoyaProvider<Self> = createProvider(networkManager: C.networkManager, plugins: C.plugins, test: test)
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


