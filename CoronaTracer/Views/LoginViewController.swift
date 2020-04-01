//
//  IntialViewController.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import UIKit
import FacebookLogin
import FBSDKCoreKit

class LoginViewController: UIViewController, LoginButtonDelegate {

    @IBOutlet weak var userInfoStackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailName: UILabel!

    var didLogin: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let loginButton = FBLoginButton(frame: CGRect(x: 0, y: 0, width: 300, height: 60), permissions: [.publicProfile, .email])
        loginButton.delegate = self
        loginButton.center = view.center
        
        view.addSubview(loginButton)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if User.isLoggedWithFacebook && !User.isLoggedInToServer {
            User.logoutFromFacebook()
        }

        if User.isLoggedWithFacebook {
            userInfoStackView.isHidden = false
        } else {
            userInfoStackView.isHidden = true
        }
    }

    private func fetchUserData() {
        LoadingView.show()
        let graphRequest: GraphRequest = GraphRequest(graphPath: "me", parameters: ["fields":"first_name,email,picture.type(large)"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            if ((error) != nil) {
                self.showAlert(title: "Error")
                print("Error: \(String(describing: error))")
            }
            else {
                guard let rDic = result as? NSDictionary else {
                    self.showAlert(title: "Error", message: "facebook Did not allowed loading email, please set that while updating profile.")
                    return
                }
                self.updateView()
                self.nameLabel.text = rDic["first_name"] as? String
                //self.emailName.text = rDic["email"] as? String

                if let pictureDic = rDic["picture"] as? [String: Any], let pictureData = pictureDic["data"] as? [String: Any], let imageUrlStr = pictureData["url"] as? String, let imageUrl = URL(string: imageUrlStr), let imageData = try? Data.init(contentsOf: imageUrl) {
                    self.imageView.image = UIImage(data: imageData)
                }
            }
            LoadingView.hide()
            self.loginToServer()
        })
    }

    private func loginToServer() {

        let endpoint = APIEndpoints.auth(with: AuthRequestDTO(fbToken: AccessToken.current?.tokenString ?? ""))
        LoadingView.show()
        DIContainer.shared.apiDataTransferService.request(with: endpoint) { (response: Result<AuthResponseDTO, Error>) in
            switch response {
            case .success(let auth):
                DIContainer.shared.authNetworkSessionManager.accessToken = auth.authToken
                
                LoadingView.show()
                
                let endpoint = APIEndpoints.getUserInfo()
                DIContainer.shared.apiDataTransferService.request(with: endpoint) { response in
                    switch response {
                    case .success(let userResponseDTO):
                        self.handleSuccess(for: userResponseDTO)
                    case .failure(let error):
                        User.logoutFromFacebook()
                        self.showAlert(title: error.localizedDescription)
                    }
                    LoadingView.hide()
                }
            case .failure(let error):
                User.logoutFromFacebook()
                self.showAlert(title: error.localizedDescription)
            }
            LoadingView.hide()
        }
    }
    
    private func handleSuccess(for userResponseDTO: UserResponseDTO) {

        let signature = userResponseDTO.bluetoothSignature
        guard let uuid = UUID(uuidString: signature) else {
            showAlert(title: "Error")
            print("Error Login: bluetoothSignature in empty")
            User.logoutFromFacebook()
            return
        }
        User.bluetoothSignature = uuid
        BluetoothScannerService.shared.setupOurPeripheral(with: User.bluetoothSignature)

        updateView()
        didLogin?()
    }

    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {

        if User.isLoggedWithFacebook {
            fetchUserData()
        }
    }

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        updateView()
    }

    func updateView() {
        if User.isLoggedInToServer {
            userInfoStackView.isHidden = false
        } else {
            userInfoStackView.isHidden = true
        }
    }
}

extension User {
    static var isLoggedWithFacebook: Bool { AccessToken.current != nil }
    static func logoutFromFacebook() { AccessToken.current = nil }
}
