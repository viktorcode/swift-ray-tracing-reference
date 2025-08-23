//
//  Wyrand.swift
//  Ray Reference
//
//  Created by Viktor Chernikov on 23.08.25.
//

import Foundation

struct Wyrand: RandomNumberGenerator {
    private var state : UInt64

    init(seed: UInt64 = mach_absolute_time()) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x2d358dccaa6c78a5
        let mul = state.multipliedFullWidth(by: state ^ 0x8bb84b93962eacc9)
        return mul.low ^ mul.high
    }
}
