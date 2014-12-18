//
//  ViewController.h
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LayerKit/LayerKit.h>

@interface LQSViewController : UIViewController

@property (nonatomic) LYRClient *layerClient;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) IBOutlet UITextView *inputTextView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *typingIndicatorLabel;

@end
