大多数 APP 都需要向服务器请求数据，一般来说，一个 APP 只需要根据一个后台设计一套网络请求的封装即可。

但是在开发工作中，可能一个 APP 需要接入其他产线的功能，甚至有可能同一个后台返回的接口也不能适用同一

个解析规则。当出现这种情况时，`MJExtension`、`ObjectMapper`、`HandyJSON` 等模型转换的工具应运而生。



## 模型转换

当我们使用这些工具时，往往需要有一个确定的类型，才能完成 data 到 model 的映射。在这个阶段，一般是这

样来设计模型：

```swift
class BaseRespose {
    var code: Int?
    var msg: String?
}

class UserInfo {
    var name: String?
    var age: Int?
}

class UserInfoResponse: BaseRespose {
    var data: UserInfo?
}
```

这样来设计 Network：

```swift
network<T: BaseResponse>(api: String, success((data: T) -> ()))
```

在这个阶段，我们运用泛型约束了模型类。使得任何继承了 `BaseResponse` 或实现了 `BaseResponse` 协议的类或结

构体可以成功的解析。这样看来，似乎已经可以做到解析所有的数据结构了，但需要注意的是，此时的 Network 

只能处理 `BaseRespose`，也就意味着这时的 Network 只能处理一种类型。

举例来说，当加入新的接口，且 `code` 或 `msg` 的解析规则发生变化时，现在的 Network 就无法使用。

当然，在这个例子中，办法还是有的，比如：

```swift
class BaseRespose {}

class UserInfo {
    var name: String?
    var age: Int?
}

class UserInfoResponse: BaseRespose {
    var code: Int?
    var msg: String?
    var data: UserInfo?
}
```

`BaseRespose` 不处理任何解析实现，依靠确定的类型 `UserInfoResponse` 进行解析，但这样你会发现，无法从 

Network 内部获取 `code` 从而判断请求状态。进行统一的处理，其次，也会产生冗余代码。

而这种情况下，只能是增加 Network 的请求方法，来适应两种不同的结构。

同时，除了增加请求方法之外，你无法使其返回 data、string、json 等数据类型。

其次，在依靠继承关系组成模型的情况下，你也无法使用结构体来进行模型的声明。

因此，一个组件化的 Network，为了适应不同的后台或不同的数据结构，应该具备可以解析任意传入的类型，并

进行输出，同时可以在 Network 的内部对请求结果进行统一的处理。且应该支持类与结构体。



## JingDataNetwork

下面让我们通过一个已经实现的网络请求组件，尝试解决和讨论以上的问题。此组件由以下四部分组成。

```
.
├── JingDataNetworkError.swift
├── JingDataNetworkManager.swift
├── JingDataNetworkResponseHandler.swift
└── JingDataNetworkSequencer.swift
```

在这个组件中，依赖了以下几个优秀的开源工具，其具体使用不再细表：

```
  ## 网络请求
  s.dependency 'Moya', '~> 11.0' 	
  ## 响应式
  s.dependency 'RxSwift',    '~> 4.0'
  s.dependency 'RxCocoa',    '~> 4.0'
```



## 如何针对不同后台进行设置

针对每一种后台，或者同一个后台返回的不同结构的响应，我们将其视为一种 `Response `，通过 `JingDataNetworkResponseHandler ` 来处理一个 `Response`。

```swift
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
```

每一种 `ResponseHandler` 要求其具备提供 `networkManager`，`plugins` 网络请求基础能力。同时具备完成 `Data` 到 `Response` 映射、抛出自定义错误和处理全局错误的能力。

其中 `plugins` 是 `Moya` 的插件机制，可以实现 log、缓存等功能。



### 如何实现 Data 到 Response 的映射

实现 `JingDataNetworkResponseHandler` 协议让如何完成解析变得相当清晰。

```swift
struct BaseResponseHandler: JingDataNetworkResponseHandler {
    
    var response: String?
    
    func makeResponse(_ data: Data) throws -> String {
         return String.init(data: data, encoding: .utf8) ?? "unknow"
    }
    
    func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        return nil
    }
    
    func handleJingDataNetworkError(_ error: JingDataNetworkError) {

    }
}
```



### 如何实现解析任意的类型

看到这里你可能会有疑惑，`Response` 每有一个类型都需要重新实现一个 `JingDataNetworkResponseHandler` 吗？这样会不会太繁琐了？

是这样的。这个问题可以通过对 `JingDataNetworkResponseHandler` 泛型化进行解决：

```swift
struct BaseTypeResponseHandler<R>: JingDataNetworkResponseHandler {
    
    var response: R?
    
    func makeResponse(_ data: Data) throws -> R {
        if R.Type.self == String.Type.self {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
        else if R.Type.self == Data.Type.self {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
        else if R.Type.self == UIImage.Type.self {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
        else {
            throw JingDataNetworkError.parser(type: "\(R.Type.self)")
        }
    }
    
    func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        return nil
    }
    
    func handleJingDataNetworkError(_ error: JingDataNetworkError) {
        
    }
}
```

但是大家都清楚，如果一个类或者方法承载了太多的功能，将会变得臃肿，分支条件增加，继而变得逻辑不清，难以维护。因此，适度的抽象，分层，解耦对于中大型项目尤为必要。

而且在这里，`Response` 还仅仅是基础类型。如果是对象类型的话，那 `ResponseHandler` 会更加的复杂。因为 `UserInfo` 和 `OrderList` 在解析，错误抛出，错误处理等方面可能根本不同。

因此就引出了下面的问题。



## 如何处理不同类型的错误处理和抛出

为了处理这个问题，我们可以声明一个 `JingDataNetworkDataResponse`，约束其具有和 `JingDataNetworkResponseHandler` 相同的能力。

```swift
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
```

实现这个协议，就会发现 `UserInfo` 和 `OrderList` 完全可以使用不同的方式来处理：

```swift
struct BaseDataResponse: JingDataNetworkDataResponse {

    var data: String = ""
    var code: Int = 0
    
    init?(_ data: Data) {
        self.data = "str"
        self.code = 0
    }
    
    func makeCustomJingDataNetworkError() -> JingDataNetworkError? {
        switch code {
        case 0:
            return nil
        default:
            return JingDataNetworkError.custom(code: code)
        }
    }
}

struct BaseDataResponseHandler<R: JingDataNetworkDataResponse>: JingDataNetworkDataResponseHandler {
    var response: R?
}
```



## 如何发起请求

`JingDataNetworkManager` 中使用 `Moya` 和 `RxSwift` 对网络请求进行了封装，主要做了下面几件事：

- 网络请求错误码抛出；
- Data 转 Response 错误抛出；
- ProgressBlock 设定；
- Test 设定；
- 网络请求 Observer  构造；



## 使用示例

```swift
        // 获取 response
        JingDataNetworkManager.base(api: TestApi.m)
            .bind(BaseResponseHandler.self)
            .single()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (response) in
                print(response)
            })
            .disposed(by: bag)
        
        // 获取 response.data
        JingDataNetworkManager.base(api: TestApi.m)
            .bind(BaseDataResponseHandler<BaseDataResponse>.self)
            .single()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (data) in
                print(data.count)
            })
            .disposed(by: bag)
        
        // 获取 response.listData
        JingDataNetworkManager.base(api: TestApi.m)
            .bind(BaseListDataResponseHandler<BaseListDataResponse>.self)
            .single()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (listData) in
                print(listData.count)
            })
            .disposed(by: bag)
```



## 时序管理

除去模型的解析之外，在 Network 的工作中，请求顺序的管理也是一个重头戏。其请求的顺序一般有几种情况。

- 请求结果以相同模型解析
  - 请求回调依次响应
  - 全部请求完毕进行回调
- 请求结果以不同模型解析
  - 请求回调依次响应
  - 全部请求完毕进行回调

下面依次来看如何进行实现。



## 相同 Response

```swift
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
```

这里使用了 `RxSwift` 对请求结果分别进行打包和顺序处理。

使用示例：

```swift
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
```



##不同 Response

###顺序请求

不同的模型相对复杂，因为它意味着不同的后台或解析规则，同时，顺序请求时，又要求可以获取上一次请求的结果，顺序请求完成时，又可以取得最终的请求结果。

在下面的实现中：

`blocks` 保存每次请求的代码块，如请求失败时则会打断下一次请求。

`semaphore` 是信号量，保证本次 `block` 完成前，下一个 `block` 会被阻塞。

`data` 是本次请求的结果，用于传给下一个请求。

```swift
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
```

示例：

```swift
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
```



### 打包请求

在打包请求中，我们将一个请求视为一个 task：

```swift
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
```

通过对 `Single.zip` 的再次封装，完成打包请求的目标：

```swift
public struct JingDataNetworkDifferentZipHandlerSequencer {
    
    public init() {}
    
    public func zip<H1: JingDataNetworkResponseHandler, H2: JingDataNetworkResponseHandler, H3: JingDataNetworkResponseHandler>(_ source1: JingDataNetworkTask<H1>, _ source2: JingDataNetworkTask<H2>, _ source3: JingDataNetworkTask<H3>) -> PrimitiveSequence<SingleTrait, (H1.Response, H2.Response, H3.Response)> {
        return Single.zip(source1.single(), source2.single(), source3.single())
    }
    
    public func zip<H1: JingDataNetworkResponseHandler, H2: JingDataNetworkResponseHandler>(_ source1: JingDataNetworkTask<H1>, _ source2: JingDataNetworkTask<H2>) -> PrimitiveSequence<SingleTrait, (H1.Response, H2.Response)> {
        return Single.zip(source1.single(), source2.single())
    }
}
```

示例：

```swift
        let task1 = JingDataNetworkTask(api: TestApi.m, handler: BaseResponseHandler.self)
        let task2 = JingDataNetworkTask(api: Test2Api.n, handler: BaseListDataResponseHandler<BaseListDataResponse>.self)
        let sequencer = JingDataNetworkSequencer.differentHandlerZip
        sequencer.zip(task1, task2).subscribe(onSuccess: { (data1, data2) in
            print(data1, data2)
        }).disposed(by: bag)
```





## 项目地址

https://github.com/tianziyao/JingDataNetwork



## 总结

至此，关于一个网络请求的组件已经基本完成。而涉及到如下载、上传等功能，已由 `Moya` 进行实现。

如对你有一些帮助请点一下 star。

其中有一些设计不完善的地方，希望大家可以提 issue。