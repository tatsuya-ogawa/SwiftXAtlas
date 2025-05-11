//
//  ViewController.swift
//  ExampleApp
//
//  Created by Tatsuya Ogawa on 2023/04/15.
//

import UIKit
struct Vertice{
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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let arViewController = ARViewController()
        arViewController.modalPresentationStyle = .fullScreen
        present(arViewController, animated: true)
    }
}

