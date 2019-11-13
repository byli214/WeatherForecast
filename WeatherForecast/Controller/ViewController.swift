//
//  ViewController.swift
//  WeatherForecast
//
//  Created by ek on 2019/10/17.
//  Copyright © 2019 ek. All rights reserved.
//

import UIKit
import ObjectMapper

class ViewController: UIViewController {

    
    @IBOutlet weak var cityName: UITextField!
    
    @IBOutlet weak var todayTemperature: UILabel!
    @IBOutlet weak var todayInfo: UILabel!
    @IBOutlet weak var todayDirect: UILabel!
    @IBOutlet weak var todayPower: UILabel!
    @IBOutlet weak var todayAqi: UILabel!
    
    @IBOutlet weak var future1Date: UILabel!
    @IBOutlet weak var future1Temperature: UILabel!
    @IBOutlet weak var futrue1Info: UILabel!
    
    @IBOutlet weak var future2Date: UILabel!
    @IBOutlet weak var future2Temperature: UILabel!
    @IBOutlet weak var future2Info: UILabel!
    
    @IBOutlet weak var future3Date: UILabel!
    @IBOutlet weak var future3Temperature: UILabel!
    @IBOutlet weak var future3Info: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    @IBAction func cityNameEntered(_ sender: UITextField) {
        print("cin")
        //        let textField = sender as! UITextField
        if let text = sender.text {
            let param = ["key": "916a101d4abb0c1b02a411ef87db8c5e", "city": "\(text)"]
            NetworkTools.shared.requestData(URLString: "http://apis.juhe.cn/simpleWeather/query", type: .post, parameters: param) { (result) in
                print(result)
                if let str = String(data: result as! Data, encoding: .utf8), let model = temperatureQueried(JSONString: str){
                    self.todayTemperature.text = model.temperature
                    self.todayInfo.text = model.info
                    self.todayDirect.text = model.direct
                    self.todayPower.text = model.power
                    self.todayAqi.text = model.aqi
                    if let future = model.future {
                        self.future1Date.text = future[0].date
                        self.future1Temperature.text = model.future![0].temperature
                        self.futrue1Info.text = future[0].weather
                        
                        self.future2Date.text = future[1].date
                        self.future2Temperature.text = model.future![1].temperature
                        self.future2Info.text = future[1].weather
                        
                        self.future3Date.text = future[2].date
                        self.future3Temperature.text = model.future![2].temperature
                        self.future3Info.text = future[2].weather
                    }
                    
                    
//                    model.birthday = Date()
//                    let jsonStr = model.toJSONString(prettyPrint: true)
//                    print(jsonStr!)
                    if let birthday = model.birthday {
                        print("生日: \(birthday)")
                    }
                    if let code = model.error_code {
                        print("code = \(code)")
                    }
                }
            }
            
        }
    }
    
}

class dateToday: Mappable {
    
    var date = Date()

    required init?(map: Map) {}
    
    func mapping(map: Map) {
        date    <- (map["date"], DateTransform())
    }
    
    
    
    
}
