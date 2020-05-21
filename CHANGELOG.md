# Change Log
All notable changes to this project will be documented in this file.
`WPMediaPicker` adheres to [Semantic Versioning](http://semver.org/).

#### Releases
- `1.7.0` Release  - [1.7](#1.7.0)
- `1.6.0` Release  - [1.6](#1.6.0)
- `1.5.0` Release  - [1.5](#1.5.0)
- `1.4.2` Release  - [1.4.2](#1.4.2)
- `1.4` Release  - [1.4](#1.4)
- `1.3.4` Release  - [1.3.4](#1.3.4)
- `1.3` Release  - [1.3](#1.3)
- `1.2` Release  - [1.2](#1.2)
- `1.1` Release  - [1.1](#1.1)
- `1.0` Release  - [1.0](#1.0)
- `0.28` Release  - [0.28](#28)
- `0.27` Release  - [0.27](#27)
- `0.26` Release  - [0.26](#26)
- `0.25` Release  - [0.25](#25)
- `0.24` Release  - [0.24](#24)
- `0.23` Release  - [0.23](#23)
- `0.22` Release  - [0.22](#22)
- `0.21` Release  - [0.21](#21)
- `0.20` Release  - [0.20](#20)
- `0.19` Release  - [0.19](#19)
- `0.18` Releases - [0.18](#18)
- `0.17` Releases - [0.17](#17)
- `0.16` Releases - [0.16](#16)
- `0.15` Releases - [0.15](#15)

---
## [1.7.0](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.7.0)
Released on 2019-10-18. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.7.0).

### Changes
- Fix image/photo capture when it's done with the device rotated. #337 #338

---
## [1.6.0](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.6.0)
Released on 2019-10-18. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.6.0).

### Fixed
- Fix bug where VC present after selection was being changed by selection updates. #353

---
## [1.5.0](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.5.0)
Released on 2019-09-09. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.5.0).

### Changes
- Update code to have as minimum working version iOS 11.

---
## [1.4.2](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.4.2)
Released on 2019-06-14. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.4.2).

### Fixed
- Sorting of user albums alphabetically. #329
- Fix selection frame when rotating device. #332
- Fix asset display on device. #333

---
## [1.4](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.4.0)
Released on 2019-05-01. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.4.0).

### Fixed
- Add new method to WPMediaCollectionDataSource protocol to allow for checking changes on the groups of the data source. This allow improving refresh on the WPMediaGroupViewController so that it only refresh when the group changes instead of when the assets of a group change. #322 #323

---
## [1.3.4](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.3.4)
Released on 2019-04-24. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.3.4).

### Fixed
- If no details of the changes are made available on PHDataSource send a change notification with the proper variable state set. Make sure observers are removed and readded when datasource changes. #305 #321

---
## [1.3](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.3)
Released on 2018-06-21. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.3).

### Fixed
- Check for nil for empty View Controller. #304 

---
## [1.2](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.2)
Released on 2018-06-21. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.2).

### Added
- Added the possibility to use a View Controller for the empty state. #303


---
## [1.1](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.1)
Released on 2018-06-21. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.1).
  
### Added
- Added the possibility to configure a badge on the top left of the media cells. Good to display extra info about the media object. #295 #296 #299
- It's now possible to configure the display of the each media on the carrousel view. #300

---
## [1.0](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/1.0)
Released on 2018-05-09. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A1.0).

### Fixed
- Fix crash when updating collection view from partial changes. #293

---
## [0.28](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.28)
Released on 2018-04-30. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.28).

### Added

- Implements a carousel view to preview multiple selection of assets. #281
- Bottom action bar. #282

### Fixed
- Fix crash when dealloc WPMediaGroupCell. #280
- Enable bounce correctly depending of scrolling type. #288

---
## [0.27](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.27)
Released on 2018-02-26. All issues associated with this milestone can be found using this [filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.27).

### Fixed
- Ordering of selection highlight and position indicator. #278

---
## [0.26](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.26)
Released on 2010-01-10. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.26).

### Added
- Smart Invert support. #272

### Fixed
- Fix video player on iPhone X. #273
- Center empty view. #274

---
## [0.25](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.25)
Released on 2017-11-20. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.25).

### Added
- Added the possibility to display a overlay view on top of the media cells. #259 #261
- Added the possibility to search for assets on the picker. #257 #260 #268

### Fixed
- Improved reload of cells by reconfiguring the cell instead of reloading it. #269

---
## [0.24](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.24)
Released on 2017-11-01. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.24).

### Fixed
- Empty albums are filtered out of the album list. #230
- Fix crash on reload when using the same data source. #253
- Fixed display of count and thumbnail of albums when scrolling super quick. #255

## [0.23](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.23)
Released on 2017-10-04. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.23).

### Fixed
- Fixed layout issues for the iPhoneX. #242
- Updated collection cell design for audio & doc files. #245
- Fixed issues with play/pause of videos. #249
- Pushed the minimum version of iOS to be the 10. Solved deprecation warnings. #248

## [0.22](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.22)
Released on 2017-09-21. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.22).

### Fixed
- Fixed crash on photos permission check. #239

## [0.21](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.21)
Released on 2017-09-06. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.21).

### Fixed
- Fixed some crashes and bugs on the demo app. #219 #221
- Fixed bugs related to selection of assets and refresh. #225 #223
- Improved performance when capturing new media inside the picker. #211
- Photos captured using the picker were not saving metadata. #226

## [0.20](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.20)
Released on 2017-08-25. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.20).

### Added
- New design for the picker media cells. #203 #205
- New design and interaction for album selector. #207

### Fixed
- Improved performance of loading albums and assets on the picker. #209
- Fixed selection bug when capturing new cell. #214
- Improved performance when capturing new media inside the picker. #211

## [0.19](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.19)
Released on 2017-07-26. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.19).

#### Fixed
- Fixed some retain cycles that were causing issues with double notifications.
- Refactor options on the picker to allow better refresh of picker.
- Allow selected assets to be pre-selected on the picker.

## [0.18](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.18)
Released on 2017-06-16. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.18).

#### Fixed
- Fixed unit tests compilation and started running them on Travis CI
- Improved startup time of the picker
- Fix long  standing issue when certain updates when switching groups where crashing the picker.

## [0.17](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.17)
Released on 2017-05-26. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.17).

#### Added
- Two new `WPMediaPickerViewControllerDelegate` methods: `mediaPickerControllerWillBeginLoadingData` and `mediaPickerControllerDidEndLoadingData` to inform the delegate when loading of data from the data source has begun / ended.

## [0.16](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.16)
Released on 2017-05-04. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/pulls?utf8=✓&q=is%3Apr%20is%3Aclosed%20milestone%3A0.16).

#### Added
- A title to the default asset preview view controller, showing the date of the asset.
- The media picker can now handle non-image and non-video assets, such as PDFs. The cells in the picker will show a placeholder icon, the file type, and filename.
- The media picker will show a placeholder icon if an image or video fails to load.

### Fixed
- Video is now captured in high quality.
- The picker's layout is now improved on iPad, for more consistent cell spacing.
- The group picker should now be much faster to load and scroll for PHAssetCollections.
- Date / time formatting code has been refactored / cleaned up a little, and should now better handle different locales.
- Optimized the loading and caching of group thumbnails.

---

## [0.15](https://github.com/wordpress-mobile/MediaPicker-iOS/releases/tag/0.15)
Released on 2017-03-29. All issues associated with this milestone can be found using this
[filter](https://github.com/wordpress-mobile/MediaPicker-iOS/issues?utf8=✓&q=milestone%3A0.15).

#### Added
- A new toolbar to WPVideoPlayerView to allow control of play/pause of video assets.

### Fixed
- Fixed scrolling issues when opening the picker.

---
