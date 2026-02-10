//
//  Types.swift
//  Ray Reference
//
//  Created by Viktor Chernikov on 13.09.25.
//

import Foundation

// MARK: Texture

enum TextureType {
    case plain
    case checker
    case perlin(Int)
}

struct Texture {
    var type: TextureType = .plain
    var albedo = V3()
}

// MARK: Material

enum MaterialType {
    case lambertian
    case metal(fuzz: Float)
    case dielectric(refIndex: Float)
}

struct Material {
    let type: MaterialType
    let texture: Texture

    init(type: MaterialType, texture: Texture) {
        self.type = type
        self.texture = texture
    }
}

// MARK: Sphere

struct Sphere {
    let center: V3
    let radius: Float
    let material: Material
}

enum PrimativeType {
    case sphere
    case triangle
}

// MARK: Camera

struct Camera {
    var origin: V3 = V3()
    var lowerLeft: V3 = V3()
    var horiz: V3 = V3()
    var vert: V3 = V3()

    var w: V3 = V3()
    var u: V3 = V3()
    var v: V3 = V3()

    var lensRad: Float = 0
}

// MARK: Ray

struct HitRecord {
    var distance = Float(0)
    var primRef: Sphere? = nil
    var primType: PrimativeType = .sphere
}

struct Ray {
    var origin: V3
    var direction: V3

    init(_ A: V3, _ B: V3) {
        self.origin = A
        self.direction = B
    }

    init() {
        self.origin = V3()
        self.direction = V3()
    }
}

// MARK: Perlin
// NOTE: (Kapsy) This is an incomplete implementation!
struct Perlin {
    var permX: ContiguousArray<Int> = .init(repeating: 0, count: PERLIN_N)
    var permY: ContiguousArray<Int> = .init(repeating: 0, count: PERLIN_N)
    var permZ: ContiguousArray<Int> = .init(repeating: 0, count: PERLIN_N)

    let randFloat: ContiguousArray<Float>

    init() {
        let N = PERLIN_N
        var random = Wyrand()

        self.randFloat = ContiguousArray((0..<N).map { _ in Float.random(in: 0..<1, using: &random) })

        for i in 0..<N {
            self.permX[i] = i
            self.permY[i] = i
            self.permZ[i] = i
        }

        for i in (0..<N).reversed() {
            permuteAxis(&self.permX, i, using: &random)
            permuteAxis(&self.permY, i, using: &random)
            permuteAxis(&self.permZ, i, using: &random)
        }
    }
}

struct SceneModel {
    let spheres: ContiguousArray<Sphere>
    let perlin: ContiguousArray<Perlin>
}

