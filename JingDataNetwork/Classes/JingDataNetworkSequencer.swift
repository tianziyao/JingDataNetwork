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

public class JingDataNetworkSequencer<C: JingDataConfigProtocol> {
    
    public static func sameApi<T: TargetType>() -> JingDataNetworkSameApiSequencer<T, C> {
        return JingDataNetworkSameApiSequencer<T, C>()
    }
    
    public static func differentApi() -> JingDataNetworkDifferentApiSequencer<C> {
        return JingDataNetworkDifferentApiSequencer<C>()
    }
}

public class JingDataNetworkDifferentApiSequencer<C: JingDataConfigProtocol> {
    
    var blocks = [JingDataNetworkViodCallback]()
    let semaphore = DispatchSemaphore(value: 1)
    var data: Any?
    var bag = DisposeBag()
    var requestSuccess = true
    var results = [Any]()
    var index: Int = 0
    
    public func next<T: TargetType, N: JingDataNetworkBaseResponseProtocol, P>(api: @escaping (P?) -> T, progress: ProgressBlock? = nil, success: @escaping (N) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentApiSequencer {
        let block: JingDataNetworkViodCallback = {
            self.semaphore.wait()
            JingDataNetworkManager<T, C>.base(api: api(self.data as? P)).observer(test: test, progress: progress)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (data: N) in
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
    
    public func next<T: TargetType, N, P>(api: @escaping (P?) -> T, progress: ProgressBlock? = nil, success: @escaping (N) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentApiSequencer {
        let block: JingDataNetworkViodCallback = {
            self.semaphore.wait()
            JingDataNetworkManager<T, C>.base(api: api(self.data as? P)).observer(test: test, progress: progress)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (data: N) in
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
            let queue = DispatchQueue(label: "\(JingDataNetworkDifferentApiSequencer.self)", qos: .default, attributes: .concurrent)
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
                    C.handleJingDataNetworkError(.sequence(.break(index: self.index)))
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

public extension JingDataNetworkDifferentApiSequencer {
    
    static public func observerOfzip<T: TargetType, R: JingDataNetworkBaseResponseProtocol>(api: T, progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
        return JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
    }
    
    static public func observerOfzip<T: TargetType, R>(api: T, progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
        return JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
    }
}

public class JingDataNetworkSameApiSequencer<T: TargetType, C: JingDataConfigProtocol> {
    
    public init () {}
    
    public func zip<R: JingDataNetworkBaseResponseProtocol>(apis: [T], progress: ProgressBlock? = nil, test: Bool = false) -> Observable<[R]> {
        var obs = [Observable<R>]()
        for api in apis {
            let ob: Observable<R> = JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
            obs.append(ob)
        }
        return Observable.zip(obs)
    }
    
    public func map<R: JingDataNetworkBaseResponseProtocol>(apis: [T], progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
        var obs = [Observable<R>]()
        for api in apis {
            let ob: Observable<R> = JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
            obs.append(ob)
        }
        return Observable.from(obs).merge()
    }
    
    public func zip<R>(apis: [T], progress: ProgressBlock? = nil, test: Bool = false) -> Observable<[R]> {
        var obs = [Observable<R>]()
        for api in apis {
            let ob: Observable<R> = JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
            obs.append(ob)
        }
        return Observable.zip(obs)
    }
    
    public func map<R>(apis: [T], progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
        var obs = [Observable<R>]()
        for api in apis {
            let ob: Observable<R> = JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
            obs.append(ob)
        }
        return Observable.from(obs).merge()
    }
}
