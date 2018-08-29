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

public class NetworkCancelWraper {
    var cancellable: Cancellable?
    init(_ cancellable: Cancellable) { self.cancellable = cancellable }
    func cancel() { cancellable?.cancel() }
}

public enum JingDataNetworkManager<T: TargetType, C: JingDataConfigProtocol> {
    
    case base(api: T)
    
    public func observer<R>(test: Bool = false, progress: ProgressBlock? = nil) -> Observable<R> {
        switch self {
        case .base(let api):
            return createObserver(api: api, test: test, progress: progress)
        }
    }
    
//    func createObjectObserver<R>(api: T, test: Bool = false, progress: ProgressBlock? = nil) -> Observable<R> {
//        return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, resp) in
//            do {
//                let model: R = try JingDataNetworkDataParser.handle(data: resp.data) as! R
//                ob.onNext(model as! R)
//            }
//            catch let error as JingDataNetworkError {
//                self.handle(ob: ob, error: error)
//            }
//            catch {}
//        })
//    }

        
    func createObserver<R>(api: T, test: Bool = false, progress: ProgressBlock? = nil) -> Observable<R> {
        if R.Type.self == String.Type.self {
            return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, resp) in
                do {
                    let string: String = try JingDataNetworkDataParser.handle(resp: resp)
                    ob.onNext(string as! R)
                }
                catch let error as JingDataNetworkError {
                    self.handle(ob: ob, error: error)
                }
                catch {}
            })
        }
        else if R.Type.self == Data.Type.self {
            return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, resp) in
                ob.onNext(resp.data as! R)
            })
        }
        else if R.Type.self == UIImage.Type.self {
            return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, resp) in
                do {
                    let image: UIImage = try JingDataNetworkDataParser.handle(resp: resp)
                    ob.onNext(image as! R)
                }
                catch {
                    self.handle(ob: ob, error: .parser(.image))
                }
            })
        }
        else if R.Type.self == JSON.Type.self {
            return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, resp) in
                do {
                    let json: JSON = try JingDataNetworkDataParser.handle(data: resp.data)
                    ob.onNext(json as! R)
                }
                catch let error as JingDataNetworkError {
                    self.handle(ob: ob, error: error)
                }
                catch {}
            })
        }
//        else if R.Type.self == M.Type.self {
//            return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, resp) in
//                do {
//                    let model: M = try JingDataNetworkDataParser.handle(data: resp.data)
//                    ob.onNext(model as! R)
//                }
//                catch let error as JingDataNetworkError {
//                    self.handle(ob: ob, error: error)
//                }
//                catch {}
//            })
//        }
        else {
            
            return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, data) in
                self.handle(ob: ob, error: .parser(.type))
            })
        }
    }
    
    func createGeneralObserver<D>(api: T, test: Bool = false, progress: ProgressBlock? = nil, success: @escaping (AnyObserver<D>, Response) -> (), error: JingDataNetworkErrorCallback? = nil) -> Observable<D> {
        let ob = Observable<D>.create { (ob) -> Disposable in
            let cancellableToken = self.createRequest(api: api, test: test, progress: progress, success: { (resp) in
                success(ob, resp)
            }, error: { (error) in
                self.handle(ob: ob, error: error)
            })
            
            return Disposables.create {
                cancellableToken.cancel()
            }
        }
        return ob
    }
    
    func createRequest(api: T, test: Bool = false, progress: ProgressBlock? = nil, success: @escaping (Response) -> (), error: JingDataNetworkErrorCallback? = nil) -> NetworkCancelWraper {
        let provider = createProvider(api: api, test: test)
        let request = provider.request(api, callbackQueue: .global(), progress: progress) { (result) in
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
    
    func createProvider(api: T, test: Bool) -> MoyaProvider<T> {
        let endpointClosure = { (target: TargetType) -> Endpoint in
            let url = target.baseURL.appendingPathComponent(target.path).absoluteString
            let endpoint = Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
            return endpoint
        }
        if test {
            return MoyaProvider<T>(endpointClosure: endpointClosure, stubClosure: { (target) -> StubBehavior in
                return StubBehavior.immediate
            }, manager: C.networkManager, plugins: C.plugins)
        }
        else {
            return MoyaProvider<T>.init(endpointClosure: endpointClosure, manager: C.networkManager, plugins: C.plugins)
        }
    }
    
    func handle<D>(ob: AnyObserver<D>, error: JingDataNetworkError) {
        C.handleJingDataNetworkError(error)
        ob.onError(error)
    }
}


