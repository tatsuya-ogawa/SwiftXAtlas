import XCTest
@testable import SwiftXAtlas

class Argument:XAtlasArgument{
    func indexData() -> UnsafeRawPointer! {
    }
    
    func indexFormat() -> IndexFormat {
        IndexFormat.uint16
    }
    
    func vertexCount() -> UInt32 {
    }
    
    func vertexPositionData() -> UnsafeRawPointer! {
    }
    
    func vertexPositionStride() -> UInt32 {
    }
    
    func vertexNormalData() -> UnsafeRawPointer! {
    }
    
    func vertexNormalStride() -> UInt32 {
    }
    
    func indexCount() -> UInt32 {
    }
        
}

final class SwiftXAtlasTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let xatlas = XAtlas()        
//        XCTAssertEqual(SwiftXAtlas().text, "Hello, World!")
    }
}
