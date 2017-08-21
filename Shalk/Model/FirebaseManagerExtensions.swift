//
//  FirebaseManagerExtensions.swift
//  Shalk
//
//  Created by Nick Lee on 2017/8/14.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import Crashlytics

// MARK: Functions for fetch and update channel.
extension FirebaseManager {

    func fetchChannel() {

        guard let language = UserManager.shared.language else { return }

        ref?.child("channels").child(language).queryOrdered(byChild: "isLocked").queryEqual(toValue: false).queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in

            guard let object = snapshot.value as? [String: Any] else {

                // MARK: No online rooms, create a new one.

                self.createNewChannel(withLanguage: language)

                return

            }

            do {

                // MARK: Find an available to join

                let channel = try AudioChannel.init(json: Array(object.values)[0])

                UserManager.shared.roomKey = channel.roomID

                self.updateChannel()

                self.fetchOpponentInfo(withUid: channel.owner, call: .audio)

                return

            } catch let error {

                // MARK: Failed to fetch channel.
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["info": "Fetch_Channel_Error"])

                UIAlertController(error: error).show()
            }

        })

    }

    func createNewChannel(withLanguage language: String) {

        // MARK: No channel online.

        guard let uid = Auth.auth().currentUser?.uid, let roomId = ref?.childByAutoId().key else { return }

        let newChannel = AudioChannel.init(roomID: roomId, owner: uid)

        UserManager.shared.roomKey = roomId

        self.ref?.child("channels").child(language).child(roomId).setValue(newChannel.toDictionary())

    }

    func updateChannel() {

        guard
            let uid = userManager.currentUser?.uid,
            let roomId = userManager.roomKey,
            let lang = userManager.language else { return }

        ref?.child("channels").child(lang).child(roomId).updateChildValues(["isLocked": true])

        ref?.child("channels").child(lang).child(roomId).updateChildValues(["participant": uid])

    }

    func closeChannel() {

        guard let roomId = userManager.roomKey, let lang = userManager.language else { return }

        ref?.child("channels").child(lang).child(roomId).updateChildValues(["isFinished": true, "isLocked": true])

        UserManager.shared.roomKey = nil

        UserManager.shared.language = nil

    }

    func leaveChannel() {

        guard
            let roomId = userManager.roomKey,
            let lang = userManager.language else { return }

        ref?.child("channels").child(lang).child(roomId).updateChildValues(["isLocked": true, "isFinished": true])

    }

}

// MARK: Functions for handle friends.
extension FirebaseManager {

    func checkFriendRequest() {

        guard let roomId = userManager.roomKey else { return }

        ref?.child("friendRequest").observeSingleEvent(of: .value, with: { (snapshot) in

            if snapshot.hasChild(roomId) {

                // MARK: We are friends now, update both data.

                guard
                    let myUid = UserManager.shared.currentUser?.uid,
                    let opponent = UserManager.shared.opponent else { return }

                self.ref?.child("friendList").child(myUid).updateChildValues([opponent.uid: "true"])

                self.ref?.child("friendList").child(opponent.uid).updateChildValues([myUid: "true"])

                UserManager.shared.closeChannel()

            } else {

                // MARK: Add myself into the queue.

                self.ref?.child("friendRequest").child(roomId).setValue(true)

                UserManager.shared.closeChannel()

            }

        })

    }

    func fetchFriendList(completion: @escaping (User, FriendType) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        ref?.child("friendList").child(uid).observe(.value, with: { (snapshot) in

            UserManager.shared.friends = []

            UserManager.shared.blockedFriends = []

            guard let friendList = snapshot.value as? [String: String] else { return }

            for friend in friendList {

                let friendUid = friend.key

                let type = FriendType(rawValue: friend.value)

                self.fetchFriendInfo(friendUid, by: type!, completion: completion)

            }

        })

    }

    func checkFriendStatus(_ friendUid: String, completion: (Bool) -> Void) {

        guard let myUid = Auth.auth().currentUser?.uid else { return }

        ref?.child("friendList").child(myUid).child(friendUid).observeSingleEvent(of: .value, with: { (snapshot) in

            guard let status = snapshot.value as? String else { return }
            
            if status == "true" {
                
                completion(true)
                
            } else {
                
                completion(false)
                
            }
            
        })

    }

    func fetchFriendInfo(_ friendUid: String, by type: FriendType, completion: @escaping (User, FriendType) -> Void) {

        ref?.child("users").child(friendUid).observeSingleEvent(of: .value, with: { (snapshot) in

                guard let object = snapshot.value else { return }

                do {

                    let user = try User.init(json: object)

                    DispatchQueue.main.async {

                        completion(user, type)

                    }

                } catch let error {

                    // MARK: Failed to fetch friend info.
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["info": "Fetch_FriendInfo_Error"])

                    UIAlertController(error: error).show()

                }

            })

    }

}

// MARK: Functions for fetch and update user profile.
extension FirebaseManager {

    func registerProfile(uid: String, userDict: [String: String]) {

        ref?.child("users").child(uid).setValue(userDict)

    }

    func fetchOpponentInfo(withUid uid: String, call: CallType) {

        ref?.child("users").child(uid).observeSingleEvent(of: .value, with: {(snapshot) in

            guard let object = snapshot.value as? [String: Any] else { return }

            do {

                let user = try User.init(json: object)

                self.userManager.opponent = user

                switch call {

                case .audio:

                    self.userManager.startAudioCall()

                    break

                case .video:

                    self.userManager.startVideoCall()

                    break

                case .none:

                    break

                }

            } catch let error {

                // MARK: Failed to fetch user profile

                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["info": "Fetch_OpponentProfile_Error"])

                UIAlertController(error: error).show()
            }

        })

    }

    func fetchMyProfile(completion: @escaping () -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else { return }

        ref?.child("users").child(userId).observeSingleEvent(of: .value, with: {(snapshot) in

            guard let object = snapshot.value as? [String: Any] else { return }

            do {

                let user = try User.init(json: object)

                UserManager.shared.currentUser = user

                DispatchQueue.main.async {

                    completion()

                }

            } catch let error {

                // MARK: Failed to fetch user profile

                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["info": "Fetch_MyProfile_Error"])

                UIAlertController(error: error).show()
            }

        })

    }

    func updateUserName(name: String) {

        guard let user = UserManager.shared.currentUser else { return }

        ref?.child("users").child(user.uid).child("name").setValue(name)

    }

    func updateUserIntro(intro: String) {

        guard let user = UserManager.shared.currentUser else { return }

        ref?.child("users").child(user.uid).child("intro").setValue(intro)

    }

    func uploadImage(withData data: Data) {

        let metaData = StorageMetadata()

        guard let user = UserManager.shared.currentUser else { return }

        metaData.contentType = "image/jpeg"

        storageRef.child("userImage").child(user.uid).putData(data, metadata: metaData) { (metadata, error) in

            if error != nil {

                // MARK: Failed to upload image.

                UIAlertController(error: error!).show()

                return

            }

            // MARK: Upload image successfully, and updated user image url.

            guard let imageUrlString = metadata?.downloadURL()?.absoluteString else { return }

            self.ref?.child("users").child(user.uid).child("imageUrl").setValue(imageUrlString)

            UserManager.shared.currentUser?.imageUrl = imageUrlString

        }

    }

}

// MARK: Real-time chat functions
extension FirebaseManager {

    func createChatRoom(to opponent: User) {

        guard
            let myUid = Auth.auth().currentUser?.uid,
            let roomId = ref?.childByAutoId().key else { return }

        let room = ChatRoom.init(roomId: roomId, opponent: opponent)
        ref?.child("chatRoomList").child(myUid).child(roomId).setValue(room.toDictionary())

        ref?.child("chatRoomList").child(opponent.uid).child(roomId).setValue(room.toDictionary())

        ref?.child("chatHistory").child(roomId).child("init").setValue(Message.init(text: "").toDictionary())

        userManager.chatRoomId = roomId

    }

    func fetchChatRoomList() {

        guard let myUid = Auth.auth().currentUser?.uid else { return }

        handle = ref?.child("chatRoomList").child(myUid).observe(.value, with: { (snapshot) in

            var rooms: [ChatRoom] = []

            guard let roomList = snapshot.value as? [String: Any] else { return }

            for object in roomList {

                do {

                    let room = try ChatRoom.init(json: object.value)

                    rooms.append(room)

                } catch let error {

                    // MARK: Failed to fetch the list of chat rooms.
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["info": "Fetch_ChatRoom_Error"])

                    UIAlertController(error: error).show()

                }

            }

            let sortedRooms = rooms.sorted(by: { (room1, room2) -> Bool in

                let formatter = DateFormatter()

                formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"

                let room1Time = formatter.date(from: room1.latestMessageTime)

                let room2Time = formatter.date(from: room2.latestMessageTime)

                return room1Time!.compare(room2Time!) == .orderedDescending

            })

            UserManager.shared.chatRooms = sortedRooms

            DispatchQueue.main.async {

                self.chatRoomDelegate?.manager(self, didGetChatRooms: sortedRooms)

            }

        })

    }

    func updateChatRoom() {

        guard let myUid = Auth.auth().currentUser?.uid else { return }

        let roomId = UserManager.shared.chatRoomId

        ref?.child("chatRoomList").child(myUid).child(roomId).updateChildValues(["isRead": true])

    }

    func sendMessage(text: String) {

        let roomId = userManager.chatRoomId

        guard
            let messageId = ref?.childByAutoId().key,
            let myUid = userManager.currentUser?.uid,
            let opponentUid = userManager.opponent?.uid else { return }

        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"

        let timestamp = formatter.string(from: Date())

        let newMessage = Message.init(text: text)

        ref?.child("chatHistory").child(roomId).child(messageId).updateChildValues(newMessage.toDictionary())

        ref?.child("chatRoomList").child(myUid).child(roomId).updateChildValues(["latestMessage": text, "latestMessageTime": timestamp])

        ref?.child("chatRoomList").child(opponentUid).child(roomId).updateChildValues(["latestMessage": text, "latestMessageTime": timestamp, "isRead": false])

    }

    func sendCallRecord(_ call: String, duration: String) {

        guard let messageId = ref?.childByAutoId().key else { return }

        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"

        let timestamp = formatter.string(from: Date())

        let newMessage = Message.init(text: duration, senderId: call, time: timestamp)

        ref?.child("chatHistory").child(UserManager.shared.chatRoomId).child(messageId).updateChildValues(newMessage.toDictionary())

    }

    func fetchChatHistory(completion: @escaping ([Message]) -> Void) {

        var messages: [Message] = []

        let roomId = userManager.chatRoomId

        handle = ref?.child("chatHistory").child(roomId).observe(.childAdded, with: { (snapshot) in

            guard let object = snapshot.value as? [String: String] else { return }

            do {

                let message = try Message.init(json: object)

                messages.append(message)

            } catch let error {

                // MARK: Failed to fetch hcat histroy
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["info": "Fetch_ChatHistory_Error"])

                UIAlertController(error: error).show()

            }

            DispatchQueue.main.async {

                completion(messages)

            }

        })

    }

}

// MARK: Handle remove user
extension FirebaseManager {

    func blockFriend(completion: @escaping () -> Void) {

        guard
            let myUid = UserManager.shared.currentUser?.uid,
            let friendUid = UserManager.shared.opponent?.uid else { return }

        let roomId = UserManager.shared.chatRoomId

        ref?.child("friendList").child(myUid).child(friendUid).removeValue()

        ref?.child("chatRoomList").child(myUid).child(roomId).removeValue()

        ref?.child("friendList").child(friendUid).child(myUid).setValue("Blocked")

        DispatchQueue.main.async {

            completion()

        }

    }

}

// MARK: Remove Firebase Observer
extension FirebaseManager {

    func removeAllObserver() {

        ref?.removeAllObservers()

    }

}

// MARK: Firebase Analystic.
extension FirebaseManager {

    func logEvent(_ eventName: String) {

        Analytics.logEvent(eventName, parameters: nil)

    }

}
