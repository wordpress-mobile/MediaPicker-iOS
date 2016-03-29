#import "WPPHAssetDataSource.h"
#import "WPIndexMove.h"
@import Photos;

@interface WPPHAssetDataSource() <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHAssetCollection *activeAssetsCollection;
@property (nonatomic, strong) PHFetchResult *assetsCollections;
@property (nonatomic, strong) PHFetchResult *assets;
@property (nonatomic, assign) WPMediaType mediaTypeFilter;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, assign) BOOL refreshGroups;
@property (nonatomic, assign) BOOL ascendingOrdering;

@end

@implementation WPPHAssetDataSource

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _mediaTypeFilter = WPMediaTypeVideoOrImage;
    _observers = [[NSMutableDictionary alloc] init];
    _refreshGroups = YES;
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

+ (PHCachingImageManager *) sharedImageManager
{
    static PHCachingImageManager *_sharedImageManager = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedImageManager = [[PHCachingImageManager alloc] init];
        [_sharedImageManager setAllowsCachingHighQualityImages:NO];
    });
    
    return _sharedImageManager;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    PHFetchResultChangeDetails *groupChangeDetails = [changeInstance changeDetailsForFetchResult:self.assetsCollections];
    PHFetchResultChangeDetails *assetsChangeDetails = [changeInstance changeDetailsForFetchResult:self.assets];
    
    if (!groupChangeDetails && !assetsChangeDetails) {
        return;
    }
    
    if (groupChangeDetails){
        self.refreshGroups = YES;
    }
    BOOL incrementalChanges = assetsChangeDetails.hasIncrementalChanges;
    NSIndexSet *removedIndexes = assetsChangeDetails.removedIndexes;
    NSIndexSet *insertedIndexes = assetsChangeDetails.insertedIndexes;
    NSIndexSet *changedIndexes = assetsChangeDetails.changedIndexes;
    NSMutableArray *moves = [NSMutableArray array];
    if  (assetsChangeDetails.hasMoves) {
        [assetsChangeDetails enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
            [moves addObject:[[WPIndexMove alloc] init:fromIndex to:toIndex]];
        }];
    }
    if (incrementalChanges) {
        self.assets = assetsChangeDetails.fetchResultAfterChanges;
    }

    [self.observers enumerateKeysAndObjectsUsingBlock:^(NSUUID *key, WPMediaChangesBlock block, BOOL *stop) {
        block(incrementalChanges, removedIndexes, insertedIndexes, changedIndexes, moves);
    }];
}

- (void)loadDataWithSuccess:(WPMediaSuccessBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied ||
            [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted) {
            if (failureBlock) {
                NSError *error = [NSError errorWithDomain:WPMediaPickerErrorDomain code:WPMediaErrorCodePermissionsFailed userInfo:nil];
                failureBlock(error);
            }
            return;
        }
        if (self.refreshGroups) {
            [[[self class] sharedImageManager] stopCachingImagesForAllAssets];
            [self loadGroupsWithSuccess:^{
                self.refreshGroups = NO;
                [self loadAssetsWithSuccess:successBlock failure:failureBlock];
            } failure:failureBlock];
        } else {
            [self loadAssetsWithSuccess:successBlock failure:failureBlock];
        }
    }];
}

- (NSArray *)smartAlbumsToShow {
    NSMutableArray *smartAlbumsOrder = [NSMutableArray arrayWithArray:@[
                                                                        @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
                                                                        @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
                                                                        ]];
    // Add iOS 9's new albums
    NSOperatingSystemVersion iOS9 = {9,0,0};
    if ( [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS9]) {
        [smartAlbumsOrder insertObject:@(PHAssetCollectionSubtypeSmartAlbumSelfPortraits) atIndex:3];
        [smartAlbumsOrder addObject:@(PHAssetCollectionSubtypeSmartAlbumScreenshots)];
    }
    return [NSArray arrayWithArray:smartAlbumsOrder];
}

- (void)loadGroupsWithSuccess:(WPMediaSuccessBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    NSMutableArray *collectionsArray=[NSMutableArray array];
    for (NSNumber *subType in [self smartAlbumsToShow]) {
        PHFetchResult * smartAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                           subtype:[subType intValue]
                                                                           options:nil];
        PHAssetCollection *collection = (PHAssetCollection *)smartAlbum.firstObject;
        if ([PHAsset fetchAssetsInAssetCollection:collection options:nil].count > 0){
            [collectionsArray addObjectsFromArray:[smartAlbum objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, smartAlbum.count)]]];
        }
    }
    
    PHFetchResult * albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                           subtype:PHAssetCollectionSubtypeAny
                                                                           options:nil];

    [collectionsArray addObjectsFromArray:[albums objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, albums.count)]]];
    
    PHCollectionList *allAlbums = [PHCollectionList transientCollectionListWithCollections:collectionsArray title:@"Root"];
    self.assetsCollections = [PHAssetCollection fetchCollectionsInCollectionList:allAlbums options:nil];
    if (self.assetsCollections.count > 0){
        if (!self.activeAssetsCollection || [self.assetsCollections indexOfObject:self.activeAssetsCollection] == NSNotFound) {
            self.activeAssetsCollection = self.assetsCollections[0];
        }
        if (successBlock) {
            successBlock();
        }
    } else {
        if (failureBlock) {
            failureBlock(nil);
        }

    }
}

- (void)loadAssetsWithSuccess:(WPMediaSuccessBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    switch (self.mediaTypeFilter) {
        case WPMediaTypeVideoOrImage:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            break;
        case WPMediaTypeImage:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d)", PHAssetMediaTypeImage];
            break;
        case WPMediaTypeVideo:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d)", PHAssetMediaTypeVideo];
            break;
        case WPMediaTypeOther:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d)", PHAssetMediaTypeUnknown];
            break;
        case WPMediaTypeAll:
            
            break;
    }
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.ascendingOrdering]];
    self.assets = [PHAsset fetchAssetsInAssetCollection:self.activeAssetsCollection options:fetchOptions];
    if (successBlock) {
        successBlock();
    }
}

#pragma mark - WPMediaCollectionDataSource

- (NSInteger)numberOfGroups
{
    return self.assetsCollections.count;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index
{
    return self.assetsCollections[index];
}

- (id<WPMediaGroup>)selectedGroup
{
    return self.activeAssetsCollection;
}

- (void)setSelectedGroup:(id<WPMediaGroup>)group
{
    NSParameterAssert([group isKindOfClass:[PHAssetCollection class]]);
    self.activeAssetsCollection = [group baseGroup];
}

- (NSInteger)numberOfAssets
{
    return self.assets.count;
}

- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return self.assets[index];
}

- (id<WPMediaAsset>)mediaWithIdentifier:(NSString *)identifier
{
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    PHAsset *asset = (PHAsset *)[result lastObject];
    return asset;
}

- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.observers setObject:[callback copy] forKey:blockKey];
    return blockKey;
    
}

- (void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    [self.observers removeObjectForKey:blockKey];
}

- (void)addImage:(UIImage *)image
        metadata:(NSDictionary *)metadata
 completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionBlock:completionBlock];
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    [self addAssetWithChangeRequest:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
    } completionBlock:completionBlock];
}

- (void)addAssetWithChangeRequest:(PHAssetChangeRequest *(^)())changeRequestBlock
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    NSParameterAssert(changeRequestBlock);
    __block NSString * assetIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = changeRequestBlock();
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        assetIdentifier = [assetPlaceholder localIdentifier];
        if ([self.activeAssetsCollection canPerformEditOperation:PHCollectionEditOperationAddContent]) {
            // Request editing the album.
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.activeAssetsCollection];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(localIdentifier == %@)", assetIdentifier];
        PHFetchResult * result = [PHAsset fetchAssetsInAssetCollection:self.activeAssetsCollection options:fetchOptions];
        if (result.count < 1){
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock([result firstObject], nil);
            });
        }
    }];
}

- (void)setMediaTypeFilter:(WPMediaType)filter
{
    _mediaTypeFilter = filter;
}

@end

#pragma mark - WPPHAssetMedia

@implementation PHAsset(WPMediaAsset)


- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.networkAccessAllowed = YES;
    return [[WPPHAssetDataSource sharedImageManager] requestImageForAsset:self
                                                        targetSize:size
                                                       contentMode:PHImageContentModeAspectFill
                                                           options:options
                                                     resultHandler:^(UIImage *result, NSDictionary *info) {
         NSError *error = info[PHImageErrorKey];
         NSNumber *canceled = info[PHImageCancelledKey];
         if (error || canceled){
             if (completionHandler && ![canceled boolValue]){
                 completionHandler(nil, error);
             }
             return;
         }
         if (completionHandler){
             completionHandler(result, nil);
         }
    }];
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{
    [[WPPHAssetDataSource sharedImageManager] cancelImageRequest:requestID];
}

- (WPMediaType)assetType
{
    if ([self mediaType] == PHAssetMediaTypeVideo){
        return WPMediaTypeVideo;
    } else if ([self mediaType] == PHAssetMediaTypeImage) {
        return WPMediaTypeImage;
    } else if ([self mediaType] == PHAssetMediaTypeUnknown) {
        return WPMediaTypeOther;
    }
    
    return WPMediaTypeOther;
}

- (id)baseAsset
{
    return self;
}

- (NSString *)identifier
{
    return [self localIdentifier];
}

- (NSDate *)date
{
    return [self creationDate];
}

@end

#pragma mark - WPPHAssetCollection

@implementation PHAssetCollection(WPMediaGroup)


- (NSString *)name
{
    return [self localizedTitle];
}


- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    PHAsset *posterAsset = [[PHAsset fetchAssetsInAssetCollection:self options:nil] lastObject];
    return [posterAsset imageWithSize:size completionHandler:completionHandler];
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{
    PHAsset *posterAsset = [[PHAsset fetchAssetsInAssetCollection:self options:nil] firstObject];
    [posterAsset cancelImageRequest:requestID];
}

- (id)baseGroup
{
    return self;
}

- (NSString *)identifier
{
    return [self localIdentifier];
}

- (NSInteger)numberOfAssets
{
    NSInteger count = [self estimatedAssetCount];
    if ( count == NSNotFound) {
        count = [[PHAsset fetchAssetsInAssetCollection:self options:nil] count];
    }
    return count;
}

@end
