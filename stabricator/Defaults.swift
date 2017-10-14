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
    private let KEY_REFRESH_INTERVAL = "refreshInterval"
    
    private let defaults: UserDefaults
    
    init() {
        self.defaults = UserDefaults()
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
