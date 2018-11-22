//
//  AlertController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/6/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit

class AlertController: UITableViewController {
    
    var savedLogin:String = "[]"

    struct Alert: Codable {
        let id: String
        let areaDesc: String
        let event: String
        let headline: String
    }
    
    lazy var refreshCtrl: UIRefreshControl = {
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.addTarget(self, action:#selector(loadData(_:)),for: UIControlEvents.valueChanged)
        refreshCtrl.tintColor = UIColor.red
        return refreshCtrl
    }()
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: cellIdentifier)
        }
        // print("\(#function) --- section = \(indexPath.section), row = \(indexPath.row)")
        cell!.textLabel?.numberOfLines = 4
        cell!.textLabel?.text = alertList[indexPath.row][0]
        cell!.detailTextLabel?.numberOfLines = 5
        cell!.detailTextLabel?.text = alertList[indexPath.row][1]
        cell!.accessoryType = .disclosureIndicator
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if alertList[indexPath.row][0] != "** NO ACTIVE ALERTS **" {
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let chatController:ChatController = storyBoard.instantiateViewController(withIdentifier: "ChatController") as! ChatController
            chatController.savedLogin = self.savedLogin
            chatController.alert_id = alertList[indexPath.row][2]
            chatController.headline = alertList[indexPath.row][1]
            chatController.event = alertList[indexPath.row][0]
            
            let navigationController = UINavigationController(rootViewController: chatController)
            self.present(navigationController, animated: true, completion: nil)
            
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alertList.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.addSubview(self.refreshCtrl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loadData("initialize")
    }
    
    @objc private func loadData(_ sender: Any) {
        let json = convertToDictionary(text: savedLogin)
        if let location = json!["location"] as? String {
            UserDefaults.standard.set(savedLogin, forKey: "currentUser")
            self.getJSONfromRequest(location: location)
            
        } else {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginController:ViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            self.present(loginController, animated: true, completion: nil)
        }
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
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode([Alert].self, from: data)
                
                if response.count > 0 {
                  self.alertList.removeAll()
                    for alert in response {
                        self.alertList.append([alert.event + " at " + alert.areaDesc, alert.headline, alert.id])
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshCtrl.endRefreshing()
                }
            } catch { print(error) }
            
        }
        task.resume()
    }

    var alertList:[[String]] = [
        ["** NO ACTIVE ALERTS **", "Pull down to refresh!", ""],
    ]
}
