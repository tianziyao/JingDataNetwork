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
    
    public static func sameResponse<Handle: JingDataNetworkResponseHandler>() -> JingDataNetworkSameResponseSequencer<Handle> {
        return JingDataNetworkSameResponseSequencer<Handle>()
    }
    
    public static func differentResponse() -> JingDataNetworkDifferentResponseSequencer {
        return JingDataNetworkDifferentResponseSequencer()
    }
}

public class JingDataNetworkDifferentResponseSequencer {
    
    var blocks = [JingDataNetworkViodCallback]()
    let semaphore = DispatchSemaphore(value: 1)
    var data: Any?
    var bag = DisposeBag()
    var requestSuccess = true
    var results = [Any]()
    var index: Int = 0
    
    public func next<C: JingDataNetworkResponseHandler, T: TargetType, P>(bind: C.Type? = nil, with: @escaping (P) -> T?, progress: ProgressBlock? = nil, success: @escaping (C.Response) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentResponseSequencer {
        let api: () -> T? = {
            guard let preData = self.data as? P else { return nil }
            return with(preData)
        }
        return next(bind: bind, api: api, progress: progress, success: success, error: error, test: test)
    }
    
    public func next<C: JingDataNetworkResponseHandler, T: TargetType>(bind: C.Type? = nil, api: @escaping () -> T?, progress: ProgressBlock? = nil, success: @escaping (C.Response) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentResponseSequencer {
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
//            JingDataNetworkManager<C>.base(api: api).observer(test: test, progress: progress)
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] (data: N) in
//                    self?.data = data
//                    self?.results.append(data)
//                    self?.requestSuccess = true
//                    success(data)
//                    self?.semaphore.signal()
//                    }, onError: { [weak self] (e) in
//                        self?.requestSuccess = false
//                        error?(e)
//                        self?.semaphore.signal()
//                })
//                .disposed(by: self.bag)
            self.semaphore.wait()
            // print("xxxxxxxxx")
            self.semaphore.signal()
        }
        blocks.append(block)
        return self
    }
    
    public func run() -> PrimitiveSequence<SingleTrait, [Any]> {
        let ob = Single<[Any]>.create { (single) -> Disposable in
            let queue = DispatchQueue(label: "\(JingDataNetworkDifferentResponseSequencer.self)", qos: .default, attributes: .concurrent)
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
}
//
//public extension JingDataNetworkDifferentModelSequencer {
//    
//    public func observerOfzip<T: TargetType, R: JingDataNetworkBaseResponse>(api: T, progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
//        return JingDataNetworkManager<C>.base(api: api).observer(test: test, progress: progress)
//    }
//    
//    public func observerOfzip<T: TargetType, R>(api: T, progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
//        return JingDataNetworkManager<C>.base(api: api).observer(test: test, progress: progress)
//    }
//}
//
public struct JingDataNetworkSameResponseSequencer<Handle: JingDataNetworkResponseHandler> {
    
    public init () {}
    
    public func zip(apis: [TargetType], progress: ProgressBlock? = nil, test: Bool = false) -> PrimitiveSequence<SingleTrait, [Handle.Response]> {
        var singles = [PrimitiveSequence<SingleTrait, Handle.Response>]()
        for api in apis {
            let single = JingDataNetworkManager.base(api: api).bind(Handle.self).single(progress: progress, test: test)
            singles.append(single)
        }
        return Single.zip(singles)
    }
    
    public func map(apis: [TargetType], progress: ProgressBlock? = nil, test: Bool = false) -> Observable<Handle.Response> {
        var singles = [PrimitiveSequence<SingleTrait, Handle.Response>]()
        for api in apis {
            let single = JingDataNetworkManager.base(api: api).bind(Handle.self).single(progress: progress, test: test)
            singles.append(single)
        }
        return Observable.from(singles).merge()
    }
}
