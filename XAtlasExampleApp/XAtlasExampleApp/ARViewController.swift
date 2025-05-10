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
import UIKit

struct MeshSnapshot {
    let id: UUID
    let transform: simd_float4x4
    let vertices: [simd_float3]
    let normals: [simd_float3]
    let faces: [[UInt32]]
    let timestamp: TimeInterval
    let image: UIImage
    let cameraTransform: simd_float4x4
}
class ARViewController: UIViewController {
    private(set) var snapshots: [UUID: MeshSnapshot] = [:]
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
                action: #selector(export),
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
    }
    override func export(_ sender: Any?) {

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
    func snapshot(from anchor: ARMeshAnchor, frame: ARFrame?) -> MeshSnapshot {
        let geometry = anchor.geometry

        let vertices = (0..<geometry.vertices.count).map {
            geometry.vertex(at: $0)
        }

        let normals = (0..<geometry.normals.count).map {
            geometry.normal(at: $0)
        }

        let faces = geometry.faces()

        let image =
            frame.map { convertToUIImage(pixelBuffer: $0.capturedImage) }
            ?? UIImage()

        return MeshSnapshot(
            id: anchor.identifier,
            transform: anchor.transform,
            vertices: vertices,
            normals: normals,
            faces: faces,
            timestamp: frame?.timestamp ?? 0.0,
            image: image,
            cameraTransform: frame?.camera.transform ?? simd_float4x4(1.0)
        )
    }
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                let frame = session.currentFrame
                snapshots[meshAnchor.identifier] = snapshot(
                    from: meshAnchor,
                    frame: frame
                )
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                let frame = session.currentFrame
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
