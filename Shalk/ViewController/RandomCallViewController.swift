//
//  RandomCallViewController.swift
//  Shalk
//
//  Created by Nick Lee on 2017/7/30.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import UIKit
import Quickblox
import QuickbloxWebRTC

class RandomCallViewController: UIViewController {

    var isMicrophoneEnabled: Bool = true

    var isSpeakerEnabled: Bool = false

    let qbManager = QBManager.shared

    let rtcManager = QBRTCClient.instance()

    @IBOutlet weak var userNameLabel: UILabel!

    @IBOutlet weak var outletSpeaker: UIButton!

    @IBOutlet weak var outletMicrophone: UIButton!

    @IBAction func btnSpeaker(_ sender: UIButton) {

        if isSpeakerEnabled == false {

            // MARK: User enable the speaker

            isSpeakerEnabled = true

            outletSpeaker.setImage(UIImage(named: "icon-speaker.png"), for: .normal)

            qbManager.audioManager.currentAudioDevice = QBRTCAudioDevice.speaker

        } else {

            // MARK: User disable the speaker

            isSpeakerEnabled = false

            outletSpeaker.setImage(UIImage(named: "icon-nospeaker.png"), for: .normal)

            qbManager.audioManager.currentAudioDevice = QBRTCAudioDevice.receiver

        }

    }

    @IBAction func btnMicrophone(_ sender: UIButton) {

        if isMicrophoneEnabled {

            // MARK: User muted the local microphone

            isMicrophoneEnabled = false

            outletMicrophone.setImage(UIImage(named: "icon-nomic.png"), for: .normal)

            qbManager.session?.localMediaStream.audioTrack.isEnabled = false

        } else {

            // MARK: User enabled the local microphone

            isMicrophoneEnabled = true

            outletMicrophone.setImage(UIImage(named: "icon-mic.png"), for: .normal)

            qbManager.session?.localMediaStream.audioTrack.isEnabled = true

        }

    }

    @IBAction func btnEndCall(_ sender: UIButton) {

        let friend = UserManager.shared.friends.filter { $0.uid == UserManager.shared.opponent?.uid }

        if friend.count == 0 {

            // MARK: Not friends, init a friend request.

            let alert = UIAlertController.init(title: NSLocalizedString("Friend_Request_Title", comment: ""), message: NSLocalizedString("Friend_Request_Message", comment: "") + "\(UserManager.shared.opponent?.name ?? "")", preferredStyle: .alert)

            alert.addAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, isEnabled: true, handler: { (_) in
                UserManager.shared.closeChannel()

                self.dismiss(animated: true, completion: nil)
            })

            alert.addAction(title: NSLocalizedString("Send", comment: ""), style: .default, isEnabled: true, handler: { (_) in

                FirebaseManager().checkFriendRequest()

                self.dismiss(animated: true, completion: nil)
            })

            self.present(alert, animated: true, completion: nil)

        } else {

            UserManager.shared.closeChannel()

            self.dismiss(animated: true, completion: nil)

        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        qbManager.session?.localMediaStream.audioTrack.isEnabled = true

        qbManager.audioManager.currentAudioDevice = QBRTCAudioDevice.receiver

        guard let opponent = UserManager.shared.opponent else { return }

        userNameLabel.text = opponent.name

    }

}
