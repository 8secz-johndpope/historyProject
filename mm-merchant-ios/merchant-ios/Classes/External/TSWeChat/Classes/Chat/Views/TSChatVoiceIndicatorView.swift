//
//  TSRecordIndicatorView.swift
//  TSWeChat
//
//  Created by Hilen on 12/22/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit

class TSChatVoiceIndicatorView: UIView {
    @IBOutlet weak var voiceCancelImageView: UIImageView!{didSet {
        voiceCancelImageView.layer.masksToBounds = true
        }}
    @IBOutlet weak var centerView: UIView!{didSet {  //中央的灰色背景 view
        centerView.layer.cornerRadius = 10.0
        centerView.layer.masksToBounds = true
        }}
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!  //取消提示
    var isMessageTooLong: Bool = false
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        self.initContent()
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
        self.initContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initContent() {
    }
    
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
}

//对外交互的 view 控制
// MARK: - @extension TSChatVoiceIndicatorView
extension TSChatVoiceIndicatorView {
    //正在录音
    func recording() {
        self.isHidden = false
        self.voiceCancelImageView.isHidden = false
        self.voiceCancelImageView.image = UIImage(named: "voice_cancel_black")
        self.centerView.isHidden = true
    }
    
    //录音过程中音量的变化
    func signalValueChanged(_ value: CGFloat) {
        
    }
    
    //滑动取消
    func slideToCancelRecord() {
        self.isHidden = false
        self.centerView.isHidden = false
        self.noteLabel.text = String.localize("LB_CA_IM_RECORD_VOICE_CANCEL")
        self.noteLabel.textColor = UIColor.red
        self.alertImageView.image = UIImage(named: "voice_cancel_white")
        self.voiceCancelImageView.isHidden = true
    }
    
    //录音时间太短的提示
    func messageTooShort() {
        let delay_t = DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay_t) {
            self.isHidden = false
            self.centerView.isHidden = false
            self.noteLabel.text = String.localize("MSG_ERR_CA_IM_RECORD_SHORT")
            self.noteLabel.textColor = UIColor.white
            self.alertImageView.image = UIImage(named: "voice_warning")
            self.voiceCancelImageView.isHidden = true
            //2.0秒后消失
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.endRecord()
            }
        }
    }
    
    func messageTooLong() {
        self.isMessageTooLong = true
        let delay_t = DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay_t) {
            self.isHidden = false
            self.centerView.isHidden = false
            self.noteLabel.text = String.localize("MSG_ERR_CA_IM_RECORD_LONG")
            self.noteLabel.textColor = UIColor.white
            self.alertImageView.image = UIImage(named: "voice_warning")
            self.voiceCancelImageView.isHidden = true
            //0.5秒后消失
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.endRecord()
            }
        }
    }
    
    //录音结束
    func endRecord() {
        self.isHidden = true
    }
    
    //    //更新麦克风的音量大小
    //    func updateMetersValue(value: Float) {
    //        var index = Int(value)
    //        index = index > 7 ? 7 : index
    //        index = index < 0 ? 0 : index
    //
    //        let array = [
    //            TSAsset.RecordingSignal001.image,
    //            TSAsset.RecordingSignal002.image,
    //            TSAsset.RecordingSignal003.image,
    //            TSAsset.RecordingSignal004.image,
    //            TSAsset.RecordingSignal005.image,
    //            TSAsset.RecordingSignal006.image,
    //            TSAsset.RecordingSignal007.image,
    //            TSAsset.RecordingSignal008.image,
    //        ]
    ////        self.signalValueImageView.image = array.get(index)
    //        
    //    }
}




