//
//  GraphJsCallResults.swift
//  GraphJS
//
//  Created by CAMOBAP on 8/31/18.
//  Copyright © 2018 Dial-Once. All rights reserved.
//

import Foundation

/// Common result struct to keep result of operation with description in case of any errors
struct GraphJsCallResult: Codable {
    public let success: Bool
    public let reason: String?

    init(success: Bool = false, reason: String? = nil) {
        self.success = success
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
    }
}

/// Common result struct to keep ids of any newly created entity
struct GraphJsCreateResult: Decodable {
    let success: Bool
    let reason: String?
    let id: String?

    init(success: Bool = false, reason: String? = nil, id: String? = nil) {
        self.success = success
        self.reason = reason
        self.id = id
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.success = try values.decode(Bool.self, forKey: .success)
        self.reason = try values.decodeIfPresent(String?.self, forKey: .reason) ?? nil

        if values.contains(.id) {
            self.id = try values.decode(String.self, forKey: .id)
        } else {
            self.id = try values.decodeIfPresent(String.self, forKey: .commentId) ?? nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case id
        case commentId = "comment_id"
    }
}

/// Common result struct to keep any count result
struct GraphJsCountResult: Codable {
    let success: Bool
    let reason: String?
    let count: Int

    init(success: Bool = false, reason: String? = nil, count: Int = 0) {
        self.success = success
        self.reason = reason
        self.count = count
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case count
    }
}

struct GraphJsRegisterResult: Codable {
    let success: Bool
    let reason: String?
    let userId: String?

    init(success: Bool = false, reason: String? = nil, userId: String? = nil) {
        self.success = success
        self.reason = reason
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case userId = "id"
    }
}

struct GraphJsLoginResult: Codable {
    let success: Bool
    let reason: String?
    let userId: String?

    init(success: Bool = false, reason: String? = nil, userId: String? = nil) {
        self.success = success
        self.reason = reason
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case userId = "id"
    }
}

struct GraphJsProfileResult: Codable {
    let success: Bool
    let reason: String?
    let profile: UserProfile?

    init(success: Bool = false, reason: String? = nil, profile: UserProfile? = nil) {
        self.success = success
        self.reason = reason
        self.profile = profile
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case profile
    }
}

struct GraphJsThreadResult: Codable {
    let success: Bool
    let reason: String?
    let title: String?
    let messages: [ThreadMessage]

    init(success: Bool = false, reason: String? = nil, title: String? = nil, messages: [ThreadMessage] = []) {
        self.success = success
        self.reason = reason
        self.title = title
        self.messages = messages
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case title
        case messages
    }
}

struct GraphJsThreadsResult: Codable {
    let success: Bool
    let reason: String?
    let threads: [ForumThread]

    init(success: Bool = false, reason: String? = nil, threads: [ForumThread] = []) {
        self.success = success
        self.reason = reason
        self.threads = threads
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case threads
    }
}

struct GraphJsFeedTokenResult: Codable {
    let success: Bool
    let reason: String?
    let token: String?

    init(success: Bool = false, reason: String? = nil, token: String? = nil) {
        self.success = success
        self.reason = reason
        self.token = token
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case token
    }
}

struct GraphJsMembersResult: Decodable {
    let success: Bool
    let reason: String?
    let members: [String: Member]

    init(success: Bool = false, reason: String? = nil, members: [String: Member] = [:]) {
        self.success = success
        self.reason = reason
        self.members = members
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.success = try values.decode(Bool.self, forKey: .success)
        self.reason = try values.decodeIfPresent(String?.self, forKey: .reason) ?? nil

        do {
            if values.contains(.members) {
                self.members = try values.decode([String: Member].self, forKey: .members)
            } else if values.contains(.following) {
                self.members = try values.decode([String: Member].self, forKey: .following)
            } else if values.contains(.followers) {
                self.members = try values.decode([String: Member].self, forKey: .followers)
            } else {
                self.members = [:]
            }
        } catch is DecodingError {
            // We need this becuse for .members/.following/.followers server may return both array (for empty values) and object
            self.members = [:]
        }
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case members
        case following
        case followers
    }
}

struct GraphJsDirectMessageResult: Codable {
    let success: Bool
    let reason: String?
    let message: DirectMessage?

    init(success: Bool = false, reason: String? = nil, message: DirectMessage? = nil) {
        self.success = success
        self.reason = reason
        self.message = message
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case message
    }
}

struct GraphJsDirectMessagesResult: Codable {
    let success: Bool
    let reason: String?
    let messages: [String: DirectMessage]

    init(success: Bool = false, reason: String? = nil, messages: [String: DirectMessage] = [:]) {
        self.success = success
        self.reason = reason
        self.messages = messages
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case messages
    }
}

struct GraphJsGroupsResult: Codable {
    let success: Bool
    let reason: String?
    let groups: [Group]

    init(success: Bool = false, reason: String? = nil, groups: [Group] = []) {
        self.success = success
        self.reason = reason
        self.groups = groups
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case groups
    }
}

struct GraphJsGroupResult: Codable {
    let success: Bool
    let reason: String?
    let group: Group?

    init(success: Bool = false, reason: String? = nil, group: Group? = nil) {
        self.success = success
        self.reason = reason
        self.group = group
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case group
    }
}

struct GraphJsGroupMembersResult: Codable {
    let success: Bool
    let reason: String?
    let memberIds: [String]

    init(success: Bool = false, reason: String? = nil, memberIds: [String] = []) {
        self.success = success
        self.reason = reason
        self.memberIds = memberIds
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case memberIds = "members"
    }
}

struct GraphJsIsStarredResult: Codable {
    let success: Bool
    let reason: String?
    let count: Int
    let starredByMe: Bool?

    init(success: Bool = false, reason: String? = nil, count: Int = 0, starredByMe: Bool = false) {
        self.success = success
        self.reason = reason
        self.count = count
        self.starredByMe = starredByMe
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case count
        case starredByMe = "starred"
    }
}

struct GraphJsStarsStatResult: Codable {
    let success: Bool
    let reason: String?
    let pages: [String: StarsStatEntry]

    init(success: Bool = false, reason: String? = nil, pages: [String: StarsStatEntry] = [:]) {
        self.success = success
        self.reason = reason
        self.pages = pages
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case pages
    }
}

struct GraphJsCommentsResult: Decodable {
    let success: Bool
    let reason: String?
    let comments: [String: ContentComment]

    init(success: Bool = false, reason: String? = nil, comments: [String: ContentComment] = [:]) {
        self.success = success
        self.reason = reason
        self.comments = comments
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.success = try values.decode(Bool.self, forKey: .success)

        if values.contains(.reason) {
            self.reason = try values.decode(String?.self, forKey: .reason)
        } else {
            self.reason = nil
        }

        var comments : [String: ContentComment] = [:]

        let arrayMapComment = try values.decode([[String: ContentComment]].self, forKey: .comments)
        for mapComment in arrayMapComment {
            for (commentId, comment) in mapComment {
                comments[commentId] = comment
            }
        }

        self.comments = comments
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case comments
    }
}

struct GraphJsContentResult: Codable {
    let success: Bool
    let reason: String?
    let content: String?

    init(success: Bool = false, reason: String? = nil, content: String? = nil) {
        self.success = success
        self.reason = reason
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case success
        case reason
        case content = "contents"
    }
}
