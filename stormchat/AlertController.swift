//
//  AlertController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/6/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit

class AlertController: UITableViewController {
    
    struct Alert: Codable {
        let id: String?
        let areaDesc: String?
        let event: String?
        let headline: String?
    }
    
    lazy var refreshCtrl: UIRefreshControl = {
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.addTarget(self, action:#selector(loadData(_:)),for: UIControlEvents.valueChanged)
        refreshCtrl.tintColor = UIColor.red
        return refreshCtrl
    }()
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AlertCell"
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chatControllerSegue" {
            
            let chatController = segue.destination
                as! ChatController
            
            let indexPath = self.tableView.indexPathForSelectedRow!
            chatController.alert_id = alertList[indexPath.row][2]
            chatController.headline = alertList[indexPath.row][1]
            chatController.event = alertList[indexPath.row][0]
        }
        
        
        if segue.identifier == "alertInfoSegue" {
            
            if let nav = segue.destination as? UINavigationController,
                let alertInfoController = nav.topViewController as? InfoController {
                
                alertInfoController.headline = """
                        The Alert tab notifies you about the
                        active alerts in your area. \n\n\n You can chat in any of these chat
                        rooms to talk or help fellow denizens in need.
                        """
            }
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
        if let data = UserDefaults.standard.object(forKey: "currentUser"),
            let savedLogin = data as? String,
             let json = convertToDictionary(text: savedLogin),
              let location = json["location"] as? String {
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
            
            DispatchQueue.main.async {
                self.refreshCtrl.endRefreshing()
            }
            
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
                        if let headline = alert.headline,
                           let event = alert.event,
                           let id = alert.id,
                           let areaDesc = alert.areaDesc {
                            self.alertList.append([event + " at " + areaDesc, headline, id])
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch { print(error) }
            
        }
        task.resume()
    }

    var alertList:[[String]] = [
        ["** NO ACTIVE ALERTS **", "Pull down to refresh!", ""],
    ]
}
