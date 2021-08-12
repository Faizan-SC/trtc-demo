//
//  ScreenViewController.swift
//  TRTCSimpleDemo
//
//  Created by J J on 2020/6/10.
//  Copyright © 2020 Tencent. All rights reserved.
//

import UIKit
import TXLiteAVSDK_TRTC

class ScreenViewController: UIViewController {
    enum State {
        case waiting
        case started
        case stopped
    }

    let buttonTitleMap : [State: String] = [
        .waiting : "Waiting",
        .started : "Started",
        .stopped : "Stopped"
    ]

    var state : State = .stopped {
        didSet {
            recordScreenButton.setTitle(buttonTitleMap[state], for: .normal)
            recordStateLabel.isHidden = state != .started
        }
    }


    let videoEncParam = TRTCVideoEncParam()

    let APPGROUP = "group.com.tencent.liteav.RPLiveStreamShare"
    let recordStateLabel = UILabel()
    let roomStateLabel = UILabel()
    let recordScreenButton = UIButton()
    let recordScreenKey = "TRTCRecordScreenKey"
    let param = TRTCParams()
    
    private lazy var trtcCloud: TRTCCloud = {
        let instance: TRTCCloud = TRTCCloud.sharedInstance()
        ///设置TRTCCloud的回调接口
        instance.delegate = self
        return instance;
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoEncParam.videoResolution = TRTCVideoResolution._1280_720
        videoEncParam.videoFps = 10
        videoEncParam.videoBitrate = 1600
        
        setupUI()
        state = .stopped
        
        if #available(iOS 11, *) {
            enterRoom()
        }
    }
    
    func setupUI() {
        title = "Some title"
        self.view.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1)

        //录屏按钮
        recordScreenButton.frame = CGRect(x: UIScreen.main.bounds.size.width * 32.0/375, y: UIScreen.main.bounds.size.height * 320.0/667, width: UIScreen.main.bounds.size.width * 311.0/375, height: 45)
        recordScreenButton.backgroundColor = UIColor(red: -0.32, green: 0.66, blue: 0.4, alpha: 1)
        recordScreenButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        recordScreenButton.addTarget(self, action: #selector(onTapRecordButton), for: .touchUpInside)
        recordScreenButton.tag = 0
        recordScreenButton.layer.masksToBounds = true
        recordScreenButton.layer.cornerRadius = 4.0
        self.view.addSubview(recordScreenButton)

        guard #available(iOS 11.0, *) else {
            recordScreenButton.isUserInteractionEnabled = false
            recordScreenButton.setTitle("Record button ios 11", for: .normal)
            return;
        }
        //静音按钮
        let muteButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width * 3.0/7, y: UIScreen.main.bounds.size.height - UIScreen.main.bounds.size.width / 5.0, width: UIScreen.main.bounds.size.width / 7.0, height: UIScreen.main.bounds.size.width / 7.0))
        muteButton.setImage(UIImage(named: "rtc_mic_off"), for: .normal)
        muteButton.tag = 0
        muteButton.addTarget(self, action: #selector(onTapMuteButton), for: .touchUpInside)
        self.view.addSubview(muteButton)
        
        //录屏提示label
        recordStateLabel.frame = CGRect(x: UIScreen.main.bounds.size.width * 32.0/375, y: UIScreen.main.bounds.size.height / 3.0, width: UIScreen.main.bounds.size.width * 311.0/375, height: 45)
        recordStateLabel.text = "record state label text"
        recordStateLabel.textAlignment = NSTextAlignment.center
        recordStateLabel.textColor = .white
        self.view.addSubview(recordStateLabel)
        view.addConstraint(NSLayoutConstraint(item: recordStateLabel,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: recordStateLabel,
                                               attribute: .bottom,
                                               relatedBy: .equal,
                                               toItem: recordScreenButton,
                                               attribute: .top,
                                               multiplier: 1,
                                               constant: -50))

        view.addSubview(roomStateLabel)
        roomStateLabel.textColor = .white
        roomStateLabel.numberOfLines = 0
        roomStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: roomStateLabel,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .left,
                                              multiplier: 1,
                                              constant: 8))
        view.addConstraint(NSLayoutConstraint(item: roomStateLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .topMargin,
                                              multiplier: 1,
                                              constant: 60))
        view.addConstraint(NSLayoutConstraint(item: roomStateLabel,
                                              attribute: .right,
                                              relatedBy: .lessThanOrEqual,
                                              toItem: view,
                                              attribute: .right,
                                              multiplier: 1,
                                              constant: -8))

    }

    @available(iOS 11, *)
    func enterRoom() {
        param.sdkAppId = UInt32(SDKAppID)
        param.roomId   = 1256732
        param.userId   = "\(UInt32(CACurrentMediaTime() * 1000))"
        param.role     = TRTCRoleType.anchor
        /// userSig是进入房间的用户签名，相当于密码（这里生成的是测试签名，正确做法需要业务服务器来生成，然后下发给客户端）
        param.userSig  = GenerateTestUserSig.genTestUserSig(param.userId)

        roomStateLabel.text = "room state label text"
        /// 指定以“视频通话场景”（TRTCAppScene.videoCall）进入房间
        trtcCloud.enterRoom(param, appScene: TRTCAppScene.videoCall)
        trtcCloud.startScreenCapture(byReplaykit: videoEncParam, appGroup: APPGROUP)
    }

    private func showPicker() {
        if #available(iOS 12.0, *) {
            TRTCBroadcastExtensionLauncher.launch()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        trtcCloud.exitRoom()
    }

}

// MARK: - Button Events
extension ScreenViewController {
    @objc func onTapRecordButton(recordButton: UIButton) {
        guard #available(iOS 11.0, *) else {
            return
        }

        switch state {
        case .started:
            trtcCloud.stopScreenCapture()
        case .stopped:
            showPicker()
            state = .waiting
            trtcCloud.startScreenCapture(byReplaykit: videoEncParam, appGroup: APPGROUP)
        case.waiting:
            showPicker()
        }
    }

    @objc func onTapMuteButton(button: UIButton) {
        if button.tag == 0 {
            print("RTC Mic On")
            button.setImage(UIImage(named: "rtc_mic_on"), for:.normal)
            button.tag = 1
            trtcCloud.stopLocalAudio()
        } else if button.tag == 1 {
            print("RTC Mic Off")
            button.setImage(UIImage(named: "rtc_mic_off"), for: .normal)
            button.tag = 0
            trtcCloud.startLocalAudio()
        }
    }
}

// MARK: - TRTCCloudDelegate
extension  ScreenViewController : TRTCCloudDelegate {
    func onEnterRoom(_ result: Int) {
        roomStateLabel.text = """
        Room Id: \(param.roomId)
        Room user id: \(param.userId)
        Resolution: "720 x 1280"
        Bla bla bla
        """
        trtcCloud.startLocalAudio()
    }

    func onScreenCaptureStarted() {
        state = .started
    }

    func onScreenCaptureStoped(_ reason: Int32) {
        state = .stopped
    }
}


