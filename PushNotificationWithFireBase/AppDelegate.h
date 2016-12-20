//
//  AppDelegate.h
//  PushNotificationWithFireBase
//
//  Created by Krishna Shanbhag on 20/12/16.
//  Copyright © 2016 WireCamp Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//GCM
@property(nonatomic, readonly, strong) NSString *registrationKey;
@property(nonatomic, readonly, strong) NSString *messageKey;
@property(nonatomic, readonly, strong) NSString *gcmSenderID;
@property(nonatomic, readonly, strong) NSDictionary *registrationOptions;


@end

