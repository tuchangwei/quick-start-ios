//
//  ChatMessageCell.h
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Abir Majumdar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatMessageCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *deviceLabel;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet UIImageView *messageStatus;

@end
