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

下面我给大家介绍一个网络请求组件，在这个组件中，依赖了以下几个优秀的开源工具，其具体使用不再细表：

```
  ## 网络请求
  s.dependency 'Moya', '~> 11.0' 
  ## 模型解析
  s.dependency 'ObjectMapper', '~> 3.3'		
  ## 响应式
  s.dependency 'RxSwift',    '~> 4.0'
  s.dependency 'RxCocoa',    '~> 4.0'
  ## JSON数据处理
  s.dependency 'SwiftyJSON',    '~> 4.0'
```



### 如何针对不同后台进行设置

 `JingDataNetworkConfig` 顾名思义。是全局的配置项。

其中 `plugins` 是 `Moya` 的插件机制，可以实现 log、缓存等功能。

`static func handleJingDataNetworkError(_ error: JingDataNetworkError)` 则是处理全局请求异常的地方。

当声明一个 Network 时，需要传入此协议的实现。

```swift
public protocol JingDataNetworkConfig {
    static var networkManager: Manager { set get }
    static var plugins: [PluginType] { set get }
    static func handleJingDataNetworkError(_ error: JingDataNetworkError)
}
```



### 如何实现接收任意模型（解析规则）

首先需要定义 `BaseResponse` 协议，协议继承了 `Mappable`，`Mappable` 是 `ObjectMapper` 中的一项协议，实现了 

`ObjectMapper` 协议的类或结构体，才可以进行解析。

`associatedtype DataSource` 表示此协议关联了一个泛型。它的作用稍后会讲到。

`func makeCustomJingDataError() -> JingDataNetworkError?` 是用于制作模型解析成功后的状态错误。

```swift
public protocol JingDataNetworkBaseResponse: Mappable {
    associatedtype DataSource
    func makeCustomJingDataError() -> JingDataNetworkError?
}
```



### 如何实现解析任意的模型

在此方法中，利用泛型约束了一个 `JingDataNetworkBaseResponse` 类型，并规范返回的结果也是此类型，然后将

这个类型传递给 `JingDataNetworkDataParser`。

```swift
func createObserver<R: JingDataNetworkBaseResponse>(api: T, test: Bool = false, progress: ProgressBlock? = nil) -> Observable<R> {
    return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, resp) in
        do {
            let model: R = try JingDataNetworkDataParser.handle(data: resp.data)
            ob.onNext(model)
        }
        catch let error as JingDataNetworkError {
            self.handle(ob: ob, error: error)
        }
        catch {}
    })
}
```

在 ``JingDataNetworkDataParser`` 方法中同样传入泛型，并将这个类型传递给 `JingDataNetworkResponseBuilder`。

在这个过程中 `response.makeCustomJingDataError()` 方法可以抛出一个错误交给全局和回调处理。

```swift
public static func handle<R: JingDataNetworkBaseResponse>(data: Data) throws -> R {
    guard let JSONString = String.init(data: data, encoding: .utf8) else {
        throw JingDataNetworkError.parser(.string)
    }
    guard let response: R = JingDataNetworkResponseBuilder.create(by: JSONString) else {
        throw JingDataNetworkError.parser(.model)
    }
    if let customError = response.makeCustomJingDataError() {
        throw customError
    }
    return response

```

最终由下面的方法，利用 `ObjectMapper` 进行解析。

```swift
public static func create<R: Mappable>(by JSONString: String) -> R? {
    let mapperModel = Mapper<R>()
    let object = mapperModel.map(JSONString: JSONString)
    return object
}
```



### 如何实现解析任意的类型

对泛型不进行约束，判断泛型的类型尝试解析。如无法解析则进入全局错误处理和错误回调。

```swift
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
        else {
            
            return createGeneralObserver(api: api, test: test, progress: progress, success: { (ob, data) in
                self.handle(ob: ob, error: .parser(.type))
            })
        }
    }
```



### 使用示例

实现一个后台对应的配置项：

```swift
struct BaseNetworkConfig: JingDataNetworkConfig {
    static var plugins: [PluginType] = []
    
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
        print(error.description)
    }
}
```

实现一个解析规则和状态错误抛出：

```swift
class BaseResp<T: Mappable>: JingDataNetworkBaseResponse {
    
    typealias DataSource = T
    
    var data: T?
    var code: Int?

    func makeCustomJingDataError() -> JingDataNetworkError? {
        guard let c = code else { return nil }
        guard c != 0 else { return nil }
        return JingDataNetworkError.custom(code: c)
    }
}
```

实现一个具体要解析的模型：

```swift
struct UserInfo: Mappable {
    var age: Int?
    var name: String?
}
```

发起一个模型解析网络请求：

```swift
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
```

发起一个 String 解析网络请求：

```swift
JingDataNetworkManager<TestApi, BaseNetworkConfig>
    .base(api: .n)
    .observer(test: true, progress: { (data) in
        print(data.progress)
    })
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { (data: String) in
        print(data)
    }, onError: { (e) in
        print(e as! JingDataNetworkError)
    })
    .disposed(by: bag)
```

发起一个 JSON 数组的网络请求：

```swift
JingDataNetworkManager<TestApi, BaseNetworkConfig>
    .base(api: .n)
    .observer(test: true, progress: { (data) in
        print(data.progress)
    })
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { (data: JSON) in
        print(data.arrayValue.count)
    }, onError: { (e) in
        print(e as! JingDataNetworkError)
    })
    .disposed(by: bag)
```

至此，我们就可以针对一个后台的不同解析规则进行适配。并可以进一步进行封装，使其使用更加简洁。



### 其他问题

现在我们已经可以解决上面抛出的问题。但是还有两点做的不够好，一个是在模型的解析上只能依赖 `ObjectMapper` 进行处理，另一方面在数组类型方面也没有特别支持。



## 时序管理

除去模型的解析之外，在 Network 的工作中，请求顺序的管理也是一个重头戏。其请求的顺序一般有几种情况。

- 请求结果以相同模型解析
  - 请求回调依次响应
  - 全部请求完毕进行回调
- 请求结果以不同模型解析
  - 请求回调依次响应
  - 全部请求完毕进行回调

下面依次来看如何进行实现。



### 相同模型

```swift
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
```

这里使用了 `RxSwift` 对请求结果分别进行打包和顺序处理。

使用示例：

```swift
JingDataNetworkSequencer<BaseNetworkConfig>.sameModel()
    .zip(apis: [TestApi.m, .n], test: true)
    .subscribe(onNext: { (d: [BaseResp<UserInfo>]) in
        print(d.map { $0.data!.name! })
    }).disposed(by: bag)
```

```
JingDataNetworkSequencer<BaseNetworkConfig>.sameModel()
    .map(apis: [TestApi.m, .n], test: true)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { (d: BaseResp<UserInfo>) in
        print(d.data!.name!)
    }).disposed(by: bag)
```



### 不同模型顺序请求

不同的模型相对复杂，因为它意味着不同的后台或解析规则，同时，顺序请求时，又要求可以获取上一次请求的结果，顺序请求完成时，又可以取得最终的请求结果。

在下面的实现中：

`blocks` 保存每次请求的代码块，如请求失败时则会打断下一次请求。

`semaphore` 是信号量，保证本次 `block` 完成前，下一个 `block` 会被阻塞。

`data` 是本次请求的结果，用于传给下一个请求。

```swift
public class JingDataNetworkDifferentModelSequencer<C: JingDataNetworkConfig> {
    
    var blocks = [JingDataNetworkViodCallback]()
    let semaphore = DispatchSemaphore(value: 1)
    var data: Any?
    var bag = DisposeBag()
    var requestSuccess = true
    var results = [Any]()
    var index: Int = 0
    
    public func next<T: TargetType, N: JingDataNetworkBaseResponse, P>(with: @escaping (P) -> T?, progress: ProgressBlock? = nil, success: @escaping (N) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentModelSequencer {
        let api: () -> T? = {
            guard let preData = self.data as? P else { return nil }
            return with(preData)
        }
        return next(api: api, progress: progress, success: success, error: error, test: test)
    }
    
    public func next<T: TargetType, N: JingDataNetworkBaseResponse>(api: @escaping () -> T?, progress: ProgressBlock? = nil, success: @escaping (N) -> (), error: ((Error) -> ())? = nil, test: Bool = false) -> JingDataNetworkDifferentModelSequencer {
        let block: JingDataNetworkViodCallback = {
            guard let api = api() else {
                self.requestSuccess = false
                return
            }
            self.semaphore.wait()
            JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
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
            let queue = DispatchQueue(label: "\(JingDataNetworkDifferentModelSequencer.self)", qos: .default, attributes: .concurrent)
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
```

示例：

```swift
JingDataNetworkSequencer<BaseNetworkConfig>.differentModel()
    .next(api: { () -> TestApi? in
        return .m
    }, success: { (data: String) in
        print(data)
    }, error: { (error) in
        print(error)
    }, test: true)
    .next(with: { (data: String) -> TestApi in
        return .m
    }, success: { (data: UserInfo) in
        print(data.data!.age!)
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
```



### 不同模型打包请求

```swift
public extension JingDataNetworkDifferentModelSequencer {
    
    public func observerOfzip<T: TargetType, R: JingDataNetworkBaseResponse>(api: T, progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
        return JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
    }
    
    public func observerOfzip<T: TargetType, R>(api: T, progress: ProgressBlock? = nil, test: Bool = false) -> Observable<R> {
        return JingDataNetworkManager<T, C>.base(api: api).observer(test: test, progress: progress)
    }
}
```

不同模型的打包请求利用 `RxSwift` 很容易处理，示例如下：

```swift
let o1: Observable<BaseResp<UserInfo>> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: TestApi.m, test: true)
let o2: Observable<BaseResp<UserInfo>> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: TestApi.n, test: true)
let o3: Observable<String> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: Test2Api.n, test: true)
let o4: Observable<BaseResp<UserInfo>> = JingDataNetworkSequencer<BaseNetworkConfig>.differentModel().observerOfzip(api: Test2Api.n, test: true)
Observable.zip(o1, o2, o3, o4)
.observeOn(MainScheduler.instance)
    .subscribe(onNext: { (str1, user1, str2, user2) in
        print(Thread.current)
        print(str1, user1, str2, user2)
    }, onError: { (e) in
        print(e)
    })
.disposed(by: bag)
```



## 项目地址

https://github.com/tianziyao/JingDataNetwork



## 总结

至此，关于一个网络请求的组件已经基本完成。而涉及到如下载、上传等功能，已由 `Moya` 进行实现。

如对你有一些帮助请点一下 star。

其中有一些设计不完善的地方，希望大家可以提 issue。