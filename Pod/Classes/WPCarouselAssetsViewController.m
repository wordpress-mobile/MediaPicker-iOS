#import "WPCarouselAssetsViewController.h"

@interface WPCarouselAssetsViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, WPAssetViewControllerDelegate>
@property (nonatomic, strong) NSArray<id<WPMediaAsset>> *assets;
@property (assign, nonatomic) NSInteger index;
@property (assign, nonatomic) NSInteger nextIndex;
@end

@implementation WPCarouselAssetsViewController

- (instancetype)initWithAssets:(NSArray<id<WPMediaAsset>> *)assets
{
    NSDictionary *options = @{UIPageViewControllerOptionInterPageSpacingKey : @20};
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:options];
    if (self) {
        _assets = assets;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initialSetup];
    [self updateTitle];
}

- (void)setIndex:(NSInteger)index animated:(BOOL)animated
{
    self.index = index;
    if (self.isViewLoaded) {
        UIViewController *newViewController = [self viewControllerAtIndex:index];
        [self setViewController:newViewController animated:animated];
    }
}

#pragma mark: - UIPageViewControllerDelegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = [self indexForViewController:viewController];
    if (index == 0) {
        return nil;
    }
    return [self viewControllerAtIndex:index - 1];
}

- (nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController
{
    NSInteger index = [self indexForViewController:viewController];
    if (index == self.assets.count - 1) {
        return nil;
    }
    return [self viewControllerAtIndex:index + 1];
}

#pragma mark: - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        self.index = self.nextIndex;
        [self updateTitle];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers
{
    UIViewController *nextViewController = pendingViewControllers.firstObject;
    self.nextIndex = [self indexForViewController:nextViewController];
}

#pragma mark: - WPAssetViewControllerDelegate

- (void)assetViewController:(nonnull WPAssetViewController *)assetPreviewVC failedWithError:(nonnull NSError *)error {
    if (self.assetViewDelegate) {
        [self.assetViewDelegate assetViewController:assetPreviewVC failedWithError:error];
    }
}

- (void)assetViewController:(nonnull WPAssetViewController *)assetPreviewVC selectionChanged:(BOOL)selected {
    if (self.assetViewDelegate) {
        [self.assetViewDelegate assetViewController:assetPreviewVC selectionChanged:selected];
    }
}

#pragma mark: - Helpers

- (void)initialSetup
{
    self.view.backgroundColor = [UIColor blackColor];
    self.dataSource = self;
    self.delegate = self;
    UIViewController *initialVC = [self viewControllerAtIndex:self.index];
    [self setViewController:initialVC animated:NO];
}

- (void)updateTitle
{
    NSString *separator = NSLocalizedString(@"of", @"Word separating the current index of the total amount. I.e.: 7 of 9");
    self.title = [NSString stringWithFormat:@"%ld %@ %ld", self.index + 1, separator, self.assets.count];
}

- (NSInteger)indexForViewController:(UIViewController *)viewController
{
    if (![viewController isKindOfClass:[WPAssetViewController class]]) {
        NSAssert(NO, @"Pages need to be of class `WPAssetViewController`");
        return 0;
    }
    WPAssetViewController *assetController = (WPAssetViewController *)viewController;
    id<WPMediaAsset> asset = assetController.asset;
    return [self.assets indexOfObject:asset];
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index
{
    id<WPMediaAsset> asset = [self.assets objectAtIndex:index];
    WPAssetViewController *fullScreenImageVC = [[WPAssetViewController alloc] init];
    fullScreenImageVC.asset = asset;
    //    fullScreenImageVC.selected = [self positionOfAssetInSelection:asset] != NSNotFound;
    fullScreenImageVC.delegate = self;
    return fullScreenImageVC;
}

- (void)setViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSArray<UIViewController *> *viewControllers = [NSArray arrayWithObject:viewController];
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:nil];
}

@end
