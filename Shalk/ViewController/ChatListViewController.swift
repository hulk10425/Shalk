//
//  ChatListViewController.swift
//  Shalk
//
//  Created by Nick Lee on 2017/7/27.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import UIKit

class ChatListViewController: UIViewController {

    let fbManager = FirebaseManager()

    var rooms: [ChatRoom] = []

    var opponentUid = ""

    var opponentName = ""

    var btnHint: UIButton?

    let screen = UIScreen.main.bounds

    @IBOutlet weak var chatListTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        fbManager.chatRoomDelegate = self

        let bgImageView = UIImageView(image: UIImage(named: "background"))

        chatListTableView.backgroundColor = UIColor.clear

        chatListTableView.backgroundView = bgImageView

        DispatchQueue.global().async {

            self.fbManager.fetchChatRoomList()

        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleRoomChange), name: NSNotification.Name(rawValue: "RoomChange"), object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addDiscoverButton()

    }

    func handleRoomChange() {

        self.rooms = []

        self.chatListTableView.reloadData()

    }

    deinit {

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "RoomChange"), object: self)

    }

    func addDiscoverButton() {

        let screen = UIScreen.main.bounds

        btnHint = UIButton(frame: CGRect(x: 50, y: 100, width: screen.width - 100, height: 50))

        btnHint?.setTitle("D I S C O V E R  !", for: .normal)

        btnHint?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)

        btnHint?.setTitleColor(UIColor.white, for: .normal)

        btnHint?.backgroundColor = UIColor.clear

        btnHint?.layer.borderColor = UIColor.white.cgColor

        btnHint?.layer.borderWidth = 2

        btnHint?.layer.shadowColor = UIColor.black.cgColor

        btnHint?.layer.shadowOffset = CGSize(width: 1, height: 1)

        btnHint?.layer.shadowRadius = 0.5

        btnHint?.layer.shadowOpacity = 1

        btnHint?.addTarget(self, action: #selector(goDiscover), for: .touchDown)

        self.view.addSubview(btnHint!)

    }

    func goDiscover() {

        self.tabBarController?.selectedIndex = 1

    }

}

//swiftlint:disable force_cast
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return rooms.count

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell

        let room = rooms[indexPath.row]

        cell.backgroundColor = UIColor.clear

        cell.latestMessage.text = room.latestMessage

        if room.isRead == false {

            cell.newMessageBubble.isHidden = false

        } else {

            cell.newMessageBubble.isHidden = true

        }

        guard let myUid = UserManager.shared.currentUser?.uid else { return UITableViewCell() }

        if myUid == room.user1Id {

            var friend = UserManager.shared.friends.filter { $0.uid == room.user2Id }

            cell.opponentImageView.sd_setImage(with: URL(string: friend[0].imageUrl), placeholderImage: UIImage(named: "icon-user"))

            cell.opponentName.text = friend[0].name

            return cell

        } else {

            var friend = UserManager.shared.friends.filter { $0.uid == room.user1Id }

            cell.opponentImageView.sd_setImage(with: URL(string: friend[0].imageUrl), placeholderImage: UIImage(named: "icon-user"))

            cell.opponentName.text = friend[0].name

            return cell

        }

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let myUid = UserManager.shared.currentUser?.uid else { return }

        let room = rooms[indexPath.row]

        if myUid == room.user1Id {

            UserManager.shared.chatRoomId = room.roomId

            var friend = UserManager.shared.friends.filter { $0.uid == room.user2Id }

            UserManager.shared.opponent = friend[0]

            self.performSegue(withIdentifier: "goChat", sender: nil)

        } else {

            UserManager.shared.chatRoomId = room.roomId

            var friend = UserManager.shared.friends.filter { $0.uid == room.user1Id }

            UserManager.shared.opponent = friend[0]

            self.performSegue(withIdentifier: "goChat", sender: nil)

        }

    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        let dismissCell = cell as? ChatTableViewCell

        dismissCell?.opponentImageView.image = nil

    }

}
//swiftlint:enable force_cast

extension ChatListViewController: FirebaseManagerChatRoomDelegate {

    func manager(_ manager: FirebaseManager, didGetChatRooms rooms: [ChatRoom]) {

        self.rooms = rooms

        btnHint?.isHidden = true

        chatListTableView.reloadData()

    }

    func manager(_ manager: FirebaseManager, didGetError error: Error) {

        // MARK: Failed to fetch chat rooms

        UIAlertController(error: error).show()

    }

}
