//
//  RegisterController.swift
//  stormchat
//
//  Created by Gautam Baghel on 9/5/18.
//  Copyright © 2018 Gautam. All rights reserved.
//
import UIKit

class RegisterController: UIViewController, UITextFieldDelegate ,UIPickerViewDataSource, UIPickerViewDelegate {
    
    struct Errors : Codable {
        var email: String
        var password: String
    }
    
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var subscribe: UISwitch!
    @IBOutlet weak var location: UIPickerView!
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        name.delegate = self
        email.delegate = self
        password.delegate = self
        location.delegate = self
        location.dataSource = self
        location.selectRow(20, inComponent: 0, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    @IBAction func register(_ sender: UIButton) {
        let url = URL(string: "https://stormchat.gautambaghel.com/api/v1/new_user")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let name = self.name.text!
        let email = self.email.text!
        let password = self.password.text!
        let row = self.location.selectedRow(inComponent: 0)
        let location = states[row].split(separator: "-")[1].trimmingCharacters(in: .whitespaces)
        let subscribed = self.subscribe.isOn
        let postString = "name=\(String(describing: name))&email=\(String(describing: email))&password=\(String(describing: password))&location=\(String(describing: location))&subscribe=\(String(describing: subscribed))"
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
                    if let err = fields["error"] {
                        let alert = UIAlertController(title: "Error", message: "\(err)", preferredStyle: .alert)
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
