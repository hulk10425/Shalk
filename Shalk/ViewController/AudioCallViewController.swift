//
//  AudioCallViewController.swift
//  Shalk
//
//  Created by Nick Lee on 2017/7/30.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import UIKit
import Quickblox
import QuickbloxWebRTC

class AudioCallViewController: UIViewController {

    var isMicrophoneEnabled: Bool = true

    var isSpeakerEnabled: Bool = false

    var selectedLang: String = ""

    var receivedUserName = ""

    let qbManager = QBManager.shared

    var session = QBManager.shared.session {

        didSet {

            print("value changed")

            if session == nil {

                self.dismiss(animated: true, completion: nil)

            }

        }

    }

    let rtcManager = QBRTCClient.instance()

    @IBOutlet weak var userImageView: UIImageView!

    @IBOutlet weak var defaultUserImageView: UIImageView!

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

        self.endCallWithFriendRequest()

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        qbManager.session?.localMediaStream.audioTrack.isEnabled = true

        qbManager.audioManager.currentAudioDevice = QBRTCAudioDevice.receiver

        userNameLabel.text = receivedUserName

    }

}