#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"
#import "WPAssetViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WPCarouselAssetsViewControllerDelegate<NSObject>
- (nullable UIViewController *)viewControllerForAsset:(id<WPMediaAsset>)asset;
- (id<WPMediaAsset>)assetForViewController:(UIViewController *)viewController;
@end

@interface WPCarouselAssetsViewController : UIPageViewController

@property (nonatomic, weak, nullable) id<WPAssetViewControllerDelegate> assetViewDelegate;

@property (nonatomic, weak, nullable) id<WPCarouselAssetsViewControllerDelegate> carouselDelegate;

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

@end

NS_ASSUME_NONNULL_END
