//
//  AppDelegate.m
//  PushNotificationWithFireBase
//
//  Created by Krishna Shanbhag on 20/12/16.
//  Copyright © 2016 WireCamp Interactive. All rights reserved.
//

#import "AppDelegate.h"
@import Firebase;
@import FirebaseMessaging;
@import FirebaseInstanceID;

@interface AppDelegate ()

@property(nonatomic, strong) void (^registrationHandler)
(NSString *registrationToken, NSError *error);
@property(nonatomic, assign) BOOL connectedToGCM;
@property(nonatomic, strong) NSString* registrationToken;
@property(nonatomic, assign) BOOL subscribedToTopic;

@end

NSString *const SubscriptionTopic = @"/topics/global";

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Register Notifications
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(sendDataMessageFailure:)
     name:FIRMessagingSendErrorNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(sendDataMessageSuccess:)
     name:FIRMessagingSendSuccessNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(didDeleteMessagesOnServer)
     name:FIRMessagingMessagesDeletedNotification object:nil];
    
    //check for OS version and do stuff accordingly.
    UIUserNotificationType allNotificationTypes =
    (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    [FIRApp configure];
    
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    
    // [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelAll];
    
    return YES;
}
- (void)tokenRefreshNotification:(NSNotification *)notification {
    
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    
    
    if (refreshedToken.length > 0) {
        
        BOOL registered = [[NSUserDefaults standardUserDefaults] boolForKey:@"apnsTokenSentSuccessfully"];
        if (!registered) {
            
            //check if the user is logged in
            
            //post the refreshed token to server. On successfully posting the token
            //save the state in NSUserdeafults
            //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"apnsTokenSentSuccessfully"];
            //else store NO.
            
            //save the token in user defaults.
        [[NSUserDefaults standardUserDefaults] setObject:refreshedToken forKey:@"apnsToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    // TODO: If necessary send token to application server.
}
- (void)connectToFcm {
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"***** Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"***** Connected to FCM.");
        }
    }];
}
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeSandbox];
}
- (void)navigateFromNotificationInfo:(NSDictionary*)userInfo withState:(UIApplicationState)state
{
    //If not logged in dont do anything, just return.
    
    
    //Note that the scenario in which this method is called is when the app is backgrounded (UIApplicationStateInactive) and
    //the user taps a notification.  No navigation takes place if the user is currently using the app.
    
    if (state == UIApplicationStateBackground) {
        return;
    }
    
    
//    UIViewController *controller = [[EGNotificationManager sharedInstance] navigateToControllerForNotificationObject:userInfo forAppState:state];
//    
//    if (state == UIApplicationStateInactive) {
//        
//        HomeBaseViewController *homeBasecontroller = (HomeBaseViewController *)[self.window rootViewController];
//        [homeBasecontroller pushNotificationController:controller];
//    }
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    
    NSLog(@"Notification received: %@", userInfo);
    
    
    UIApplicationState state = [application applicationState];
    int storedBadgeNumber = [[[NSUserDefaults standardUserDefaults] valueForKey:@"applicationIconBadgeNumber"] intValue];
    
    // user tapped notification while app was in background
    int badgeNumber = (int)[[UIApplication sharedApplication] applicationIconBadgeNumber];
    storedBadgeNumber = badgeNumber + storedBadgeNumber;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:storedBadgeNumber] forKey:@"applicationIconBadgeNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:storedBadgeNumber];
    //only notifications which the app was not active
    [self navigateFromNotificationInfo:userInfo withState:state];
    
    [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
    
    // Handle the received message
    // Invoke the completion handler passing the appropriate UIBackgroundFetchResult value
    // [START_EXCLUDE]
    [[NSNotificationCenter defaultCenter] postNotificationName:_messageKey
                                                        object:nil
                                                      userInfo:userInfo];
    handler(UIBackgroundFetchResultNoData);
}
- (void)sendDataMessageFailure:(NSNotification *)notification {
    //  NSString *messageID = (NSString *)message.object;
}
- (void)sendDataMessageSuccess:(NSNotification *)notification {
    //NSString *messageID = (NSString *)message.object;
    //NSDictionary *userInfo = message.userInfo;
}

- (void)didDeleteMessagesOnServer {
}
- (void)didSendDataMessageWithID:(NSString *)messageID {
    // Did successfully send message identified by messageID
}

- (void)willSendDataMessageWithID:(NSString *)messageID error:(NSError *)error {
    if (error) {
        // Failed to send the message.
    } else {
        // Will send message, you can save the messageID to track the message
    }
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [[FIRMessaging messaging] disconnect];
    
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    [[NSUserDefaults standardUserDefaults] setValue:@0 forKey:@"applicationIconBadgeNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [self connectToFcm];
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}



- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
