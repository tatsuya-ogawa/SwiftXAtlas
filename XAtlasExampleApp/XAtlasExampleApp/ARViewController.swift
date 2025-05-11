//
//  ARViewController.swift
//  XAtlasExampleApp
//
//  Created by Tatsuya Ogawa on 2025/05/10.
//

//
//  ExportViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/10.
//

import ARKit
import RealityKit
import SwiftXAtlas
import UIKit

class ARXAtlasArgument: SwiftXAtlasArgument, SwiftXAtlasBatchUVProtocol {
    func setUv(index: UInt32, uv: simd_float2) {
        self.uvs[Int(index)] = uv
    }

    var vertices: [SIMD3<Float>]
    var normals: [SIMD3<Float>]
    var indices: [UInt32]
    var uvs: [SIMD2<Float>]

    func indexFormat() -> SwiftIndexFormat {
        return .uint32
    }

    func vertexCount() -> UInt32 {
        return UInt32(self.vertices.count)
    }

    func vertexPositionData() -> UnsafeRawPointer {
        return UnsafeRawPointer(self.vertices)
    }

    func vertexPositionStride() -> UInt32 {
        return UInt32(MemoryLayout<SIMD3<Float>>.stride)
    }

    func vertexNormalData() -> UnsafeRawPointer? {
        return UnsafeRawPointer(self.normals)
    }

    func vertexNormalStride() -> UInt32 {
        return UInt32(MemoryLayout<SIMD3<Float>>.stride)
    }

    func indexCount() -> UInt32 {
        return UInt32(indices.count)
    }

    func indexData() -> UnsafePointer<UInt32> {
        return UnsafePointer(self.indices)
    }

    init(vertices: [SIMD3<Float>], normals: [SIMD3<Float>], indices: [[UInt32]])
    {
        self.vertices = vertices
        self.normals = normals
        self.indices = indices.flatMap { i in
            return i
        }
        self.uvs = Array(repeating: SIMD2<Float>(0, 0), count: vertices.count)
    }
}
extension Array {
    /// 配列を size 個ずつに分割して二次元配列にする
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        var chunks: [[Element]] = []
        chunks.reserveCapacity((self.count + size - 1) / size)
        for start in stride(from: 0, to: self.count, by: size) {
            let end =
                index(start, offsetBy: size, limitedBy: self.count)
                ?? self.count
            chunks.append(Array(self[start..<end]))
        }
        return chunks
    }
}
struct MeshSnapshot {
    let id: UUID
    let transform: simd_float4x4
    var vertices: [simd_float3]
    var normals: [simd_float3]
    let faces: [[UInt32]]
    let timestamp: TimeInterval
    let image: UIImage
    let modelMatrix: simd_float4x4
    let viewProjectionMatrix: simd_float4x4
    var uvs: [simd_float2]?
}
class ARViewController: UIViewController {
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    private(set) var snapshots: [UUID: MeshSnapshot] = [:]
    private var baker = ProjectionTextureBaker()
    override func viewDidLoad() {
        let arView = ARView(frame: self.view.frame)
        func setARViewOptions() {
            arView.debugOptions.insert(.showSceneUnderstanding)
        }
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()

            configuration.environmentTexturing = .automatic
            configuration.sceneReconstruction = .mesh
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
                configuration.frameSemantics = .sceneDepth
            }

            return configuration
        }
        func initARView() {

            setARViewOptions()
            let configuration = buildConfigure()
            arView.session.run(configuration)
        }
        func initExportButton() {
            let exportButton = UIButton(type: .system)
            exportButton.setTitle("Export", for: .normal)
            exportButton.titleLabel?.font = UIFont.systemFont(
                ofSize: 20,
                weight: .medium
            )
            exportButton.backgroundColor = UIColor.systemBlue
            exportButton.setTitleColor(.white, for: .normal)
            exportButton.layer.cornerRadius = 8
            exportButton.clipsToBounds = true
            exportButton.addTarget(
                self,
                action: #selector(generateMesh),
                for: .touchUpInside
            )
            let stackView = UIStackView(arrangedSubviews: [exportButton])
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.alignment = .center
            stackView.distribution = .equalSpacing
            stackView.translatesAutoresizingMaskIntoConstraints = false

            self.view.addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(
                    equalTo: self.view.centerXAnchor
                ),
                stackView.bottomAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                    constant: -20
                ),
            ])
        }
        arView.session.delegate = self
        super.viewDidLoad()
        self.view.addSubview(arView)
        initARView()
        initExportButton()
        try! baker.setup()
        self.view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
        ])
    }
    func createARXAtlasArgument(meshes: [MeshSnapshot]) -> ARXAtlasArgument {
        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [[UInt32]] = []
        var totalVertices: Int = 0
        for v in meshes {
            vertices.append(contentsOf: v.vertices)
            normals.append(contentsOf: v.normals)
            indices.append(
                contentsOf: v.faces.map { face in
                    face.map { f in
                        return f + UInt32(totalVertices)
                    }
                }
            )
            totalVertices += v.vertices.count
        }
        return ARXAtlasArgument(
            vertices: vertices,
            normals: normals,
            indices: indices
        )
    }
    func bakeTexture(meshes: [MeshSnapshot]) throws {
        let xatlas = SwiftXAtlas()
        var meshes = meshes.map { m in
            var m = m
            m.vertices = m.vertices.map { v in
                let newV = m.modelMatrix * simd_float4(v.x, v.y, v.z, 1.0)
                return simd_float3(newV.x, newV.y, newV.z)
            }
            let normalMatrix = simd_transpose(
                simd_inverse(simd_float4x4(m.modelMatrix))
            )

            m.normals = m.normals.map { n in
                let n = normalize(normalMatrix * simd_float4(n.x, n.y, n.z, 1.0))
                return simd_float3(n.x, n.y, n.z)
            }
            return m
        }
        let argument = createARXAtlasArgument(meshes: meshes)
        xatlas.generate([argument])
        let mesh = xatlas.mesh(at: 0)
        mesh.applyUvs(mesh: argument)

        try self.exportAndShareOBJ(argument: argument)
        return
        var totalUv = 0
        meshes = meshes.map { m in
            var m = m
            let uvs = Array(
                argument.uvs[totalUv..<(totalUv + m.vertices.count)]
            )
            m.uvs = uvs
            totalUv += m.vertices.count
            return m
        }

        let outputTexture = baker.getOutputTexture(
            textureWidth: 4096,
            textureHeight: 4096
        )
        guard let outputTexture else {
            fatalError("outputTexture is nil")
        }
        for mesh in meshes {
            let colorTexture = try baker.makeTexture(from: mesh.image)
            guard let colorTexture else {
                fatalError("colorTexture is nil")
            }
            guard let uvs = mesh.uvs else {
                fatalError("uvs is nil")
            }
            let faces = mesh.faces.flatMap { $0 }

            let _ = baker.draw(
                vertices: mesh.vertices,
                uvs: uvs,
                indices: faces,
                viewProjMatrix: mesh.viewProjectionMatrix,
                colorTexture: colorTexture,
                outputTexture: outputTexture
            )
        }
        let image = baker.image(from: outputTexture)
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            let image = UIImage(cgImage: image!)
            self.shareImageAsPNG(image, from: self)
        }
    }
    func shareFile(_ fileURL: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        viewController.present(activityVC, animated: true, completion: nil)
    }

    // MARK: — OBJ エクスポート＋共有
    func exportAndShareOBJ(
        argument: ARXAtlasArgument,
        filename: String = "xatlas_uv.obj"
    ) throws {
        let uvs = argument.uvs
        let vertexCount = argument.vertices.count

        var objText = ""
        for i in 0..<vertexCount {
            let p = argument.vertices[i]
            objText += String(format: "v %f %f %f\n", p.x, p.y, p.z)
        }
        for i in 0..<vertexCount {
            let uv = uvs[i]
            objText += String(format: "vt %f %f\n", uv.x, uv.y)
        }
        for t in argument.indices.chunked(into: 3) {
            let i0 = t[0] + 1
            let i1 = t[1] + 1
            let i2 = t[2] + 1
            objText += "f \(i0)/\(i0) \(i1)/\(i1) \(i2)/\(i2)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try objText.write(to: fileURL, atomically: true, encoding: .utf8)

        DispatchQueue.main.async {
            self.shareFile(fileURL, from: self)
        }
    }
    func shareImageAsPNG(
        _ image: UIImage,
        from viewController: UIViewController
    ) {
        // 1. UIImage を PNG データに変換
        guard let pngData = image.pngData() else {
            print("Error: PNG 変換に失敗しました")
            return
        }

        // 2. 一時ディレクトリにファイルとして保存
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("shared_image.png")

        do {
            try pngData.write(to: fileURL, options: .atomic)
        } catch {
            print("Error: ファイル書き出しに失敗しました → \(error)")
            return
        }

        // 3. UIActivityViewController を生成して表示
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        // iPad 対応（ポップオーバー表示先の指定）
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true, completion: nil)
    }
    @objc func generateMesh(_ sender: Any?) {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        var meshes = self.snapshots.map { (k, v) in
            return v
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.bakeTexture(meshes: meshes)
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
}
extension ARMeshGeometry {
    func vertex(at index: Int) -> SIMD3<Float> {
        assert(
            vertices.format == MTLVertexFormat.float3,
            "Expected three floats (twelve bytes) per vertex."
        )
        let vertexPointer = vertices.buffer.contents().advanced(
            by: vertices.offset + (vertices.stride * index)
        )
        let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self)
            .pointee
        return vertex
    }
    func normal(at index: Int) -> SIMD3<Float> {
        assert(
            normals.format == MTLVertexFormat.float3,
            "Expected three floats (twelve bytes) per normal."
        )
        let normalPointer = normals.buffer.contents().advanced(
            by: normals.offset + (normals.stride * index)
        )
        let normal = normalPointer.assumingMemoryBound(to: SIMD3<Float>.self)
            .pointee
        return normal
    }
    func faces() -> [[UInt32]] {
        let primitiveCount = faces.count
        let indicesPerPrimitive = Int(faces.indexCountPerPrimitive)
        assert(indicesPerPrimitive == 3, "Expected triangles.")
        let byteStride = faces.bytesPerIndex
        let bufferPointer = faces.buffer.contents()

        var allFaces: [[UInt32]] = []

        for i in 0..<primitiveCount {
            var face: [UInt32] = []
            for j in 0..<indicesPerPrimitive {
                let byteOffset = (i * indicesPerPrimitive + j) * byteStride
                let index: UInt32

                switch faces.bytesPerIndex {
                case 2:
                    index = UInt32(
                        bufferPointer.load(
                            fromByteOffset: byteOffset,
                            as: UInt16.self
                        )
                    )
                case 4:
                    index = bufferPointer.load(
                        fromByteOffset: byteOffset,
                        as: UInt32.self
                    )
                default:
                    fatalError(
                        "Unsupported bytesPerIndex: \(faces.bytesPerIndex)"
                    )
                }

                face.append(index)
            }
            allFaces.append(face)
        }

        return allFaces
    }
}
extension ARViewController: ARSessionDelegate {
    func convertToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage()  // fallback
    }
    func snapshot(from anchor: ARMeshAnchor, frame: ARFrame) -> MeshSnapshot {
        let geometry = anchor.geometry

        let vertices = (0..<geometry.vertices.count).map {
            geometry.vertex(at: $0)
        }

        let normals = (0..<geometry.normals.count).map {
            geometry.normal(at: $0)
        }

        let faces = geometry.faces()

        let image = convertToUIImage(pixelBuffer: frame.capturedImage)
        let orientation = UIInterfaceOrientation.landscapeRight
        let viewMatrix = frame.camera.viewMatrix(for: orientation)
        let projectionMatrix = frame.camera.projectionMatrix(
            for: orientation,
            viewportSize: image.size,
            zNear: 0.001,
            zFar: 0
        )
        return MeshSnapshot(
            id: anchor.identifier,
            transform: anchor.transform,
            vertices: vertices,
            normals: normals,
            faces: faces,
            timestamp: frame.timestamp,
            image: image,
            modelMatrix: anchor.transform,
            viewProjectionMatrix: projectionMatrix * viewMatrix
        )
    }
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor,
                let frame = session.currentFrame
            {
                snapshots[meshAnchor.identifier] = snapshot(
                    from: meshAnchor,
                    frame: frame
                )
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor,
                let frame = session.currentFrame
            {
                snapshots[meshAnchor.identifier] = snapshot(
                    from: meshAnchor,
                    frame: frame
                )
            }
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                snapshots.removeValue(forKey: meshAnchor.identifier)
            }
        }
    }
}
