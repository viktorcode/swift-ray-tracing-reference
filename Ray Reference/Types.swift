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
    var albedo = V3(repeating: 0)
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

    var A: V3
    var B: V3

    // NOTE: (Kapsy) For C union like behavior.
    var origin: V3 { get { return A } }
    var direction: V3 { get { return B } }

    init(_ A: V3, _ B: V3) {
        self.A = A
        self.B = B
    }

    init() {
        self.A = V3(repeating: 0)
        self.B = V3(repeating: 0)
    }
}

// MARK: Perlin
// NOTE: (Kapsy) This is an incomplete implementation!
struct Perlin {
    var permX: [Int]
    var permY: [Int]
    var permZ: [Int]

    let randFloat: [Float]

    init() {
        let N = PERLIN_N
        var random = Wyrand()

        self.permX = [Int](repeating: 0, count: PERLIN_N)
        self.permY = [Int](repeating: 0, count: PERLIN_N)
        self.permZ = [Int](repeating: 0, count: PERLIN_N)

        self.randFloat = (0..<N).map { _ in Float.random(in: 0..<1, using: &random) }

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

