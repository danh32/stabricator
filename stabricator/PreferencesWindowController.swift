//
//  PreferencesWindowController.swift
//  stabricator
//
//  Created by Dan Hill on 10/21/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate {

    @IBOutlet weak var userImage: NSImageView!
    @IBOutlet weak var userName: NSTextField!
    @IBOutlet weak var refreshInterval: NSTextField!
    @IBOutlet weak var startOnLaunch: NSButton!
    @IBOutlet weak var notifyActionable: NSButton!
    @IBOutlet weak var playSound: NSButton!
    
    let defaults = Defaults()
    let loginWindowController = LoginWindowController(windowNibName: NSNib.Name(rawValue: "LoginWindow"))
    
    override func windowDidLoad() {
        super.windowDidLoad()

        let user = defaults.user!
        userImage.image = NSImage(byReferencing: URL(string: user.image)!)
        userName.stringValue = user.realName

        refreshInterval.delegate = self
        refreshInterval.integerValue = defaults.refreshInterval ?? 60

        let autoStart = defaults.autoStart ?? false
        startOnLaunch.state = autoStart ? .on : .off

        let notifyEnabled = defaults.notify ?? true
        notifyActionable.state = notifyEnabled ? .on : .off

        let soundOn = defaults.playSound ?? true
        playSound.state = soundOn ? .on : .off
        playSound.isEnabled = notifyEnabled
    }
    
    @IBAction func onChangeLoginClicked(_ sender: Any) {
        loginWindowController.window?.center()
        loginWindowController.window?.delegate = self
        loginWindowController.showWindow(self)
    }
    
    func windowWillClose(_ notification: Notification) {
        if (defaults.hasApiToken()) {
            // refresh the ui
            windowDidLoad()
        }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        defaults.refreshInterval = refreshInterval.integerValue
    }
    
    @IBAction func onStartOnLaunchToggled(_ sender: Any) {
        // todo: set to start on launch??
        // https://stackoverflow.com/questions/35339277/make-swift-cocoa-app-launch-on-startup-on-os-x-10-11
    }

    @IBAction func onNotifyToggled(_ sender: Any) {
        defaults.notify = notifyActionable.state == .on
    }

    @IBAction func onPlaySoundToggled(_ sender: Any) {
        defaults.playSound = playSound.state == .on
    }
    
    @IBAction func onOkClicked(_ sender: Any) {
        close()
    }
}
