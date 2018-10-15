//
//  AlertController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/6/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit

class AlertController: UITableViewController {
    
    var text:String = "[]"

    struct Alert : Codable {
        let id: String
        let areaDesc: String
        let event: String
        let headline: String
        
        enum CodingKeys : String, CodingKey {
            case id = "    id "
            case areaDesc = "    areaDesc "
            case event = "    event "
            case headline = "    headline "
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: cellIdentifier)
        }
        // print("\(#function) --- section = \(indexPath.section), row = \(indexPath.row)")
        cell!.textLabel?.numberOfLines = 4
        cell!.textLabel?.text = data[indexPath.row][0]
        cell!.detailTextLabel?.numberOfLines = 5
        cell!.detailTextLabel?.text = data[indexPath.row][1]
        cell!.accessoryType = .disclosureIndicator
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let json = getDictionary(text: text)
        if let location = json!["location"] as? String {
            UserDefaults.standard.set(text, forKey: "currentUser")
            self.getJSONfromRequest(location: location)
        } else {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginController:ViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            self.present(loginController, animated: true, completion: nil)
        }
    }
    
    private func getDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
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

    private func getJSONfromRequest(location: String){
        let location = "https://stormchat.gautambaghel.com/api/v1/alerts/mobile/" + location
        let url = URL(string: location)!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)!
            self.convertDataToValuableForm(jsonString: responseString)
        }
        task.resume()
    }

    private func convertDataToValuableForm(jsonString: String) {
        let val = self.convertToDictionary(text: jsonString)
        for (_, alerts) in val! {
            let respString = "\(alerts)"
            let fjsonString = respString.replacingOccurrences(of: "=", with: "\" :", options: .literal, range: nil)
            let sjsonString = fjsonString.replacingOccurrences(of: "\n", with: "\n \"", options: .literal, range: nil)
            let tjsonString = sjsonString.replacingOccurrences(of: ";", with: ",", options: .literal, range: nil)
            let jsonString = tjsonString.replacingOccurrences(of: ",\n \"}", with: "\n }", options: .literal, range: nil)
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()
            let alert = try! decoder.decode(Alert.self, from: jsonData)
            
            data.append([alert.event + " at " + alert.areaDesc, alert.headline])
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
      data.remove(at: 0)
    }
    
    var data:[[String]] = [
        ["** NO ACTIVE ALERTS **", "Pull down to refresh!"],
    ]
}
