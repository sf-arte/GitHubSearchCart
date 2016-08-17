// The MIT License (MIT)
//
// Copyright (c) 2015 Hatena Co., Ltd.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

import Alamofire
import SwiftyJSON

public typealias RequestParamater = [String: AnyObject]

/**
Request paremeters
*/
public struct Parameters: DictionaryLiteralConvertible {
    public private(set) var dictionary: [String: AnyObject] = [:]
    public typealias Key = String
    public typealias Value = AnyObject?
    /**
    Initialized from dictionary literals
    */
    public init(dictionaryLiteral elements: (Parameters.Key, Parameters.Value)...) {
        for case let (key, value?) in elements {
            dictionary[key] = value
        }
    }
}

/**
API error
- UnexpectedResponse: Unexpected structure
*/
public enum APIError: ErrorProtocol {
    case UnexpectedResponse
}

/** GitHub API
- SeeAlso: https://developer.github.com/v3/s
*/
public class GitHubAPI {

    public init() {
    }

    /**
    Perform HTTP request for any endpoints.
    - Parameters:
      - params: "GET" parameters.
      - handler:  Request results handler.
    */
    public func request(params: RequestParamater, handler: (response: SearchResult<Repository>?) -> Void) -> Void{
        Alamofire.request(.GET, "https://api.github.com/search/repositories", parameters: params, encoding: .url, headers: nil).responseJSON{ response in
            let response = response.result.value.flatMap {
                SearchResult<Repository>(json: JSON($0))
            }
            handler(response: response)
        }
        
    }

}

/**
JSON decodable type
*/
public protocol JSONDecodable {
    init?(json: JSON)
}

/**
JSON decode error
- MissingRequiredKey:   Required key is missing
- UnexpectedType:       Value type is unexpected
- CannotParseURL:       Value cannot be parsed as URL
- CannotParseDate:      Value cannot be parsed as date
*/
public enum JSONDecodeError: ErrorProtocol, CustomDebugStringConvertible {
    case MissingRequiredKey(String)
    case UnexpectedType(key: String, expected: Any.Type, actual: Any.Type)
    case CannotParseURL(key: String, value: String)
    case CannotParseDate(key: String, value: String)

    public var debugDescription: String {
        switch self {
        case .MissingRequiredKey(let key):
            return "JSON Decode Error: Required key '\(key)' missing"
        case let .UnexpectedType(key: key, expected: expected, actual: actual):
            return "JSON Decode Error: Unexpected type '\(actual)' was supplied for '\(key): \(expected)'"
        case let .CannotParseURL(key: key, value: value):
            return "JSON Decode Error: Cannot parse URL '\(value)' for key '\(key)'"
        case let .CannotParseDate(key: key, value: value):
            return "JSON Decode Error: Cannot parse date '\(value)' for key '\(key)'"
        }
    }
}

/**
Search result data
- SeeAlso: https://developer.github.com/v3/search/
*/
public struct SearchResult<ItemType: JSONDecodable>: JSONDecodable {
    public let totalCount: Int
    public let incompleteResults: Bool
    public let items: [ItemType]

    public init?(json: JSON){
        guard let totalCount = json["total_count"].int,
            let incompleteResults = json["incomplete_results"].bool,
            let items = json["items"].array else{ return nil }
        self.totalCount = totalCount
        self.incompleteResults = incompleteResults
        var tmpItems : [ItemType] = []
        for i in items {
            guard let item = ItemType(json: i) else { return nil }
            tmpItems.append(item)
        }
        self.items = tmpItems
    }
}

/**
Repository data
- SeeAlso: https://developer.github.com/v3/search/#search-repositories
*/
public struct Repository: JSONDecodable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let isPrivate: Bool
    public let HTMLURL: NSURL
    public let description: String?
    public let fork: Bool
    public let URL: NSURL
    public let createdAt: NSDate
    public let updatedAt: NSDate
    /*
    public let pushedAt: NSDate?
    public let homepage: String?
    public let size: Int
    public let stargazersCount: Int
    public let watchersCount: Int
    public let language: String?
    public let forksCount: Int
    public let openIssuesCount: Int
    public let masterBranch: String?
    public let defaultBranch: String
    public let score: Double
    public let owner: User
    */

    public init?(json: JSON) {
        guard let id = json["id"].int,
            let name = json["name"].string,
            let fullName = json["full_name"].string,
            let isPrivate = json["private"].bool,
            let HTMLURL = json["html_url"].string,
            let description = json["description"].string,
            let fork = json["fork"].bool,
            let URL = json["url"].string,
            let createdAt = json["created_at"].string,
            let updatedAt = json["updated_at"].string
            else {
                return nil
        }
        /*
        self.pushedAt = try getOptionalDate(JSON: JSON, key: "pushed_at")
        self.homepage = try getOptionalValue(JSON: JSON, key: "homepage")
        self.size = try getValue(JSON: JSON, key: "size")
        self.stargazersCount = try getValue(JSON: JSON, key: "stargazers_count")
        self.watchersCount = try getValue(JSON: JSON, key: "watchers_count")
        self.language = try getOptionalValue(JSON: JSON, key: "language")
        self.forksCount = try getValue(JSON: JSON, key: "forks_count")
        self.openIssuesCount = try getValue(JSON: JSON, key: "open_issues_count")
        self.masterBranch = try getOptionalValue(JSON: JSON, key: "master_branch")
        self.defaultBranch = try getValue(JSON: JSON, key: "default_branch")
        self.score = try getValue(JSON: JSON, key: "score")
        self.owner = try User(JSON: getValue(JSON: JSON, key: "owner") as JSONObject)
         */
        
        
        guard let uHTMLURL = NSURL(string: HTMLURL),
            let uURL = NSURL(string: URL),
            let uCreatedAt = dateFormatter.date(from: createdAt),
            let uUpdatedAt = dateFormatter.date(from: updatedAt)
            else {
                return nil
        }
        
        
        self.id = id
        self.name = name
        self.fullName = fullName
        self.isPrivate = isPrivate
        self.HTMLURL = uHTMLURL
        self.description = description
        self.fork = fork
        self.URL = uURL
        self.createdAt = uCreatedAt
        self.updatedAt = uUpdatedAt
        
    }
}

/**
User data
- SeeAlso: https://developer.github.com/v3/search/#search-repositories
*/
/*
public struct User: JSONDecodable {
    public let login: String
    public let id: Int
    public let avatarURL: NSURL
    public let gravatarID: String
    public let URL: NSURL
    public let receivedEventsURL: NSURL
    public let type: String

    /**
    Initialize from JSON object
    - Parameter JSON: JSON object
    - Throws: JSONDecodeError
    - Returns: SearchResult
    */
    public init?(JSON: JSON){
        self.login = try getValue(JSON: JSON, key: "login")
        self.id = try getValue(JSON: JSON, key: "id")
        self.avatarURL = try getURL(JSON: JSON, key: "avatar_url")
        self.gravatarID = try getValue(JSON: JSON, key: "gravatar_id")
        self.URL = try getURL(JSON: JSON, key: "url")
        self.receivedEventsURL = try getURL(JSON: JSON, key: "received_events_url")
        self.type = try getValue(JSON: JSON, key: "type")
    }
}
*/



/**
Parse ISO 8601 format date string
- SeeAlso: https://developer.github.com/v3/#schema
*/
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(calendarIdentifier: Calendar.Identifier.gregorian)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return formatter
    }()
