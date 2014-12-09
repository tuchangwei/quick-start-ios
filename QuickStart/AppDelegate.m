//
//  AppDelegate.m
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Abir Majumdar. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic) LYRClient *layerClient;
@property (nonatomic,retain) ViewController *viewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //Show a usage the first time the app is launched
    [self showFirstTimeMessage];
    
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    ViewController *controller = (ViewController *)navigationController.topViewController;
    self.viewController = controller;
    
    
    // Set up push notifications
    // Checking if app is running iOS 8
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        // Register device for iOS8
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound
                                                                                             categories:nil];
        [application registerUserNotificationSettings:notificationSettings];
        [application registerForRemoteNotifications];
    } else {
        // Register device for iOS7
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
    }
    
    
    // Initializes a LYRClient object
    NSUUID *appID = [[NSUUID alloc] initWithUUIDString:kAppID];
    
  self.layerClient = [LYRClient clientWithAppID:appID];
  self.viewController.layerClient = self.layerClient;
    
    // Authenticate Layer
    [self.layerClient connectWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Failed to connect to Layer: %@", error);
            //abort();
            return;
        }
        
        if (!self.layerClient.authenticatedUserID) {
            [self.layerClient requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
                if (!nonce) {
                    NSLog(@"Request for Layer authentication nonce failed: %@", error);
                    abort();
                    return;
                }
                
                NSURL *identityTokenURL = [NSURL URLWithString:@"https://layer-identity-provider.herokuapp.com/identity_tokens"];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:identityTokenURL];
                request.HTTPMethod = @"POST";
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                NSDictionary *parameters = @{ @"app_id": [self.layerClient.appID UUIDString], @"user_id": kUserID, @"nonce": nonce };
                __block NSError *serializationError = nil;
                NSData *requestBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&serializationError];
                if (!requestBody) {
                    NSLog(@"Failed serialization of request parameters: %@", serializationError);
                    abort();
                    return;
                }
                request.HTTPBody = requestBody;
                
                NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
                NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
                [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (!data) {
                        NSLog(@"Failed requesting identity token: %@", error);
                        abort();
                        return;
                    }
                    
                    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                    if (!responseObject) {
                        NSLog(@"Failed deserialization of response: %@", serializationError);
                        abort();
                        return;
                    }
                    
                    NSString *identityToken = responseObject[@"identity_token"];
                    [self.layerClient authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
                        if (!authenticatedUserID) {
                            NSLog(@"Failed authentication with Layer: %@", error);
                            return;
                        }
                    }];
                }] resume];
            }];
        }        
    }];
    
    return YES;
}

- (void)showFirstTimeMessage;
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // This is the first launch ever
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:@"This app is a very simple chat app using Layer.  Launch this app on a Simulator and a Device to start a 1:1 conversation." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
        [alert addButtonWithTitle:@"Got It!"];
        [alert show];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSError *error;
    BOOL success = [self.layerClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
    if (success) {
        NSLog(@"Application did register for remote notifications");
    } else {
        NSLog(@"Error updating Layer device token for push:%@", error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    __block LYRMessage *message = [self messageFromRemoteNotification:userInfo];
    if (application.applicationState == UIApplicationStateInactive && message) {
        //Navigate user to right part of the app here
    }
    
    NSError *error;
    BOOL success = [self.layerClient synchronizeWithRemoteNotification:userInfo completion:^(UIBackgroundFetchResult fetchResult, NSError *error) {
        if (fetchResult == UIBackgroundFetchResultFailed) {
            NSLog(@"Failed processing remote notification: %@", error);
        }
        
        message = [self messageFromRemoteNotification:userInfo];
        //Navigate user to right part of the app here
        NSString *alertString = [[NSString alloc] initWithData:[message.parts[0] data] encoding:NSUTF8StringEncoding];
        
        UILocalNotification *localNotification = [UILocalNotification new];
        localNotification.alertBody = alertString;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        completionHandler(fetchResult);
    }];
    if (success) {
        NSLog(@"Application did complete remote notification sycn");
    } else {
        NSLog(@"Error handling push notification: %@", error);
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (LYRMessage *)messageFromRemoteNotification:(NSDictionary *)remoteNotification
{
    // Fetch message object from LayerKit
    NSURL *messageURL = [NSURL URLWithString:[remoteNotification valueForKeyPath:@"layer.event_url"]];
    //NSSet *messages = [viewController.layerClient messagesForIdentifiers:[NSSet setWithObject:messageURL]];
    
    LYRQuery *query = [LYRQuery queryWithClass:[LYRMessage class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"identifier" operator:LYRPredicateOperatorIsIn value:[NSSet setWithObject:messageURL]];
    
    NSError *error;
    NSOrderedSet *messages = [self.layerClient executeQuery:query error:&error];
    if (!error) {
        NSLog(@"messageFromRemoteNotification Fetched %tu messages", messages.count);
    } else {
        NSLog(@"messageFromRemoteNotification Query failed with error %@", error);
    }
    
    return [messages firstObject];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
