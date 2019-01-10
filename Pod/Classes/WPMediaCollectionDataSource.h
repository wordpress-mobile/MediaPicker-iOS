@import AVFoundation;

typedef NS_OPTIONS(NSInteger, WPMediaType){
    WPMediaTypeImage = 1,
    WPMediaTypeVideo = 1 << 1,
    WPMediaTypeAudio = 1 << 2,
    WPMediaTypeOther = 1 << 3,
    WPMediaTypeAll= 0XFF
};

static NSString * _Nonnull const WPMediaPickerErrorDomain = @"WPMediaPickerErrorDomain";

typedef NS_ENUM(NSInteger, WPMediaPickerErrorCode){
    WPMediaPickerErrorCodePermissionDenied,
    WPMediaPickerErrorCodeRestricted,
    WPMediaPickerErrorCodeUnknown,
    WPMediaPickerErrorCodeVideoURLNotAvailable
};

@protocol WPMediaMove <NSObject>
- (NSUInteger)from;
- (NSUInteger)to;
@end

typedef NS_ENUM(NSInteger, WPMediaLoadOptions){
    WPMediaLoadOptionsGroups,
    WPMediaLoadOptionsAssets,
    WPMediaLoadOptionsGroupsAndAssets
};


@protocol WPMediaAsset;

typedef void (^WPMediaChangesBlock)(BOOL incrementalChanges, NSIndexSet * _Nonnull removed, NSIndexSet * _Nonnull inserted, NSIndexSet * _Nonnull changed, NSArray<id<WPMediaMove>> * _Nonnull moves);
typedef void (^WPMediaSuccessBlock)(void);
typedef void (^WPMediaFailureBlock)(NSError * _Nullable error);
typedef void (^WPMediaAddedBlock)(_Nullable id<WPMediaAsset> media, NSError * _Nullable error);
typedef void (^WPMediaImageBlock)(UIImage * _Nullable result, NSError * _Nullable error);
typedef void (^WPMediaCountBlock)(NSInteger result, NSError * _Nullable error);
typedef void (^WPMediaAssetBlock)(AVAsset * _Nullable asset, NSError * _Nullable error);
typedef int32_t WPMediaRequestID;


/**
 * The WPMediaGroup protocol is adopted by an object that mediates between a media collection and it's representation on
 * an visualization like WPMediaGroupPickerViewController.
 */
@protocol WPMediaGroup <NSObject>

- (NSString *_Nonnull)name;

/**
 *  Asynchronously fetches an image that represents the group
 *
 *  @param size the target size for the image, this may not be respected if the requested size is not available
 *
 *  @param completionHandler a block that is invoked when the image is available or when an error occurs.
 *
 *  @return an unique ID of the fetch operation
 */
- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(nonnull WPMediaImageBlock)completionHandler;

- (void)cancelImageRequest:(WPMediaRequestID)requestID;

/**
 *  The original object that represents a group on the underlying media implementation
 *
 *  @return a object from the underlying media implementation
 */
- (id _Nonnull )baseGroup;

/**
 *  An unique identifer for the media group
 *
 *  @return a string that uniquely identifies the group
 */
- (nonnull NSString *)identifier;

/**
 The numbers of assets that exist in the group of a certain mediaType

 @param mediaType the asset type to count
 @param completionHandler a block that is executed when the real number of assets is know.
 @return return an estimation of the current number of assets, if no estimate is known return NSNotFound
 */
- (NSInteger)numberOfAssetsOfType:(WPMediaType)mediaType completionHandler:(nullable WPMediaCountBlock)completionHandler;

@end

/**
 * The WPMediaAsset protocol is adopted by an object that mediates between a concrete media asset and it's representation on 
 * a WPMediaCollectionViewCell.
 */
@protocol WPMediaAsset <NSObject>

/**
 Asynchronously fetches an image that represents the asset with the requested size

 @param size the target size for the image, this may not be respected if the requested size is not available. If the size request is zero the maximum available
 @param completionHandler a block that is invoked when the image is available or when an error occurs.
 @return an unique ID of the fetch operation that can be used to cancel it.
 */
- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(nonnull WPMediaImageBlock)completionHandler;

/**
 *  Cancels a previous ongoing request for an asset image
 *
 *  @param requestID an identifier returned by the imageWithSize:completionHandler: method.
 */
- (void)cancelImageRequest:(WPMediaRequestID)requestID;

/**
 Asynchronously fetches an AVAsset that represents the media object.

 @param completionHandler a block that is invoked when the asset is available or when an error occurs.

 @return an unique ID of the fetch operation that can be used to cancel it.
 */
- (WPMediaRequestID)videoAssetWithCompletionHandler:(nonnull WPMediaAssetBlock)completionHandler;

/**
 *  The media type of the asset. This could be an image, video, or another unknow type.
 *
 *  @return a WPMEdiaType object.
 */
- (WPMediaType)assetType;

/**
 *  The duration of a video media asset. The is only available on video assets.
 *
 *  @return The duration of a video asset. Always zero if the asset is not a video.
 */
- (NSTimeInterval)duration;

/**
 *  The original object that represents an asset on the underlying media implementation
 *
 *  @return a object from the underlying media implementation
 */
- (nonnull id)baseAsset;

/**
 *  A unique identifier for the media asset
 *
 *  @return a string that uniquely identifies the media asset
 */
- (nonnull NSString *)identifier;

/**
 *  The date when the asset was created.
 *
 *  @return  a NSDate object that represents the creation date of the asset.
 */
- (nonnull NSDate *)date;

/**
 *  The size, in pixels, of the asset’s image or video data.
 *
 *  @return The size, in pixels, of the asset’s image or video data.
 */
- (CGSize)pixelSize;

@optional

/**
 *  @return The filename of this asset. Optional.
 */
- (nullable NSString *)filename;

/**
 *  @return The file extension of this asset (PDF, doc, etc). Optional.
 */
- (nullable NSString *)fileExtension;

/**
 *  @return The uniform type identifier for this asset. Optional.
 */
- (nullable NSString *)UTTypeIdentifier;

@end

/**
 *  The WPMediaCollectionDataSource protocol is adopted by an object that mediates between a media library implementation
 * and a WPMediaPickerViewController / WPMediaCollectionViewController. The data source provides information about the media groups
 * that exist and the media assets inside. It also provides methods to add new media assets to the library and observe changes that
 * happen outside it's interface.
 */
@protocol WPMediaCollectionDataSource <NSObject>

/**
 *  Asks the data source for the number of groups existing on the media library.
 *
 *  @return the number of groups existing on the media library.
 */
- (NSInteger)numberOfGroups;

/**
 *  Asks the data source for the group at a selected index.
 *
 *  @param index index location the group requested.
 *
 *  @return an object implementing WPMediaGroup protocol.
 */
- (nonnull id<WPMediaGroup>)groupAtIndex:(NSInteger)index;

/**
 *  Ask the data source for the current active group of the library
 *
 *  @return an object implementing WPMediaGroup protocol.
 */
- (nullable id<WPMediaGroup>)selectedGroup;

/**
 *  Ask the data source to select a specific group and update it's assets for that group.
 *
 *  @param group object implementing the WPMediaGroup protocol
 */
- (void)setSelectedGroup:(nonnull id<WPMediaGroup>)group;

/**
 *  Asks the data source for the number of assets existing on the currect selected group
 *
 *  @return the number of assets existing on the current selected group.
 */
- (NSInteger)numberOfAssets;

/**
 *  Asks the data source for the asset at the selected index.
 *
 *  @param index index location of the asset requested.
 *
 *  @return an object implementing the WPMediaAsset protocol
 */
- (nonnull id<WPMediaAsset>)mediaAtIndex:(NSInteger)index;

/**
 *  Returns the object with the matching identifier if it exists on the datasource
 *
 *  @param identifier a unique identifier for the media
 *
 *  @return the media object if it exists or nil if it's not found.
 */
- (nullable id<WPMediaAsset>)mediaWithIdentifier:(nonnull NSString *)identifier;

/**
 *  Asks the data source to be notify about changes on the media library using the given callback block.
 *
 *  @discussion the callback object is retained by the data source so it needs to 
 * be unregistered on the end to avoid leaks or retain cycles.
 *
 *  @param callback a WPMediaChangesBlock that is invoked every time a change is detected.
 *
 *  @return an opaque object that identifies the callback register. This should be used to later unregister the block
 */
- (nonnull id<NSObject>)registerChangeObserverBlock:(nonnull WPMediaChangesBlock)callback;

/**
 *  Asks the data source to unregister the block that is identified by the block key.
 *
 *  @param blockKey the unique identifier of the block. This must have been obtained 
 * by a call to registerChangesObserverBlock
 */
- (void)unregisterChangeObserver:(nonnull id<NSObject>)blockKey;

/**
 *  Asks the data source to reload the data available of the media library. This should be invoked after changing the 
 *  current active group or if a change is detected.
 *
 *  @param options specifiy what type of data to load
 *  @param successBlock a block that is invoked when the data is loaded with success.
 *  @param failureBlock a block that is invoked when the are is any kind of error when loading the data.
 */
- (void)loadDataWithOptions:(WPMediaLoadOptions)options
                    success:(nullable WPMediaSuccessBlock)successBlock
                    failure:(nullable WPMediaFailureBlock)failureBlock;

/**
 *  Requests to the data source to add an image to the library.
 *
 *  @param image           an UIImage object with the asset to add
 *  @param metadata        the metadata information of the image to add.
 *  @param completionBlock a block that is invoked when the image is added. 
 * On success the media parameter is returned with a new object implemeting the WPMedia protocol
 * If an error occurs the media is nil and the error parameter contains a value
 */
- (void)addImage:(nonnull UIImage *)image metadata:(nullable NSDictionary *)metadata completionBlock:(nullable WPMediaAddedBlock)completionBlock;

/**
 *  Requests to the data source to add a video to the library.
 *
 *  @param url             an url pointing to a file that contains the video to be added to the library.
 *  @param completionBlock  a block that is invoked when the image is added.
 * On success the media parameter is returned with a new object implemeting the WPMedia protocol
 * If an error occurs the media is nil and the error parameter contains a value
 */
- (void)addVideoFromURL:(nonnull NSURL *)url completionBlock:(nullable WPMediaAddedBlock)completionBlock;

/**
 *  Filter the assets acording to their media type.
 *
 *  @param filter the WPMediaType to filter objects to. The default value is WPMediaTypeVideoOrImage
 */
- (void)setMediaTypeFilter:(WPMediaType)filter;

/**
 *
 *
 *  @return The media type filter that is being used.
 */
- (WPMediaType)mediaTypeFilter;

/**
 *  Sets the sorting order the assets are show based on creationDate
 *
 *  @param ascending the order wich assets are retrieved, based on the creationDate. The default value is YES
 */
- (void)setAscendingOrdering:(BOOL)ascending;

/**
 *  The sorting order on wich the assets are returned
 *
 *  @return if the assets are return in ascending order
 */
- (BOOL)ascendingOrdering;

@optional

/**
 *  Tells the Data Source that the search string has been changed
 *
 *  @param searchText the new search text
 */
- (void)searchFor:(nullable NSString *)searchText;

/**
 *  Tells the Data Source that the search was cancelled by the user
 */
- (void)searchCancelled;

@end

