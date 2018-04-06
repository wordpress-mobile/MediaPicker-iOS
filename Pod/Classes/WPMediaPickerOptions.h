#import <Foundation/Foundation.h>
#import "WPMediaCollectionDataSource.h"

@interface WPMediaPickerOptions: NSObject<NSCopying>

/**
 If YES the picker will show a cell that allows capture of new media, that can be used immediatelly
 */
@property (nonatomic, assign) BOOL allowCaptureOfMedia;

/**
 If YES and the media picker allows media capturing, it will use the front camera by default when possible
 */
@property (nonatomic, assign) BOOL preferFrontCamera;

/**
 If YES the picker will show the most recent items on the top left. If not set it will show on the bottom right. Either way it will always scroll to the most recent item when showing the picker.
 */
@property (nonatomic, assign) BOOL showMostRecentFirst;

/**
 *  Sets what kind of elements the picker show: allAssets, allPhotos, allVideos
 */
@property (nonatomic, assign) WPMediaType filter;

/**
 The maximum number of selection allowed.
 */
@property (nonatomic, assign) int selectionLimit;

/**
 If YES the picker will scroll media vertically. Defaults to YES (vertical).
 */
@property (nonatomic, assign) BOOL scrollVertically;

/**
 If YES the picker will show a search bar on top.
 */
@property (nonatomic, assign) BOOL showSearchBar;

@end
