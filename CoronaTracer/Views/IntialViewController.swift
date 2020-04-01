//
//  IntialViewController.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import UIKit

class IntialViewController: UIViewController {

    var didStartBluetooth: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

    @IBAction func enableBluetoothAction(_ sender: Any) {
        BluetoothScannerService.shared.startScanning(
            onStartScanning: {
                UserDefaults.standard.set(true, forKey: UserDefaultsConstants.isInitialScreenDoneKey)
                self.didStartBluetooth?()
        },
            onFailStarting: { error in

                if error == .unauthorized {
                    let alertController = UIAlertController (title: error.localizedDescription, message: nil, preferredStyle: .alert)

                    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in

                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }

                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                print("Settings opened: \(success)") // Prints true
                            })
                        }
                    }

                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                    alertController.addAction(cancelAction)
                    alertController.addAction(settingsAction)

                    self.present(alertController, animated: true, completion: nil)
                }
                else {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
        }
        )
    }
}
