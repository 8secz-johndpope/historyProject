//
//  TSVoiceConverter.swift
//  TSWeChat
//
//  Created by Hilen on 1/5/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

class TSVoiceConverter {
    /**
     将 amr 文件转换成 wav 文件
     
     - parameter amrFilePath: amr 文件路径
     - parameter wavSavePath: wav 的保存文件路径
     
     - returns: 是否转换成功
     */
    static func convertAmrToWav(_ amrFilePath: String, wavSavePath: String) -> Bool {
        let amrCString = amrFilePath.cString(using: String.Encoding.utf8)
        let wavCString = wavSavePath.cString(using: String.Encoding.utf8)
        let decode = DecodeAMRFileToWAVEFile(amrCString!, wavCString!)
        return Bool(decode)
    }
    
    
    /**
     将 wav 文件转换成 amr 文件
     
     - parameter wavFilePath: wav 文件路径
     - parameter amrSavePath: amr 的保存文件路径
     
     - returns: 是否转换成功
     */
    static func convertWavToAmr(_ wavFilePath: String, amrSavePath: String) -> Bool {
        let wavCString = wavFilePath.cString(using: String.Encoding.utf8)
        let amrCString = amrSavePath.cString(using: String.Encoding.utf8)
        let encode = EncodeWAVEFileToAMRFile(wavCString!, amrCString!, 1, 16)
        return Bool(encode)
    }
    
    
    /**
     是否是 amr 文件
     
     - parameter filePath: amr 文件路径

     - returns: Bool
     */
//    static func isAMRFile(_ filePath: String) -> Bool {
//        let result = String(cString: filePath)
//        return isAMRFile(result)
//    }
}


private extension Bool {
    init<T : BinaryInteger>(_ integer: T){
        self.init(integer != 0)
    }
}


