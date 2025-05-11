//
//  File.swift
//  
//
//  Created by Tatsuya Ogawa on 2023/04/16.
//

import Foundation
import XAtlasObjc
import simd
public typealias SwiftIndexFormat = IndexFormat
public protocol SwiftXAtlasArgument :XAtlasArgument{
    func indexFormat()->SwiftIndexFormat;
}
public protocol SwiftXAtlasUVProtocol{
    var uv:simd_float2 { get set }
}
public protocol SwiftXAtlasBatchUVProtocol{
    func setUv(index:UInt32,uv:simd_float2)
}
public class SwiftXAtlasMesh:XAtlasMesh{
    public var mappings:[UInt32] = []
    public var uvs:[simd_float2] = []
    public var indices:[simd_uint3] = []
    fileprivate func fillArray(){
        mappings = Array(UnsafeBufferPointer(start: self.mappingsPointer()!, count: self.vertexCount))
        uvs = Array(UnsafeBufferPointer(start: self.uvsPointer()!, count: self.vertexCount))
        indices = Array(UnsafeBufferPointer(start: self.indicesPointer()!, count: self.indicesCount))
    }
    public func reArrange<T>(points:[T])->[T]{
        return mappings.map{points[Int($0)]}
    }
    public func applyUv<T:SwiftXAtlasUVProtocol>(points:[T])->[T]{
        return mappings.enumerated().map{(index,map) in
            var point = points[Int(map)]
            point.uv = uvs[index]
            return point
        }
    }
    public func applyUvs<T:SwiftXAtlasBatchUVProtocol>(mesh:T){
        mappings.enumerated().forEach{(index,map) in
            mesh.setUv(index: map, uv: uvs[index])
        }
    }
}
public class SwiftXAtlas:XAtlas{
    public override func mesh(at:Int)->SwiftXAtlasMesh{
        let mesh = SwiftXAtlasMesh()
        super.mesh(at: at, fill: mesh)
        mesh.fillArray()
        mesh.clearCache()
        return mesh
    }
}
