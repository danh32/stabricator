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
    @IBOutlet weak var refreshMenuItem: NSMenuItem!
    
    let loginWindowController = LoginWindowController(windowNibName: NSNib.Name(rawValue: "LoginWindow"))
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let knife = NSImage(named: NSImage.Name(rawValue: "knife"))!
    let error = NSImage(named: NSImage.Name(rawValue: "error"))!

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


    }
    
    func windowWillClose(_ notification: Notification) {
        if (defaults.hasApiToken()) {
            // login window closing, initialize Phabricator with new values
            initPhabricator()
        } else {
            quitClicked(self)
        }
    }
    
    private func initPhabricator() {
        self.userPhid = defaults.userPhid!
        self.userImage = defaults.userImage!

        let phabUrl = defaults.phabricatorUrl!
        let apiToken = defaults.apiToken!
        self.phab = Phabricator(phabricatorUrl: phabUrl, apiToken: apiToken) { error in
            let icon = self.error
            self.statusItem.image = icon
            self.refreshMenuItem.image = icon
            self.refreshMenuItem.toolTip = "Refresh failed. Check your wifi and vpn connection and try again."
        }

        refreshDiffs()
    }

    override func awakeFromNib() {
        let icon = knife
        icon.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        NSUserNotificationCenter.default.delegate = self
        
        if (defaults.hasApiToken()) {
            initPhabricator()
        } else {
            // show login window
            loginWindowController.window?.center()
            loginWindowController.window?.delegate = self
            loginWindowController.showWindow(self)
        }
        
        refreshDiffs()
    }

    private func refreshDiffs() {
        refreshMenuItem.image = nil
        if let phab = self.phab {
            phab.fetchActiveDiffs() { response in
                self.statusItem.image = self.knife
                self.refreshMenuItem.image = nil
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
        // update title
        self.statusItem.title = "\(diffs.count)"
        print("Fetched \(diffs.count) active diffs")
        
        // clear out last update's menu items
        while (statusMenu.items.count > INSERTION_INDEX + 1) {
            statusMenu.removeItem(at: INSERTION_INDEX)
        }

        var newDiffs: [Diff] = []
        var newKnownDiffIds: Set<String> = []
        let sortedDiffs = sortDiffs(userPhid: userPhid!, diffs: diffs)
        for category in categories {
            let diffs = sortedDiffs[category]!
            let header = NSMenuItem(title: category.title, action: nil, keyEquivalent: "")
            insertMenuItem(menuItem: header)
            
            // if this category is empty, insert the empty message
            if (diffs.isEmpty) {
                let empty = NSMenuItem(title: category.emptyMessage, action: nil, keyEquivalent: "")
                empty.indentationLevel = 1
                insertMenuItem(menuItem: empty)
            }

            for diff in diffs {
                // always add to new known diffs
                newKnownDiffIds.insert(diff.phid)

                // add to new diffs if we haven't seen it yet
                if !knownDiffIds.contains(diff.phid) {
                    newDiffs.append(diff)
                }

                // insert the diff's row
                let row = NSMenuItem(title: diff.fields.title, action: #selector(onDiffMenuItemClicked), keyEquivalent: "")
                row.target = self
                row.representedObject = diff
                row.image = NSImage(named: NSImage.Name(rawValue: diff.fields.status.value))
                insertMenuItem(menuItem: row)
            }
            
            insertMenuItem(menuItem: NSMenuItem.separator())
        }

        // notify for new diffs!
        showNotification(diffs: newDiffs)

        // setup known diffs for next iteration
        self.knownDiffIds = newKnownDiffIds
    }
    
    @objc private func onDiffMenuItemClicked(_ menuItem: NSMenuItem) {
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
