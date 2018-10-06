//
//  ViewController.swift
//  stormchat
//
//  Created by Gautam on 4/24/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn

class ViewController: UIViewController, UITextFieldDelegate , GIDSignInUIDelegate, GIDSignInDelegate, FBSDKLoginButtonDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        print("reached")
        //if any error stop and print the error
        if error != nil{
            print(error ?? "google error")
            return
        }
        
        //if success display the email on label
        print(user.profile.email)
        DispatchQueue.main.async {
            self.segueToAlertController(data: user.profile.email)
        }
    }
    
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var fbLogin: FBSDKLoginButton!
    @IBOutlet weak var loginStack: UIStackView!
    @IBAction func googleLogin(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        email.delegate = self
        password.delegate = self
        
        
        // Google Sign in thing
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Facebook Sign in button delegate
        self.fbLogin.readPermissions = ["email"]
        self.fbLogin.delegate = self
        
        // Uncomment to automatically sign in the user.
        // GIDSignIn.sharedInstance().signInSilently()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height/4
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y = 0
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Google

    // Facebook Login
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if ((error) != nil) {
            print(error)
        }
        else if (result.isCancelled) {
            print("User Cancelled Login")
        }
        else {
            self.getFBUserData()
        }
    }
    
    // Facebook Logout
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("User Logged out!")
    }

    // Facebook helper
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name"]).start(completionHandler: { (connection, result, error) -> Void in
                // For picture use -> ["fields": "email, name, picture.type(large)"]
                if (error == nil){
                    self.segueToAlertController(data: "\(String(describing: result!))")
                } else {
                    print("Error Logging in with Facebook, try again or use other methods to log in")
                }
            })
        }
    }

    // Server DB Login
    @IBAction func loginAction(_ sender: UIButton) {
        let url = URL(string: "https://stormchat.gautambaghel.com/api/v1/token")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let email = self.email.text!
        let password = self.password.text!
        let postString = "email=\(String(describing: email))&pass=\(String(describing: password))"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            DispatchQueue.main.async {
                self.segueToAlertController(data: responseString!)
            }
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
    // Display the Strings
    func segueToAlertController(data json: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let alertController:AlertController = storyBoard.instantiateViewController(withIdentifier: "AlertController") as! AlertController
        alertController.text = json
        self.present(alertController, animated: true, completion: nil)
    }
}

