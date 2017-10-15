//
//  Models.swift
//  stabricator
//
//  Created by Dan Hill on 10/14/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Foundation

typealias DiffArrayResponse = Response<ListResult<Diff>>

struct Response<T: Codable> : Codable {
    let result: T
    let error_code: String?
    let error_info: String?
}

struct ListResult<T: Codable> : Codable {
    let data: [T]
}

struct Diff : Codable {
    let id: Int
    let phid: String
    let fields: Fields
}

struct Fields : Codable {
    let title: String
    let authorPHID: String
    let status: Status
    let dateCreated: Date
    let dateModified: Date
}

struct Status : Codable {
    static let NEEDS_REVIEW = "needs-review"
    static let NEEDS_REVISION = "needs-revision"
    static let ACCEPTED = "accepted"
    
    let value: String
    let name: String
    let closed: Bool
    // TODO: use codingkeys later
    //    let color.ansi: String
}

struct User: Codable {
    let phid: String
    let userName: String
    let realName: String
    let image: String
    let uri: String
    let primaryEmail: String
}
