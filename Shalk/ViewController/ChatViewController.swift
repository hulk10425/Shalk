//
//  ChatViewController.swift
//  Shalk
//
//  Created by Nick Lee on 2017/8/5.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

    var messages: [Message] = []

    let fbManager = FirebaseManager()

    var opponent: User!

    @IBOutlet weak var chatTableView: UITableView!

    @IBOutlet weak var inputTextView: UITextView!

    @IBAction func sendMessage(_ sender: UIButton) {

        fbManager.sendMessage(text: inputTextView.text)

        inputTextView.text = ""

    }

    @IBAction func sendImage(_ sender: UIButton) {

    }

    @IBAction func btnBack(_ sender: UIBarButtonItem) {

        self.navigationController?.popViewController(animated: true)

    }

    @IBAction func btnAudioCall(_ sender: UIBarButtonItem) {

        self.startAudioCall(uid: opponent.uid, name: opponent.name)

    }

    @IBAction func btnVideoCall(_ sender: UIBarButtonItem) {

        self.startVideoCall(uid: opponent.uid, name: opponent.name)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        inputTextView.delegate = self

        chatTableView.estimatedRowHeight = 300

        chatTableView.rowHeight = UITableViewAutomaticDimension

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        opponent = UserManager.shared.opponent

        self.navigationItem.title = opponent.name

        fbManager.fetchChatHistory { fetchMessages in

            self.messages = fetchMessages

            self.chatTableView.reloadData()

        }

    }

}

//swiftlint:disable force_cast
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {

        return 1

    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let showMessages = messages.filter { $0.text != "" }

        return  showMessages.count

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let showMessages = messages.filter { $0.text != "" }

        guard let myUid = UserManager.shared.currentUser?.uid else { return UITableViewCell() }

        switch showMessages[indexPath.row].senderId {

        case myUid:

            let cell = tableView.dequeueReusableCell(withIdentifier: "senderCell", for: indexPath) as! SenderTableViewCell

            cell.sendedMessage.text = showMessages[indexPath.row].text

            cell.sendedTime.text = showMessages[indexPath.row].time

            return cell

        default:

            let friend = UserManager.shared.friendsInfo.filter { $0.uid == showMessages[indexPath.row].senderId }

            let cell = tableView.dequeueReusableCell(withIdentifier: "receiverCell", for: indexPath) as! ReceiverTableViewCell

            cell.receivedMessage.text = showMessages[indexPath.row].text

            cell.receivedTime.text = showMessages[indexPath.row].time

            cell.receiverImageView.sd_setImage(with: URL(string: friend[0].imageUrl))

            return cell

        }

    }

}

extension ChatViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {

        if inputTextView.text == "write something.." {

            inputTextView.text = ""

        }

    }

    func textViewDidEndEditing(_ textView: UITextView) {

        if inputTextView.text.isEmpty {

            inputTextView.text = "write something.."

        }
    }

}
