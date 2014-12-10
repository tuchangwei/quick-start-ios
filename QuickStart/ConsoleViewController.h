//
//  ConsoleViewController.h
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LayerKit/LayerKit.h>
#import "Constants.h"

@interface ConsoleViewController : UIViewController

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UILabel *appIDLabel;
@property (nonatomic, retain) IBOutlet UILabel *authenticatedUserIDLabel;
@property (atomic, retain) LYRClient *layerClient;

@end
