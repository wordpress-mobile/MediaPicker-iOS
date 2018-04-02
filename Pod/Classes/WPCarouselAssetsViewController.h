#import <UIKit/UIKit.h>
#import "WPMediaCollectionDataSource.h"

@interface WPCarouselAssetsViewController : UIPageViewController

- (instancetype)initWithAssets:(NSArray<id<WPMediaAsset>> *)assets;
- (void)setIndex:(NSInteger)index animated:(BOOL)animated;

@end
