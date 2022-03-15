#import "UIViewController+MediaAdditions.h"
#import "WPMediaCollectionDataSource.h"
#import "WPMediaPickerHelper.h"

@implementation UIViewController (MediaAdditions)

- (void)wpm_showAlertWithError:(NSError *)error okActionHandler:(void (^ __nullable)(UIAlertAction *action))handler {
    UIAlertController *alertController = [WPMediaPickerHelper buildAlertControllerWithError:error okActionHandler:handler];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
