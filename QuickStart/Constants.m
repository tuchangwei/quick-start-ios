//
//  Constants.m
//  QuickStart
//
//  Created by Abir Majumdar on 10/15/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "Constants.h"

#if TARGET_IPHONE_SIMULATOR
//If on simulator set the user ID to Simulator and participant to Device
NSString * const kUserID = @"Simulator";
NSString * const kParticipant = @"Device";
NSString * const kInitialMessage = @"Hey De Vice, this is your friend, Simul Ator.";
#else
//If on device set the user ID to Device and participant to Simulator
NSString * const kUserID = @"Device";
NSString * const kParticipant = @"Simulator";
NSString * const kInitialMessage =  @"Hey Simul Ator, this is your friend, De Vice.";
#endif

NSString * const kAppID = @"5a731a4c-63be-11e4-9124-aaa5020075f8";
NSString * const kMIMETypeTextPlain = @"text/plain";
