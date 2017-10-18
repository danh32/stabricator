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
    let attachments: Attachments?
    
    func isActionable(userPhid: String) -> Bool {
        let selfAuthored = isAuthoredBy(userPhid: userPhid)
        let acceptedByUser = isAcceptedBy(userPhid: userPhid)
        switch fields.status.value {
        case Status.NEEDS_REVIEW:
            return !selfAuthored && !acceptedByUser
        case Status.NEEDS_REVISION:
            return selfAuthored
        case Status.ACCEPTED:
            return selfAuthored
        case Status.CHANGES_PLANNED:
            return selfAuthored
        case Status.DRAFT:
            return false
        default:
            return false
        }
    }
    
    func isStatus(status: String) -> Bool {
        return fields.status.value == status
    }
    
    func isAuthoredBy(userPhid: String) -> Bool {
        return fields.authorPHID == userPhid
    }
    
    func isBlockingReviewer(userPhid: String) -> Bool {
        let reviewer = attachments?.reviewers?.reviewers.first() { reviewer in
            reviewer.reviewerPHID == userPhid
        }
        return reviewer?.isBlocking ?? false
    }
    
    func isAcceptedBy(userPhid: String) -> Bool {
        let reviewer = attachments?.reviewers?.reviewers.first() { reviewer in
            reviewer.reviewerPHID == userPhid
        }
        return reviewer?.status == "accepted"
    }
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
    static let CHANGES_PLANNED = "changes-planned"
    static let DRAFT = "draft"
    
    let value: String
    let name: String
    let closed: Bool
}

struct Attachments : Codable {
    let reviewers: Reviewers?
}

struct Reviewers : Codable {
    let reviewers: [Reviewer]
}

struct Reviewer : Codable {
    let reviewerPHID: String
    // added, accepted, or rejected
    let status: String
    let isBlocking: Bool
    let actorPHID: String?
}

struct User: Codable {
    let phid: String
    let userName: String
    let realName: String
    let image: String
    let uri: String
    let primaryEmail: String
}
