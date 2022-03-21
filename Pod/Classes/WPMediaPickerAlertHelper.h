#import <Foundation/Foundation.h>

@interface WPMediaPickerAlertHelper : NSObject

+ (UIAlertController *)buildAlertControllerWithError:(NSError *)error okActionHandler:(void (^ __nullable)(UIAlertAction *action))handler;

@end
