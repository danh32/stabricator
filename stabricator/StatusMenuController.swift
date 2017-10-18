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
    var actionableDiffIds: Set<String> = []

    @IBAction func refreshClicked(_ sender: Any) {
        refreshDiffs()
    }

    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    override func awakeFromNib() {
        let icon = knife
        icon.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        NSUserNotificationCenter.default.delegate = self
        
        if (defaults.hasApiToken()) {
            // if we already have an api token, init phabricator immediately
            initPhabricator()
        } else {
            // otherwise, show login window
            loginWindowController.window?.center()
            loginWindowController.window?.delegate = self
            loginWindowController.showWindow(self)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        if (defaults.hasApiToken()) {
            // login window closing, initialize phabricator
            initPhabricator()
        } else {
            // user clicked close window, so close program
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

        // fetch diffs now that we've initialized
        refreshDiffs()
    }

    private func refreshDiffs() {
        refreshMenuItem.image = nil
        if let phab = self.phab {
            phab.fetchActiveDiffs() { response in
                self.statusItem.image = self.knife
                self.refreshMenuItem.image = nil
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

        var diffsToNotify: [Diff] = []
        var newActionableDiffIds: Set<String> = []
        let sortedDiffs = sortDiffs(userPhid: userPhid!, diffs: diffs)
        for category in categories {
            let diffs = sortedDiffs[category]!
            let header = NSMenuItem(title: category.title, action: nil, keyEquivalent: "")
            insertMenuItem(menuItem: header)
            
            // if this category is empty, insert the empty message
            if (diffs.isEmpty) {
                let empty = NSMenuItem(
                    title: category.emptyMessage,
                    action: nil,
                    keyEquivalent: ""
                )
                empty.indentationLevel = 1
                insertMenuItem(menuItem: empty)
            }

            for diff in diffs {
                // check to see if we should notify for this diff
                if diff.isActionable(userPhid: userPhid!) {
                    // keep track of all actionable diffs for this iteration
                    newActionableDiffIds.insert(diff.phid)
                    // we'll send an alert for diffs that are now actionable that weren't last time
                    if !actionableDiffIds.contains(diff.phid) {
                        diffsToNotify.append(diff)
                    }
                }

                // insert the diff's row
                insertMenuItem(menuItem: createMenuItemFor(diff: diff))
            }
            
            insertMenuItem(menuItem: NSMenuItem.separator())
        }

        // notify for newly actionable diffs!
        showNotification(diffs: diffsToNotify)

        // setup known actionable diffs for next iteration
        self.actionableDiffIds = newActionableDiffIds
    }
    
    private func createMenuItemFor(diff: Diff) -> NSMenuItem {
        let menuItem = NSMenuItem(
            title: diff.fields.title,
            action: #selector(onDiffMenuItemClicked),
            keyEquivalent: ""
        )
        menuItem.target = self
        menuItem.representedObject = diff
        menuItem.image = NSImage(named: NSImage.Name(rawValue: diff.fields.status.value))
        return menuItem
    }
    
    @objc private func onDiffMenuItemClicked(_ menuItem: NSMenuItem) {
        let diff = menuItem.representedObject as! Diff
        let url = phab?.getDiffWebUrl(diff: diff)
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
