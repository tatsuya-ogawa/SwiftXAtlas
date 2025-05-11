//
//  BunnyViewController.swift
//  ExampleApp
//
//  Created by Tatsuya Ogawa on 2023/04/15.
//

import UIKit

import SwiftStanfordBunny
import simd
import SwiftXAtlas

class BunnyXAtlasArgument:SwiftXAtlasArgument{
    var points:[BunnyPoint]
    var indices:[UInt32]
    
    func indexFormat()->SwiftIndexFormat{
        return .uint32
    }
    
    func vertexCount() -> UInt32 {
        return UInt32(self.points.count)
    }
    
    func vertexPositionData() -> UnsafeRawPointer {
        return UnsafeRawPointer(self.points)
    }
    
    func vertexPositionStride() -> UInt32 {
        return UInt32(MemoryLayout<BunnyPoint>.stride)
    }
    
//    func vertexNormalData() -> UnsafeRawPointer? {
//        return UnsafeRawPointer(self.points).advanced(by: MemoryLayout<SIMD3<Float>>.stride)
//    }
//    func vertexNormalStride() -> UInt32 {
//        return UInt32(MemoryLayout<Point>.stride)
//    }
    func indexCount() -> UInt32 {
        return UInt32(indices.count)
    }
    func indexData() -> UnsafePointer<UInt32> {
        return UnsafePointer(self.indices)
    }
    init(points:[BunnyPoint],indices:[[Int]]){
        self.points = points
        self.indices = indices.flatMap{$0.map{UInt32($0)}}
    }
}
struct BunnyPoint:BunnyPointProtocol,SwiftXAtlasUVProtocol{
    var pos: SIMD3<Float32>
    var normal: SIMD3<Float32>
    var color: SIMD4<Float32>
    var uv: SIMD2<Float32>
    init(pos: SIMD3<Float32>, normal: SIMD3<Float>, uv: SIMD2<Float>) {
        self.pos = pos
        self.normal = normal
        self.color = SIMD4<Float>.zero
        self.uv = uv
    }
}

class BunnyViewController: UIViewController {
    func boundingBox(positions:[SIMD3<Float>])->(min:SIMD3<Float>,max:SIMD3<Float>){
        var min:SIMD3<Float> = SIMD3<Float>.one * Float.greatestFiniteMagnitude
        var max:SIMD3<Float> = SIMD3<Float>.one * Float.leastNormalMagnitude
        for p in positions{
            min = simd_min(min,p)
            max = simd_max(max,p)
        }
        return (min,max)
    }
    func drawOrigin(){
        let bunny = SwiftStanfordBunny<BunnyPoint>.instance()
        let (originalPoints,faces) = try! bunny.load()
        let texture = VertexColorTextureBaker()
        try! texture.setup()
        
        var vertices = originalPoints.map{p in
            let color = simd_normalize(SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0))
            let uv = (p.uv - SIMD2<Float32>(0.5,0.5))*2
            return VertexColorTextureBaker.Argument(position: SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0), uv: uv, color: color)
        }
        var indices = faces.flatMap{$0.map{UInt32($0)}}
        
        let image = texture.draw(vertices: vertices, indices: indices)
        let imageView = UIImageView(image:UIImage(cgImage: image!))
        imageView.frame = self.view.frame
        self.view.addSubview(imageView)
    }
    func draw(){
        DispatchQueue.global().async{
            let bunny = SwiftStanfordBunny<BunnyPoint>.instance()
            let (originalPoints,faces) = try! bunny.load()
            
            var vertices = originalPoints.map{p in
                let color = simd_normalize(SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0))
                let uv = (p.uv - SIMD2<Float32>(0.5,0.5))*2
                return VertexColorTextureBaker.Argument(position: SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0), uv: uv, color: color)
            }
            var indices = faces.flatMap{$0.map{UInt32($0)}}
            let xatlas = SwiftXAtlas()
            xatlas.generate([BunnyXAtlasArgument(points: originalPoints, indices: faces)])
            let mesh = xatlas.mesh(at: 0)
            
            let points = mesh.applyUv(points: originalPoints)
            var bb = self.boundingBox(positions: points.map{$0.pos})
            vertices = points.map{p in
                let n = p.pos-bb.min
                let uv = (p.uv - SIMD2<Float>(0.5,0.5))*2
                let color = simd_normalize(SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0))
                return VertexColorTextureBaker.Argument(position: SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0), uv: uv, color: color)
            }
            indices = mesh.indices.flatMap{[$0.x,$0.y,$0.z]}
            DispatchQueue.main.async {
                let texture = VertexColorTextureBaker()
                try! texture.setup()
                let image = texture.draw(vertices: vertices, indices: indices)
                let imageView = UIImageView(image: UIImage(cgImage: image!))
                imageView.frame = self.view.frame
                self.view.addSubview(imageView)
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        draw()
    }
}

