//
//  JingDataNetworkError.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import Moya

public enum JingDataNetworkParserError {
    case json
    case model
    case type
    case string
    case image
}

public enum JingDataNetworkSequenceError {
    case `break`(index: Int)
}

public enum JingDataNetworkError: Error {
    case parser(JingDataNetworkParserError)
    case custom(code: Int)
    case status(code: Int)
    case sequence(JingDataNetworkSequenceError)
    case `default`(error: MoyaError)
}

public extension JingDataNetworkError {
    
    var description: String {
        switch self {
        case .custom(let code):
            return "JingDataNetwork: " + "error from makeCustomJingDataError. code: \(code)"
        case .parser(let type):
            return "JingDataNetwork: " + "data transform \(type) fail."
        case .default(let e):
            return "JingDataNetwork: " + "request fail: " + "\(e.errorDescription ?? "unknow")" + "\(String(describing: e.helpAnchor))"
        case .status(let code):
            return "JingDataNetwork: " + "network status exception. code: \(code)"
        case .sequence(let error):
            return "JingDataNetwork: " + "sequencer thread \(error)"
        }
    }
    
}
