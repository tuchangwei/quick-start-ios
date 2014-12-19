//
//  AppDelegate.m
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <LayerKit/LayerKit.h>
#import "LQSViewController.h"
#import "LQSAppDelegate.h"

/**
 Layer App ID from developer.layer.com
 */
static NSString *const LQSLayerAppIDString = @"LAYER_APP_ID";

#if TARGET_IPHONE_SIMULATOR
    // If on simulator set the user ID to Simulator and participant to Device
    NSString *const LQSCurrentUserID = @"Simulator";
    NSString *const LQSParticipantUserID = @"Device";
    NSString *const LQSInitialMessageText = @"Hey Device! This is your friend, Simulator.";
#else
    // If on device set the user ID to Device and participant to Simulator
    NSString *const LQSCurrentUserID = @"Device";
    NSString *const LQSParticipantUserID = @"Simulator";
    NSString *const LQSInitialMessageText =  @"Hey Simulator! This is your friend, Device.";
#endif

@interface LQSAppDelegate () <LYRClientDelegate>

@property (nonatomic) LYRClient *layerClient;

@end

@implementation LQSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Check if Sample App is using a valid app ID.
    if([self isValidAppID])
    {
        // Add support for shake gesture
        application.applicationSupportsShakeToEdit = YES;
        
        //Show a usage the first time the app is launched
        [self showFirstTimeMessage];
        
        // Initializes a LYRClient object
        NSUUID *appID = [[NSUUID alloc] initWithUUIDString:LQSLayerAppIDString];
        self.layerClient = [LYRClient clientWithAppID:appID];
        self.layerClient.delegate = self;
        
        // Connect to Layer
        // See "Quick Start - Connect" for more details
        // https://developer.layer.com/docs/quick-start/ios#connect
        [self.layerClient connectWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Failed to connect to Layer: %@", error);
            } else {
                [self authenticateLayerWithUserID:LQSCurrentUserID completion:^(BOOL success, NSError *error) {
                    if (!success) {
                        NSLog(@"Failed Authenticating Layer Client with error:%@", error);
                    }
                }];
            }
        }];
        
        // Register for push
        [self registerApplicationForPushNotifications:application];
        
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        [(LQSViewController *)navigationController.topViewController setLayerClient:self.layerClient];
    }
    return YES;
}

#pragma mark - Push Notification Methods

- (void)registerApplicationForPushNotifications:(UIApplication *)application
{
    // Set up push notifications
    // For more information about Push, check out:
    // https://developer.layer.com/docs/guides/ios#push-notification
    
    // Checking if app is running iOS 8
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        // Register device for iOS8
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:notificationSettings];
        [application registerForRemoteNotifications];
    } else {
        // Register device for iOS7
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Send device token to Layer so Layer can send pushes to this device.
    // For more information about Push, check out:
    // https://developer.layer.com/docs/guides/ios#push-notification
    NSError *error;
    BOOL success = [self.layerClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
    if (success) {
        NSLog(@"Application did register for remote notifications.");
    } else {
        NSLog(@"Failed updating device token with error: %@", error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // Increment badge count if a message
    if ([[userInfo valueForKeyPath:@"aps.content-available"] integerValue] != 0) {
        NSInteger badgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeNumber + 1];
    }

    // Get Message from Metadata
    __block LYRMessage *message = [self messageFromRemoteNotification:userInfo];
    
    NSError *error;
    BOOL success = [self.layerClient synchronizeWithRemoteNotification:userInfo completion:^(UIBackgroundFetchResult fetchResult, NSError *error) {
        if (fetchResult == UIBackgroundFetchResultFailed) {
            NSLog(@"Failed processing remote notification: %@", error);
        }
        message = [self messageFromRemoteNotification:userInfo];
        completionHandler(fetchResult);
    }];
    
    if (success) {
        NSLog(@"Application did complete remote notification sync");
    } else {
        NSLog(@"Failed processing push notification with error: %@", error);
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (LYRMessage *)messageFromRemoteNotification:(NSDictionary *)remoteNotification
{
    static NSString *const LQSPushMessageIdentifierKeyPath = @"layer.message_identifier";
    
    // Retrieve message URL from Push Notification
    NSURL *messageURL = [NSURL URLWithString:[remoteNotification valueForKeyPath:LQSPushMessageIdentifierKeyPath]];
    
    // Retrieve LYRMessage from Message URL
    LYRQuery *query = [LYRQuery queryWithClass:[LYRMessage class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"identifier" operator:LYRPredicateOperatorIsIn value:[NSSet setWithObject:messageURL]];
    
    NSError *error;
    NSOrderedSet *messages = [self.layerClient executeQuery:query error:&error];
    if (!error) {
        NSLog(@"Query contains %lu messages", (unsigned long)messages.count);
    } else {
        NSLog(@"Query failed with error %@", error);
    }
    return [messages firstObject];
}

#pragma mark - Layer Authentication Methods

- (void)authenticateLayerWithUserID:(NSString *)userID completion:(void (^)(BOOL success, NSError * error))completion
{
    if (self.layerClient.authenticatedUserID) {
        NSLog(@"Layer Authenticated as User %@", self.layerClient.authenticatedUserID);
        if (completion) completion(YES, nil);
        return;
    }

    // Authenticate with Layer
    // See "Quick Start - Authenticate" for more details
    // https://developer.layer.com/docs/quick-start/ios#authenticate
    
    /*
     * 1. Request an authentication Nonce from Layer
     */
    [self.layerClient requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
        if (!nonce) {
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        /*
         * 2. Acquire identity Token from Layer Identity Service
         */
        [self requestIdentityTokenForUserID:userID appID:[self.layerClient.appID UUIDString] nonce:nonce completion:^(NSString *identityToken, NSError *error) {
            if (!identityToken) {
                if (completion) {
                    completion(NO, error);
                }
                return;
            }
            
            /*
             * 3. Submit identity token to Layer for validation
             */
            [self.layerClient authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
                if (authenticatedUserID) {
                    if (completion) {
                        completion(YES, nil);
                    }
                    NSLog(@"Layer Authenticated as User: %@", authenticatedUserID);
                } else {
                    completion(NO, error);
                }
            }];
        }];
    }];
}

- (void)requestIdentityTokenForUserID:(NSString *)userID appID:(NSString *)appID nonce:(NSString *)nonce completion:(void(^)(NSString *identityToken, NSError *error))completion
{
    NSParameterAssert(userID);
    NSParameterAssert(appID);
    NSParameterAssert(nonce);
    NSParameterAssert(completion);
    
    NSURL *identityTokenURL = [NSURL URLWithString:@"https://layer-identity-provider.herokuapp.com/identity_tokens"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:identityTokenURL];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSDictionary *parameters = @{ @"app_id": appID, @"user_id": userID, @"nonce": nonce };
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    request.HTTPBody = requestBody;
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        // Deserialize the response
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *identityToken = responseObject[@"identity_token"];
        completion(identityToken, nil);
        
    }] resume];
}

#pragma - mark LYRClientDelegate Delegate Methods

- (void)layerClient:(LYRClient *)client didReceiveAuthenticationChallengeWithNonce:(NSString *)nonce
{
    NSLog(@"Layer Client did recieve authentication challenge with nonce: %@", nonce);
}

- (void)layerClient:(LYRClient *)client didAuthenticateAsUserID:(NSString *)userID
{
    NSLog(@"Layer Client did recieve authentication nonce");
}

- (void)layerClientDidDeauthenticate:(LYRClient *)client
{
    NSLog(@"Layer Client did deauthenticate");
}

- (void)layerClient:(LYRClient *)client didFinishSynchronizationWithChanges:(NSArray *)changes
{
    NSLog(@"Layer Client did finish sychronization");
}

- (void)layerClient:(LYRClient *)client didFailSynchronizationWithError:(NSError *)error
{
    NSLog(@"Layer Client did fail synchronization with error: %@", error);
}

- (void)layerClient:(LYRClient *)client willAttemptToConnect:(NSUInteger)attemptNumber afterDelay:(NSTimeInterval)delayInterval maximumNumberOfAttempts:(NSUInteger)attemptLimit
{
    NSLog(@"Layer Client will attempt to connect");
}

- (void)layerClientDidConnect:(LYRClient *)client
{
    NSLog(@"Layer Client did connect");
}

- (void)layerClient:(LYRClient *)client didLoseConnectionWithError:(NSError *)error
{
    NSLog(@"Layer Client did lose connection with error: %@", error);
}

- (void)layerClientDidDisconnect:(LYRClient *)client
{
    NSLog(@"Layer Client did disconnect with error");
}

#pragma mark - First Run Notification 

- (void)showFirstTimeMessage;
{
    static NSString *const LQSApplicationHasLaunchedOnceDefaultsKey = @"applicationHasLaunchedOnce";
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:LQSApplicationHasLaunchedOnceDefaultsKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LQSApplicationHasLaunchedOnceDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // This is the first launch ever
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello!"
                                                        message:@"This is a very simple example of a chat app using Layer. Launch this app on a Simulator and a Device to start a 1:1 conversation. If you shake the Device the navbar color will change on both the Simulator and Device."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
        [alert addButtonWithTitle:@"Got It!"];
        [alert show];
    }
}

#pragma mark - Check if Sample App is using a valid app ID.

- (BOOL) isValidAppID
{
    if([LQSLayerAppIDString isEqual: @"LAYER_APP_ID"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"\xF0\x9F\x98\xA5"
                                                        message:@"To correctly use this project you need to replace LAYER_APP_ID in LQSAppDelegate.m (line 16) with your App ID from developer.layer.com."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
        [alert addButtonWithTitle:@"Ok"];
        [alert show];
        return NO;
    }
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Ok"])
    {
        abort();
    }
}

@end
