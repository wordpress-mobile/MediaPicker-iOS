//
//  WPActionBar.h
//  WPMediaPicker
//
//  Created by Eduardo Toledo on 4/5/18.
//

#import <UIKit/UIKit.h>

@interface WPActionBar : UIView

/**
 The color for the top horizontal line.
 */
@property (nonatomic, strong) UIColor *lineColor;

/**
 Adds the given button to the left side of the bar

 @param button The button to add.
 */
- (void)addLeftButton:(UIButton *)button;

/**
 Adds the given button to the right side of the bar

 @param button The button to add.
 */
- (void)addRightButton:(UIButton *)button;

@end
