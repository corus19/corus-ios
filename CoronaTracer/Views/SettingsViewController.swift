//
//  SettingsViewController.swift
//  CoronaTracer
//
//  Created by Arifin Firdaus on 29/03/20.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        fetchSettings()
    }
    
    private func fetchSettings() {
        LoadingView.show()
        
        let requestDTO = SettingsPostRequestDTO(country: "string", keys: ["string"])
        let endpoint = APIEndpoints.postGetSettings(with: requestDTO)
        DIContainer.shared.apiDataTransferService.request(with: endpoint) { response in
            switch response {
            case .success(let responseDTO):
                print(responseDTO)
            case .failure(let error):
                self.showAlert(title: error.localizedDescription)
            }
            LoadingView.hide()
        }
    }
}
