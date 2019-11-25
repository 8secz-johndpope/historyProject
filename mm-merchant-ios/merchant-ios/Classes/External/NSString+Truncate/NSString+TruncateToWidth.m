//
//  NSString+TruncateToWidth.m
//  merchant-ios
//
//  Created by Phan Manh Hung on 7/26/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

#import "NSString+TruncateToWidth.h"

#define ellipsis @"…"

@implementation NSString (TruncateToWidth)

- (NSString *)stringByTruncatingAtString:(NSString *)string toWidth:(CGFloat)width withFont:(UIFont *)font
{
    // If the string is already short enough, or
    // if the 'truncation location' string doesn't exist
    // go ahead and pass the string back unmodified.
    if ([self sizeWithAttributes:@{NSFontAttributeName:font}].width < width ||
        [self rangeOfString:string].location == NSNotFound)
        return self;
    
    // Create copy that will be the returned result
    NSMutableString *truncatedString = [self mutableCopy];
    
    // Accommodate for ellipsis we'll tack on the beginning
    width -= [ellipsis sizeWithAttributes:@{NSFontAttributeName:font}].width;
    
    // Get range of the passed string. Note that this only works to the first instance found,
    // so if there are multiple, you need to modify your solution
    NSRange range = [truncatedString rangeOfString:string options:NSBackwardsSearch];
    range.length = 1;
    
    while([truncatedString sizeWithAttributes:@{NSFontAttributeName:font}].width > width
          && range.location > 0)
    {
        range.location -= 1;
        [truncatedString deleteCharactersInRange:range];
    }
    
    // Append ellipsis
    range.length = 0;
    [truncatedString replaceCharactersInRange:range withString:ellipsis];
    
    return truncatedString;
}

@end