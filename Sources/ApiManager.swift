//
//  GraphJsApiManager.swift
//  GraphJS-iOS
//
//  Created by CAMOBAP on 8/30/18.
//  Copyright © 2018 Pho Networks. All rights reserved.
//

import Foundation
import os
import os.log

@objc
class GraphJsApiManager : NSObject {
    static let log = OSLog(subsystem: "com.phonetwork.graphjs-ios", category: "ApiManager")
    static let cookieExpirationInterval : TimeInterval = 10 * 60 // 10 min

    let urlSession = URLSession(configuration: .default)
    let birthdayDateFormatter = DateFormatter()

    let publicId: String!
    let serverUrl: URL!
    let requestTimeoutInterval: TimeInterval
    let debugEnabled: Bool

    var currentUserId: String?

    init(publicId: String!,
         serverUrl: URL! = URL(string: "https://phonetworks.com:1338/")!,
         requestTimeoutInterval: TimeInterval = 20,
         debugEnabled: Bool = false) {
        self.publicId = publicId
        self.requestTimeoutInterval = requestTimeoutInterval
        self.serverUrl = serverUrl
        self.debugEnabled = debugEnabled

        birthdayDateFormatter.dateFormat = "MM/dd/yyyy"
    }

    func signup(username: String, email: String, password: String, callback: @escaping (GraphJsRegisterResult) -> Void) -> URLSessionTask? {
        let params = ["username": username, "email": email, "password": password]

        return sendRequest("signup", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsRegisterResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsRegisterResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsRegisterResult(success: false, reason: "Cannot parse response", userId: nil))
            }
        }
    }

    func login(username: String, password: String, callback: @escaping (GraphJsLoginResult) -> Void) -> URLSessionTask? {
        let params = ["username": username, "password": password]

        return sendRequest("login", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsLoginResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsLoginResult.self, from: data!) {
                if (result.success) {
                    self.currentUserId = result.userId

                    let cookieStorage = HTTPCookieStorage.shared;
                    let key = self.publicId.replacingOccurrences(of: "-", with: "")

                    var cookieProperties: [HTTPCookiePropertyKey: Any] = [:]
                    cookieProperties[HTTPCookiePropertyKey.name]    = "graphjs_\(key)_id"
                    cookieProperties[HTTPCookiePropertyKey.value]   = result.userId
                    cookieProperties[HTTPCookiePropertyKey.domain]  = self.serverUrl.host
                    cookieProperties[HTTPCookiePropertyKey.path]    = "/"
                    cookieProperties[HTTPCookiePropertyKey.version] = NSNumber(value: 0)
                    cookieProperties[HTTPCookiePropertyKey.expires] = NSDate()
                            .addingTimeInterval(GraphJsApiManager.cookieExpirationInterval)

                    cookieStorage.setCookie(HTTPCookie(properties: cookieProperties)!)

                    if let cookies = cookieStorage.cookies(for: self.serverUrl) {
                        for cookie in cookies {
                            if cookie.name == "graphjs_\(key)_session_off" {
                                cookieStorage.deleteCookie(cookie)
                            }
                        }
                    }
                }

                callback(result)
            } else {
                callback(GraphJsLoginResult(success: false, reason: "Cannot parse response", userId: nil))
            }
        }
    }

    func whoami(callback: @escaping (GraphJsLoginResult) -> Void) -> URLSessionTask? {
        return sendRequest("whoami") { (data, response, error) in
            if let error = error {
                callback(GraphJsLoginResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsLoginResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsLoginResult(success: false, reason: "Cannot parse response", userId: nil))
            }
        }
    }

    func logout(callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        return sendRequest("logout") { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                if (result.success) {
                    self.currentUserId = nil

                    let cookieStorage = HTTPCookieStorage.shared;
                    let key = self.publicId.replacingOccurrences(of: "-", with: "")

                    if let cookies = cookieStorage.cookies(for: self.serverUrl) {
                        for cookie in cookies {
                            if cookie.name == "graphjs_\(key)_id" {
                                cookieStorage.deleteCookie(cookie)
                            }
                        }
                    }

                    var cookieProperties: [HTTPCookiePropertyKey: Any] = [:]
                    cookieProperties[HTTPCookiePropertyKey.name]    = "graphjs_\(key)_session_off"
                    cookieProperties[HTTPCookiePropertyKey.value]   = "true"
                    cookieProperties[HTTPCookiePropertyKey.domain]  = self.serverUrl.host
                    cookieProperties[HTTPCookiePropertyKey.path]    = "/"
                    cookieProperties[HTTPCookiePropertyKey.version] = NSNumber(value: 1)
                    cookieProperties[HTTPCookiePropertyKey.expires] = nil

                    cookieStorage.setCookie(HTTPCookie(properties: cookieProperties)!)
                }

                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func resetPassword(email: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["email": email]

        return sendRequest("resetPassword", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func verifyPasswordReset(email: String, code: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["email": email, "code": code]

        return sendRequest("verifyReset", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    // MARK: Profile API

    func profile(userId: String? = nil, callback: @escaping (GraphJsProfileResult) -> Void) -> URLSessionTask? {
        let params = ["id": (userId ?? self.currentUserId)]

        return sendRequest("getProfile", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsProfileResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsProfileResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsProfileResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func setProfile(email: String? = nil, about: String? = nil, avatar: URL? = nil, birthday: Date? = nil,
                    username: String? = nil, password: String? = nil,
                    callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {

        var params = ["email": email, "about": about, "avatar": avatar?.absoluteString, "username": username, "password": password]

        if let birthday = birthday {
            params["birthday"] = birthdayDateFormatter.string(from: birthday)
        }

        return sendRequest("setProfile", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func generateFeedToken(type: FeedType, userId: String? = nil, callback: @escaping (GraphJsFeedTokenResult) -> Void) -> URLSessionTask? {
        let params = ["type": type.rawValue, "id": (userId ?? self.currentUserId)]

        return sendRequest("generateFeedToken", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsFeedTokenResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsFeedTokenResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsFeedTokenResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    // MARK: Thread API

    func startThread(title: String, message: String, callback: @escaping (GraphJsCreateResult) -> Void) -> URLSessionTask? {
        let params = ["title": title, "message": message]

        return sendRequest("startThread", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCreateResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCreateResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCreateResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func replyThread(threadId: String, message: String, callback: @escaping (GraphJsCreateResult) -> Void) -> URLSessionTask? {
        let params = ["id": threadId, "message": message]

        return sendRequest("reply", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCreateResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCreateResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCreateResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func getThread(threadId: String, callback: @escaping (GraphJsThreadResult) -> Void) -> URLSessionTask? {
        let params = ["id": threadId]

        return sendRequest("getThread", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsThreadResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsThreadResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsThreadResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func threads(callback: @escaping (GraphJsThreadsResult) -> Void) -> URLSessionTask? {
        return sendRequest("getThreads") { (data, response, error) in
            if let error = error {
                callback(GraphJsThreadsResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsThreadsResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsThreadsResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func deleteForumPost(postId: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": postId]

        return sendRequest("deleteForumPost", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    /**
     * NOTE: you cannot edit replies posts only threads
     */
    func editForumPost(postId: String, content: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": postId, "content": content]

        return sendRequest("editForumPost", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    // MARK: Members API

    func members(callback: @escaping (GraphJsMembersResult) -> Void) -> URLSessionTask? {
        return members("getMembers", callback)
    }

    func followers(userId: String? = nil, callback: @escaping (GraphJsMembersResult) -> Void) -> URLSessionTask? {
        return members("getFollowers", callback)
    }

    func following(userId: String? = nil, callback: @escaping (GraphJsMembersResult) -> Void) -> URLSessionTask? {
        return members("getFollowing", callback)
    }

    private func members(_ apiMethod: String, _ callback: @escaping (GraphJsMembersResult) -> Void) -> URLSessionTask? {
        return sendRequest(apiMethod) { (data, response, error) in
            if let error = error {
                callback(GraphJsMembersResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsMembersResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsMembersResult(success: false, reason: "Cannot parse response for \(#function)/\(apiMethod)"))
            }
        }
    }

    func follow(followeeId: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": followeeId]

        return sendRequest("follow", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func unfollow(followeeId: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": followeeId]

        return sendRequest("unfollow", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }


    // MARK: Direct Messaging API

    func sendDirectMessage(toUserId: String, message: String, callback: @escaping (GraphJsCreateResult) -> Void) -> URLSessionTask? {
        let params = ["to": toUserId, "message": message]

        return sendRequest("sendMessage", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCreateResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCreateResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCreateResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func sendDirectAnonymousMessage(sender: String, toUserId: String, message: String, callback: @escaping (GraphJsCreateResult) -> Void) -> URLSessionTask? {
        let params = ["sender": sender, "to": toUserId, "message": message]

        return sendRequest("sendAnonymousMessage", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCreateResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCreateResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCreateResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func countUnreadMessages(callback: @escaping (GraphJsCountResult) -> Void) -> URLSessionTask? {
        return sendRequest("countUnreadMessages") { (data, response, error) in
            if let error = error {
                callback(GraphJsCountResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCountResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCountResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func inbox(callback: @escaping (GraphJsDirectMessagesResult) -> Void) -> URLSessionTask? {
        return self.msgbox("getInbox", callback)
    }

    func outbox(callback: @escaping (GraphJsDirectMessagesResult) -> Void) -> URLSessionTask? {
        return self.msgbox("getOutbox", callback)
    }

    private func msgbox(_ method: String, _ callback: @escaping (GraphJsDirectMessagesResult) -> Void) -> URLSessionTask? {
        return sendRequest(method) { (data, response, error) in
            if let error = error {
                callback(GraphJsDirectMessagesResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsDirectMessagesResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsDirectMessagesResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func getConversation(withUserId: String, callback: @escaping (GraphJsDirectMessagesResult) -> Void) -> URLSessionTask? {
        let params = ["with": withUserId]

        return sendRequest("getConversation", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsDirectMessagesResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsDirectMessagesResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsDirectMessagesResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func conversations(callback: @escaping (GraphJsDirectMessagesResult) -> Void) -> URLSessionTask? {
        return sendRequest("getConversations") { (data, response, error) in
            if let error = error {
                callback(GraphJsDirectMessagesResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsDirectMessagesResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsDirectMessagesResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func getMessage(messageId: String, callback: @escaping (GraphJsDirectMessageResult) -> Void) -> URLSessionTask? {
        let params = ["msgid": messageId]

        return sendRequest("getMessage", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsDirectMessageResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsDirectMessageResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsDirectMessageResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    // MARK: Group managment API

    func createGroup(title: String, description: String, callback: @escaping (GraphJsCreateResult) -> Void) -> URLSessionTask? {
        let params = ["title": title, "description": description]

        return sendRequest("createGroup", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCreateResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCreateResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCreateResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func setGroup(groupId: String, title: String? = nil, description: String? = nil, cover: URL? = nil,
        callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": groupId, "title": title, "description": description, "cover": cover?.absoluteString]

        return sendRequest("setGroup", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func joinGroup(groupId: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": groupId]

        return sendRequest("join", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func leaveGroup(groupId: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": groupId]

        return sendRequest("leave", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func listMemberships(userId: String? = nil, callback: @escaping (GraphJsGroupsResult) -> Void) -> URLSessionTask? {
        let params = ["id": userId ?? currentUserId]

        return sendRequest("listMemberships", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsGroupsResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsGroupsResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsGroupsResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func groups(callback: @escaping (GraphJsGroupsResult) -> Void) -> URLSessionTask? {
        return sendRequest("listGroups") { (data, response, error) in
            if let error = error {
                callback(GraphJsGroupsResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsGroupsResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsGroupsResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func getGroup(groupId: String, callback: @escaping (GraphJsGroupResult) -> Void) -> URLSessionTask? {
        let params = ["id": groupId]

        return sendRequest("getGroup", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsGroupResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsGroupResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsGroupResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func listMembers(groupId: String, callback: @escaping (GraphJsGroupMembersResult) -> Void) -> URLSessionTask? {
        let params = ["id": groupId]

        return sendRequest("listMembers", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsGroupMembersResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsGroupMembersResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsGroupMembersResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    //region Content Management API

    func star(contentUrl: URL, callback: @escaping (GraphJsCountResult) -> Void) -> URLSessionTask? {
        let params = ["url": contentUrl.absoluteString]

        return sendRequest("star", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCountResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCountResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCountResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func unstar(contentUrl: URL, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["url": contentUrl.absoluteString]

        return sendRequest("unstar", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func isStarred(contentUrl: URL, callback: @escaping (GraphJsIsStarredResult) -> Void) -> URLSessionTask? {
        let params = ["url": contentUrl.absoluteString]

        return sendRequest("isStarred", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsIsStarredResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsIsStarredResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsIsStarredResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func starredContent(callback: @escaping (GraphJsStarsStatResult) -> Void) -> URLSessionTask? {
        return sendRequest("getStarredContent") { (data, response, error) in
            if let error = error {
                callback(GraphJsStarsStatResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsStarsStatResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsStarsStatResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func myStars(callback: @escaping (GraphJsStarsStatResult) -> Void) -> URLSessionTask? {
        return sendRequest("getMyStarredContent") { (data, response, error) in
            if let error = error {
                callback(GraphJsStarsStatResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsStarsStatResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsStarsStatResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func addComment(contentUrl: URL, content: String, callback: @escaping (GraphJsCreateResult) -> Void) -> URLSessionTask? {
        let params = ["url": contentUrl.absoluteString, "content": content]

        return sendRequest("addComment", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCreateResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCreateResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCreateResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func editComment(commentId: String, content: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": commentId, "content": content]

        return sendRequest("editComment", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func comments(contentUrl: URL, callback: @escaping (GraphJsCommentsResult) -> Void) -> URLSessionTask? {
        let params = ["url": contentUrl.absoluteString]

        return sendRequest("getComments", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCommentsResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCommentsResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCommentsResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func deleteComment(commentId: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["comment_id": commentId]

        return sendRequest("removeComment", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func addPrivateContent(data: String, callback: @escaping (GraphJsCreateResult) -> Void) -> URLSessionTask? {
        let params = ["data": data]

        return sendRequest("addPrivateContent", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCreateResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCreateResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCreateResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func getPrivateContent(contentId: String, callback: @escaping (GraphJsContentResult) -> Void) -> URLSessionTask? {
        let params = ["id": contentId]

        return sendRequest("getPrivateContent", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsContentResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsContentResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsContentResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func editPrivateContent(contentId: String, data: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": contentId, "data": data]

        return sendRequest("editPrivateContent", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    func deletePrivateContent(contentId: String, callback: @escaping (GraphJsCallResult) -> Void) -> URLSessionTask? {
        let params = ["id": contentId]

        return sendRequest("deletePrivateContent", params) { (data, response, error) in
            if let error = error {
                callback(GraphJsCallResult(success: false, reason: error.localizedDescription))
            } else if let result = try? JSONDecoder().decode(GraphJsCallResult.self, from: data!) {
                callback(result)
            } else {
                callback(GraphJsCallResult(success: false, reason: "Cannot parse response for \(#function)"))
            }
        }
    }

    private func sendRequest(_ apiMethod: String, _ params: [String: String?] = [:], callback: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTask? {
        var urlComponents = URLComponents(url: serverUrl, resolvingAgainstBaseURL: false)!

        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        queryItems.append(URLQueryItem(name: "public_id", value: publicId))

        for (key, value) in params {
            if (value != nil) {
                guard key != "email" || value!.contains("@") else {
                    callback(nil, nil, GraphJsApiError.invalidEmailError("Valid email required."))
                    return nil
                }

                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        urlComponents.queryItems = queryItems

        var urlRequest = URLRequest(
            url: urlComponents.url!.appendingPathComponent(apiMethod),
            cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy,
            timeoutInterval: requestTimeoutInterval)

        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        os_log("Request: %@", log: GraphJsApiManager.log, type: .debug, urlRequest.url?.absoluteString ?? "unknown")

        let task = URLSession.shared.dataTask(with: urlRequest) { (data, responce, error) in
            var requestFailed = true

            // TODO check error before

            if let httpResponse = responce as? HTTPURLResponse {
                os_log("Response: %d %@", log: GraphJsApiManager.log, type: .debug,
                       httpResponse.statusCode, String(data: data!, encoding: .utf8)!)
                requestFailed = httpResponse.statusCode >= 400
            }

            if requestFailed {
                os_log("Request failed wit error: %@", log: GraphJsApiManager.log, type: .error, error.debugDescription)
                if error != nil {
                    callback(data, responce, error)
                } else {
                    let responseString = String(data: data!, encoding: .utf8)!
                    callback(data, responce, GraphJsApiError.serverError(responseString))
                }
            } else {
                callback(data, responce, error)
            }

            os_log("----", log: GraphJsApiManager.log, type: .debug)
        }

        task.resume()

        return task
    }
}
