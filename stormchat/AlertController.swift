//
//  AlertController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/6/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit

class AlertController: UIViewController {
    
    @IBOutlet weak var alertText: UILabel!
    var text:String = "No String here!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertText?.text = text
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
