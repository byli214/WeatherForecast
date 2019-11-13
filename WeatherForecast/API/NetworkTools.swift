//
//  NetworkTools.swift
//  networkTryAgain
//
//  Created by ek on 2019/10/17.
//  Copyright © 2019 ek. All rights reserved.
//

import Foundation
import Alamofire

enum MethodType {
    case get
    case post
}

class NetworkTools: NSObject {
    
    static let shared = NetworkTools()
    
    func requestData(URLString: String, type: MethodType, parameters: [String: Any]? = nil, finishCallback: @escaping(_ result: Any) -> Void ) {
        
        let method = type == .get ? HTTPMethod.get : HTTPMethod.post
        Alamofire.request(URLString, method: method, parameters: parameters).responseJSON { (response) in
            print(response)
            guard let result = response.data else { return }
            finishCallback(result)
        }
        EKDataRequestManager.shared().start(withUrl: URLString, argument: parameters) { (EKDataResultProtocol) in
            print("123")
        }
    }

    
}
