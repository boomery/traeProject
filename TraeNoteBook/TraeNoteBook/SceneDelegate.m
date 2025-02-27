//
//  SceneDelegate.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "NoteListViewController.h"
#import "VideoFeedViewController.h"
#import "WebViewController.h"
@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // 创建视频流页面
    VideoFeedViewController *videoFeedVC = [[VideoFeedViewController alloc] init];
    UINavigationController *videoNavController = [[UINavigationController alloc] initWithRootViewController:videoFeedVC];
    UIImage *videoImage = [[UIImage systemImageNamed:@"play.circle.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *videoSelectedImage = [videoImage imageWithTintColor:[UIColor whiteColor]];
    videoNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"视频" image:videoImage selectedImage:videoSelectedImage];
    
    // 创建笔记本页面
    NoteListViewController *noteListVC = [[NoteListViewController alloc] init];
    UINavigationController *noteNavController = [[UINavigationController alloc] initWithRootViewController:noteListVC];
    UIImage *noteImage = [[UIImage systemImageNamed:@"note.text"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *noteSelectedImage = [noteImage imageWithTintColor:[UIColor whiteColor]];
    noteNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"笔记" image:noteImage selectedImage:noteSelectedImage];
    
    // 创建浏览器页面
    WebViewController *webVC = [[WebViewController alloc] init];
    UINavigationController *webNavController = [[UINavigationController alloc] initWithRootViewController:webVC];
    UIImage *webImage = [[UIImage systemImageNamed:@"safari.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *webSelectedImage = [webImage imageWithTintColor:[UIColor whiteColor]];
    webNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"浏览器" image:webImage selectedImage:webSelectedImage];
    
    // 创建TabBarController并设置样式
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[webNavController, videoNavController, noteNavController];
    
    // 设置TabBar样式
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.backgroundColor = [UIColor blackColor];
    tabBar.tintColor = [UIColor whiteColor];
    tabBar.unselectedItemTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor blackColor];
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.5]};
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            tabBar.scrollEdgeAppearance = appearance;
        }
    }
    
    // 设置导航栏样式
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        appearance.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        
        [UINavigationBar appearance].standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            [UINavigationBar appearance].scrollEdgeAppearance = appearance;
        }
    }
    
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.

    // Save changes in the application's managed object context when the application transitions to the background.
    [(AppDelegate *)UIApplication.sharedApplication.delegate saveContext];
}


@end
