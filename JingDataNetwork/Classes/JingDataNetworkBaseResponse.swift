//
//  JingDataNetworkBaseModel.swift
//  Alamofire
//
//  Created by Tian on 2018/8/22.
//

import Foundation
import ObjectMapper

class JingDataNetworkBaseResponse<DataSource: Mappable>: Mappable {
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {}
}
