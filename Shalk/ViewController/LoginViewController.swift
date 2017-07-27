//
//  LoginViewController.swift
//  Shalk
//
//  Created by Nick Lee on 2017/7/27.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var iconEmail: UIImageView!
    @IBOutlet weak var iconKey: UIImageView!

    @IBOutlet weak var inputEmail: UITextField!

    @IBOutlet weak var inputPassword: UITextField!

    @IBAction func btnLogin(_ sender: UIButton) {

    }

    @IBAction func btnCreateNewAccount(_ sender: UIButton) {

        let registerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "registerVC")

        self.present(registerVC, animated: true, completion: nil)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        iconEmail.tintColor = UIColor.lightGray

        iconKey.tintColor = UIColor.lightGray

    }

}