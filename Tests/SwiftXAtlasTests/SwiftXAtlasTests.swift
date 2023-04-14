import XCTest
import SwiftStanfordBunny
@testable import SwiftXAtlas

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
    var color: SIMD4<UInt8>
    init(pos: SIMD3<Float>, normal: SIMD3<Float>, color: SIMD4<UInt8>) {
        self.pos = pos
        self.normal = normal
        self.color = color
    }
}

final class SwiftXAtlasTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let bunny = SwiftStanfordBunny<Point>.instance()
        let (points,faces) = try! bunny.load()
        let xatlas = XAtlas()
        xatlas.generate([ExampleArgument(points: points, indices: faces)])
        let mesh = xatlas.mesh(at: 0)
        XCTAssertEqual(mesh!.indices.count,faces.count)
        XCTAssertEqual(mesh!.mappings.count,mesh!.uvs.count/2)
    }
}
