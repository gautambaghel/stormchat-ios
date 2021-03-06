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
        
        //if any error stop and print the error
        if error != nil{
            print(error ?? "google error")
            return
        }
        
        DispatchQueue.main.async {
            self.registerOrSigninUser(provider: "google", auth: user.userID ,username: user.profile.name, email: user.profile.email)
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
        GIDSignIn.sharedInstance().delegate = self
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
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name, locale, timezone"]).start(completionHandler: { (connection, result, error) -> Void in
                // For picture use -> ["fields": "email, name, picture.type(large)"]
                if (error == nil){
                    if
                        let fields = result as? [String:Any],
                        let name = fields["name"] as? String,
                        let id = fields["id"] as? String
                    {
                        let email = fields["email"] as? String
                        self.registerOrSigninUser(provider: "facebook", auth: id, username: name, email: email!)
                    } else {
                        print("Error getting data from Facebook, try again or use other methods to log in")
                    }
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
        let postString = "email=\(String(describing: email))&password=\(String(describing: password))"
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
            if let fields = self.convertToDictionary(text: responseString!){
                DispatchQueue.main.async {
                    if let err = fields["error"] as? String {
                        let alert = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    } else {
                        UserDefaults.standard.set(responseString, forKey: "currentUser")
                        self.segueToMainTabController()
                    }
                }
            }
        }
        task.resume()
    }
    
    func segueToMainTabController() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTabController:MainTabController = storyBoard.instantiateViewController(withIdentifier: "MainTabController") as! MainTabController
        self.present(mainTabController, animated: true, completion: nil)
    }
    
    // Choose location
    func segueToLocationController(email: String, provider: String, auth: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let locationController:LocationController = storyBoard.instantiateViewController(withIdentifier: "LocationController") as! LocationController
        
        locationController.auth = auth
        locationController.email = email
        locationController.provider = provider
        
        let navigationController = UINavigationController(rootViewController: locationController)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    // if the fb/google User is already registered on system, then they must've location set in
    // Otherwise take them to location controller
    func registerOrSigninUser(provider: String, auth: String,username name: String, email: String) {
        let url = URL(string: "https://stormchat.gautambaghel.com/api/v1/new_user")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString = "provider=\(String(describing: provider))&auth=\(String(describing: auth))&name=\(String(describing: name))"
        print(postString)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            if let fields = self.convertToDictionary(text: responseString!){
                let location = fields["location"] as? String
                if location == nil {
                    DispatchQueue.main.async {self.segueToLocationController(email: email, provider: provider, auth: auth)}
                } else {
                  UserDefaults.standard.set(responseString, forKey: "currentUser")
                  DispatchQueue.main.async {self.segueToMainTabController()}
               }
            }
        }
        task.resume()
    }
    
    private func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

