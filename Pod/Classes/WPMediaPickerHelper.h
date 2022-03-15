#import <Foundation/Foundation.h>

@interface WPMediaPickerHelper : NSObject

+ (UIAlertController *)buildAlertControllerWithError:(NSError *)error okActionHandler:(void (^ __nullable)(UIAlertAction *action))handler;

@end
