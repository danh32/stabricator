//
//  Defaults.swift
//  stabricator
//
//  Created by Dan Hill on 10/14/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Foundation

class Defaults {
    private let KEY_PHAB_URL = "phabUrl"
    private let KEY_API_TOKEN = "apiToken"
    // TODO: store user object instead?
    private let KEY_USER = "user"
    private let KEY_REFRESH_INTERVAL = "refreshInterval"
    private let KEY_AUTO_START = "autoStart"
    private let KEY_NOTIFY = "notify"
    private let KEY_PLAY_SOUND = "playSound"
    
    private let defaults: UserDefaults
    
    init() {
        self.defaults = UserDefaults()
    }
    
    func hasApiToken() -> Bool {
        return apiToken != nil
    }
    
    func clearAll() {
        defaults.removeObject(forKey: KEY_PHAB_URL)
        defaults.removeObject(forKey: KEY_API_TOKEN)
        defaults.removeObject(forKey: KEY_REFRESH_INTERVAL)
        defaults.synchronize()
    }
    
    var phabricatorUrl: String? {
        get {
            return defaults.string(forKey: KEY_PHAB_URL)
        }
        set(value) {
            defaults.set(value, forKey: KEY_PHAB_URL)
        }
    }
    
    var apiToken: String? {
        get {
            return defaults.string(forKey: KEY_API_TOKEN)
        }
        set(value) {
            defaults.set(value, forKey: KEY_API_TOKEN)
        }
    }
    
    var user: User? {
        get {
            let decoder = PropertyListDecoder()
            if let userData = defaults.data(forKey: KEY_USER) {
                let user = try? decoder.decode(User.self, from: userData)
                return user
            }
            return nil
        }
        set(value) {
            let encoder = PropertyListEncoder()
            if let encoded = try? encoder.encode(value) {
                defaults.set(encoded, forKey: KEY_USER)
            }
        }
    }
    
    var refreshInterval: Int? {
        get {
            let value = defaults.integer(forKey: KEY_REFRESH_INTERVAL)
            return value == 0 ? nil : value
        }
        set(value) {
            defaults.set(value, forKey: KEY_REFRESH_INTERVAL)
        }
    }
    
    var autoStart: Bool? {
        get {
            return defaults.object(forKey: KEY_AUTO_START) == nil
                ? defaults.bool(forKey: KEY_AUTO_START)
                : nil
        }
        set(value) {
            defaults.set(value, forKey: KEY_AUTO_START)
        }
    }

    
    var notify: Bool? {
        get {
            return defaults.object(forKey: KEY_NOTIFY) == nil
                ? defaults.bool(forKey: KEY_NOTIFY)
                : nil
        }
        set(value) {
            defaults.set(value, forKey: KEY_NOTIFY)
        }
    }
    
    var playSound: Bool? {
        get {
            return defaults.object(forKey: KEY_PLAY_SOUND) == nil
                ? defaults.bool(forKey: KEY_PLAY_SOUND)
                : nil
        }
        set(value) {
            defaults.set(value, forKey: KEY_PLAY_SOUND)
        }
    }
}
