//
//  SortedDiffs.swift
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

    // TODO: figure out this condition - I don't think we have enough info with the single query
//    Category(title: "Must Review", emptyMessage: "No revisions are blocked on your review.") { _, _ in false },
    
    // TODO: get empty message
    Category(title: "Ready to Review", emptyMessage: "No revisions are ready to review.") { userPhid, diff in
        diff.fields.status.value == Status.NEEDS_REVIEW &&
            diff.fields.authorPHID != userPhid
    },
    
    Category(title: "Ready to Land", emptyMessage: "None of your revisions are ready to land.") { userPhid, diff in
        diff.fields.status.value == Status.ACCEPTED &&
            diff.fields.authorPHID == userPhid
    },
    
    Category(title: "Ready to Update", emptyMessage: "None of your revisions are ready to update.") { userPhid, diff in
        (diff.fields.status.value == Status.NEEDS_REVISION ||
            diff.fields.status.value == Status.CHANGES_PLANNED) &&
            diff.fields.authorPHID == userPhid
    },

    Category(title: "Drafts", emptyMessage: "You have no draft revisions.") { _, diff in
        diff.fields.status.value == Status.DRAFT
    },
    
    Category(title: "Waiting on Review", emptyMessage: "None of your revisions are waiting on review.") { userPhid, diff in
        diff.fields.status.value == Status.NEEDS_REVIEW &&
            diff.fields.authorPHID == userPhid
    },
    
    Category(title: "Waiting on Authors", emptyMessage: "No revisions are waiting on authors.") { userPhid, diff in
        (diff.fields.status.value == Status.ACCEPTED ||
            diff.fields.status.value == Status.NEEDS_REVISION) &&
            diff.fields.authorPHID != userPhid
    },

    // TODO: figure out this condition - I don't think we have enough info with the single query
//    Category(title: "Waiting on Other Reviewers", emptyMessage: "No revisions are waiting on other reviewers.") { _, _ in false },
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
