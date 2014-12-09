//
//  Constants.m
//  QuickStart
//
//  Created by Abir Majumdar on 10/15/14.
//  Copyright (c) 2014 Abir Majumdar. All rights reserved.
//

#import "Constants.h"

#if TARGET_IPHONE_SIMULATOR
//If on simulator use local service to get identiferToken
NSString * const kUserID = @"Simulator";
NSString * const kParticipant = @"Device";
NSString * const kInitialMessage = @"Hey De Vice, this is your friend, Simul Ator.";
#else
//If on device use remote service to get identiferToken
NSString * const kUserID = @"Device";
NSString * const kParticipant = @"Simulator";
NSString * const kInitialMessage =  @"Hey Simul Ator, this is your friend, De Vice.";
#endif

NSString * const kAppID = @"44a270b6-7c58-11e4-bbba-fcf307000352";
NSString * const kMIMETypeTextPlain = @"text/plain";
