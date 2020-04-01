//
//  AppFlowCoordiantor.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import UIKit

class FlowCoordinator {

    var navigationController: UINavigationController
    lazy var bgVc: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        return vc
    }()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        navigationController.setViewControllers([bgVc], animated: false)

        if !UserDefaults.standard.bool(forKey: UserDefaultsConstants.isInitialScreenDoneKey) {
            showInitialScreen()
        } else {
            BluetoothScannerService.shared.startScanning(
                onStartScanning: {
                    self.showLoginOrMarkPositiveScreen()
            },
                onFailStarting: { error in
                    self.showInitialScreen()
                    self.navigationController.showAlert(title: "Error", message: error.localizedDescription)
            }
            )
        }
    }

    private func showInitialScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "IntialViewController") as! IntialViewController
        vc.didStartBluetooth = showLoginOrMarkPositiveScreen
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showLoginOrMarkPositiveScreen() {
        if !User.isLoggedInToServer {
            self.showLoginScreen()
        } else {
            self.showMarkPositiveScreen()
        }
    }

    private func showLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        vc.didLogin = showMarkPositiveScreen
        navigationController.setViewControllers([vc], animated: true)
    }

    private func showMarkPositiveScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MarkPositiveViewController") as! MarkPositiveViewController
        vc.didShowMarkPositiveSuccess = showMarkPositiveSuccessScreen
        navigationController.setViewControllers([vc], animated: true)
        
        if UserStorage.shared.shouldMarkedAsPositive {
            showMarkPositiveSuccessScreen()
        }
    }
    
    private func showMarkPositiveSuccessScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MarkPositiveSuccessViewController")
        if let unwrappedLastViewController = navigationController.viewControllers.last {
            unwrappedLastViewController.present(vc, animated: true) { }
        }
    }
    
}
