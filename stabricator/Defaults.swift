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
    private let KEY_USER_PHID = "userPhid"
    private let KEY_USER_IMG_URL = "userImgUrl"
    private let KEY_REFRESH_INTERVAL = "refreshInterval"
    
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
        defaults.removeObject(forKey: KEY_USER_PHID)
        defaults.removeObject(forKey: KEY_USER_IMG_URL)
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
    
    var userPhid: String? {
        get {
            return defaults.string(forKey: KEY_USER_PHID)
        }
        set(value) {
            defaults.set(value, forKey: KEY_USER_PHID)
        }
    }

    var userImage: String? {
        get {
            return defaults.string(forKey: KEY_USER_IMG_URL)
        }
        set(value) {
            defaults.set(value, forKey: KEY_USER_IMG_URL)
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
}
