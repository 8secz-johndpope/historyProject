//
//  NSString+TruncateToWidth.h
//  merchant-ios
//
//  Created by Phan Manh Hung on 7/26/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (TruncateToWidth)

- (NSString*)stringByTruncatingAtString:(NSString *)string toWidth:(CGFloat)width withFont:(UIFont *)font;

@end
