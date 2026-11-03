#pragma once
#import <UIKit/UIKit.h>

@interface UIKitMenu : UIView
+ (instancetype)shared;
- (void)show;
- (void)hide;
- (void)toggle;
@end
