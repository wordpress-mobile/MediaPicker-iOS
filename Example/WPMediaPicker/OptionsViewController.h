@import UIKit;

extern NSString const *MediaPickerOptionsShowMostRecentFirst;
extern NSString const *MediaPickerOptionsShowCameraCapture;
extern NSString const *MediaPickerOptionsPreferFrontCamera;
extern NSString const *MediaPickerOptionsSelectionLimit;
extern NSString const *MediaPickerOptionsPostProcessingStep;
extern NSString const *MediaPickerOptionsFilterType;
extern NSString const *MediaPickerOptionsCustomPreview;
extern NSString const *MediaPickerOptionsScrollInputPickerVertically;
extern NSString const *MediaPickerOptionsShowSampleCellOverlays;
extern NSString const *MediaPickerOptionsShowSearchBar;

@class OptionsViewController;

@protocol OptionsViewControllerDelegate <NSObject>

- (void)optionsViewController:(OptionsViewController *)optionsViewController changed:(NSDictionary *)options;

- (void)cancelOptionsViewController:(OptionsViewController *)optionsViewController;

@end
@interface OptionsViewController : UITableViewController

@property (nonatomic, weak) id<OptionsViewControllerDelegate> delegate;
@property (nonatomic, copy) NSDictionary *options;

@end
