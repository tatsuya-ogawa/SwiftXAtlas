//
//  File.swift
//  
//
//  Created by Tatsuya Ogawa on 2023/04/15.
//

import Foundation
import Metal
import CoreGraphics
public class TextureFromVertexColor{
    let textureWidth = 256
    let textureHeight = 256
    public struct Vertex {
        var position: SIMD4<Float32>
        var uv: SIMD2<Float32>
        var color: SIMD4<Float32>
        public init(position: SIMD4<Float32>, uv: SIMD2<Float32>, color: SIMD4<Float32>) {
            self.position = position
            self.uv = uv
            self.color = color
        }
    }
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    public init() {
    }
    public func setup()throws{
        guard let shadersUrl = Bundle.module.url(forResource: "shaders", withExtension: "metallib") else {
            throw NSError(domain: "resource not found", code: 0)
        }
        let source =  try String(contentsOf: shadersUrl)

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        let library = try device.makeLibrary(source: source, options: nil)
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm;
        //        let vertexDescriptor = MTLVertexDescriptor()
        //        vertexDescriptor.attributes[0].format = .float4
        //        vertexDescriptor.attributes[0].offset = 0
        //        vertexDescriptor.attributes[0].bufferIndex = 0
        //        vertexDescriptor.attributes[1].format = .float2
        //        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float32>>.stride
        //        vertexDescriptor.attributes[1].bufferIndex = 0
        //        vertexDescriptor.attributes[2].format = .float4
        //        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD4<Float32>>.stride + MemoryLayout<SIMD2<Float>>.size
        //        vertexDescriptor.attributes[2].bufferIndex = 0
        //        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        //        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        commandQueue = device.makeCommandQueue()
    }
    public func draw(vertices:[Vertex],indices:[UInt32])->CGImage?{
        guard let device = self.device else {
            return nil
        }
        
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return nil
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: textureWidth, height: textureHeight, mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return nil
        }
        encoder.setViewport(MTLViewport(originX: 0,
                                        originY: 0,
                                        width: Double(textureWidth),
                                        height: Double(textureHeight),
                                        znear: 0.0,
                                        zfar: 1.0))
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: [])
        
        encoder.setRenderPipelineState(pipelineState!)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt32>.size, options: [])
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint32, indexBuffer: indexBuffer!, indexBufferOffset: 0)
        
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return image(from: texture)
    }
    func image(from mtlTexture: MTLTexture) -> CGImage? {
        let w = mtlTexture.width
        let h = mtlTexture.height
        let bytesPerPixel: Int = 4
        let imageByteCount = w * h * bytesPerPixel
        let bytesPerRow = w * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        let region = MTLRegionMake2D(0, 0, w, h)
        mtlTexture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src,
                                width: w,
                                height: h,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        return context?.makeImage()
    }
}
