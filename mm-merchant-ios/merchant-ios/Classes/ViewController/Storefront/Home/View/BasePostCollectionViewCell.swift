//
//  BasePostCollectionViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 11/13/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import YYText

class BasePostCollectionViewCell: UICollectionViewCell {
    
    var hashTagRanges: [NSRange] = []
    var hiddenURLRanges: [(url: String, range: NSRange)] = []
    var urlRanges: [(url: String, range: NSRange)] = []
    
    class func getDescriptionHeight(_ postText: String, fontSize: Int, width: CGFloat) -> CGFloat {
        
        let label = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont.fontWithSize(fontSize, isBold: false)
        
        let text = NSMutableAttributedString(string: postText)
        text.yy_lineBreakMode = NSLineBreakMode.byWordWrapping
        text.yy_font = UIFont.fontWithSize(fontSize, isBold: false)
        
        let ranges = postText.rangeMatches(pattern: RegexManager.ValidPattern.HashTag, exclude: RegexManager.ValidPattern.ExcludeHttp)
        for range in ranges {
            text.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(fontSize, isBold: true), range: range)
        }
        label.attributedText = text
        label.sizeToFit()
        
        var height = ceil(label.frame.size.height)
        if postText.containsEmoji() {
            height += 14
        }
        return height
    }
    
    func formatDescription(_ label: YYLabel, post: Post, fontSize: Int) {
        
        DispatchQueue.main.async {
            
            let postText =  post.postText
            
            let text = NSMutableAttributedString(string: postText)
            text.yy_font = UIFont.fontWithSize(fontSize, isBold: false)
            text.yy_color = UIColor.secondary2()
            
           let attributedString = BasePostCollectionViewCell.formatHashTagAndAppLinks(hashTagRanges: &self.hashTagRanges, hiddenURLRanges: &self.hiddenURLRanges, urlRanges: &self.urlRanges, attributedText: text, postText: post.postText, fontSize: fontSize)
            if attributedString.string.length > 0 {
                label.attributedText = attributedString
            } else {
                label.text = post.postText
            }

            label.highlightTapAction = { (view, attribute, range: NSRange, rect) in
                
                //CLick URL
                let urlRanges = self.hiddenURLRanges + self.urlRanges
                for currentURL in urlRanges {
                    if range.location >= currentURL.range.location && range.location <= (currentURL.range.location + currentURL.range.length) {
                        self.didClickURL(currentURL.url)
                        return
                    }
                }
                
                //Click HashTag
                if let tempRange = Range(range, in: attribute.string) {
                    let tag = String(attribute.string[tempRange])
                    self.didClickOnHashTag(tag)
                    return
                }
            }
            
            label.textTapAction = { (view, attribute, range: NSRange, rect) in
                var found = false
                
                //Click HashTag
                for currentRange in self.hashTagRanges {
                    if range.location >= currentRange.location && range.location <= (currentRange.length + currentRange.location) {
                        found = true
                        break
                    }
                }
                
                //CLick URL
                let urlRanges = self.hiddenURLRanges + self.urlRanges
                for currentURL in urlRanges {
                    if range.location >= currentURL.range.location && range.location <= (currentURL.range.location + currentURL.range.length) {
                        found = true
                        break
                    }
                }
                
                if !found {
                    self.recordAction(.Tap, sourceRef: "\(post.postId)", sourceType: .Post, targetRef: "Post-Detail", targetType: .View)
                    self.didClickDescriptionText(post)
                }
            }
        }
        
    }
    
    func didClickOnHashTag(_ tag: String) {
        
    }
    
    func didClickDescriptionText(_ post: Post) {
        
    }
    
    func didClickURL(_ url: String) {
        
    }
    
  static func formatHashTagAndAppLinks(hashTagRanges:inout [NSRange],hiddenURLRanges:inout [(url: String, range: NSRange)],urlRanges:inout [(url: String, range: NSRange)],attributedText:NSMutableAttributedString,postText:String,fontSize:Int) ->  NSMutableAttributedString {
    
        hashTagRanges.removeAll()
        hiddenURLRanges.removeAll()
        urlRanges.removeAll()
    
        let ranges = postText.rangeMatches(pattern:RegexManager.ValidPattern.HashTag, exclude:RegexManager.ValidPattern.ExcludeHttp)
        for range in ranges {
            attributedText.yy_setTextHighlight(range, color: UIColor.hashtagColor(), backgroundColor: nil, userInfo: nil)
            attributedText.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(fontSize, isBold: true), range: range)
            hashTagRanges.append(range)
        }
        
        let plainText = attributedText.string
        
        
        // Use a data detector to find urls in the text
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        guard let matches = detector?.matches(in: plainText, options: [], range: NSRange(location: 0, length: (plainText as NSString).length )) else {
            return attributedText
        }
        
        //---- START REPLACE URL
        var listURLReplace = [String]() //list of URL need to be replaced
        var listURLRemain = [String]() //list of URL DON'T need to be replaced
        let linkColor = UIColor.init(hexString: "#507DAF")
        let iconSizeWidth: CGFloat = CGFloat(fontSize) * 0.7
        
        //Find URL need to be replaced
        for match: NSTextCheckingResult in matches {
            let matchRange: NSRange = match.range
            let realURL: String = (plainText as NSString).substring(with: matchRange)
            if BasePostCollectionViewCell.shouldHideURL(realURL) {
                listURLReplace.append(realURL)
            } else {
                listURLRemain.append(realURL)
            }
        }
        
        for currentUrlReplace in listURLReplace {
            
            //Prepare Image to replace
            let attachmentString = NSMutableAttributedString.yy_attachmentString(withContent: UIImage(named: "sdp_link"), contentMode: .left, attachmentSize: CGSize(width: iconSizeWidth, height: iconSizeWidth), alignTo: UIFont.systemFont(ofSize: CGFloat(fontSize)), alignment: .center)
            
            
            //Prepare Text to replace
            let replacementText = " \(String.localize("LB_CA_SDP_CHECK_LINK"))"
            let textAfterImage = NSMutableAttributedString(string: replacementText)
            
            textAfterImage.addAttributes([NSAttributedStringKey.foregroundColor: linkColor], range: NSRange(location: 0, length: (replacementText as String).length))
            
            //Prepare Image and Text will be replace
            let completeImageText = NSMutableAttributedString(string: "")
            completeImageText.append(attachmentString)
            completeImageText.append(textAfterImage)
            
            //Replace
            let rangeReplace = attributedText.mutableString.range(of: currentUrlReplace)
            attributedText.replaceCharacters(in: rangeReplace, with: completeImageText)
            let rangeHiddenURL = NSRange(location: rangeReplace.location, length: completeImageText.length)
            attributedText.yy_setTextHighlight(rangeHiddenURL, color: linkColor, backgroundColor: nil, userInfo: nil)
            attributedText.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(fontSize, isBold: false), range: rangeHiddenURL)
            hiddenURLRanges.append((currentUrlReplace, rangeHiddenURL))
        }
        
        for currentURL in listURLRemain {
            let currentRange = attributedText.mutableString.range(of: currentURL)
            urlRanges.append((currentURL, currentRange))
            attributedText.yy_setTextHighlight(currentRange, color: linkColor, backgroundColor: nil, userInfo: nil)
            attributedText.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(fontSize, isBold: false), range: currentRange)
        }
        return attributedText
    }
    
    //MARK: - Format Label
    
    func formatHashTag(_ label: YYLabel, post: Post, fontSize: Int) {
        hashTagRanges.removeAll()
        let text = label.attributedText != nil ? NSMutableAttributedString(attributedString: label.attributedText!) : NSMutableAttributedString(string: label.text ?? "")
        let ranges = post.postText.rangeMatches(pattern:RegexManager.ValidPattern.HashTag, exclude:RegexManager.ValidPattern.ExcludeHttp)
        for range in ranges {
            text.yy_setTextHighlight(range, color: UIColor.hashtagColor(), backgroundColor: nil, userInfo: nil)
            text.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(fontSize, isBold: true), range: range)
            hashTagRanges.append(range)
        }
        label.attributedText = text
    }
    
    /*
     This function to hide app link in post description and make it touchable
     */
    func formatAppLinks(_ label: YYLabel, fontSize: Int) {
        
        hiddenURLRanges.removeAll()
        urlRanges.removeAll()
        
        let attributedText = label.attributedText != nil ? NSMutableAttributedString(attributedString: label.attributedText!) : NSMutableAttributedString(string: label.text ?? "")
        let plainText = label.attributedText?.string ?? ""
        if (plainText as String).length <= 0 {
            return
        }
        
        // Use a data detector to find urls in the text
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        guard let matches = detector?.matches(in: plainText, options: [], range: NSRange(location: 0, length: (plainText as NSString).length )) else {
            return
        }
        
        //---- START REPLACE URL
        var listURLReplace = [String]() //list of URL need to be replaced
        var listURLRemain = [String]() //list of URL DON'T need to be replaced
        let linkColor = UIColor.init(hexString: "#507DAF")
        let iconSizeWidth: CGFloat = label.font.pointSize * 0.7
        
        //Find URL need to be replaced
        for match: NSTextCheckingResult in matches {
            let matchRange: NSRange = match.range
            let realURL: String = (plainText as NSString).substring(with: matchRange)
            if BasePostCollectionViewCell.shouldHideURL(realURL) {
                listURLReplace.append(realURL)
            } else {
                listURLRemain.append(realURL)
            }
        }
        
        for currentUrlReplace in listURLReplace {
            
            //Prepare Image to replace
            let attachmentString = NSMutableAttributedString.yy_attachmentString(withContent: UIImage(named: "sdp_link"), contentMode: .left, attachmentSize: CGSize(width: iconSizeWidth, height: iconSizeWidth), alignTo: label.font, alignment: .center)
            
            
            //Prepare Text to replace
            let replacementText = " \(String.localize("LB_CA_SDP_CHECK_LINK"))"
            let textAfterImage = NSMutableAttributedString(string: replacementText)
            
            textAfterImage.addAttributes([NSAttributedStringKey.foregroundColor: linkColor], range: NSRange(location: 0, length: (replacementText as String).length))
            
            //Prepare Image and Text will be replace
            let completeImageText = NSMutableAttributedString(string: "")
            completeImageText.append(attachmentString)
            completeImageText.append(textAfterImage)
            
            //Replace
            let rangeReplace = attributedText.mutableString.range(of: currentUrlReplace)
            attributedText.replaceCharacters(in: rangeReplace, with: completeImageText)
            let rangeHiddenURL = NSRange(location: rangeReplace.location, length: completeImageText.length)
            attributedText.yy_setTextHighlight(rangeHiddenURL, color: linkColor, backgroundColor: nil, userInfo: nil)
            attributedText.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(fontSize, isBold: false), range: rangeHiddenURL)
            hiddenURLRanges.append((currentUrlReplace, rangeHiddenURL))
        }
        
        for currentURL in listURLRemain {
            let currentRange = attributedText.mutableString.range(of: currentURL)
            urlRanges.append((currentURL, currentRange))
            attributedText.yy_setTextHighlight(currentRange, color: linkColor, backgroundColor: nil, userInfo: nil)
            attributedText.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(fontSize, isBold: false), range: currentRange)
        }
        label.attributedText = attributedText
    }
    
    //MARK: - URL Replacment
    
    private func getFirstMatchURLHiddenIfNeeded(_ matches: [NSTextCheckingResult], text: String) -> NSTextCheckingResult? {
        for match: NSTextCheckingResult in matches {
            let matchRange: NSRange = match.range
            let realURL: String = (text as NSString).substring(with: matchRange)
            if BasePostCollectionViewCell.shouldHideURL(realURL) {
                return match
            }
        }
        return nil
    }
    
    
    class func shouldHideURL(_ urlString: String) -> Bool {
        for currentHost: String in PostManager.hiddenUrls {
            if let endCodeUrlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                let url = URL(string: endCodeUrlString) {
                if let hostName = url.host, hostName.lowercased().range(of: currentHost) != nil {
                    return true
                }
            }
        }
        return false
    }
    
    // Use a data detector to find urls in the text
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    
    class func getTextByRemovingAppUrls(_ originalText: String) -> String {
        
        var plainText: String = originalText
        let matches = detector?.matches(in: plainText, options: [], range: NSRange(location: 0, length: (originalText.count)))
        var listHiddenUrls = [String]()
        if let matches = matches {
            for match: NSTextCheckingResult in matches {
                let matchRange: NSRange = match.range
                
                let realURL: String = (plainText as NSString).substring(with: matchRange)
                if BasePostCollectionViewCell.shouldHideURL(realURL) {
                    listHiddenUrls.append(realURL)
                }
            }
        } else {
            return originalText
        }
        
        let labelLinkValue = String.localize("LB_CA_SDP_CHECK_LINK")
        for urlString: String in listHiddenUrls {
            plainText = plainText.replacingOccurrences(of: urlString, with: "   \(labelLinkValue)")
        }
        return plainText
    }
    
    
}

