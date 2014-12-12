//
//  LayerClientDelegate.h
//  QuickStart
//
//  Created by Kevin Coleman on 12/12/14.
//  Copyright (c) 2014 Abir Majumdar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h> 

extern NSString *const LayerDidReceiveAuthenticationChallenge;
extern NSString *const LayerAuthenticationChallengeNonce;

@interface LQSLayerClientDelegate : NSObject <LYRClientDelegate>

@end
