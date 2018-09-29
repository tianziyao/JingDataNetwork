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
        sequencerDifferentZipResponse()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func base() {
        
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
    
    func sequencerSameModel() {
        let sequencer = JingDataNetworkSequencer.sameHandler(BaseListDataResponseHandler<BaseListDataResponse>.self)
        sequencer.zip(apis: [TestApi.m, Test2Api.n])
            .subscribe(onSuccess: { (responseList) in
                print(responseList.map({$0.listData}))
            })
        .disposed(by: bag)
        
        sequencer.map(apis: [TestApi.m, Test2Api.n])
            .subscribe(onNext: { (response) in
                print(response.listData)
            })
        .disposed(by: bag)
    }
    
    func sequencerDifferentMapResponse() {
        let sequencer = JingDataNetworkSequencer.differentHandlerMap
        sequencer.next(bind: BaseResponseHandler.self, api: {TestApi.m}, success: { (response) in
            print(response)
        })
        sequencer.next(bind: BaseListDataResponseHandler<BaseListDataResponse>.self, with: { (data: String) -> TestApi? in
            print(data)
            return .n
        }, success: { (response) in
            print(response)
        })
        sequencer.next(bind: BaseListDataResponseHandler<BaseListDataResponse>.self, with: { (data: BaseListDataResponse) -> Test2Api? in
            print(data)
            return .n
        }, success: { (response) in
            print(response)
        })
        sequencer.run().asObservable()
            .subscribe(onNext: { (results) in
                print(results)
            })
        .disposed(by: bag)
    }

    
    func sequencerDifferentZipResponse() {
        let task1 = JingDataNetworkTask(api: TestApi.m, handler: BaseResponseHandler.self)
        let task2 = JingDataNetworkTask(api: Test2Api.n, handler: BaseListDataResponseHandler<BaseListDataResponse>.self)
        let sequencer = JingDataNetworkSequencer.differentHandlerZip
        sequencer.zip(task1, task2).subscribe(onSuccess: { (data1, data2) in
            print(data1, data2)
        }).disposed(by: bag)
    }
}

