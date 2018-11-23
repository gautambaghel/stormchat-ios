//
//  ChatInfoController.swift
//  stormchat
//
//  Created by Gautam Baghel on 11/23/18.
//  Copyright © 2018 Gautam. All rights reserved.
//

import UIKit

class ChatInfoController: UIViewController {

    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var infoText: UITextView!
    
    var headline = ""
    var event = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoText.text = event + "\n\n\n" + headline
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
