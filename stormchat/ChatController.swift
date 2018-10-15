//
//  ChatController.swift
//  stormchat
//
//  Created by Gautam Baghel on 10/15/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit

class ChatController: UIViewController {

    var id:String = ""
    var headline:String = ""
    var event:String = ""
    
    @IBOutlet weak var display: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        display.text = id + headline + event
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
