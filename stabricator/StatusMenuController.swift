//
//  StatusMenuController.swift
//  weatherbar
//
//  Created by Dan Hill on 10/10/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject, NSWindowDelegate {
    let INSERTION_INDEX = 2

    @IBOutlet weak var statusMenu: NSMenu!

    let loginWindowController = LoginWindowController(windowNibName: NSNib.Name(rawValue: "LoginWindow"))
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    let defaults = Defaults()
    var phab: Phabricator? = nil
    var userPhid: String? = nil
    var userImage: String? = nil
    var diffs: [Diff]? = nil

    @IBAction func refreshClicked(_ sender: Any) {
        refreshDiffs()
    }

    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    override init() {
        super.init()

        if (defaults.hasApiToken()) {
            initPhabricator()
        } else {
            // show login window
            loginWindowController.window?.center()
            loginWindowController.window?.delegate = self
            loginWindowController.showWindow(self)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        // login window closing, initialize Phabricator with new values
        initPhabricator()
    }
    
    private func initPhabricator() {
        self.userPhid = defaults.userPhid!
        self.userImage = defaults.userImage!

        let phabUrl = defaults.phabricatorUrl!
        let apiToken = defaults.apiToken!
        self.phab = Phabricator(phabricatorUrl: phabUrl, apiToken: apiToken)

        refreshDiffs()
    }

    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "knife"))!
        icon.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        refreshDiffs()
    }

    private func refreshDiffs() {
        if let phab = self.phab {
            phab.fetchActiveDiffs() { response in
                self.diffs = response.result.data
                self.refreshUi(diffs: response.result.data)
                
                // TODO: have time be configurable
                let seconds = self.defaults.refreshInterval ?? 60
                let deadlineTime = DispatchTime.now() + .seconds(seconds)
                DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                    self.refreshDiffs()
                }
            }
        }
    }

    private func refreshUi(diffs: [Diff]) {
        // update title on main thread
        DispatchQueue.main.async(execute: {
            self.statusItem.title = "\(diffs.count)"
        })
        
        print("Fetched \(diffs.count) active diffs")
        
        // clear out last update's menu items
        while (statusMenu.items.count > INSERTION_INDEX + 1) {
            statusMenu.removeItem(at: INSERTION_INDEX)
        }

        // assemble by status
        var categories = [String: [Diff]]()
        for diff in diffs {
            let status = diff.fields.status.value
            if categories[status] == nil {
                categories[status] = [Diff]()
            }
            categories[status]?.append(diff)
        }
        
        // insert new ones
        for (_, diffs) in categories {
            let title = diffs[0].fields.status.name
            let header = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            insertMenuItem(menuItem: header)

            for diff in diffs {
                let row = NSMenuItem(title: diff.fields.title, action: #selector(launchUrl), keyEquivalent: "")
                row.target = self
                row.representedObject = diff
                
                if (diff.fields.authorPHID == userPhid) {
                    if let imageUrl = self.userImage {
                        row.image = NSImage(byReferencing: URL(string: imageUrl)!)
                    }
                }

                insertMenuItem(menuItem: row)
            }
            insertMenuItem(menuItem: NSMenuItem.separator())
        }
    }
    
    @objc private func launchUrl(_ menuItem: NSMenuItem) {
        let diff = menuItem.representedObject as! Diff
        let urlString = "https://phabricator.robinhood.com/D\(diff.id)"
        let url = URL(string: urlString)
        NSWorkspace.shared.open(url!)
    }
    
    private func insertMenuItem(menuItem: NSMenuItem) {
        statusMenu.insertItem(menuItem, at: statusMenu.items.count - 1)
    }
}
