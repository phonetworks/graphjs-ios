//
//  GraphJsModels.swift
//  GraphJS
//
//  Created by CAMOBAP on 9/1/18.
//  Copyright © 2018 Dial-Once. All rights reserved.
//

import Foundation

enum FeedType: String {
    case wall = "wall"
    case timeline = "timeline"
}

struct UserProfile: Codable {
    let username: String
    let email: String
    let joinTime: Date?
    let avatar: URL?
    let birthday: Date?
    let about: String?
    let followerCount: Int
    let followingCount: Int
    let membershipCount: Int

    init(username: String, email: String, joinTime: Date? = nil, avatar: URL? = nil, birthday: Date? = nil, about: String? = nil, followerCount: Int = 0, followingCount: Int = 0, membershipCount: Int = 0) {
        self.username = username
        self.email = email
        self.joinTime = joinTime
        self.avatar = avatar
        self.birthday = birthday
        self.about = about
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.membershipCount = membershipCount
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.username = try values.decode(String.self, forKey: .username)
        self.email = try values.decode(String.self, forKey: .email)
        self.joinTime = try values.decode(Date.self, forKey: .joinTime)
        self.avatar = URL(string: try values.decode(String.self, forKey: .avatar))
        self.about = try values.decode(String.self, forKey: .about)
        self.followerCount = try values.decode(Int.self, forKey: .followerCount)
        self.followingCount = try values.decode(Int.self, forKey: .followingCount)
        self.membershipCount = try values.decode(Int.self, forKey: .membershipCount)

        let birthDayString = try values.decode(String.self, forKey: .birthday)
        let birthdayFormatter = DateFormatter()
        birthdayFormatter.dateFormat = "MM/dd/yyyy"
        birthdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.birthday = birthdayFormatter.date(from: birthDayString)
    }

    enum CodingKeys: String, CodingKey {
        case username
        case email
        case joinTime = "jointime"
        case avatar
        case birthday
        case about
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case membershipCount = "membership_count"
    }
}

struct ForumThread: Codable {
    let id: String
    let title: String
    let authorId: String
    let createdAt: Date
    let contributors: [String: UserProfile]

    init(id: String, title: String, authorId: String, createdAt: Date, contributors: [String: UserProfile]) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.createdAt = createdAt
        self.contributors = contributors
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case authorId = "author"
        case createdAt = "timestamp"
        case contributors
    }
}

struct Member: Codable {
    let username: String
    let avatar: URL?

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.username = try values.decode(String.self, forKey: .username)
        self.avatar = URL(string: try values.decode(String.self, forKey: .avatar))
    }

    enum CodingKeys: String, CodingKey {
        case username
        case avatar
    }
}

struct ThreadMessage: Codable {
    let id: String
    let authorId: String
    let content: String
    let createdAt: Date?

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try values.decode(String.self, forKey: .id)
        self.authorId = try values.decode(String.self, forKey: .authorId)
        self.content = try values.decode(String.self, forKey: .content)
        if let createdAt = TimeInterval(try values.decode(String.self, forKey: .createdAt)) {
            self.createdAt = Date(timeIntervalSince1970: createdAt)
        } else {
            self.createdAt = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author"
        case content
        case createdAt = "timestamp"
    }
}

struct DirectMessage: Codable {
    /// may be empty for outgoing
    let fromUserId: String?
    /// may be empty for incoming
    let toUserId: String?
    let content: String?
    let isRead: Bool
    let sentTime: Date?

    init(fromUserId: String? = nil, toUserId: String? = nil, content: String? = nil, isRead: Bool = false, sentTime: Date? = nil) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.content = content
        self.isRead = isRead
        self.sentTime = sentTime
    }

    enum CodingKeys: String, CodingKey {
        case fromUserId = "from"
        case toUserId = "to"
        case content = "message"
        case isRead = "is_read"
        case sentTime = "timestamp"
    }
}

struct Group: Codable {
    let id: String
    let title: String
    let description: String
    let creatorId: String
    let cover: URL?
    let membersCounter: Int
    let memberIds: [String]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try values.decode(String.self, forKey: .id)
        self.title = try values.decode(String.self, forKey: .title)
        self.description = try values.decode(String.self, forKey: .description)
        self.creatorId = try values.decode(String.self, forKey: .creatorId)
        self.cover = URL(string: try values.decode(String.self, forKey: .cover))
        self.membersCounter = Int(try values.decode(String.self, forKey: .membersCounter)) ?? 0
        self.memberIds = try values.decodeIfPresent([String].self, forKey: .memberIds) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case creatorId = "creator"
        case cover
        case membersCounter = "count"
        case memberIds = "members"
    }
}

struct StarsStatEntry: Codable {
    let title: String
    let stars: Int

    init(title: String, stars: Int = 0) {
        self.title = title
        self.stars = stars
    }

    enum CodingKeys: String, CodingKey {
        case title
        case stars = "star_count"
    }
}

struct ContentComment: Codable {
    let content: String
    let createTime: Date
    let authorId: String

    init(content: String, createTime: Date, authorId: String) {
        self.content = content
        self.createTime = createTime
        self.authorId = authorId
    }

    enum CodingKeys: String, CodingKey {
        case content
        case createTime
        case authorId = "author"
    }
}
