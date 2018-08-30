//
//  ViewController.swift
//  JingDataNetwork
//
//  Created by tianziyao on 08/22/2018.
//  Copyright (c) 2018 tianziyao. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import JingDataNetwork
import Moya

struct BaseNetworkConfig: JingDataConfigProtocol {
    static var plugins: [PluginType] {
        set {
            
        }
        get {
            // let logger = NetworkLoggerPlugin(verbose: true, output: BaseResp.reversedPrint)
            return []
        }
    }
    
    static func reversedPrint(_ separator: String, terminator: String, items: Any...) {
        for item in items {
            print(item, separator: separator, terminator: terminator)
        }
    }
    
    static var networkManager: Manager {
        set {
            
        }
        get {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 60
            let manager = Manager(configuration: configuration)
            manager.startRequestsImmediately = false
            return manager
        }
    }
    
    static func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        //print(error.description)
    }
}

class ViewController: UIViewController {
    
    var bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        next()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func base() {
        JingDataNetworkManager<TestApi, BaseNetworkConfig>
            .base(api: .n)
            .observer(test: true, progress: { (data) in
                print(data.progress)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (data: BaseResp<UserInfo>) in
                print(data)
            }, onError: { (e) in
                print(e as! JingDataNetworkError)
            })
            .disposed(by: bag)
    }
    
    
    func zip() {
        JingDataNetworkSequencer<BaseNetworkConfig>.sameApi()
            .zip(apis: [TestApi.m, .n], test: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (d: [BaseResp<UserInfo>]) in
                print(Thread.current)
                print(d.map { $0.data!.name! })
            }).disposed(by: bag)
    }
    
    func map() {
        JingDataNetworkSequencer<BaseNetworkConfig>.sameApi()
            .map(apis: [TestApi.m, .n], test: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (d: BaseResp<UserInfo>) in
                print(Thread.current)
                print(d.data!.name!)
            }).disposed(by: bag)
    }
    
    func next() {
        JingDataNetworkSequencer<BaseNetworkConfig>.differentApi()
            .next(api: { (data: String?) -> TestApi in
                return .m
            }, success: { (data: String) in
                print(data)
            }, error: { (error) in
                print(error)
            }, test: true)
            .next(api: { (data: BaseResp<UserInfo>?) -> TestApi in
                return .m
            }, success: { (data: UserInfo) in
                //print(data.data!.age!)
            }, error: { (error) in
                print(error)
            }, test: true)
            .run()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (result) in
                print("success", Thread.current)
            }) { (error) in
                print(error)
        }.disposed(by: bag)
    }
    
//    func wait() {
//        let o1: Observable<BaseResp<UserInfo>> = JingDataNetworkDifferentApiSequencer<BaseNetworkConfig>.observerOfzip(api: TestApi.m, test: true)
//        let o2: Observable<BaseResp<UserInfo>> = JingDataNetworkDifferentApiSequencer<BaseNetworkConfig>.observerOfzip(api: TestApi.n, test: true)
//        let o3: Observable<String> = JingDataNetworkDifferentApiSequencer<BaseNetworkConfig>.observerOfzip(api: Test2Api.n, test: true)
//        let o4: Observable<BaseResp<UserInfo>> = JingDataNetworkDifferentApiSequencer<BaseNetworkConfig>.observerOfzip(api: Test2Api.n, test: true)
//        Observable.zip(o1, o2, o3, o4)
//        .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { (str1, user1, str2, user2) in
//                print(Thread.current)
//                print(str1, user1, str2, user2)
//            }, onError: { (e) in
//                print(e)
//            })
//        .disposed(by: bag)
//    }
//
}

