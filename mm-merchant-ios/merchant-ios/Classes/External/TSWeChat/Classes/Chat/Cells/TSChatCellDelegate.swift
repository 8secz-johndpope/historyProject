//
//  TSChatCellDelegate.swift
//  TSWeChat
//
//  Created by Hilen on 1/29/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

@objc protocol TSChatCellDelegate: class {
    /**
     点击了 cell 本身
     */
    @objc optional func cellDidTaped(_ cell: TSChatBaseCell)

    /**
     点击了 cell 的头像
     */
    func cellDidTapedAvatarImage(_ cell: TSChatBaseCell)

    /**
     点击了 cell 的图片
     */
    func cellDidTappedImageView(_ cell: TSChatBaseCell, model: ChatModel)
    
    /**
     点击了 cell 中文字的 URL
     */
    func cellDidTapedLink(_ cell: TSChatBaseCell, linkString: String)

    /**
     点击了 cell 中文字的 电话
     */
    func cellDidTapedPhone(_ cell: TSChatBaseCell, phoneString: String)
    
    /**
     点击了声音 cell 的播放 button
     */
    func cellDidTapedVoiceButton(_ cell: TSChatVoiceCell?, isPlayingVoice: Bool)

    func forwardImageDidTaped(_ image: UIImage)
    
    func forwardTextDidTapped(_ string: String)
    
    func saveImageDidTaped(_ image: UIImage)

    func cellDidPressLong(_ cell: TSChatBaseCell)

    func forwardUserDidTaped(_ user: User)
    
    func forwardVoiceDidTaped(_ audioModel: ChatAudioModel)
    
    func resendMessage(_ model: ChatModel)
}
