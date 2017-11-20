#import "WPMediaPickerViewController.h"
#import "WPMediaCollectionViewCell.h"
#import "WPMediaCapturePreviewCollectionView.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"
#import "WPPHAssetDataSource.h"
#import "WPMediaCapturePresenter.h"
#import "WPInputMediaPickerViewController.h"

@import MobileCoreServices;
@import AVFoundation;

static CGFloat const IPhoneSELandscapeWidth = 568.0f;
static CGFloat const IPhone7PortraitWidth = 375.0f;
static CGFloat const IPhone7LandscapeWidth = 667.0f;
static CGFloat const IPadPortraitWidth = 768.0f;
static CGFloat const IPadLandscapeWidth = 1024.0f;
static CGFloat const IPadPro12LandscapeWidth = 1366.0f;

@interface WPMediaPickerViewController ()
<
 UICollectionViewDataSource,
 UICollectionViewDelegate,
 UIImagePickerControllerDelegate,
 UINavigationControllerDelegate,
 UIPopoverPresentationControllerDelegate,
 UICollectionViewDelegateFlowLayout,
 UIViewControllerPreviewingDelegate,
 UISearchBarDelegate
>

@property (nonatomic, readonly) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *internalSelectedAssets;
@property (nonatomic, strong) id<WPMediaAsset> capturedAsset;
@property (nonatomic, strong) WPMediaCapturePreviewCollectionView *captureCell;
@property (nonatomic, strong) WPMediaCapturePresenter *capturePresenter;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSObject *changesObserver;
@property (nonatomic, strong) NSIndexPath *firstVisibleCell;
@property (nonatomic, assign) BOOL refreshGroupFirstTime;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSIndexPath *assetIndexInPreview;

@property (nonatomic, strong, nullable) Class overlayViewClass;

@property (nonatomic, strong, readwrite) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *searchBarTopConstraint;

@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) UILabel *defaultEmptyView;

/**
 The size of the camera preview cell
 */
@property (nonatomic, assign) CGSize cameraPreviewSize;

@end

@implementation WPMediaPickerViewController

static CGFloat SelectAnimationTime = 0.2;

- (instancetype)init
{
    return [self initWithOptions:[WPMediaPickerOptions new]];
}

- (instancetype)initWithOptions:(WPMediaPickerOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:(CGRectZero) collectionViewLayout:layout];
        _internalSelectedAssets = [[NSMutableArray alloc] init];
        _capturedAsset = nil;
        _options = [options copy];
        _refreshGroupFirstTime = YES;
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressOnAsset:)];
        _viewControllerToUseToPresent = self;
    }
    return self;
}

- (void)dealloc
{
    if (_changesObserver) {
        [_dataSource unregisterChangeObserver:_changesObserver];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];

    // Setup subviews
    [self addCollectionViewToView];
    [self addEmptyViewToView];
    [self setupCollectionView];
    [self setupSearchBar];
    [self setupLayout];

    //setup data
    [self.dataSource setMediaTypeFilter:self.options.filter];
    [self.dataSource setAscendingOrdering:!self.options.showMostRecentFirst];
    __weak __typeof__(self) weakSelf = self;
    self.changesObserver = [self.dataSource registerChangeObserverBlock:
                            ^(BOOL incrementalChanges, NSIndexSet *removed, NSIndexSet *inserted, NSIndexSet *changed, NSArray *moves) {
                                if (incrementalChanges && !weakSelf.refreshGroupFirstTime) {
                                    [weakSelf updateDataWithRemoved:removed inserted:inserted changed:changed moved:moves];
                                } else {
                                    [weakSelf refreshData];
                                }
                            }];

    if ([self.traitCollection containsTraitsInCollection:[UITraitCollection traitCollectionWithForceTouchCapability:UIForceTouchCapabilityAvailable]]) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    } else {
        [self.view addGestureRecognizer:self.longPressGestureRecognizer];
    }

    if (@available(iOS 11.0, *)) {
        self.layout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    }
    [self refreshDataAnimated:NO];
}

- (void)setOptions:(WPMediaPickerOptions *)options {
    WPMediaPickerOptions *originalOptions = _options;
    _options = [options copy];

    if (!self.viewLoaded) {
        return;
    }

    [self.dataSource setMediaTypeFilter:options.filter];
    [self.dataSource setAscendingOrdering:!options.showMostRecentFirst];
    self.collectionView.allowsMultipleSelection = options.allowMultipleSelection;
    self.collectionView.alwaysBounceHorizontal = !options.scrollVertically;
    self.collectionView.alwaysBounceVertical = options.scrollVertically;

    BOOL refreshNeeded = (originalOptions.filter != options.filter) ||
    (originalOptions.showMostRecentFirst != options.showMostRecentFirst) ||
    (originalOptions.allowCaptureOfMedia != options.allowCaptureOfMedia);

    if (refreshNeeded) {
        [self refreshDataAnimated:NO];
    } else {
        // if just the selection mode changed we just need to reload the collection view not all the data.
        if (originalOptions.allowMultipleSelection != options.allowMultipleSelection || options.allowCaptureOfMedia != originalOptions.allowCaptureOfMedia) {
            [self.collectionView reloadData];
        }
    }

    [self setupSearchBar];
}

- (void)registerClassForReusableCellOverlayViews:(Class)overlayClass
{
    NSParameterAssert([overlayClass isSubclassOfClass:[UIView class]]);

    self.overlayViewClass = overlayClass;
}

- (UICollectionViewFlowLayout *)layout
{
    return (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)setupLayout
{
    CGFloat photoSpacing = 1.0f;
    CGFloat photoSize;
    UICollectionViewFlowLayout *layout = self.layout;
    CGFloat frameWidth = self.view.frame.size.width;
    CGFloat frameHeight = self.view.frame.size.width - self.topLayoutGuide.length;
    CGFloat dimensionToUse = frameWidth;
    if (self.options.scrollVertically) {
        dimensionToUse = frameWidth;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionInset = UIEdgeInsetsMake(2, 0, 0, 0);
    } else {
        dimensionToUse = frameHeight;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(5, 0, 5, 0);
    }
    NSUInteger numberOfPhotosForLine = [self numberOfPhotosPerRow:dimensionToUse];

    photoSize = [self cellSizeForPhotosPerLineCount:numberOfPhotosForLine
                                       photoSpacing:photoSpacing
                                         frameWidth:dimensionToUse];

    self.cameraPreviewSize = CGSizeMake(photoSize, photoSize);
    layout.itemSize = CGSizeMake(photoSize, photoSize);
    layout.minimumLineSpacing = photoSpacing;
    layout.minimumInteritemSpacing = photoSpacing;

    [self resetContentInset];
}

- (void)resetContentInset
{
    if (@available(iOS 11.0, *)) {
        CGFloat searchBarHeight = self.searchBar.bounds.size.height;
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(searchBarHeight, 0, 0, 0);
        self.searchBarTopConstraint.constant = self.view.safeAreaInsets.top - searchBarHeight;
    } else {
        UIEdgeInsets inset = self.collectionView.contentInset;
        inset.top = self.searchBar.bounds.size.height + self.topLayoutGuide.length;
        inset.bottom = self.bottomLayoutGuide.length;
        self.collectionView.contentInset = inset;
        self.collectionView.scrollIndicatorInsets = inset;
        self.searchBarTopConstraint.constant = self.topLayoutGuide.length;
    }
}

- (CGFloat)cellSizeForPhotosPerLineCount:(NSUInteger)photosPerLine photoSpacing:(CGFloat)photoSpacing frameWidth:(CGFloat)frameWidth
{
    CGFloat totalSpacing = (photosPerLine - 1) * photoSpacing;
    return floorf((frameWidth - totalSpacing) / photosPerLine);
}

/**
 Given the provided frame width, this method returns a progressively increasing number of photos
 to be used in a picker row.

 @param frameWidth Width of the frame containing the picker

 @return The number of photo cells to be used in a row. Defaults to 3.
 */
- (NSUInteger)numberOfPhotosPerRow:(CGFloat)frameWidth {
    NSUInteger numberOfPhotos = 3;

    if (frameWidth >= IPhone7PortraitWidth && frameWidth < IPhoneSELandscapeWidth) {
        numberOfPhotos = 4;
    } else if (frameWidth >= IPhoneSELandscapeWidth && frameWidth < IPhone7LandscapeWidth) {
        numberOfPhotos = 5;
    } else if (frameWidth >= IPhone7LandscapeWidth && frameWidth < IPadPortraitWidth) {
        numberOfPhotos = 6;
    } else if (frameWidth >= IPadPortraitWidth && frameWidth < IPadLandscapeWidth) {
        numberOfPhotos = 7;
    } else if (frameWidth >= IPadLandscapeWidth && frameWidth < IPadPro12LandscapeWidth) {
        numberOfPhotos = 9;
    } else if (frameWidth >= IPadPro12LandscapeWidth) {
        numberOfPhotos = 12;
    }

    return numberOfPhotos;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setupLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureCell stopCaptureOnCompletion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.captureCell startCapture];
    [self registerForKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unregisterForKeyboardNotifications];
}

- (UIViewController *)viewControllerToUseToPresent
{
    // viewControllerToUseToPresent defaults to self but could be set to nil. Reset to self if needed.
    if (!_viewControllerToUseToPresent) {
        _viewControllerToUseToPresent = self;
    }

    return _viewControllerToUseToPresent;
}

- (void)setupCollectionView
{
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = self.options.allowMultipleSelection;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.alwaysBounceVertical = YES;
    
    // Register cell classes
    [self.collectionView registerClass:[WPMediaCollectionViewCell class]
            forCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class])];
    [self.collectionView registerClass:[WPMediaCapturePreviewCollectionView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class])];
    [self.collectionView registerClass:[WPMediaCapturePreviewCollectionView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class])];
}

- (void)addCollectionViewToView
{
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:
     @[
       [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
       [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
       ]
     ];
}

- (void)setupSearchBar
{
    BOOL shouldShowSearchBar = self.options.showSearchBar &&
        ![self.parentViewController isKindOfClass:[WPInputMediaPickerViewController class]] && //Disable search bar on WPInputMediaPicker
        [self.dataSource respondsToSelector:@selector(searchFor:)];

    if (shouldShowSearchBar && self.searchBar == nil) {
        self.searchBar = [[UISearchBar alloc] init];
        self.searchBar.delegate = self;
        self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSearchBarToView];
    } else if (!shouldShowSearchBar && self.searchBar) {
        [self hideSearchBar];
    }
}

- (void)showSearchBar
{
    [self setupSearchBar];
}

- (void)hideSearchBar
{
    [self.searchBar removeFromSuperview];
    self.searchBar = nil;
}

- (void)addSearchBarToView
{
    [self.searchBar sizeToFit];
    [self.view addSubview:self.searchBar];
    self.searchBarTopConstraint = [self.searchBar.topAnchor constraintEqualToAnchor:self.view.topAnchor];

    [NSLayoutConstraint activateConstraints:
     @[
       self.searchBarTopConstraint,
       [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
       ]
     ];
}

#pragma mark - Actions

- (void)pullToRefresh:(id)sender
{
    [self refreshData];
}

- (BOOL)isShowingCaptureCell
{
    return self.options.allowCaptureOfMedia && [WPMediaCapturePresenter isCaptureAvailable] && !self.refreshGroupFirstTime;
}

- (void)clearSelectedAssets:(BOOL)animated
{
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems]) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:animated];
    }

    [self.internalSelectedAssets removeAllObjects];
}

- (void)resetState:(BOOL)animated {
    [self clearSelectedAssets:animated];
    [self scrollToStart:animated];
}

- (void)scrollToStart:(BOOL)animated {
    if ([self.dataSource numberOfAssets] == 0) {
        return;
    }

    NSInteger sectionToScroll = 0;
    NSInteger itemToScroll = self.options.showMostRecentFirst ? 0 : [self.dataSource numberOfAssets] - 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemToScroll inSection:sectionToScroll];
    UICollectionViewScrollPosition position = UICollectionViewScrollPositionBottom;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if (layout && layout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        position = UICollectionViewScrollPositionCenteredHorizontally;
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:position
                                        animated:animated];
}

- (void)showCapture {
    [self captureMedia];
    return;
}

- (UIView *)emptyView
{
    if (_emptyView) {
        return _emptyView;
    }

    if ([self.mediaPickerDelegate respondsToSelector:@selector(emptyViewForMediaPickerController:)]) {
        _emptyView = [self.mediaPickerDelegate emptyViewForMediaPickerController:self];
    } else {
        _emptyView = [self defaultEmptyView];
    }

    return _emptyView;
}

- (void)addEmptyViewToView
{
    if (self.emptyView.superview == nil) {
        [self.collectionView addSubview:_emptyView];
        [self centerEmptyView];
    }
}

- (UILabel *)defaultEmptyView
{
    if (_defaultEmptyView) {
        return _defaultEmptyView;
    }
    _defaultEmptyView = [[UILabel alloc] init];
    _defaultEmptyView.text = NSLocalizedString(@"Nothing to show", @"Default message for empty media picker");
    [_defaultEmptyView sizeToFit];
    return _defaultEmptyView;
}

#pragma mark - UICollectionViewDataSource

-(void)updateDataWithRemoved:(NSIndexSet *)removed inserted:(NSIndexSet *)inserted changed:(NSIndexSet *)changed moved:(NSArray<id<WPMediaMove>> *)moves {
    if ([removed containsIndex:self.assetIndexInPreview.item]){
        self.assetIndexInPreview = nil;
    }
    [self.collectionView performBatchUpdates:^{
        if (removed) {
            [self.collectionView deleteItemsAtIndexPaths:[self indexPathsFromIndexSet:removed section:0]];
        }
        if (inserted) {
            [self.collectionView insertItemsAtIndexPaths:[self indexPathsFromIndexSet:inserted section:0]];
        }
    } completion:^(BOOL finished) {
        [self.collectionView performBatchUpdates:^{
            NSArray<NSIndexPath *> *indexPaths = [self indexPathsFromIndexSet:changed section:0];
            for (NSIndexPath *indexPath in indexPaths) {
                WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                [self configureCell:cell forIndexPath:indexPath];
            }
            for (id<WPMediaMove> move in moves) {
                [self.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:[move from] inSection:0]
                                             toIndexPath:[NSIndexPath indexPathForItem:[move to] inSection:0]];
                if (self.assetIndexInPreview.row == move.from) {
                    self.assetIndexInPreview = [NSIndexPath indexPathForItem:move.to inSection:0];
                }
            }
        } completion:^(BOOL finished) {
            [self refreshSelection];
            [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForSelectedItems];
        }];
    }];

}

-(NSArray *)indexPathsFromIndexSet:(NSIndexSet *)indexSet section:(NSInteger)section{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:indexSet.count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return [NSArray arrayWithArray:indexPaths];
}

- (void)refreshData
{
    [self refreshDataAnimated:YES];
}

- (void)refreshDataAnimated:(BOOL)animated
{
    [self.refreshControl beginRefreshing];
    self.collectionView.allowsSelection = NO;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.scrollEnabled = NO;

    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerWillBeginLoadingData:)]) {
        [self.mediaPickerDelegate mediaPickerControllerWillBeginLoadingData:self];
    }

    __weak __typeof__(self) weakSelf = self;

    [self.dataSource loadDataWithOptions:WPMediaLoadOptionsAssets success:^{
        __typeof__(self) strongSelf = weakSelf;
        BOOL refreshGroupFirstTime = strongSelf.refreshGroupFirstTime;
        strongSelf.refreshGroupFirstTime = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.collectionView.allowsSelection = YES;
            strongSelf.collectionView.allowsMultipleSelection = strongSelf.options.allowMultipleSelection;
            strongSelf.collectionView.scrollEnabled = YES;
            [strongSelf refreshSelection];
            [strongSelf.collectionView reloadData];

            if (animated) {
                [strongSelf.refreshControl endRefreshing];
            } else {
                [UIView performWithoutAnimation:^{
                    [strongSelf.refreshControl endRefreshing];
                }];
            }
            if (@available(iOS 11, *)) {} else { // Just on iOS 10
                [self resetContentInset]; //Fix top content inset when refresh control dissapear.
            }

            // Scroll to the correct position
            if (refreshGroupFirstTime){
                [strongSelf scrollToStart:NO];
            }

            [strongSelf informDelegateDidEndLoadingData];
        });
    } failure:^(NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        strongSelf.refreshGroupFirstTime = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf informDelegateDidEndLoadingData];
            [strongSelf showError:error];
        });
    }];
}

- (void)informDelegateDidEndLoadingData
{
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerDidEndLoadingData:)]) {
        [self.mediaPickerDelegate mediaPickerControllerDidEndLoadingData:self];
    }
}

- (void)showError:(NSError *)error {
    [self.refreshControl endRefreshing];
    self.collectionView.allowsSelection = YES;
    self.collectionView.scrollEnabled = YES;
    [self.collectionView reloadData];
    NSString *title = NSLocalizedString(@"Media Library", @"Title for alert when a generic error happened when loading media");
    NSString *message = NSLocalizedString(@"There was a problem when trying to access your media. Please try again later.",  @"Explaining to the user there was an generic error accesing media.");
    NSString *cancelText = NSLocalizedString(@"OK", "");
    NSString *otherButtonTitle = nil;
    if (error.domain == WPMediaPickerErrorDomain &&
        error.code == WPMediaErrorCodePermissionsFailed) {
        otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
        title = NSLocalizedString(@"Media Library", @"Title for alert when access to the media library is not granted by the user");
        message = NSLocalizedString(@"This app needs permission to access your device media library in order to add photos and/or video to your posts. Please change the privacy settings if you wish to allow this.",
                                    @"Explaining to the user why the app needs access to the device media library.");
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:cancelText
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *action) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
            [self.mediaPickerDelegate mediaPickerControllerDidCancel:self];
        }
    }];
    [alertController addAction:okAction];

    if (otherButtonTitle) {
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        }];
        [alertController addAction:otherAction];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)setSelectedAssets:(NSArray *)selectedAssets {
    self.internalSelectedAssets = [selectedAssets copy];
    if ([self isViewLoaded]) {
        [self refreshDataAnimated: NO];
    }
}

- (NSArray *)selectedAssets {
    return [self.internalSelectedAssets copy];
}

- (void)refreshSelection
{
    NSArray *selectedAssets = [NSArray arrayWithArray:self.internalSelectedAssets];
    NSMutableArray *stillExistingSeletedAssets = [NSMutableArray array];
    for (id<WPMediaAsset> asset in selectedAssets) {
        NSString *assetIdentifier = [asset identifier];
        if ([self.dataSource mediaWithIdentifier:assetIdentifier]) {
            [stillExistingSeletedAssets addObject:asset];
        }
    }
    if (self.capturedAsset != nil) {
        NSString *assetIdentifier = [self.capturedAsset identifier];
        if ([self.dataSource mediaWithIdentifier:assetIdentifier]) {
            [stillExistingSeletedAssets addObject:self.capturedAsset];
        }
        NSInteger positionToUpdate = self.options.showMostRecentFirst ? 0 : self.dataSource.numberOfAssets-1;
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:positionToUpdate inSection:0]
                                          animated:NO
                                    scrollPosition:UICollectionViewScrollPositionNone];
        self.capturedAsset = nil;
    }

    self.internalSelectedAssets = stillExistingSeletedAssets;
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:selectionChanged:)]) {
        [self.mediaPickerDelegate mediaPickerController:self selectionChanged:[self.internalSelectedAssets copy]];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.refreshGroupFirstTime ? 0 : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfAssets = [self.dataSource numberOfAssets];

    if (self.searchBar.text && [self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didUpdateSearchWithAssetCount:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didUpdateSearchWithAssetCount:numberOfAssets];
    }

    [self.emptyView setHidden:(numberOfAssets != 0)];

    return numberOfAssets;
}

- (id<WPMediaAsset>)assetForPosition:(NSIndexPath *)indexPath
{
    NSInteger itemPosition = indexPath.item;
    NSInteger count = [self.dataSource numberOfAssets];
    if (itemPosition >= count || itemPosition < 0) {
        return nil;
    }
    id<WPMediaAsset> asset = [self.dataSource mediaAtIndex:itemPosition];
    return asset;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WPMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class]) forIndexPath:indexPath];

    [self configureCell:cell forIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(WPMediaCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];

    cell.asset = asset;
    NSUInteger position = [self positionOfAssetInSelection:asset];
    cell.hiddenSelectionIndicator = !self.options.allowMultipleSelection;
    if (position != NSNotFound) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        if (self.options.allowMultipleSelection) {
            [cell setPosition:position + 1];
        } else {
            [cell setPosition:NSNotFound];
        }
        cell.selected = YES;
    } else {
        [cell setPosition:NSNotFound];
        cell.selected = NO;
    }
}

- (void)configureOverlayViewForCell:(WPMediaCollectionViewCell *)cell
{
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldShowOverlayViewForCellForAsset:)]) {
        if ([self.mediaPickerDelegate mediaPickerController:self shouldShowOverlayViewForCellForAsset:cell.asset]) {
            if (!cell.overlayView || ![cell.overlayView isKindOfClass:self.overlayViewClass]) {
                NSAssert(self.overlayViewClass != nil, @"Media Picker: Attempted to instantiate a reusable overlay view, but no reuse class has been set.");

                cell.overlayView = [self.overlayViewClass new];
            }

            cell.overlayView.hidden = NO;
        }
    }

    if (cell.overlayView && [self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:willShowOverlayView:forCellForAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self
                                    willShowOverlayView:cell.overlayView
                                        forCellForAsset:cell.asset];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    if ( [self isShowingCaptureCell] && self.options.showMostRecentFirst)
    {
        return self.cameraPreviewSize;
    }
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section
{
    if ( [self isShowingCaptureCell] && !self.options.showMostRecentFirst)
    {
        return self.cameraPreviewSize;
    }
    return CGSizeZero;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    if ((kind == UICollectionElementKindSectionHeader && self.options.showMostRecentFirst) ||
       (kind == UICollectionElementKindSectionFooter && !self.options.showMostRecentFirst))
    {
        if (!self.captureCell) {
            self.captureCell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class]) forIndexPath:indexPath];
            if (self.captureCell.gestureRecognizers == nil) {
                UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(captureMedia)];
                [self.captureCell addGestureRecognizer:tapGestureRecognizer];
            }
            self.captureCell.preferFrontCamera = self.options.preferFrontCamera;
            [self.captureCell startCapture];
        }
        CGRect newFrame = self.captureCell.frame;
        CGSize fixedSize = self.cameraPreviewSize;
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        if (layout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            if (@available(iOS 11, *)) {
                fixedSize.height = self.view.frame.size.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom - self.collectionView.contentInset.bottom;
            } else {
                fixedSize.height = self.view.frame.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;
            }
        } else {
            fixedSize.width = self.view.frame.size.width;
        }
        newFrame.size = fixedSize;
        self.captureCell.frame = newFrame;
        return self.captureCell;
    }

    return [UICollectionReusableView new];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[WPMediaCollectionViewCell class]]) {
        [self configureOverlayViewForCell:(WPMediaCollectionViewCell *)cell];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[WPMediaCollectionViewCell class]]) {
        WPMediaCollectionViewCell *mediaCell = (WPMediaCollectionViewCell *)cell;
        mediaCell.overlayView.hidden = YES;
    }
}

/**
 Returns the position of the asset in the current selection if any

 @param asset to find in selection
 @return the position if the asset is selected or NSNotFound
 */
- (NSUInteger)positionOfAssetInSelection:(id<WPMediaAsset>)asset
{
    NSUInteger position = [self.internalSelectedAssets indexOfObjectPassingTest:^BOOL(id<WPMediaAsset> loopAsset, NSUInteger idx, BOOL *stop) {
        BOOL found =  [[asset identifier]  isEqual:[loopAsset identifier]];
        return found;
    }];
    return position;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        return [self.mediaPickerDelegate mediaPickerController:self shouldSelectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if (asset == nil) {
        return;
    }
    if (!self.options.allowMultipleSelection) {
        [self.internalSelectedAssets removeAllObjects];
    }
    [self.internalSelectedAssets addObject:asset];

    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (self.options.allowMultipleSelection) {
        [cell setPosition:self.internalSelectedAssets.count];
    } else {
        [cell setPosition:NSNotFound];
    }
    [self animateCellSelection:cell completion:nil];

    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didSelectAsset:asset];
    }
    if (!self.options.allowMultipleSelection) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
            [self.mediaPickerDelegate mediaPickerController:self didFinishPickingAssets:[self.internalSelectedAssets copy]];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]) {
        return [self.mediaPickerDelegate mediaPickerController:self shouldDeselectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{

    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if (asset == nil){
        return;
    }
    NSUInteger deselectPosition = [self positionOfAssetInSelection:asset];
    if (deselectPosition != NSNotFound) {
        [self.internalSelectedAssets removeObjectAtIndex:deselectPosition];
    }

    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self animateCellSelection:cell completion:^{
        for (NSIndexPath *selectedIndexPath in self.collectionView.indexPathsForSelectedItems){
            WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:selectedIndexPath];
            id<WPMediaAsset> asset = [self assetForPosition:selectedIndexPath];
            NSUInteger position = [self positionOfAssetInSelection:asset];
            if (position != NSNotFound) {
                if (self.options.allowMultipleSelection) {
                    [cell setPosition:position + 1];
                } else {
                    [cell setPosition:NSNotFound];
                }
            }
        }
    }];

    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didDeselectAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didDeselectAsset:asset];
    }
}

- (void)animateCellSelection:(UIView *)cell completion:(void (^)(void))completionBlock
{
    [UIView animateKeyframesWithDuration:SelectAnimationTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, 1, 1);
        }];
        [UIView addKeyframeWithRelativeStartTime:SelectAnimationTime/2 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, -1, -1);
        }];
    } completion:^(BOOL finished) {
        if(completionBlock){
            completionBlock();
        }
    }];
}

#pragma mark - Media Capture

- (WPMediaCapturePresenter *)capturePresenter
{
    if (!_capturePresenter) {
        _capturePresenter = [[WPMediaCapturePresenter alloc] initWithPresentingViewController:self.viewControllerToUseToPresent];
        _capturePresenter.mediaType = self.options.filter;
        _capturePresenter.preferFrontCamera = self.options.preferFrontCamera;

        __weak typeof(self) weakSelf = self;
        _capturePresenter.completionBlock = ^(NSDictionary *mediaInfo) {
            if (mediaInfo) {
                [weakSelf processMediaCaptured:mediaInfo];
            }

            weakSelf.capturePresenter = nil;
        };
    }

    return _capturePresenter;
}

- (void)captureMedia
{
    [self.capturePresenter presentCapture];
}

- (void)processMediaCaptured:(NSDictionary *)info
{
    WPMediaAddedBlock completionBlock = ^(id<WPMediaAsset> media, NSError *error) {
        if (error || !media) {
            NSLog(@"Adding media failed: %@", [error localizedDescription]);
            return;
        }
        [self addMedia:media animated:YES];
    };
    if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeImage]) {
        UIImage *image = (UIImage *)info[UIImagePickerControllerOriginalImage];
        [self.dataSource addImage:image
                         metadata:info[UIImagePickerControllerMediaMetadata]
                  completionBlock:completionBlock];
    } else if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeMovie]) {
        [self.dataSource addVideoFromURL:info[UIImagePickerControllerMediaURL] completionBlock:completionBlock];
    }
}

- (void)addMedia:(id<WPMediaAsset>)asset animated:(BOOL)animated
{
    BOOL willBeSelected = YES;
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        if ([self.mediaPickerDelegate mediaPickerController:self shouldSelectAsset:asset]) {
            self.capturedAsset = asset;
        } else {
            willBeSelected = NO;
        }
    } else {
        self.capturedAsset = asset;
    }

    if (!willBeSelected) {
        return;
    }
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.mediaPickerDelegate mediaPickerController:self didSelectAsset:asset];
    }
    if (!self.options.allowMultipleSelection) {
        if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
            if (self.capturedAsset) {
                [self.internalSelectedAssets addObject:self.capturedAsset];
            }
            [self.mediaPickerDelegate mediaPickerController:self didFinishPickingAssets:self.internalSelectedAssets];
        }
    }
}

- (void)setGroup:(id<WPMediaGroup>)group {
    if (group == [self.dataSource selectedGroup]){
        return;
    }
    [self.dataSource setSelectedGroup:group];
    if (self.isViewLoaded) {
        self.refreshGroupFirstTime = YES;
        [self.layout invalidateLayout];
        [self refreshData];
    }
}

#pragma mark - Long Press Handling

- (void)handleLongPressOnAsset:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [gestureRecognizer locationInView:self.collectionView];
        UIViewController *viewController = [self previewControllerForTouchLocation:location];
        [self displayPreviewController:viewController];
    }
}

- (nullable UIViewController *)previewControllerForTouchLocation:(CGPoint)location
{
    self.assetIndexInPreview = [self.collectionView indexPathForItemAtPoint:location];
    if (!self.assetIndexInPreview) {
        return nil;
    }

    id<WPMediaAsset> asset = [self assetForPosition:self.assetIndexInPreview];
    if (!asset) {
        return nil;
    }

    return [self previewViewControllerForAsset:asset];
}

- (UIViewController *)previewViewControllerForAsset:(id <WPMediaAsset>)asset
{
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:previewViewControllerForAsset:)]) {
        return [self.mediaPickerDelegate mediaPickerController:self
                                 previewViewControllerForAsset:asset];
    }

    return [self defaultPreviewViewControllerForAsset:asset];
}

- (UIViewController *)defaultPreviewViewControllerForAsset:(id <WPMediaAsset>)asset
{
    // We can't preview PHAssets that are audio files
    if ([self.dataSource isKindOfClass:[WPPHAssetDataSource class]] && asset.assetType == WPMediaTypeAudio) {
        return nil;
    }

    WPAssetViewController *fullScreenImageVC = [[WPAssetViewController alloc] init];
    fullScreenImageVC.asset = asset;
    fullScreenImageVC.selected = [self positionOfAssetInSelection:asset] != NSNotFound;
    fullScreenImageVC.delegate = self;
    return fullScreenImageVC;
}

- (void)displayPreviewController:(UIViewController *)viewController {
    if (viewController) {
        // Attempt to use the viewControllerToUseToPresent's nav controller, otherwise lets create a new nav controller and present it.
        if (self.viewControllerToUseToPresent.navigationController) {
            [self.viewControllerToUseToPresent.navigationController pushViewController:viewController animated:YES];
        } else {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
            viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                            target:self
                                                                                                            action:@selector(dismissPreviewController)];
            [self.viewControllerToUseToPresent presentViewController:navController animated:YES completion:nil];
        }
    }
}

- (void)dismissPreviewController {
    if (self.viewControllerToUseToPresent.navigationController) {
        [self.viewControllerToUseToPresent.navigationController popViewControllerAnimated:YES];
    } else {
        [self.viewControllerToUseToPresent dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Keyboard Handling

- (BOOL)isPresentedAsPopover
{
    for (UIViewController *controller = self; controller != nil; controller = controller.parentViewController) {
        if (controller.popoverPresentationController) {
            return controller.popoverPresentationController.arrowDirection != UIPopoverArrowDirectionUnknown;
        }
    }

    return NO;
}

- (void)registerForKeyboardNotifications
{
    if (![self.parentViewController isKindOfClass:[WPInputMediaPickerViewController class]]) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)unregisterForKeyboardNotifications
{
    if (![self.parentViewController isKindOfClass:[WPInputMediaPickerViewController class]]) {
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    if([self isPresentedAsPopover]) {
        return;
    }

    CGRect keyboardFrameEnd = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIEdgeInsets contentInset = self.collectionView.contentInset;

    contentInset.bottom = keyboardFrameEnd.size.height - self.view.layoutMargins.bottom; //Remove extra safe area
    if (!self.tabBarController.tabBar.translucent) {
        contentInset.bottom -= self.tabBarController.tabBar.frame.size.height;
    }
    self.collectionView.contentInset = contentInset;
    self.collectionView.scrollIndicatorInsets = contentInset;

    [self centerEmptyView];

    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    UIEdgeInsets contentInset = self.collectionView.contentInset;

    if (@available(iOS 11, *)) {
        contentInset.bottom = 0.f;
    } else {
        contentInset.bottom = self.bottomLayoutGuide.length;
    }

    self.collectionView.contentInset = contentInset;
    self.collectionView.scrollIndicatorInsets = contentInset;

    [self centerEmptyView];

    [self.collectionView.collectionViewLayout invalidateLayout];
}


/**
 Centers the empty view vertically taking into account the collection view height and content insets.
 */
- (void)centerEmptyView
{
    CGRect emptyViewFrame = self.emptyView.frame;
    CGFloat superviewHeight = self.collectionView.frame.size.height;
    CGFloat totalInsets = self.collectionView.contentInset.top + self.collectionView.contentInset.bottom;

    superviewHeight = superviewHeight - totalInsets > 0 ? superviewHeight - totalInsets : superviewHeight;
    emptyViewFrame.origin.y = (superviewHeight / 2.0) - (emptyViewFrame.size.height / 2.0) + self.collectionView.frame.origin.y;

    self.emptyView.frame = emptyViewFrame;
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    CGPoint convertedLocation = [self.collectionView convertPoint:location fromView:self.view];
    self.assetIndexInPreview = [self.collectionView indexPathForItemAtPoint:convertedLocation];
    if (self.assetIndexInPreview) {
        UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:self.assetIndexInPreview];
        CGRect rect = [self.view convertRect:attributes.frame fromView:self.collectionView];
        [previewingContext setSourceRect:rect];
    }

    return [self previewControllerForTouchLocation:convertedLocation];
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    [self displayPreviewController:viewControllerToCommit];
}

#pragma mark - WPAssetViewControllerDelegate

- (void)assetViewController:(WPAssetViewController *)assetPreviewVC selectionChanged:(BOOL)selected
{
    [self dismissPreviewController];

    if ( [self.dataSource mediaWithIdentifier:[assetPreviewVC.asset identifier]] == nil ) {

    }
    if (self.assetIndexInPreview == nil) {
        return;
    }
    if (selected) {
        [self.collectionView selectItemAtIndexPath:self.assetIndexInPreview animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:self.assetIndexInPreview];
    } else {
        [self.collectionView deselectItemAtIndexPath:self.assetIndexInPreview animated:YES];
        [self collectionView:self.collectionView didDeselectItemAtIndexPath:self.assetIndexInPreview];
    }
}

- (void)assetViewController:(WPAssetViewController *)assetPreviewVC failedWithError:(NSError *)error
{
    BOOL needToPop = YES;
    if (self.navigationController.topViewController == self) {
        needToPop = NO;
    }
    NSString *errorDetails = error.localizedDescription;
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    if (underlyingError) {
        errorDetails = underlyingError.localizedDescription;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Media preview failed.", @"Alert title when there is issues loading an asset to preview.")
                                                                             message:errorDetails
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"Action to show on alert when view asset fails.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (needToPop) {
            [self dismissPreviewController];
        }
    }];
    [alertController addAction:dismissAction];

    if (!needToPop) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:alertController animated:YES completion:nil];
        }];
    } else {
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([self.dataSource respondsToSelector:@selector(searchFor:)]) {
        [self.dataSource searchFor:searchText];
        [self.collectionView reloadData];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    self.searchBar.text = nil;
    if ([self.dataSource respondsToSelector:@selector(searchCancelled)]) {
        [self.dataSource searchCancelled];
        [self.collectionView reloadData];
    }
}

@end
