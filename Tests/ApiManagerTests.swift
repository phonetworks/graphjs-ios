//
//  ApiManagerTests.swift
//  ApiManagerTests
//
//  Created by CAMOBAP on 8/30/18.
//  Copyright © 2018 Dial-Once. All rights reserved.
//

import XCTest

@testable import GraphJS

class ApiManagerTests: XCTestCase {

    // Test data can be generated with https://github.com/esokullu/graphjs-website/tree/master/scripts/data-gen
    struct Constants {
        static let testUserName = "johndoe"
        static let testUserPassword = "qwerty"
        static let testUserEmail = "jdoe@example.org"
        static let testUserId = "4276f9f759d87d7f91b5895a4ef5d6c1"

        static let alice = "alice"
        static let bob = "bob"

        static let serverUrl = URL(string: "http://localhost:1338/")! // emulator host
        static let publicId = "79982844-6a27-4b3b-b77f-419a79be0e10"
    }

    let subject = GraphJsApiManager(publicId: Constants.publicId,
        serverUrl: Constants.serverUrl,
        debugEnabled: true)

    override func setUp() {
        super.setUp()

        let lock = DispatchSemaphore(value: 0)

        _ = subject.login(username: Constants.testUserName, password: Constants.testUserPassword) { (result) in
            XCTAssert(result.success)

            lock.signal()
        }

        lock.wait()

        super.tearDown()
    }
    
    override func tearDown() {
        let lock = DispatchSemaphore(value: 0)

        _ = subject.logout { (result) in
            XCTAssert(result.success)

            lock.signal()
        }

        lock.wait()

        super.tearDown()
    }

    func dropAllCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies(for: Constants.serverUrl) {
            for c in cookies {
                HTTPCookieStorage.shared.deleteCookie(c)
            }
        }
    }

    func testSignupInvalidEmail() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsRegisterResult()

        _ = subject.signup(username: Constants.testUserName, email: Constants.testUserEmail.replacingOccurrences(of: "@", with: "a"), password: Constants.testUserPassword) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("Valid email required.", result.reason)
    }

    func testRegisterExistingUser() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsRegisterResult()

        _ = subject.signup(username: Constants.testUserName, email: Constants.testUserEmail, password: Constants.testUserPassword) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
    }

    func testWhoami() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsLoginResult()

        _ = subject.whoami { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertEqual(Constants.testUserId, result.userId)
    }

    func testLoginWrongPassword() {
        super.setUp()

        let semaphore = DispatchSemaphore(value: 0)

        _ = subject.login(username: Constants.testUserName, password: Constants.testUserName) { (result) in
            XCTAssertFalse(result.success)
            XCTAssertEqual("Information don't match records", result.reason)
            XCTAssertNil(result.userId)

            semaphore.signal()
        }

        semaphore.wait()

        super.tearDown()
    }

    func testLoginUnregisteredUser() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsLoginResult()

        _ = subject.login(username:"xxxxxx", password: "xxxxxx@example.org") { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("Information don't match records", result.reason)
        XCTAssertNil(result.userId)
    }

    func testResetPasswordSuccess() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.resetPassword(email: Constants.testUserEmail) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
    }

    func testVerifyPasswordResetWrongCode() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.verifyPasswordReset(email: Constants.testUserEmail, code:"------") { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("Valid email and code required.", result.reason)
    }

    // MARK: Profile API Tests

    func testProfileHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsProfileResult()

        _ = subject.profile(userId: Constants.testUserId) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
        XCTAssertNotNil(result.profile)
        XCTAssertEqual(Constants.testUserEmail, result.profile?.email)
        XCTAssertEqual(Constants.testUserName, result.profile?.username)
        XCTAssertNotNil(result.profile?.avatar)
    }

    func testProfileCurrentUserHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsProfileResult()

        _ = subject.profile { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
        XCTAssertNotNil(result.profile)
        XCTAssertEqual(Constants.testUserEmail, result.profile?.email)
        XCTAssertEqual(Constants.testUserName, result.profile?.username)
        XCTAssertNotNil(result.profile?.avatar)
    }

    func testProfileWithBadUserId() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsProfileResult()

        _ = subject.profile(userId: "00000000000000000000000000000") { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("Invalid user ID", result.reason)
    }

    func testChangeProfileBioHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.setProfile(about: "123145678901235567890") { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
    }

    func testChangeProfileBirthdayHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        let newBirthday = Calendar.current.date(
            byAdding: .year,
            value: -14,
            to: Date())!

        _ = subject.setProfile(birthday: newBirthday) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
    }

    func testChangeProfileUsernameToSame() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.setProfile(username: Constants.testUserName) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        // It's ok that we get error here because we send the same testUserName as user already have
        // We not changing it to keep test as simple as possible
        XCTAssertEqual("Given field (Username) is not unique with the value (\(Constants.testUserName))", result.reason)
    }

    func testChangeProfileEmailToSame() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.setProfile(email: Constants.testUserEmail) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        // It's ok that we get error here because we send the same testUserName as user already have
        // We not changing it to keep test as simple as possible
        XCTAssertEqual("Given field (Email) is not unique with the value (\(Constants.testUserEmail))", result.reason)
    }

    func testChangeProfilePasswordHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.setProfile(password: Constants.testUserPassword) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
    }

    func testChangeProfileAvatarHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.setProfile(avatar: URL(string:"https://www.fnordware.com/superpng/pnggrad16rgb.png")!) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
    }

    func testChangeProfileNoData() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.setProfile { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("No field to set", result.reason)
    }

    func testGenerateFeedTokenShallow() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsFeedTokenResult()

        _ = subject.generateFeedToken(type: .wall) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNotNil(result.token)
    }

    // MARK: region Thread API

    func testThreadsShallow() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsThreadsResult()

        _ = subject.threads { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNotNil(result.threads)
    }

    func testThreadCRUD() {
        var lock = DispatchSemaphore(value: 0)
        var createResult = GraphJsCreateResult()

        _ = subject.startThread(title: "Unit Test Thread", message: "First!") { (r) in
            createResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(createResult.success)
        XCTAssertNotNil(createResult.id)

        lock = DispatchSemaphore(value: 0)
        var replyResult = GraphJsCreateResult()

        _ = subject.replyThread(threadId: createResult.id!, message: "Second!") { (r) in
            replyResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(replyResult.success)
        XCTAssertNotNil(replyResult.id)

        lock = DispatchSemaphore(value: 0)
        var editResult = GraphJsCallResult()
        _ = subject.editForumPost(postId: createResult.id!, content: "First!!") { (r) in
            editResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(editResult.success)

        lock = DispatchSemaphore(value: 0)
        var getResult = GraphJsThreadResult()
        _ = subject.getThread(threadId: createResult.id!) { (r) in
            getResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(getResult.success)
        XCTAssertNotNil(getResult.messages)
        XCTAssertNotNil(getResult.messages.first(where: {$0.id == createResult.id }))
        XCTAssertNotNil(getResult.messages.first(where: {$0.id == replyResult.id }))

        lock = DispatchSemaphore(value: 0)
        var deleteResult = GraphJsCallResult()
        _ = subject.deleteForumPost(postId: replyResult.id!) { (r) in
            deleteResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(deleteResult.success)

        lock = DispatchSemaphore(value: 0)
        _ = subject.deleteForumPost(postId: createResult.id!) { (r) in
            deleteResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(deleteResult.success)
    }

    // MARK: Members API

    func testMembers() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsMembersResult()

        _ = subject.members { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNotNil(result.members)
    }

    func testFollowers() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsMembersResult()

        _ = subject.followers { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNotNil(result.members)
    }

    func testFollowing() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsMembersResult()

        _ = subject.following { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNotNil(result.members)
    }

    func testCannotFollowYourself() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.follow(followeeId: Constants.testUserId) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("Follower and followee can't be the same", result.reason)
    }

    func testCannotUnfollowYourself() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCallResult()

        _ = subject.unfollow(followeeId: Constants.testUserId) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("No follow edge found", result.reason)
    }

    // MARK: Messaging API

    func testTalkingToMyself() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCreateResult()

        _ = subject.sendDirectMessage(toUserId: Constants.testUserId, message: "Hello to myself") { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("Can't send a message to self", result.reason)
    }

    func testAnonymousMessageHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCreateResult()

        self.dropAllCookies()

        _ = subject.sendDirectAnonymousMessage(sender: Constants.alice, toUserId: Constants.testUserId, message: "Hello from $alice") { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
    }

    func testAnonymousMessageFail() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCreateResult()

        self.dropAllCookies()

        _ = subject.sendDirectAnonymousMessage(sender: Constants.bob, toUserId: "--------", message: "Hello from $bob") { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssertFalse(result.success)
        XCTAssertEqual("Invalid recipient", result.reason)
    }

    func countUnreadMessagesHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsCountResult()

        _ = subject.countUnreadMessages { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNil(result.reason)
    }

    func inboxHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsDirectMessagesResult()

        _ = subject.inbox { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
    }

    func outboxHappyAndGetMessage() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsDirectMessagesResult()

        _ = subject.outbox { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)

        for (messageId, message) in result.messages {
            let msgLock = DispatchSemaphore(value: 0)
            var msgResult = GraphJsDirectMessageResult()

            _ = subject.getMessage(messageId: messageId) { (r) in
                msgResult = r
                msgLock.signal()
            }

            msgLock.wait()

            XCTAssert(msgResult.success)
            XCTAssertNotNil(msgResult.message)
            XCTAssertEqual(message.toUserId, msgResult.message!.toUserId)
        }
    }

    func testConversationsHappy() {
        let lock = DispatchSemaphore(value: 0)
        var result = GraphJsDirectMessagesResult()

        _ = subject.conversations { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssertNotNil(result.messages)

        for (messageId, _) in result.messages {
            let msgLock = DispatchSemaphore(value: 0)
            var msgResult = GraphJsDirectMessagesResult()

            _ = subject.getConversation(withUserId: messageId) { (r) in
                msgResult = r
                msgLock.signal()
            }

            msgLock.wait()

            XCTAssert(msgResult.success)
            XCTAssertNotNil(msgResult.messages)
        }
    }

    // MARK: Group managment API tests

    func testGroupCRUD() {
        var lock = DispatchSemaphore(value: 0)
        var createResult = GraphJsCreateResult()

        _ = subject.createGroup(title: "MyGroup", description: "MyGroupDescription") { (r) in
            createResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(createResult.success)
        XCTAssertNotNil(createResult.id)

        lock = DispatchSemaphore(value: 0)
        var readResult = GraphJsGroupResult()

        _ = subject.getGroup(groupId: createResult.id!) { (r) in
            readResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(readResult.success)
        XCTAssertEqual("MyGroup", readResult.group?.title)
        XCTAssertEqual("MyGroupDescription", readResult.group?.description)
        XCTAssertTrue(readResult.group?.memberIds.contains(Constants.testUserId) ?? false)

        lock = DispatchSemaphore(value: 0)
        var setResult = GraphJsCallResult()

        _ = subject.setGroup(groupId: createResult.id!, title: "MyGroupNew",
                             description: "MyGroupDescriptionNew",
                             cover: URL(string: "https://www.fnordware.com/superpng/pnggrad16rgb.png")!) { (r) in
            setResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(setResult.success)

        lock = DispatchSemaphore(value: 0)
        var read2Result = GraphJsGroupsResult()

        _ = subject.groups { (r) in
            read2Result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(read2Result.success)
        XCTAssertNotNil(read2Result.groups)
        XCTAssertNotNil(read2Result.groups.first(where: { $0.id == createResult.id }))

        lock = DispatchSemaphore(value: 0)
        var read3Result = GraphJsGroupsResult()

        _ = subject.listMemberships { (r) in
            read3Result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(read3Result.success)
        XCTAssertNotNil(read2Result.groups)

        let group = read2Result.groups.first(where: { $0.id == createResult.id })
        XCTAssertNotNil(group)
        XCTAssertEqual("MyGroupNew", group?.title)
        XCTAssertEqual("MyGroupDescriptionNew", group?.description)

        lock = DispatchSemaphore(value: 0)
        var leaveResult = GraphJsCallResult()

        _ = subject.leaveGroup(groupId: createResult.id!) { (r) in
            leaveResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(leaveResult.success)

        lock = DispatchSemaphore(value: 0)
        var joinResult = GraphJsCallResult()

        _ = subject.joinGroup(groupId: createResult.id!) { (r) in
            joinResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(joinResult.success)

        lock = DispatchSemaphore(value: 0)
        var membersResult = GraphJsGroupMembersResult()

        _ = subject.listMembers(groupId: createResult.id!) { (r) in
            membersResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(membersResult.success)
        XCTAssert(membersResult.memberIds.contains(Constants.testUserId))
    }

    // MARK: Content Management API

    func testWhoCaresIfOneMoreLightGoesOut() {
        let contentUrl = URL(string: "https://www.youtube.com/watch?v=Tm8LGxTLtQk")!
        var lock = DispatchSemaphore(value: 0)

        var result = GraphJsCountResult()
        _ = subject.star(contentUrl: contentUrl) { (r) in
            result = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(result.success)
        XCTAssert(result.count > 0)

        lock = DispatchSemaphore(value: 0)
        var isStarredResult = GraphJsIsStarredResult()
        _ = subject.isStarred(contentUrl: contentUrl) { (r) in
            isStarredResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(isStarredResult.success)
        XCTAssert(isStarredResult.starredByMe ?? false)
        XCTAssertEqual(result.count, isStarredResult.count)

        lock = DispatchSemaphore(value: 0)
        var unstarResult = GraphJsCallResult()
        _ = subject.unstar(contentUrl: contentUrl) { (r) in
            unstarResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(unstarResult.success)
        lock = DispatchSemaphore(value: 0)
        _ = subject.isStarred(contentUrl: contentUrl) { (r) in
            isStarredResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(isStarredResult.success)
        XCTAssertFalse(isStarredResult.starredByMe ?? false)
        XCTAssertEqual(result.count - 1, isStarredResult.count)
    }

    func testAllStars() {
        let contentUrl1 = URL(string: "https://www.youtube.com/watch?v=vjF9GgrY9c0")!
        let contentUrl2 = URL(string: "https://www.youtube.com/watch?v=nKOPF6XtEZw")!
        let contentUrl3 = URL(string: "https://www.youtube.com/watch?v=3hJOCCXPwT8")!

        var lock = DispatchSemaphore(value: 0)
        _ = subject.star(contentUrl: contentUrl1) { (r) in
            lock.signal()
        }
        lock.wait()

        lock = DispatchSemaphore(value: 0)
        _ = subject.star(contentUrl: contentUrl2) { (r) in
            lock.signal()
        }
        lock.wait()

        lock = DispatchSemaphore(value: 0)
        _ = subject.star(contentUrl: contentUrl3) { (r) in
        lock.signal()
        }
        lock.wait()

        lock = DispatchSemaphore(value: 0)
        var result = GraphJsStarsStatResult()
        _ = subject.myStars { (r) in
        result = r
        lock.signal()
        }
        lock.wait()

        XCTAssert(result.success)
        XCTAssert(result.pages.count >= 3)

        lock = DispatchSemaphore(value: 0)
        _ = subject.starredContent { (r) in
        result = r
        lock.signal()
        }
        lock.wait()

        XCTAssert(result.success)
        XCTAssert(result.pages.count >= 3)
    }

    func testCommentCRUD() {
        let contentUrl = URL(string: "https://www.youtube.com/watch?v=vjF9GgrY9c0")!

        var lock = DispatchSemaphore(value: 0)
        var createResult1 = GraphJsCreateResult()
        _ = subject.addComment(contentUrl: contentUrl, content: "First!") { (r) in
            createResult1 = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(createResult1.success)
        XCTAssertNotNil(createResult1.id)

        lock = DispatchSemaphore(value: 0)
        var createResult2 = GraphJsCreateResult()
        _ = subject.addComment(contentUrl: contentUrl, content: "Second!") { (r) in
            createResult2 = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(createResult2.success)
        XCTAssertNotNil(createResult2.id)

        lock = DispatchSemaphore(value: 0)
        var readResult = GraphJsCommentsResult()
        _ = subject.comments(contentUrl: contentUrl) { (r) in
            readResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(readResult.success)
        XCTAssertNotNil(readResult.comments)
        XCTAssertNotNil(readResult.comments[createResult1.id!])
        XCTAssertNotNil(readResult.comments[createResult2.id!])

        lock = DispatchSemaphore(value: 0)
        var editResult = GraphJsCallResult()
        _ = subject.editComment(commentId: createResult1.id!, content: "First!!!") { (r) in
            editResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(editResult.success)

        lock = DispatchSemaphore(value: 0)
        var deleteResult1 = GraphJsCallResult()
        _ = subject.deleteComment(commentId: createResult1.id!) { (r) in
            deleteResult1 = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(deleteResult1.success)

        lock = DispatchSemaphore(value: 0)
        var deleteResult2 = GraphJsCallResult()
        _ = subject.deleteComment(commentId: createResult2.id!) { (r) in
            deleteResult2 = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(deleteResult2.success)
    }

    func testPrivateContentCRUD() {
        var lock = DispatchSemaphore(value: 0)
        var createResult = GraphJsCreateResult()

        _ = subject.addPrivateContent(data: "First Secured!") { (r) in
            createResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(createResult.success)
        XCTAssertNotNil(createResult.id)

        lock = DispatchSemaphore(value: 0)
        var readResult = GraphJsContentResult()
        _ = subject.getPrivateContent(contentId: createResult.id!) { (r) in
            readResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(readResult.success)
        XCTAssertEqual("First Secured!", readResult.content)

        lock = DispatchSemaphore(value: 0)
        var editResult = GraphJsCallResult()
        _ = subject.editPrivateContent(contentId: createResult.id!, data: "First Secured!!!") { (r) in
            editResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(editResult.success)

        lock = DispatchSemaphore(value: 0)
        _ = subject.getPrivateContent(contentId: createResult.id!) { (r) in
            readResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(readResult.success)
        XCTAssertEqual("First Secured!!!", readResult.content)

        XCTAssert(editResult.success)

        lock = DispatchSemaphore(value: 0)
        var deleteResult = GraphJsCallResult()
        _ = subject.deletePrivateContent(contentId: createResult.id!) { (r) in
            deleteResult = r
            lock.signal()
        }

        lock.wait()

        XCTAssert(deleteResult.success)
    }
}
