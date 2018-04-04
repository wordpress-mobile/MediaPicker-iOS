#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"
#import "WPAssetViewController.h"

@interface WPCarouselAssetsViewController : UIPageViewController

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, weak, nullable) id<WPAssetViewControllerDelegate> assetViewDelegate;


/**
 Init a WPCarouselAssetsViewController with the list of assets to preview.

 @param assets An array of assets to show in the carousel preview.
 @return an initiated WPCarouselAssetsViewController.
 */
- (instancetype)initWithAssets:(NSArray<id<WPMediaAsset>> *)assets;


/**
 Set a new asset as the presenting asset in the carousel preview

 @param index Index of the asset to present
 @param animated Should the change be animated?
 */
- (void)setPreviewingAssetAtIndex:(NSInteger)index animated:(BOOL)animated;

NS_ASSUME_NONNULL_END

@end
