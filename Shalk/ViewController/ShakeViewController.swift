//
//  ShakeViewController.swift
//  Shalk
//
//  Created by Nick Lee on 2017/7/27.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import UIKit
import Magnetic
import SpriteKit
import Quickblox
import AudioToolbox
import QuickbloxWebRTC
import NVActivityIndicatorView

class ShakeViewController: UIViewController {

    let rtcManager = QBRTCClient.instance()

    let qbManager = QBManager.shared

    let fbManager = FirebaseManager()

    let userManager = UserManager.shared

    var names = UIImage.names

    var selectedNode: Node?

    var opponent: Opponent?

    var selectedLanguage: String = ""

    var isDiscovering: Bool = false

    @IBOutlet weak var loadingView: NVActivityIndicatorView!

    @IBOutlet weak var labelSearching: UILabel!

    @IBOutlet weak var magneticView: MagneticView! {

        didSet {

            magnetic.magneticDelegate = self

        }

    }

    var magnetic: Magnetic {

        return magneticView.magnetic

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addLangBubbles(nil)

        labelSearching.isHidden = true

        rtcManager.add(self)

        QBManager.shared.audioManager.initialize()

        QBManager.shared.audioManager.currentAudioDevice = QBRTCAudioDevice.receiver

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        selectedNode?.isSelected = false

        selectedNode = nil

        loadingView.stopAnimating()

        labelSearching.isHidden = true

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        userManager.isConnected = false

        userManager.opponent = nil

        isDiscovering = false

    }

    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {

        if isDiscovering == false {

            isDiscovering = true

            if motion == .motionShake {

                guard let selectedLanguage = selectedNode?.text else {

                    labelSearching.text = "Please select a preferred language."

                    labelSearching.isHidden = false

                    return

                }

                self.selectedLanguage = selectedLanguage

                // MARK: Start pairing...

                loadingView.startAnimating()

                labelSearching.text = "Discovering, please wait!"

                labelSearching.isHidden = false

                fbManager.fetchChannels(withLang: selectedLanguage)

            }

        } else {

            labelSearching.text = "You are discovering the partner, please wait!"

        }

    }

    @IBAction func addLangBubbles(_ sender: UIControl?) {

        for _ in 0...3 {

            let name = names.randomItem()

            names.removeAll(name)

            let color = UIColor.colors.randomItem()

            let node = Node(text: name.capitalized, image: UIImage(named: name), color: color, radius: 40)

            magnetic.addChild(node)

        }

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "audioCall" {

            let audioVC = segue.destination as? AudioCallViewController

//            audioVC.userName =

        }

    }

}

extension ShakeViewController: QBRTCClientDelegate {

    func didReceiveNewSession(_ session: QBRTCSession, userInfo: [String : String]? = nil) {

        if qbManager.session != nil {

            let userInfo = ["key": "value"]

            session.rejectCall(userInfo)

        } else {

            do {

                qbManager.session = session
                
                print("@@@@@@@@@@@@@@@@@@@", userInfo!)

                userManager.opponent = try Opponent.init(json: userInfo!)

                qbManager.acceptCall()

                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

                self.performSegue(withIdentifier: "audioCall", sender: nil)

            } catch let error {

                // TODO: Error handling

                print(error.localizedDescription)

            }
        }
    }

    func session(_ session: QBRTCBaseSession, receivedRemoteAudioTrack audioTrack: QBRTCAudioTrack, fromUser userID: NSNumber) {

        audioTrack.isEnabled = true

    }

    func session(_ session: QBRTCSession, acceptedByUser userID: NSNumber, userInfo: [String : String]? = nil) {

        userManager.isConnected = true

        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

    }

    func session(_ session: QBRTCBaseSession, connectedToUser userID: NSNumber) {

        self.performSegue(withIdentifier: "audioCall", sender: nil)

    }

    func sessionDidClose(_ session: QBRTCSession) {

        qbManager.session = nil

    }

    func session(_ session: QBRTCSession, rejectedByUser userID: NSNumber, userInfo: [String : String]? = nil) {

        fbManager.fetchChannels(withLang: selectedLanguage)

    }

    func session(_ session: QBRTCSession, hungUpByUser userID: NSNumber, userInfo: [String : String]? = nil) {

        // MARK: Received a hung up signal from user.

        guard let info = userInfo else { return }

        print("-------------- user info -------------", userInfo)

        self.receivedEndCallwithFriendRequest(withInfo: info)

    }

}

// MARK: - MagneticDelegate
extension ShakeViewController: MagneticDelegate {

    func magnetic(_ magnetic: Magnetic, didSelect node: Node) {

        print("didSelect -> \(node)")

        selectedNode?.isSelected = false

        selectedNode = node

        selectedNode?.isSelected = true

    }

    func magnetic(_ magnetic: Magnetic, didDeselect node: Node) {

        print("didDeselect -> \(node)")

        guard let language = node.text else { return }

        fbManager.removeFromChatPool(withLanguage: language)

    }

}

// MARK: - ImageNode
class ImageNode: Node {

    override var image: UIImage? {

        didSet {

            sprite.texture = image.map { SKTexture(image: $0) }

        }
    }

    override func selectedAnimation() {}

    override func deselectedAnimation() {}

}
