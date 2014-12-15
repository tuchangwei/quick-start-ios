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

// Your Layer App ID from developer.layer.com
NSString * const kAppID = @"5a731a4c-63be-11e4-9124-aaa5020075f8";

NSString * const kPushMessageIdentifier = @"layer.message_identifier";

// Metadata keys related to navbar color
NSString * const kBackgroundColorMetadataKey = @"backgroundColor";
NSString * const kRedBackgroundColorMetadataKeyPath = @"backgroundColor.red";
NSString * const kBlueBackgroundColorMetadataKeyPath = @"backgroundColor.blue";
NSString * const kGreenBackgroundColorMetadataKeyPath = @"backgroundColor.green";
NSString * const kRedBackgroundColor = @"red";
NSString * const kBlueBackgroundColor = @"blue";
NSString * const kGreenBackgroundColor = @"green";

int  const kKeyBoardHeight = 255;

// Message State Images
NSString * const kMessageSentImageName = @"message-sent.jpg";
NSString * const kMessageDeliveredImageName =@"message-delivered.jpg";
NSString * const kMessageReadImageName =@"message-read.jpg";

NSString * const kLogoImageName = @"Logo";

NSString * const kChatMessageCell = @"ChatMessageCell";