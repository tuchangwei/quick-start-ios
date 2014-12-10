//
//  ViewController.h
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Abir Majumdar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LayerKit/LayerKit.h>
#import "Constants.h"
#import "ConsoleViewController.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (nonatomic, retain) IBOutlet UITextView *inputTextView;

@property (nonatomic, retain) LYRClient *layerClient;
@property (nonatomic) LYRConversation *conversation;
@property (nonatomic) LYRMessage *message;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, retain) LYRQueryController *queryController;

- (void)logMessage:(NSString*) messageText;

@end

