#import "AppDelegate.h"
#import "DemoViewController.h"
#import <WPMediaPicker/WPMediaPicker.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[DemoViewController alloc]  init]];
    [self.window makeKeyAndVisible];
    
    // Customize appearance
    self.window.tintColor = [UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f];
    self.window.backgroundColor = [UIColor whiteColor];
    
    //Configure navigation bar background color
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f]];
    //Configure navigation bar items text color
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    //Configure navigation bar title text color
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} ];

    //Configure navigation bar background color
    [[UINavigationBar appearanceWhenContainedIn:[WPMediaPickerViewController class],nil] setBarTintColor:[UIColor colorWithRed:0/255.0f green:135/255.0f blue:190/255.0f alpha:1.0f]];
    //Configure navigation bar items text color
    [[UINavigationBar appearanceWhenContainedIn:[WPMediaPickerViewController class],nil] setTintColor:[UIColor whiteColor]];
    //Configure navigation bar title text color
    [[UINavigationBar appearanceWhenContainedIn:[WPMediaPickerViewController class],nil] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} ];
    //Configure background color for media scroll view
    [[UICollectionView appearanceWhenContainedIn:[WPMediaCollectionViewController class],nil] setBackgroundColor:[UIColor colorWithRed:233/255.0f green:239/255.0f blue:243/255.0f alpha:1.0f]];
    //Configure background color for media cell while loading image.
    [[WPMediaCollectionViewCell appearanceWhenContainedIn:[WPMediaCollectionViewController class],nil] setBackgroundColor:[UIColor colorWithRed:243/255.0f green:246/255.0f blue:248/255.0f alpha:1.0f]];
    //Configure color for activity indicator while loading media collection
    [[UIActivityIndicatorView appearanceWhenContainedIn:[WPMediaCollectionViewController class],nil] setColor:[UIColor grayColor]];
    return YES;
}
							

@end
