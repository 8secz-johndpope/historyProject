//
//  ContentPageHelper.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 8/3/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

enum ContentPageType {
	case mmAbout
	case mmCopyRight
	case mmLegalStatement
	case mmipStatement
	case mmPrivacyStatement
	case mmUserAgreement
	case mmReturn
	case mmTnc
	case mmContactUs
    case mmRefereeTNC
}

struct ContentName {
	
	//关于美美
	static let mmAbout = "mmTnC.html#aboutMM"
	
	//版权信息
	static let mmCopyRight = "mmTnC.html#copyright"
	
	//法律声明
	static let mmLegalStatement = "mmTnC.html#legalStatement"
	
	//知识产权声明
	static let mmIPStatement = "mmTnC.html#IPStatement"
	
	//隐私权政策
	static let mmPrivacyStatement = "mmTnC.html#PrivacyStatement"
	
	//用户协议
	static let mmUserAgreement = "mmTnC.html#userAgreement"
	
	//美美退换货政策
	static let mmReturn = "mmTnC.html#returnPolicy"
	
	static let mmTnc = "mm_tnc.html"
	static let mmContactUs = "mm_contact_us.html"
    
    static let mmRefereeTNC = "/operations/vip/referral_rule.html" //"/web/vip/referral_rule.html?v=1"
}

struct ProtocolWeb {
    static let http = "http"
    static let https = "https"
}

struct PathContent {
    //static let UrlString = "https://" + Constants.Path.Domain + "/assets/docs/tnc/"
    static let UrlString = "https://cdnc.mymm.cn/operations/tnc/"
    static let HostContent = "https://cdnc.mymm.cn"
}

enum ContentURLFactory {
    static func urlForContentType(_ contentType: ContentPageType) -> String? {
        
        switch contentType {
		case .mmAbout:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmAbout
		case .mmCopyRight:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmCopyRight
		case .mmLegalStatement:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmLegalStatement
		case .mmipStatement:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmIPStatement
		case .mmPrivacyStatement:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmPrivacyStatement
		case .mmUserAgreement:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmUserAgreement
		case .mmReturn:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmReturn
		case .mmTnc:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmTnc
		case .mmContactUs:
			return PathContent.UrlString + Context.getCc() + "/" + ContentName.mmContactUs
        case .mmRefereeTNC:
            return PathContent.HostContent + ContentName.mmRefereeTNC
		}
		
    }
}
