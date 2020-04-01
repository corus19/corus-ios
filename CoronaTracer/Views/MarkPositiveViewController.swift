//
//  MarkPositiveViewController.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 29/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation
import UIKit

class MarkPositiveViewController: UIViewController {
    private var shouldMarkedAsPositive = false
    
    var didShowMarkPositiveSuccess: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func markPostive(_ sender: Any) {

        let title = "You have been tested positive and you want people who were in your close proximity to be alerted about the same. Alert will be sent after the Health Department verifies your information."
        let alert = UIAlertController(title: title,
                                      message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) { (action) in
            let endpoint = APIEndpoints.putMarkPositive()
            DIContainer.shared.apiDataTransferService.request(with: endpoint) { (result) in
                switch result {
                case .success(_):
                    self.shouldMarkedAsPositive = true
                    self.saveUserMarked()
                    self.didShowMarkPositiveSuccess?()
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    break
                }
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    private func saveUserMarked() {
        UserStorage.shared.shouldMarkedAsPositive = shouldMarkedAsPositive
    }

}
