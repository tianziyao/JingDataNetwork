//
//  JingDataNetworkSequencer.swift
//  JingDataNetwork
//
//  Created by Tian on 2018/8/28.
//

import Foundation
import Moya
import RxCocoa
import RxSwift

public typealias JingDataNetworkViodCallback = () -> ()

public struct JingDataNetworkSequencer {
    public static var differentHandlerMap = JingDataNetworkDifferentMapHandlerSequencer()
    public static var differentHandlerZip = JingDataNetworkDifferentZipHandlerSequencer()
    
    public static func sameHandler<Handler: JingDataNetworkResponseHandler>(_ bind: Handler.Type) -> JingDataNetworkSameHandlerSequencer<Handler> {
        return JingDataNetworkSameHandlerSequencer()
    }
}

public protocol JingDataNetworkTaskInterface {
    associatedtype Handler: JingDataNetworkResponseHandler
    var api: TargetType { get }
    var handler: Handler.Type { get }
    var progress: ProgressBlock? { get }
    var test: Bool { get }
    init(api: TargetType, handler: Handler.Type, progress: ProgressBlock?, test: Bool)
    func single() -> PrimitiveSequence<SingleTrait, Handler.Response>
}

public struct JingDataNetworkTask<H: JingDataNetworkResponseHandler>: JingDataNetworkTaskInterface {
    
    public var api: TargetType
    public var handler: H.Type
    public var progress: ProgressBlock? = nil
    public var test: Bool = false
    
    public init(api: TargetType, handler: Handler.Type, progress: ProgressBlock? = nil, test: Bool = false) {
        self.api = api
        self.handler = handler
        self.progress = progress
        self.test = test
    }
    
    public func single() -> PrimitiveSequence<SingleTrait, H.Response> {
        return JingDataNetworkManager.base(api: api).bind(handler).single(progress: progress, test: test)
    }
}


public struct JingDataNetworkDifferentZipHandlerSequencer {
    
    public init() {}
    
    public func zip<H1: JingDataNetworkResponseHandler, H2: JingDataNetworkResponseHandler, H3: JingDataNetworkResponseHandler>(_ source1: JingDataNetworkTask<H1>, _ source2: JingDataNetworkTask<H2>, _ source3: JingDataNetworkTask<H3>) -> PrimitiveSequence<SingleTrait, (H1.Response, H2.Response, H3.Response)> {
        return Single.zip(source1.single(), source2.single(), source3.single())
    }
    
    public func zip<H1: JingDataNetworkResponseHandler, H2: JingDataNetworkResponseHandler>(_ source1: JingDataNetworkTask<H1>, _ source2: JingDataNetworkTask<H2>) -> PrimitiveSequence<SingleTrait, (H1.Response, H2.Response)> {
        return Single.zip(source1.single(), source2.single())
    }
}

public class JingDataNetworkDifferentMapHandlerSequencer {
    
    var blocks = [JingDataNetworkViodCallback]()
    let semaphore = DispatchSemaphore(value: 1)
    var data: Any?
    var bag = DisposeBag()
    var requestSuccess = true
    var results = [Any]()
    var index: Int = 0
    
    public init() {}
    
    @discardableResult
    public func next<C: JingDataNetworkResponseHandler, T: TargetType, P>(bind: C.Type, with: @escaping (P) -> T?, progress: ProgressBlock? = nil, success: @escaping (C.Response) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentMapHandlerSequencer {
        let api: () -> T? = {
            guard let preData = self.data as? P else { return nil }
            return with(preData)
        }
        return next(bind: bind, api: api, progress: progress, success: success, error: error, test: test)
    }
    
    @discardableResult
    public func next<C: JingDataNetworkResponseHandler, T: TargetType>(bind: C.Type, api: @escaping () -> T?, progress: ProgressBlock? = nil, success: @escaping (C.Response) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentMapHandlerSequencer {
        let block: JingDataNetworkViodCallback = {
            guard let api = api() else {
                self.requestSuccess = false
                return
            }
            self.semaphore.wait()
            JingDataNetworkManager.base(api: api).bind(C.self)
            .single(progress: progress, test: test)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (data) in
                self?.data = data
                self?.results.append(data)
                self?.requestSuccess = true
                success(data)
                self?.semaphore.signal()
                }, onError: { [weak self] (e) in
                    self?.requestSuccess = false
                    error?(e)
                    self?.semaphore.signal()
            })
            .disposed(by: self.bag)

            self.semaphore.wait()
            // print("xxxxxxxxx")
            self.semaphore.signal()
        }
        blocks.append(block)
        return self
    }
    
    public func run() -> PrimitiveSequence<SingleTrait, [Any]> {
        let ob = Single<[Any]>.create { (single) -> Disposable in
            let queue = DispatchQueue(label: "\(JingDataNetworkDifferentMapHandlerSequencer.self)", qos: .default, attributes: .concurrent)
            queue.async {
                for i in 0 ..< self.blocks.count {
                    self.index = i
                    guard self.requestSuccess else {
                        break
                    }
                    self.blocks[i]()
                }
                if self.requestSuccess {
                    single(.success(self.results))
                }
                else {
                    single(.error(JingDataNetworkError.sequence(.break(index: self.index))))
                }
                self.requestFinish()
            }
            return Disposables.create()
        }
        return ob
    }
    
    func requestFinish() {
        requestSuccess = true
        index = 0
        blocks.removeAll()
        results.removeAll()
    }
    
    deinit {
        debugPrint("\(#file) \(#function)")
    }
}

public struct JingDataNetworkSameHandlerSequencer<Handler: JingDataNetworkResponseHandler> {
    
    public init () {}
    
    public func zip(apis: [TargetType], progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, [Handler.Response]> {
        var singles = [PrimitiveSequence<SingleTrait, Handler.Response>]()
        for api in apis {
            let single = JingDataNetworkManager.base(api: api).bind(Handler.self).single(progress: progress, test: test)
            singles.append(single)
        }
        return Single.zip(singles)
    }
    
    public func map(apis: [TargetType], progress: ProgressBlock? = nil, test: Bool = false) -> Observable<Handler.Response> {
        var singles = [PrimitiveSequence<SingleTrait, Handler.Response>]()
        for api in apis {
            let single = JingDataNetworkManager.base(api: api).bind(Handler.self).single(progress: progress, test: test)
            singles.append(single)
        }
        return Observable.from(singles).merge()
    }
}
