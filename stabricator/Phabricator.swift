//
//  Phabricator.swift
//  weatherbar
//
//  Created by Dan Hill on 10/10/17.
//  Copyright © 2017 Dan Hill. All rights reserved.
//

import Foundation

class Phabricator {

    let PHABRICATOR_URL: String
    let API_TOKEN: String
    let PATH_DIFFS_SEARCH = "differential.revision.search"
    let PATH_USER_SELF = "user.whoami"

    init(phabricatorUrl: String, apiToken: String) {
        self.PHABRICATOR_URL = phabricatorUrl
        self.API_TOKEN = apiToken
    }

    func fetchUser(success: @escaping (Response<User>) -> Void) {
        var request = getRequest(url: PHABRICATOR_URL + PATH_USER_SELF)
        request.httpBody = "api.token=\(API_TOKEN)".data(using: .utf8)
        execute(request: request, type: Response<User>.self, success: success)
    }

    func fetchActiveDiffs(success: @escaping (DiffArrayResponse) -> Void) {
        var request = getRequest(url: PHABRICATOR_URL + PATH_DIFFS_SEARCH)
        request.httpBody = "api.token=\(API_TOKEN)&queryKey=active".data(using: .utf8)
        execute(request: request, type: DiffArrayResponse.self, success: success)
    }
    
    func getRequest(url: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    func execute<T: Decodable>(request: URLRequest, type: T.Type, success: @escaping (T) -> Void) {
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
                        if let response = self.parseJsonResponse(jsonString: dataString, type: type) {
                            success(response)
                        }
                    }

                default:
                    print("Phabricator api returned response: %d %@", httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                }
            }
        }
        task.resume()
    }
    
    func parseJsonResponse<T: Decodable>(jsonString: String, type: T.Type) -> T? {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(type, from: jsonData)
    }
}
