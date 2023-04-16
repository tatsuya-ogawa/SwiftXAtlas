//
//  ViewController.swift
//  ExampleApp
//
//  Created by Tatsuya Ogawa on 2023/04/15.
//

import UIKit

import SwiftStanfordBunny
import SwiftXAtlas
import simd

class ExampleArgument:XAtlasArgument{
    
    var points:[Point]
    var indices:[UInt32]
    
    func indexFormat() -> IndexFormat {
        return IndexFormat.uint32
    }
    
    func vertexCount() -> UInt32 {
        return UInt32(self.points.count)
    }
    
    func vertexPositionData() -> UnsafeRawPointer {
        return UnsafeRawPointer(self.points)
    }
    
    func vertexPositionStride() -> UInt32 {
        return UInt32(MemoryLayout<Point>.stride)
    }
    
    func vertexNormalData() -> UnsafeRawPointer {
        return UnsafeRawPointer(self.points).advanced(by: MemoryLayout<SIMD3<Float>>.stride)
    }
    func vertexNormalStride() -> UInt32 {
        return UInt32(MemoryLayout<Point>.stride)
    }
    func indexCount() -> UInt32 {
        return UInt32(indices.count/3)
    }
    func indexData() -> UnsafePointer<UInt32> {
        return UnsafePointer(self.indices)
    }
    init(points:[Point],indices:[[Int]]){
        self.points = points
        self.indices = indices.flatMap{$0.map{UInt32($0)}}
    }
}
struct Point:BunnyPointProtocol{
    var pos: SIMD3<Float>
    var normal: SIMD3<Float>
    var color: SIMD4<Float>
    var uv: SIMD2<Float>
    init(pos: SIMD3<Float>, normal: SIMD3<Float>, color: SIMD4<Float>, uv: SIMD2<Float>) {
        self.pos = pos
        self.normal = normal
        self.color = color
        self.uv = uv
    }
}

class ViewController: UIViewController {
    func boundingBox(positions:[SIMD3<Float>])->(min:SIMD3<Float>,max:SIMD3<Float>){
        var min:SIMD3<Float> = SIMD3<Float>.one * Float.greatestFiniteMagnitude
        var max:SIMD3<Float> = SIMD3<Float>.one * Float.leastNormalMagnitude
        for p in positions{
            min = simd_min(min,p)
            max = simd_max(max,p)
        }
        return (min,max)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let bunny = SwiftStanfordBunny<Point>.instance()
        let (points,faces) = try! bunny.load()
        let texture = TextureFromVertexColor()
        texture.setup()

        var vertices = points.map{p in
            var color = SIMD4<Float32>(1.0,1.0,1.0,1.0)
            let uv = (p.uv - SIMD2<Float32>(0.5,0.5))*2
            return TextureFromVertexColor.Vertex(position: SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0), uv: uv, color: color)
        }
        var indices = faces.flatMap{$0.map{UInt32($0)}}
//        vertices = [
//            TextureFromVertexColor.Vertex(position: SIMD4<Float32>.zero, uv: SIMD2<Float>(100,0), color: SIMD4<Float>(1,0,0,1)),
//            TextureFromVertexColor.Vertex(position: SIMD4<Float32>.zero, uv: SIMD2<Float>(-100,0), color: SIMD4<Float>(0,1,0,1)),
//            TextureFromVertexColor.Vertex(position: SIMD4<Float32>.zero, uv: SIMD2<Float>(0,100), color: SIMD4<Float>(0,0,1,1)),
//        ]
//        indices = [0,1,2]
        let image = texture.draw(vertices: vertices, indices: indices)

//        let image = texture.draw(vertices: vertices, indices: faces.flatMap{$0.map{UInt32($0)}})
        //        let xatlas = XAtlas()
        //        xatlas.generate([ExampleArgument(points: points, indices: faces)])
        //        let mesh = xatlas.mesh(at: 0)
        //        var bb = self.boundingBox(positions: points.map{$0.pos})
        //        var vertices = points.map{p in
        //            let n = p.pos-bb.min
        //            var color = SIMD4<Float32>(1.0,1.0,1.0,1.0)
        //            return TextureFromVertexColor.Vertex(position: SIMD4<Float32>( p.pos.x,p.pos.y,p.pos.z,1.0), uv: SIMD2<Float32>.zero, color: color)
        //        }
        //        for (index,mapping) in mesh!.mappings.enumerated(){
        //            var uv = SIMD2<Float32>(Float32(truncating: mesh!.uvs[index*2]),Float32(truncating: mesh!.uvs[index*2+1]))
        //            uv = (uv - SIMD2<Float32>(0.5,0.5))*2
        //            vertices[Int(UInt(mapping.int32Value))].uv = uv
        //        }
        //        let image = texture.draw(vertices: vertices, indices: mesh!.indices.map{UInt32(truncating: $0)})
        let imageView = UIImageView(image: image)
        imageView.frame = self.view.frame
        self.view.addSubview(imageView)
    }
    
    
}

