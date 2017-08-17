@import UIKit;
#import "WPMediaCollectionDataSource.h"
#import "WPMediaPickerOptions.h"

@class WPMediaPickerViewController;
@protocol WPMediaPickerViewControllerDelegate;

@interface WPNavigationMediaPickerViewController : UIViewController

/**
 Init a WPNavigationMediaPickerViewController with the selection options

 @param options an WPMediaPickerOption object
 @return an initiated WPNavigationMediaPickerViewController with the designated options
 */
- (instancetype _Nonnull )initWithOptions:(WPMediaPickerOptions *_Nonnull)options;

@property (nonatomic, weak) _Nullable id<WPMediaPickerViewControllerDelegate> delegate;

/**
The internal WPMediaPickerViewController that is used to display the media.
*/
@property (nonatomic, readonly)  WPMediaPickerViewController * _Nonnull mediaPicker;

/**
 The object that acts as the data source of the media picker.
 
 @Discussion
 If no object is defined before the picker is show then the picker will use a shared data source that access the user media library.
*/
@property (nonatomic, weak) _Nullable id<WPMediaCollectionDataSource> dataSource;

/**
 Pushes a given ViewController into the internal UINavigationController. Useful for post-processing steps.
 */
- (void)showAfterViewController:(nonnull UIViewController *)viewController;

@property (nonatomic, strong, readonly) UICollectionViewFlowLayout * _Nonnull layout;

/**
 A localized string that reflect the action that will be done when the picker is selected.
 This string can contain a a placeholder for a numeric value that will indicate the number of media items selected.
 If this is nil the default value will be used. The default the value is 'Select %@'
 */
@property (nonatomic, copy, nullable) NSString *selectionActionTitle;

@end
