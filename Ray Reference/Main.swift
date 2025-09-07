import Foundation

// MARK: Perlin Noise

let PERLIN_N: Int = (1 << 8)

func permuteAxis(_ axis: inout [Int], _ i: Int, using generator: inout some RandomNumberGenerator) {
    let tar = Int(Float.random(in: 0..<1, using: &generator) * Float(i + 1))
    let tmp = axis[i]
    axis[i] = axis[tar]
    axis[tar] = tmp
}

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

extension Perlin {
    func getNoise(_ p0: V3) -> Float {

        let p1 = p0 * 20.0

        let u = Float(p1.x - floor(p1.x))
        let v = Float(p1.y - floor(p1.y))
        let w = Float(p1.z - floor(p1.z))

        let i = Int(floor(p1.x))
        let j = Int(floor(p1.y))
        let k = Int(floor(p1.z))

        var c: InlineArray<8, Float> = .init(repeating: 0)

        for di in 0..<2 {
            for dj in 0..<2 {
                for dk in 0..<2 {
                    c[di * 4 + dj * 2 + dk] =
                    randFloat[permX[(i+di) & (PERLIN_N - 1)] ^
                              permY[(j+dj) & (PERLIN_N - 1)] ^
                              permZ[(k+dk) & (PERLIN_N - 1)]]
                }}}

        var accum = Float(0.0)

        for i in 0..<2 {
            for j in 0..<2 {
                for k in 0..<2 {
                    let I = (Float(i)*u + (1.0 - Float(i))*(1.0 - u))
                    let J = (Float(j)*v + (1.0 - Float(j))*(1.0 - v))
                    let K = (Float(k)*w + (1.0 - Float(k))*(1.0 - w))

                    accum += I * J * K * Float(c[i * 4 + j * 2 + k])
                }}}

        assert(accum <= 1.0)

        return accum
    }
}
// MARK: Texture

enum TextureType {
    case plain
    case checker
 //   case perlin(Perlin)
}

struct Texture {
    var type: TextureType = .plain
    var albedo = V3(0)
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

extension Texture {
    func getAlbedo(_ u: Float, _ v: Float, _ p: V3) -> V3 {
        let res: V3

        switch type {
        case .checker:
            let selector = Float(sin(10.0 * p.x) * sin(10.0 * p.z))
            if selector > 0.0 {
                res = V3(0,0,0)
            } else {
                res = V3(1.0,1.0,1.0)
            }

        case .plain:
            res = albedo

//        case .perlin(let perlin):
//            res = V3(1.0) * perlin.getNoise(p)
        }

        return res
    }
}

func schlick(_ cos: Float, _ refIndex: Float) -> Float {
    var r0 = (1.0 - refIndex) / (1.0 + refIndex);
    r0 = r0 * r0;
    r0 = r0 + (1.0 - r0) * pow((1.0 - cos), 5.0);

    return r0
}

func reflect(_ v: V3, _ N: V3) -> V3 {
    v - 2 * dot(v, N) * N
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
        self.A = V3(0)
        self.B = V3(0)
    }
}

extension Camera {
    func getRay(_ s: Float, _ t: Float, random: inout some RandomNumberGenerator) -> Ray {
        // NOTE: (Kapsy) Random in unit disk.
        var rand = V3(0)
        repeat  {
            rand = 2.0 * V3(Float.random(in: 0..<1, using: &random), Float.random(in: 0..<1, using: &random), 0) - V3(1,1,0)
        } while dot(rand, rand) >= 1.0

        let rd = lensRad * rand;
        let offset = u * rd.x + v * rd.y

        let res = Ray(origin + offset, lowerLeft + s * horiz + t * vert - origin - offset)
        return res
    }
}

extension Ray {
    func pointAt(_ t: Float) -> V3 {
        A + t * B
    }
}

extension Array where Element == Sphere {
    func traverseSpheres(_ ray: inout Ray, _ hit: inout HitRecord) {

        let tnear = Float(0.001)
        var tfar = Float.greatestFiniteMagnitude

        for sphere in self {

            let rad = sphere.radius
            let center = sphere.center
            let oc = ray.origin - center

            let a = dot(ray.direction, ray.direction)
            let b = dot(oc, ray.direction)
            let c = dot(oc, oc) - rad * rad
            let discriminant = b * b - a * c;

            if discriminant > 0.0 {
                let discriminantRoot = sqrt(discriminant)
                var t = (-b - discriminantRoot) / a
                if (tnear < t && t < tfar)
                {
                    tfar = t

                    hit.distance = t;
                    hit.primRef = sphere
                    hit.primType = .sphere;
                }

                t = (-b + discriminantRoot) / a
                if (tnear < t && t < tfar)
                {
                    tfar = t

                    hit.distance = t;
                    hit.primRef = sphere
                    hit.primType = .sphere;
                }
            }
        }
    }
}

let MAX_DEPTH = Int(10)

extension Array where Element == Sphere {
    func getColorForRay(_ ray: inout Ray, _ depth: Int, using random: inout some RandomNumberGenerator) -> V3 {

        var res = V3()

        var hit = HitRecord()
        hit.distance = Float.greatestFiniteMagnitude

        traverseSpheres(&ray, &hit)

        if hit.distance < Float.greatestFiniteMagnitude {

            var p = V3(0)
            var N = V3(0)
            var mat: Material? = nil;

            switch hit.primType {

            case .sphere:

                if let sphere = hit.primRef {

                    let rad = sphere.radius
                    let center = sphere.center

                    p = ray.pointAt(hit.distance)
                    N = (p - center) / rad
                    mat = sphere.material
                }

            case .triangle:
                break
            }

            if let mat {

                switch mat.type {

                case .lambertian:

                    let rand = randomInUnitSphere(using: &random)
                    let target = p + N + rand
                    let albedo = mat.texture.getAlbedo(0, 0, p)
                    var scattered = Ray(p, target - p)

                    if depth < MAX_DEPTH {
                        res = albedo * getColorForRay(&scattered, depth + 1, using: &random)
                    } else {
                        res = V3()
                    }

                case .metal(let fuzz):

                    let v = unit(ray.direction)
                    let reflected = v - 2*dot(v, N)*N
                    let bias = N*1e-4

                    var scattered = Ray(p + bias, reflected + fuzz * randomInUnitSphere(using: &random))

                    let albedo = mat.texture.getAlbedo(0, 0, p)

                    // NOTE: (Kapsy) Direction between normal and reflection should never be more than 90 deg.
                    let result = (dot(scattered.direction, N) > 0.0)
                    if (depth < MAX_DEPTH && result) {
                        res = albedo * getColorForRay(&scattered, depth + 1, using: &random)
                    } else {
                        res = V3()
                    }

                case .dielectric(let refIndex):

                    var scattered = Ray()

                    var outwardNormal = V3(0)
                    var niOverNt = Float(0)
                    let reflected = reflect(ray.direction, N)

                    var reflectProb = Float(0)
                    var cos = Float(0)

                    if dot(ray.direction, N) > 0.0 {
                        outwardNormal = -N
                        niOverNt = refIndex
                        cos = refIndex*dot(ray.direction, N)/length(ray.direction)
                    }
                    else
                    {
                        outwardNormal = N
                        niOverNt = 1.0 / refIndex
                        cos = -dot(ray.direction, N) / length(ray.direction)
                    }

                    var refracted = V3()

                    let bias = outwardNormal*1e-2
                    p = p - bias

                    let uv = unit(ray.direction)
                    let dt = dot(uv, outwardNormal)
                    let discriminant = 1.0 - niOverNt*niOverNt*(1.0 - dt*dt)

                    // NOTE: (Kapsy) Approximate reflection/refraction probability.
                    if discriminant > 0.0 {
                        refracted = niOverNt*(uv - outwardNormal*dt) - outwardNormal * sqrt(discriminant)
                        reflectProb = schlick(cos, refIndex)
                    } else {
                        scattered = Ray(p, reflected)
                        reflectProb = 1.0
                    }

                    if Float.random(in: 0..<1, using: &random) < reflectProb {
                        scattered = Ray(p, reflected)
                    } else {
                        scattered = Ray(p, refracted)
                    }

                    if depth < MAX_DEPTH {
                        res = getColorForRay(&scattered, depth + 1, using: &random)
                    } else {
                        res = V3()
                    }
                }
            }

        } else {

            // NOTE: (Kapsy) Draw our psuedo sky background.
            let rdir = ray.direction

            let t = (unit(rdir).y + 1.0)*0.5
            let cola = V3(1.0)
            let colb = (1.0/255.0) * V3(255.0, 128.0, 0.0)

            res = (1.0 - t)*cola + t*colb
        }

        return res
    }
}

extension ContentView {
    func setup() -> [Sphere] {
        // MARK: Init spheres
        var spheres: [Sphere] = []

//        var perlinTexture = Texture()
//        perlinTexture.albedo = V3(1,1,1)
//        perlinTexture.type = .perlin(Perlin())
//        let sphere0Mat = Material(type: .lambertian, texture: perlinTexture)
//        let sphere0 = Sphere(center: V3(0, 0.32, 0), radius: 0.34, material: sphere0Mat)
//        spheres.append(sphere0)

        var glassTexture = Texture()
        glassTexture.albedo = V3(1)
        let sphere1Mat = Material(type: .dielectric(refIndex: 1.1), texture: glassTexture)
        let sphere1 = Sphere(center: V3(0.53, 0.3, -0.33), radius: -0.23, material: sphere1Mat)
        spheres.append(sphere1)

        var whiteTexture = Texture()
        whiteTexture.albedo = V3(1,0.97,0.97)
        let sphere2Mat = Material(type: .metal(fuzz: 0.24), texture: whiteTexture)
        let sphere2 = Sphere(center: V3(-0.7, 0.3, 0), radius: 0.24, material: sphere2Mat)
        spheres.append(sphere2)

        var groundTexture = Texture()
        groundTexture.albedo = V3(0.2,0.5,0.3)
        groundTexture.type = .checker
        let sphere3Mat = Material(type: .lambertian, texture: groundTexture)
        let sphere3 = Sphere(center: V3(0, -99.99, 0), radius: 100.0, material: sphere3Mat)
        spheres.append(sphere3)

        var greenTexture = Texture()
        greenTexture.albedo = V3(0,1.3,0)
        let sphere4Mat = Material(type: .lambertian, texture: greenTexture)
        let sphere4 = Sphere(center: V3(0.0, 0.3, 0.5), radius: 0.13, material: sphere4Mat)
        spheres.append(sphere4)

        var redTexture = Texture()
        redTexture.albedo = V3(2,0.3,0.3)
        let sphere5Mat = Material(type: .lambertian, texture: redTexture)
        let sphere5 = Sphere(center: V3(0.1, 0.3, -0.6), radius: 0.16, material: sphere5Mat)
        spheres.append(sphere5)

        var purpleTexture = Texture()
        purpleTexture.albedo = V3(1,0,1)
        let sphere6Mat = Material(type: .metal(fuzz: 0.2), texture: purpleTexture)
        let sphere6 = Sphere(center: V3(0.68, 0.33, 0.79), radius: 0.33, material: sphere6Mat)
        spheres.append(sphere6)

        var blueTexture = Texture()
        blueTexture.albedo = V3(0.2,0.2,3)
        let sphere7Mat = Material(type: .lambertian, texture: blueTexture)
        let sphere7 = Sphere(center: V3(-0.5, 0.3, -0.9), radius: 0.13, material: sphere7Mat)
        spheres.append(sphere7)

        var purple2Texture = Texture()
        purple2Texture.albedo = V3(1,1,1)
        let sphere8Mat = Material(type: .dielectric(refIndex: 1.1), texture: purple2Texture)
        let sphere8 = Sphere(center: V3(-0.6, 0.24, 0.6), radius: 0.18, material: sphere8Mat)
        spheres.append(sphere8)

        var metalTexture = Texture()
        metalTexture.albedo = V3(0,1,1)
        let sphere9Mat = Material(type: .metal(fuzz: 0.3), texture: metalTexture)
        let sphere9 = Sphere(center: V3(0.5, 0.3, -0.9), radius: 0.10, material: sphere9Mat)
        spheres.append(sphere9)
        data.reserveCapacity(nx * ny)
        (0..<ny).forEach { _ in
            data.append([])
        }

        return spheres
    }

    func raytraceFrame(in scene: [Sphere]) async {
        // NOTE: (Kapsy) Primary rays per pixel
        let ns = Int(30)

        let startTime = CFAbsoluteTimeGetCurrent()

        // NOTE: (Kapsy) Camera setup stuff.
        var lookFromRes = lookFrom
        lookFromRes = lookFromRes*((-cos(ellipsePhase) + 1.0) * 0.07 + 1.3);

        let vup = V3(0.18, 1, 0)
        let vfov = Float(60)
        let aspect = Float(nx)/Float(ny)
        let aperture = Float(0.09)
        let focusDist = length(lookFromRes - lookAt)

        let theta = vfov*Float.pi/180
        let halfHeight = tan(theta/2)
        let halfWidth = Float(aspect*halfHeight)

        let w = unit(lookFromRes - lookAt)
        let u = unit(cross(vup, w))
        let v = cross(w, u)

        let camera = Camera(origin: lookFromRes,
                            lowerLeft: lookFromRes - halfWidth * focusDist * u - halfHeight * focusDist * v - focusDist * w,
                            horiz: 2 * halfWidth * focusDist * u,
                            vert: 2 * halfHeight * focusDist * v,
                            w: w, u: u, v: v,
                            lensRad: aperture/2.0)

        // Compute rows in parallel using a task group.
        let width = nx
        let height = ny
        var results: [(Int, [V3])] = []
        results.reserveCapacity(height)

        await withTaskGroup(of: (Int, [V3]).self) { group in
            for j in 0..<height {
                group.addTask {
                    var row: [V3] = []
                    row.reserveCapacity(width)
                    var random = Wyrand()
                    for i in 0..<width {
                        var col = V3(0)
                        for _ in 0..<ns {
                            let uVal = (Float(i) + Float.random(in: 0..<1, using: &random))/Float(width)
                            let vVal = (Float(j) + Float.random(in: 0..<1, using: &random))/Float(height)
                            var r = camera.getRay(uVal, vVal, random: &random)
                            col += scene.getColorForRay(&r, 0, using: &random)
                        }
                        col /= Float(ns)
                        col.r = clamp01(col.r)
                        col.g = clamp01(col.g)
                        col.b = clamp01(col.b)
                        row.append(col)
                    }
                    // Original code wrote rows in reversed order
                    let rowIndex = height - j - 1
                    return (rowIndex, row)
                }
            }

            for await result in group {
                results.append(result)
            }
        }

        // Apply results and update state on the main actor
        for (rowIndex, row) in results {
            data[rowIndex] = row
        }
        let raytracingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("Time spent raytracing: \(raytracingTime)s")

        // NOTE: (Kapsy) Rodrigues Rotation formula
        var vector = lookFrom
        vector = vector * cos(omega) + cross(k, vector) * sin(omega) + k * dot(k, v) * (1.0 - cos(omega))
        lookFrom = vector

        ellipsePhase += omega
    }
}
