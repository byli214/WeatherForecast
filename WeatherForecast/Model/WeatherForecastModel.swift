//
//  WeatherForecastModel.swift
//  WeatherForecast
//
//  Created by ek on 2019/10/17.
//  Copyright © 2019 ek. All rights reserved.
//

import Foundation
import ObjectMapper

class temperatureQueried: Mappable {
    
    var temperature: String?
    var info: String?
    var direct: String?
    var power: String?
    var aqi: String?
    var future: Array<futureTemperature>?
    
    var birthday: Date?
    var error_code: Int?
    
    let transform = TransformOf<Int, Any>(fromJSON: { (code) -> Int? in
        if let str = code as? String {
            let pattern = "\\d+"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: str, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange(location: 0, length: str.count))
            var substr = ""
            for match in matches {
                substr += (str as NSString).substring(with: match.range)
            }
            return Int(substr)
        } else if let int = code as? Int {
            return int
        }
        return nil
    }) { (code) -> Any? in
        return code
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        temperature  <- map["result.realtime.temperature"]
        info         <- map["result.realtime.info"]
        direct       <- map["result.realtime.direct"]
        power        <- map["result.realtime.power"]
        aqi          <- map["result.realtime.aqi"]
        future       <- map["result.future"]
        
        birthday     <- (map["birthday"], DateTransform())
        error_code   <- (map["error_code"], transform)
    }
}

class futureTemperature: Mappable {
    
    var date: String?
    var temperature: String?
    var weather: String?
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        date         <- map["date"]
        temperature  <- map["temperature"]
        weather      <- map["weather"]
    }
}
