#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"
#import "WPAssetViewController.h"

@interface WPCarouselAssetsViewController : UIPageViewController

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, weak, nullable) id<WPAssetViewControllerDelegate> assetViewDelegate;

- (instancetype)initWithAssets:(NSArray<id<WPMediaAsset>> *)assets;
- (void)setIndex:(NSInteger)index animated:(BOOL)animated;

NS_ASSUME_NONNULL_END

@end
