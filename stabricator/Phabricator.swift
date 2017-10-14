//
//  Phabricator.swift
//  weatherbar
//
//  Created by Dan Hill on 10/10/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Foundation

class Phabricator {

    let API_PATH = "/api/differential.revision.search"
    let PHABRICATOR_URL: String
    let REQUEST_BODY: String
    
    init(phabricatorUrl: String, apiToken: String) {
        self.PHABRICATOR_URL = "\(phabricatorUrl)/\(API_PATH)"
        self.REQUEST_BODY = "api.token=\(apiToken)&queryKey=active"
    }
    
    func fetchActiveDiffs(success: @escaping (Response) -> Void) {
        let url = URL(string: PHABRICATOR_URL)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = REQUEST_BODY.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, err in
            // first check for a hard error
            if let error = err {
                print("Phabricator api error: \(error)")
            }
            
            // then check the response code
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: // all good!
                    if let dataString = String(data: data!, encoding: .utf8) {
                        if let response = self.parseJsonResponse(jsonString: dataString) {
                            success(response)
                        }
                    }
                case 401: // unauthorized
                    print("Phabricator returned an 'unauthorized' response. Did you set your API key?")
                default:
                    print("Phabricator api returned response: %d %@", httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                }
            }
        }
        task.resume()
    }
    
    func parseJsonResponse(jsonString: String) -> Response? {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(Response.self, from: jsonData)
    }
}

struct Response : Codable {
    let result: Result
    let error_code: String?
    let error_info: String?
}

struct Result : Codable {
    let data: [Diff]
}

struct Diff : Codable {
    let id: Int
    let type: Type
    let phid: String
    let fields: Fields
}

enum Type : String, Codable {
    case DREV
    // others??
}

struct Fields : Codable {
    let title: String
    let authorPHID: String
    let status: Status
    let dateCreated: Date
    let dateModified: Date
}

struct Status : Codable {
    let value: String
    let name: String
    let closed: Bool
    // TODO: use codingkeys later
    //    let color.ansi: String
}
