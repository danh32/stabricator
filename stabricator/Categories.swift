//
//  Categories.swift
//  stabricator
//
//  Created by Dan Hill on 10/14/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Foundation

struct Category : Hashable {
    // ui title
    let title: String
    // message to show when the diff list is empty
    let emptyMessage: String
    // decides if the diff is of this category
    let isOfType: (String, Diff) -> Bool

    var hashValue: Int {
        return title.hashValue
    }
    
    static func ==(lhs: Category, rhs: Category) -> Bool {
        return lhs.title == rhs.title
    }
}

let categories: [Category] = [

    Category(title: "Must Review", emptyMessage: "No revisions are blocked on your review.") { userPhid, diff in
        diff.isStatus(Status.NEEDS_REVIEW) &&
            !diff.isAuthoredBy(userPhid) &&
            diff.isBlockingReviewer(userPhid)
    },

    // TODO: get empty message
    Category(title: "Ready to Review", emptyMessage: "No revisions are ready to review.") { userPhid, diff in
        diff.isStatus(Status.NEEDS_REVIEW) &&
            !diff.isAuthoredBy(userPhid) &&
            !diff.isAcceptedBy(userPhid)
    },
    
    Category(title: "Ready to Land", emptyMessage: "No revisions are ready to land.") { userPhid, diff in
        diff.isStatus(Status.ACCEPTED) &&
            diff.isAuthoredBy(userPhid)
    },
    
    Category(title: "Ready to Update", emptyMessage: "None of your revisions are ready to update.") { userPhid, diff in
        diff.isStatus(Status.NEEDS_REVISION, Status.CHANGES_PLANNED) &&
            diff.isAuthoredBy(userPhid)
    },

    Category(title: "Drafts", emptyMessage: "You have no draft revisions.") { _, diff in
        diff.isStatus(Status.DRAFT)
    },
    
    Category(title: "Waiting on Review", emptyMessage: "None of your revisions are waiting on review.") { userPhid, diff in
        diff.isStatus(Status.NEEDS_REVIEW) &&
            diff.isAuthoredBy(userPhid)
    },
    
    Category(title: "Waiting on Authors", emptyMessage: "No revisions are waiting on authors.") { userPhid, diff in
        diff.isStatus(Status.ACCEPTED, Status.NEEDS_REVISION, Status.CHANGES_PLANNED) &&
            !diff.isAuthoredBy(userPhid)
    },

    Category(title: "Waiting on Other Reviewers", emptyMessage: "No revisions are waiting for other reviewers.") { userPhid, diff in
        diff.isStatus(Status.NEEDS_REVIEW) &&
            !diff.isAuthoredBy(userPhid) &&
            diff.isAcceptedBy(userPhid)
    },
]

func sortDiffs(userPhid: String, diffs: [Diff]) -> Dictionary<Category, [Diff]> {
    var sorted = [Category: [Diff]]()

    for diff in diffs {
        var claimed = false
        
        for category in categories {
            // initialize dictionary with empty array
            if sorted[category] == nil {
                sorted[category] = [Diff]()
            }
            
            if category.isOfType(userPhid, diff) {
                sorted[category]!.append(diff)
                claimed = true
            }
        }

        if !claimed {
            print("No category claimed: \(diff.fields.title)")
        }
    }
    
    return sorted
}
