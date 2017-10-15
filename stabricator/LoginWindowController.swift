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
    
    @IBAction func onLoadFromFileClicked(_ sender: Any) {
        let dialog = NSOpenPanel();
        dialog.title = "Open ~/.arcrc file";
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = true;
        dialog.canChooseDirectories = false;
        dialog.canCreateDirectories = false;
        dialog.allowsMultipleSelection = false;
        dialog.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("/.arcrc")

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url
            if (result != nil) {
                tryToReadArcrc(path: result!.path)
            }
        }
    }
    
    private func tryToReadArcrc(path: String) {
        do {
            let utf8 = String.Encoding.utf8.rawValue
            let jsonData = try NSString(contentsOfFile: path, encoding: utf8).data(using: utf8)!
            let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            let hosts = json["hosts"] as! [String: [String: String]]
            for (url, object) in hosts {
                let token = object["token"]!
                urlTextField.stringValue = url
                apiTokenTextField.stringValue = token
            }
        } catch {
            print(error)
        }
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
