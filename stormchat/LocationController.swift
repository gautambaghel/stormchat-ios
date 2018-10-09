//
//  LocationController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/8/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn

class LocationController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var location: UIPickerView!
    @IBOutlet weak var subscribed: UISwitch!
    
    var auth:String?
    var email:String?
    var provider:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        location.delegate = self
        location.selectRow(20, inComponent: 0, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
        if provider == "google" {
            GIDSignIn.sharedInstance().signOut()
        } else if provider == "facebook" {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }
        
        UserDefaults.standard.set(nil, forKey: "currentUser")
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController:ViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func continueButtonAction(_ sender: UIButton) {
        let row = self.location.selectedRow(inComponent: 0)
        let location = states[row].split(separator: "-")[1].trimmingCharacters(in: .whitespaces)
        let subscribed = self.subscribed.isOn
        self.getJSONfromRequest(auth: auth!, email: email!, location: location, subscribed: subscribed, provider: provider!)
    }
    
    func getJSONfromRequest(auth: String, email: String, location: String, subscribed: Bool, provider: String) {
        let url = URL(string: "https://stormchat.gautambaghel.com/api/v1/token")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString = "auth=\(String(describing: auth))&email=\(String(describing: email))&location=\(String(describing: location))&subscribed=\(String(describing: subscribed))"
        print(postString)
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
                let location = fields["location"] as? String
                if location == nil {
                    DispatchQueue.main.async {self.segueToLocationController(data: responseString!, email: email, provider: provider)}
                } else {
                    print(location ?? "default loc")
                    DispatchQueue.main.async {self.segueToAlertController(data: responseString!)}
                }
            }
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
    
    // Choose location
    func segueToLocationController(data json: String, email: String, provider: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let locationController:LocationController = storyBoard.instantiateViewController(withIdentifier: "LocationController") as! LocationController
        locationController.email = email
        locationController.provider = provider
        self.present(locationController, animated: true, completion: nil)
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return states.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return states[row]
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
