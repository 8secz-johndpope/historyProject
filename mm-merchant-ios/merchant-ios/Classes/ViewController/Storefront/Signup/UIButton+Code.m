//
//  UIButton+Code.m
//  UIButton+SVCode
//
//  Created by Leslie on 2017/7/16.
//  Copyright © 2017年 Leslie. All rights reserved.
//

#import "UIButton+Code.h"

static dispatch_source_t _timer;
@implementation UIButton (Code)
- (void)setCountdown:(NSTimeInterval )timeOut{
    __block int timeout=timeOut;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    
    dispatch_source_set_event_handler(_timer, ^{
        if(timeout<=0){
            [self cancelCountdown];
            
        }else{
            
            int seconds = timeout;
            NSString *strTime = [NSString stringWithFormat:@"%d", seconds];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setTitle:[NSString stringWithFormat:@"%@(%@s)",COUNTDOWNTITLE,strTime] forState:UIControlStateNormal];
                self.backgroundColor = [UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1];
                [self setTitleColor:[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1] forState:UIControlStateNormal];
                self.userInteractionEnabled = NO;
                
            });
            timeout--;
        }
    });
    dispatch_resume(_timer);
    
}
- (void)cancelCountdown
{
    if(_timer)
    {
        
        dispatch_source_cancel(_timer);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setTitle:GETCODETITLE forState:UIControlStateNormal];
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.backgroundColor = [UIColor colorWithRed:237/255.0 green:34/255.0 blue:71/255.0 alpha:1];
            self.userInteractionEnabled = YES;
        });
    }
}

@end
