//
//  ViewController.swift
//  ExampleApp
//
//  Created by Tatsuya Ogawa on 2023/04/15.
//

import UIKit

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

