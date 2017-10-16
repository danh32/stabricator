//
//  StatusMenuController.swift
//  weatherbar
//
//  Created by Dan Hill on 10/10/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject, NSWindowDelegate, NSUserNotificationCenterDelegate {
    let INSERTION_INDEX = 2

    @IBOutlet weak var statusMenu: NSMenu!

    let loginWindowController = LoginWindowController(windowNibName: NSNib.Name(rawValue: "LoginWindow"))
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    let defaults = Defaults()
    var phab: Phabricator? = nil
    var userPhid: String? = nil
    var userImage: String? = nil
    var diffs: [Diff]? = nil
    var knownDiffIds: Set<String> = []

    @IBAction func refreshClicked(_ sender: Any) {
        refreshDiffs()
    }

    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    override init() {
        super.init()

        NSUserNotificationCenter.default.delegate = self

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

        var newDiffs: [Diff] = []
        let sortedDiffs = sortDiffs(userPhid: userPhid!, diffs: diffs)
        for category in categories {
            let diffs = sortedDiffs[category]!
            let header = NSMenuItem(title: category.title, action: nil, keyEquivalent: "")
            insertMenuItem(menuItem: header)
            
            if (diffs.isEmpty) {
                let empty = NSMenuItem(title: category.emptyMessage, action: nil, keyEquivalent: "")
                empty.indentationLevel = 1
                insertMenuItem(menuItem: empty)
            }

            for diff in diffs {
                // add to new diffs if we haven't seen it yet
                if !knownDiffIds.contains(diff.phid) {
                    newDiffs.append(diff)
                }

                let row = NSMenuItem(title: diff.fields.title, action: #selector(launchUrl), keyEquivalent: "")
                row.target = self
                row.representedObject = diff
                
                if (diff.fields.authorPHID == userPhid) {
                    if let imageUrl = self.userImage {
                        let avatar = NSImage(byReferencing: URL(string: imageUrl)!)
                        // TODO: don't hardcode, get the height of the item
                        let height = 18
                        avatar.size = NSSize(width: height, height: height)
                        row.image = avatar
                    }
                }
                
                insertMenuItem(menuItem: row)
            }
            
            insertMenuItem(menuItem: NSMenuItem.separator())
        }


        if (!newDiffs.isEmpty) {
            // notify!
            showNotification(diffs: newDiffs)
        }

        knownDiffIds.removeAll()
        for diff in diffs {
            knownDiffIds.insert(diff.phid)
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

    private func showNotification(diffs: [Diff]) -> Void {
        if (diffs.isEmpty) {
            return
        }

        for diff in diffs {
            let notification = NSUserNotification()
            notification.title = diff.fields.title
            notification.subtitle = diff.fields.status.name
            notification.identifier = "\(diff.id)"
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        // TODO: make configurable
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        let id = notification.identifier!
        let urlString = "https://phabricator.robinhood.com/D\(id)"
        let url = URL(string: urlString)
        NSWorkspace.shared.open(url!)
        NSUserNotificationCenter.default.removeDeliveredNotification(notification)
    }
}
