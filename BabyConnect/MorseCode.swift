//
//  MorseCode.swift
//  BabyConnect
//
//  Created by Mithun Das on 5/26/21.
//

enum MorseCode :String, CaseIterable {
    case A = ".-"
    case B = "-..."
    case C = "-.-."
    case D = "-.."
    case E = "."
    case F = "..-."
    case G = "--."
    case H = "...."
    case I = ".."
    case J = ".---"
    case K = "-.-"
    case L = ".-.."
    case M = "--"
    case N = "-."
    case O = "---"
    case P = ".--."
    case Q = "--.-"
    case R = ".-."
    case S = "..."
    case T = "-"
    case U = "..-"
    case V = "...-"
    case W = ".--"
    case X = "-..-"
    case Y = "-.--"
    case Z = "--.."
    
    var name: String {
            return Mirror(reflecting: self).children.first?.label ?? String(describing: self)
        }
}
