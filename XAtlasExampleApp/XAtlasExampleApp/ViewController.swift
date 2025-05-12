import UIKit

struct Vertice {
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
    private let arButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Show AR View", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    private let exportButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Show Bunny View", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Add buttons in a stack view centered
        let stack = UIStackView(arrangedSubviews: [arButton, exportButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Button actions
        arButton.addTarget(self, action: #selector(showAR), for: .touchUpInside)
        exportButton.addTarget(self, action: #selector(showExport), for: .touchUpInside)
    }

    @objc private func showAR() {
        let arVC = ARViewController()
        arVC.modalPresentationStyle = .fullScreen
        present(arVC, animated: true)
    }

    @objc private func showExport() {
        let exportVC = BunnyViewController()
        exportVC.modalPresentationStyle = .fullScreen
        present(exportVC, animated: true)
    }

    // Remove automatic presentation on appear
    // override func viewDidAppear(_ animated: Bool) {
    //     super.viewDidAppear(animated)
    // }
}
