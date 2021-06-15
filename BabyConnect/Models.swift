//
//  Models.swift
//  BabyConnect
//
//  Created by Mithun Das on 5/14/21.
//

import Foundation

final class Card: Codable{
    var name: String
    var icon: String
    var description: String
    var id: Int
    var cards: [Card]?
    var frames: String?
    var level: Int?
    
    init(id: Int, name: String, icon: String, description: String){
        self.name = name
        self.icon = icon
        self.description = description
        self.id = id
    }
    
    func getCode() -> String{
        var m0:String = ""
        var m1:String = ""
        var m2:String = ""
        var m3:String = ""
        
        
        let splitted = self.frames!.components(separatedBy: ";")
        for s in splitted {
            
            let motors = s.components(separatedBy: ",")
            
            
            
            if Int(motors[0]) == 255{
                m0 = "\(m0) _ "
            }else if Int(motors[0]) == 50 {
                m0 = "\(m0)  .  "
            }else{
                m0 = "\(m0)    "
            }
            
            if Int(motors[1]) == 255{
                m1 = "\(m1) _ "
            }else if Int(motors[1]) == 50 {
                m1 = "\(m1)  .  "
            }else{
                m1 = "\(m1)    "
            }
            
            if Int(motors[2]) == 255{
                m2 = "\(m2) _ "
            }else if Int(motors[2]) == 50 {
                m2 = "\(m2)  .  "
            }else{
                m2 = "\(m2)    "
            }
            
            if Int(motors[3]) == 255{
                m3 = "\(m3) _ "
            }else if Int(motors[3]) == 50 {
                m3 = "\(m3)  .  "
            }else{
                m3 = "\(m3)    "
            }
            
        }
        
        return "\(m0)\n\(m1)\n\(m2)\n\(m3)"
    }
    
    func getPeriodFrame() -> [UInt8] {
        var buzzFrames: [UInt8] = []
        let counter = 20
        for _ in 1...counter{
            
            for _ in 0...3{
                buzzFrames.append(0)
            }
            
        }
        
        return buzzFrames
    }
    
    func getFrames() -> [[UInt8]] {
        let counter = 20
        var allFrames: [[UInt8]] = []
        
        let splitted = self.frames!.components(separatedBy: ";")
        for s in splitted {
            var buzzFrames: [UInt8] = []
            let motors = s.components(separatedBy: ",")
            
            for _ in 0..<counter{
                buzzFrames.append(UInt8(motors[0])!)
                buzzFrames.append(UInt8(motors[1])!)
                buzzFrames.append(UInt8(motors[2])!)
                buzzFrames.append(UInt8(motors[3])!)
            }
            
            allFrames.append(buzzFrames)
            
        }
        
        return allFrames
    }
}


class  Vibrate: Codable {
    
    var motor1: Int
    var motor2: Int
    var motor3: Int
    var motor4: Int
    
    init(motor1: Int, motor2: Int, motor3: Int, motor4: Int) {
        self.motor1 = motor1
        self.motor2 = motor2
        self.motor3 = motor3
        self.motor4 = motor4
    }
    
    
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
