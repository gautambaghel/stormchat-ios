//
//  ProfileController.swift
//  stormchat
//
//  Created by Gautam Baghel on 11/24/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn

class ProfileController: UIViewController, UITextFieldDelegate ,UIPickerViewDataSource, UIPickerViewDelegate  {
    
    var provider: String = ""
    var auth: String = ""
    var user_id: String = ""
    var token: String = ""
    
    @IBOutlet weak var locationPicker: UIPickerView!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var subscribe: UISwitch!
    
    @IBAction func updateAction(_ sender: UIButton) {
        let row = self.locationPicker.selectedRow(inComponent: 0)
        let location = states[row].split(separator: "-")[1].trimmingCharacters(in: .whitespaces)
        let subscribed = self.subscribe.isOn
        
        // Edit user data for facebook and google
        if auth != "" {
            self.setUserDataForProvider(auth: auth, email: self.email.text!, location: location, subscribed: subscribed)
        } else {
        // edit user for internal database
            let name = self.name.text!
            self.setUserData(name: name, email: self.email.text!, location: location, subscribed: subscribed, user_id: user_id, token: token)
        }
    }
    
    @IBAction func logout(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            
            if self.provider == "google" {
                GIDSignIn.sharedInstance().signOut()
            }
            
            if self.provider == "facebook" {
                let loginManager = FBSDKLoginManager()
                loginManager.logOut()
            }
            
            UserDefaults.standard.set(nil, forKey: "currentUser")
            self.segueToViewController()
            
        }))
        self.present(alert, animated: true)
        
    }
    
    func segueToViewController() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController:ViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.present(viewController, animated: true, completion: nil)
    }
    
    // Facebook Logout
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("User Logged out!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        name.delegate = self
        email.delegate = self
        locationPicker.delegate = self
        locationPicker.dataSource = self
        self.loadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func loadData() {
        if let data = UserDefaults.standard.object(forKey: "currentUser"),
            let savedLogin = data as? String,
            let json = convertToDictionary(text: savedLogin) {
            
             if let name = json["name"],
                let email = json["email"],
                let location = json["location"],
                let subscribed = json["subscribed"],
                let token = json["token"] {
                
                self.name.text = "\(name)"
                self.email.text = "\(email)"
                self.token = "\(token)"
                self.subscribe.setOn((subscribed as? Bool)!, animated: true)
                self.selectRow(location: location as? String)
            }
            
             if let auth = json["auth"],
                let provider = json["provider"] {
                self.name.isUserInteractionEnabled = false
                self.email.isUserInteractionEnabled = false
                self.auth = "\(auth)"
                self.provider = "\(provider)"
             }
            
             if let user_id = json["user_id"] {
                self.user_id = "\(user_id)"
             }
            
        } else {
             let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
             let loginController:ViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
             self.present(loginController, animated: true, completion: nil)
        }
    }
    
    func selectRow(location loc: String?) {
        for (index,state) in states.enumerated() {
            let initials = state.split(separator: "-")[1].trimmingCharacters(in: .whitespaces)
            if initials == loc! {
                locationPicker.selectRow(index, inComponent: 0, animated: true)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return states.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return states[row]
    }
    
    func setUserDataForProvider(auth: String, email: String, location: String, subscribed: Bool) {
        let url = URL(string: "https://stormchat.gautambaghel.com/api/v1/token")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString = "auth=\(String(describing: auth))&email=\(String(describing: email))&location=\(String(describing: location))&subscribed=\(String(describing: subscribed))"
        print(postString)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            if let fields = self.convertToDictionary(text: responseString!){
                let location = fields["location"] as? String
                if location == nil {
                    self.showAlert(title: "Error in setting location", message: "Something went wrong while setting \(String(describing: location!)) as location")
                } else {
                    UserDefaults.standard.set(responseString, forKey: "currentUser")
                    self.showAlert(title: "Successful", message: "Current location set to \(String(describing: location!)) and subscription settings updated")
                }
            }
        }
        task.resume()
    }
    
    func setUserData(name: String, email: String, location: String, subscribed: Bool, user_id: String, token: String) {
        let url = URL(string: "https://stormchat.gautambaghel.com/api/v1/edit_user")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString = "name=\(String(describing: name))&email=\(String(describing: email))&location=\(String(describing: location))&subscribed=\(String(describing: subscribed))&user_id=\(String(describing: user_id))&token=\(String(describing: token))"
        print(postString)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            if let fields = self.convertToDictionary(text: responseString!){
              DispatchQueue.main.async {
                if let location = fields["location"] as? String,
                    let _ = fields["subscribed"] as? Bool,
                    let _ = fields["name"] as? String,
                    let _ = fields["email"] as? String {
                    UserDefaults.standard.set(responseString, forKey: "currentUser")
                    self.showAlert(title: "Successful", message: "Current location set to \(String(describing: location)) and other settings updated")
                } else {
                    if let err = fields["error"] {
                        self.showAlert(title: "Error", message: "\(err)")
                    } else {
                        self.showAlert(title: "Error", message: "Sorry, something went wrong!")
                    }
                }
              }
            }
        }
        task.resume()
    }
    
    private func showAlert(title: String, message msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true)
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
    
    let states = [
        "Alabama - AL",
        "Alaska - AK",
        "Arizona - AZ",
        "Arkansas - AR",
        "California - CA",
        "Colorado - CO",
        "Connecticut - CT",
        "Delaware - DE",
        "Florida - FL",
        "Georgia - GA",
        "Hawaii - HI",
        "Idaho - ID",
        "Illinois - IL",
        "Indiana - IN",
        "Iowa - IA",
        "Kansas - KS",
        "Kentucky - KY",
        "Louisiana - LA",
        "Maine - ME",
        "Maryland - MD",
        "Massachusetts - MA",
        "Michigan - MI",
        "Minnesota - MN",
        "Mississippi - MS",
        "Missouri - MO",
        "Montana - MT",
        "Nebraska - NE",
        "Nevada - NV",
        "New Hampshire - NH",
        "New Jersey - NJ",
        "New Mexico - NM",
        "New York - NY",
        "North Carolina - NC",
        "North Dakota - ND",
        "Ohio - OH",
        "Oklahoma - OK",
        "Oregon - OR",
        "Pennsylvania - PA",
        "Rhode Island - RI",
        "South Carolina - SC",
        "South Dakota - SD",
        "Tennessee - TN",
        "Texas - TX",
        "Utah - UT",
        "Vermont - VT",
        "Virginia - VA",
        "Washington - WA",
        "West Virginia - WV",
        "Wisconsin - WI",
        "Wyoming - WY"
    ]

}
