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
    let preferencesWindowController = PreferencesWindowController(windowNibName: NSNib.Name(rawValue: "PreferencesWindowController"))
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let knife = NSImage(named: NSImage.Name(rawValue: "knife"))!
    let error = NSImage(named: NSImage.Name(rawValue: "error"))!

    let defaults = Defaults.instance
    var phab: Phabricator? = nil
    var user: User? = nil
    var actionableDiffIds: Set<String> = []

    @IBAction func refreshClicked(_ sender: Any) {
        refreshDiffs()
    }

    @IBAction func preferencesClicked(_ sender: Any) {
        preferencesWindowController.window?.center()
//        preferencesWindowController.window?.delegate = self
        preferencesWindowController.showWindow(self)
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
        self.user = defaults.user
        
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
                
                self.scheduleRefresh()
            }
        }
    }
    
    private func scheduleRefresh() {
        let seconds = self.defaults.refreshInterval
        let deadlineTime = DispatchTime.now() + .seconds(seconds)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.refreshDiffs()
        }
    }

    private func refreshUi(diffs: [Diff]) {
        print("Fetched \(diffs.count) active diffs")
        
        // clear out last update's menu items
        while (statusMenu.items.count > INSERTION_INDEX + 2) {
            statusMenu.removeItem(at: INSERTION_INDEX)
        }

        var diffsToNotify: [Diff] = []
        var newActionableDiffIds: Set<String> = []
        let sortedDiffs = sortDiffs(userPhid: user!.phid, diffs: diffs)
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
                if diff.isActionable(userPhid: user!.phid) {
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
        
        // update title
        self.statusItem.title = "\(actionableDiffIds.count)"
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
        statusMenu.insertItem(menuItem, at: statusMenu.items.count - 2)
    }

    private func showNotification(diffs: [Diff]) -> Void {
        if (diffs.isEmpty || !defaults.notify) {
            return
        }

        for diff in diffs {
            let notification = NSUserNotification()
            notification.title = diff.fields.title
            notification.subtitle = diff.fields.status.name
            notification.identifier = "\(diff.id)"
            if (defaults.playSound) {
                notification.soundName = NSUserNotificationDefaultSoundName
            }
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return defaults.notify
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        let id = Int(notification.identifier!)!
        let url = phab!.getDiffWebUrl(diffId: id)
        NSWorkspace.shared.open(url)
        NSUserNotificationCenter.default.removeDeliveredNotification(notification)
    }
}
