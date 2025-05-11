//
//  File.swift
//
//
//  Created by Tatsuya Ogawa on 2023/04/15.
//

import CoreGraphics
import Foundation
import Metal
import MetalKit
import simd

public class ProjectionTextureBaker {
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var textureCache: CVMetalTextureCache?
    fileprivate func makeTextureCache() -> CVMetalTextureCache {
        // Create captured image texture cache
        guard let device = self.device else {
            fatalError("Metal device is nil")
        }
        var cache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)

        return cache
    }
    public init() {
    }
    public func setup() throws {
        guard
            let shadersUrl = Bundle.module.url(
                forResource: "projection_baker_shaders",
                withExtension: "metallib"
            )
        else {
            throw NSError(domain: "resource not found", code: 0)
        }
        let source = try String(contentsOf: shadersUrl)

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        let library = try device.makeLibrary(source: source, options: nil)
        let vertexFunction = library.makeFunction(
            name: "projectionVertexShader"
        )
        let fragmentFunction = library.makeFunction(
            name: "projectionFragmentShader"
        )
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction

        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        pipelineState = try! device.makeRenderPipelineState(
            descriptor: pipelineDescriptor
        )
        commandQueue = device.makeCommandQueue()
        textureCache = makeTextureCache()
    }
    public func getOutputTexture(
        textureWidth: Int = 256,
        textureHeight: Int = 256
    ) -> MTLTexture? {
        guard let device = self.device else {
            return nil
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: textureWidth,
            height: textureHeight,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        return device.makeTexture(descriptor: textureDescriptor)
    }
    public func makeTexture(
        from image: UIImage,
        usage: MTLTextureUsage = .shaderRead
    ) throws -> MTLTexture? {
        guard let cgImage = image.cgImage else { return nil }
        guard let device = self.device else {
            return nil
        }
        let loader = MTKTextureLoader(device: device)

        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: usage.rawValue),
            .textureStorageMode: NSNumber(
                value: MTLStorageMode.private.rawValue
            ),
            .SRGB: false,
        ]

        let texture = try loader.newTexture(
            cgImage: cgImage,
            options: options
        )
        return texture
    }
    public func draw(
        vertices: [SIMD3<Float>],
        uvs: [SIMD2<Float>],
        indices: [UInt32],
        worldToCameraMatrix: matrix_float4x4,
        viewProjMatrix: matrix_float4x4,
        colorTexture: MTLTexture,
        outputTexture: MTLTexture
    ) -> MTLTexture? {
        guard let device = self.device else {
            return nil
        }
        guard let commandQueue = self.commandQueue else {
            return nil
        }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }
        guard let pipelineState = self.pipelineState else {
            return nil
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: {
                    let rpd = MTLRenderPassDescriptor()
                    rpd.colorAttachments[0].texture = outputTexture
                    // 既存内容を読み込む
                    rpd.colorAttachments[0].loadAction = .load
                    rpd.colorAttachments[0].storeAction = .store
                    return rpd
                }()
            )
        else { return nil }

        // ビューポート
        encoder.setViewport(
            MTLViewport(
                originX: 0,
                originY: 0,
                width: Double(outputTexture.width),
                height: Double(outputTexture.height),
                znear: 0,
                zfar: 1
            )
        )
        encoder.setRenderPipelineState(pipelineState)

        // バッファ 0: 頂点位置
        let vBuf = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SIMD3<Float>>.stride * vertices.count,
            options: []
        )!
        encoder.setVertexBuffer(vBuf, offset: 0, index: 0)

        // バッファ 1: 出力 UV
        let uvBuf = device.makeBuffer(
            bytes: uvs,
            length: MemoryLayout<SIMD2<Float>>.stride * uvs.count,
            options: []
        )!
        encoder.setVertexBuffer(uvBuf, offset: 0, index: 1)

        // バッファ 2: ビュー×プロジェクション行列
        var m = viewProjMatrix
        let mBuf = device.makeBuffer(
            bytes: &m,
            length: MemoryLayout<matrix_float4x4>.stride,
            options: []
        )!
        encoder.setVertexBuffer(mBuf, offset: 0, index: 2)
        
        // バッファ 3: world to camera matrix
        var c = worldToCameraMatrix
        let cBuf = device.makeBuffer(
            bytes: &c,
            length: MemoryLayout<matrix_float4x4>.stride,
            options: []
        )!
        encoder.setVertexBuffer(cBuf, offset: 0, index: 2)

        // テクスチャ 0: 投影元カラー
        encoder.setFragmentTexture(colorTexture, index: 0)

        // インデックス描画
        let iBuf = device.makeBuffer(
            bytes: indices,
            length: MemoryLayout<UInt32>.size * indices.count,
            options: []
        )!
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indices.count,
            indexType: .uint32,
            indexBuffer: iBuf,
            indexBufferOffset: 0
        )

        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return outputTexture
    }
    func image(from mtlTexture: MTLTexture) -> CGImage? {
        let w = mtlTexture.width
        let h = mtlTexture.height
        let bytesPerPixel: Int = 4
        let imageByteCount = w * h * bytesPerPixel
        let bytesPerRow = w * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        let region = MTLRegionMake2D(0, 0, w, h)
        mtlTexture.getBytes(
            &src,
            bytesPerRow: bytesPerRow,
            from: region,
            mipmapLevel: 0
        )
        let bitmapInfo = CGBitmapInfo(
            rawValue: (CGBitmapInfo.byteOrder32Big.rawValue
                | CGImageAlphaInfo.premultipliedLast.rawValue)
        )
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(
            data: &src,
            width: w,
            height: h,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        return context?.makeImage()
    }
}
