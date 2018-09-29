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
import SwiftyJSON

class ViewController: UIViewController {
    
    var bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        base()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func base() {
//        JingDataNetworkManager<BaseNetworkConfig>
//            .base(api: TestApi.n)
//            .observer(test: true, progress: { (data) in
//                print(data.progress)
//            })
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { (data: BaseResp<UserInfo>) in
//                print(data.code!)
//            }, onError: { (e) in
//                print(e as! JingDataNetworkError)
//            })
//            .disposed(by: bag)
//
//        JingDataNetworkManager<BaseNetworkConfig>
//            .base(api: TestApi.n)
//            .observer(test: true, progress: { (data) in
//                print(data.progress)
//            })
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { (data: String) in
//                print(data)
//            }, onError: { (e) in
//                print(e as! JingDataNetworkError)
//            })
//            .disposed(by: bag)
//
//        JingDataNetworkManager<BaseNetworkConfig>
//            .base(api: TestApi.n)
//            .observer(test: true, progress: { (data) in
//                print(data.progress)
//            })
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { (data: JSON) in
//                print(data.arrayValue.count)
//            }, onError: { (e) in
//                print(e as! JingDataNetworkError)
//            })
//            .disposed(by: bag)
        
        JingDataNetworkManager.base(api: TestApi.m)
        .bind(BaseResponseHandler.self)
        .single()
        .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (response) in
                print(response)
            })
        .disposed(by: bag)
        
        JingDataNetworkManager.base(api: TestApi.m)
            .bind(BaseDataResponseHandler<BaseDataResponse>.self)
            .single()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (data) in
                print(data)
            })
            .disposed(by: bag)
        
        JingDataNetworkManager.base(api: TestApi.m)
            .bind(BaseListDataResponseHandler<BaseListDataResponse>.self)
            .single()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (listData) in
                print(listData)
            })
            .disposed(by: bag)
    }
    
//    func zip() {
//        JingDataNetworkSequencer<BaseNetworkConfig>.sameModel()
//            .zip(apis: [TestApi.m, .n], test: true)
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { (d: [BaseResp<UserInfo>]) in
//                print(Thread.current)
//                print(d.map { $0.data!.name! })
//            }).disposed(by: bag)
//    }
//
//    func map() {
//        JingDataNetworkSequencer<BaseNetworkConfig>.sameModel()
//            .map(apis: [TestApi.m, .n], test: true)
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { (d: BaseResp<UserInfo>) in
//                print(Thread.current)
//                print(d.data!.name!)
//            }).disposed(by: bag)
//    }
//
    func next() {
//        JingDataNetworkSequencer.differentResponse()
//            .next(bind: BaseRespHandler.self, api: { () -> TestApi? in
//                .m
//            }, test: true, success: { (data) in
//                print(data)
//            })
//        
//        JingDataNetworkSequencer<BaseNetworkConfig>.differentModel()
//            .next(api: { () -> TestApi? in
//                return .m
//            }, success: { (data: String) in
//                print(data)
//            }, error: { (error) in
//                print(error)
//            }, test: true)
//            .next(with: { (data: String) -> TestApi in
//                return .m
//            }, success: { (data: UserInfo) in
//                //print(data.data!.age!)
//            }, error: { (error) in
//                print(error)
//            }, test: true)
//            .run()
//            .observeOn(MainScheduler.instance)
//            .subscribe(onSuccess: { (result) in
//                print("success", Thread.current)
//            }) { (error) in
//                print(error)
//        }.disposed(by: bag)
    }
//
//    func wait() {
//        let o1: Observable<BaseResp<UserInfo>> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: TestApi.m, test: true)
//        let o2: Observable<BaseResp<UserInfo>> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: TestApi.n, test: true)
//        let o3: Observable<String> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: Test2Api.n, test: true)
//        let o4: Observable<BaseResp<UserInfo>> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: Test2Api.n, test: true)
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

}

