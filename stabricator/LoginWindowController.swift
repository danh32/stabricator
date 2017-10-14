//
//  LoginWindowController.swift
//  stabricator
//
//  Created by Dan Hill on 10/14/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Cocoa

class LoginWindowController: NSWindowController, NSTextFieldDelegate {

    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var apiTokenTextField: NSTextField!

    let defaults = Defaults()

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @IBAction func onOkClicked(_ sender: Any) {
        let url = urlTextField.stringValue
        let apiToken = apiTokenTextField.stringValue
        let phab = Phabricator(phabricatorUrl: url, apiToken: apiToken)
        phab.fetchUser() { response in
            self.defaults.phabricatorUrl = url
            self.defaults.apiToken = apiToken
            self.defaults.userPhid = response.result.phid
            self.defaults.userImage = response.result.image
            self.close()
        }
    }
}
