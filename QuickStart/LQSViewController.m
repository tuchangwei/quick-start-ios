//
//  ViewController.m
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "LQSViewController.h"
#import "LQSChatMessageCell.h"

// Defined in LQSAppDelegate.m
extern NSString *const LQSCurrentUserID;
extern NSString *const LQSParticipantUserID;
extern NSString *const LQSInitialMessageText;

// Metadata keys related to navbar color
static NSString *const LQSBackgroundColorMetadataKey = @"backgroundColor";
static NSString *const LQSRedBackgroundColorMetadataKeyPath = @"backgroundColor.red";
static NSString *const LQSBlueBackgroundColorMetadataKeyPath = @"backgroundColor.blue";
static NSString *const LQSGreenBackgroundColorMetadataKeyPath = @"backgroundColor.green";
static NSString *const LQSRedBackgroundColor = @"red";
static NSString *const LQSBlueBackgroundColor = @"blue";
static NSString *const LQSGreenBackgroundColor = @"green";

// Message State Images
static NSString *const LQSMessageSentImageName = @"message-sent";
static NSString *const LQSMessageDeliveredImageName =@"message-delivered";
static NSString *const LQSMessageReadImageName =@"message-read";

static NSString *const LQSChatMessageCellReuseIdentifier = @"ChatMessageCell";

static NSString *const LQSLogoImageName = @"Logo";
static CGFloat const LQSKeyboardHeight = 255.0f;

static NSDateFormatter *LQSDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss";
    }
    return dateFormatter;
}

static UIColor *LSRandomColor(void)
{
    CGFloat redFloat = arc4random() % 100 / 100.0f;
    CGFloat greenFloat = arc4random() % 100 / 100.0f;
    CGFloat blueFloat = arc4random() % 100 / 100.0f;
    
    return [UIColor colorWithRed:redFloat
                           green:greenFloat
                            blue:blueFloat
                           alpha:1.0f];
}

@interface LQSViewController () <UITextViewDelegate, LYRQueryControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) LYRConversation *conversation;
@property (nonatomic, retain) LYRQueryController *queryController;

@end

@implementation LQSViewController

#pragma mark - VC Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLayerNotificationObservers];
    [self fetchLayerConversation];
    
    // Setup for Shake
    [self becomeFirstResponder];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:LQSLogoImageName]];
    self.navigationItem.hidesBackButton = YES;
    
    self.inputTextView.delegate = self;
    self.inputTextView.text = LQSInitialMessageText;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupLayerNotificationObservers
{
    // Register for Layer object change notifications
    // For more information about Synchronization, check out https://developer.layer.com/docs/integration/ios#synchronization
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveLayerObjectsDidChangeNotification:)
                                                 name:LYRClientObjectsDidChangeNotification
                                               object:nil];
    
    // Register for typing indicator notifications
    // For more information about Typing Indicators, check out https://developer.layer.com/docs/integration/ios#typing-indicator
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTypingIndicator:)
                                                 name:LYRConversationDidReceiveTypingIndicatorNotification
                                               object:self.conversation];
}

#pragma mark - Fetching Layer Content

- (void)fetchLayerConversation
{
    // Fetches all conversations between the authenticated user and the supplied participant
    // For more information about Querying, check out https://developer.layer.com/docs/integration/ios#querying
    
    LYRQuery *query = [LYRQuery queryWithClass:[LYRConversation class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"participants" operator:LYRPredicateOperatorIsEqualTo value:@[ LQSCurrentUserID, LQSParticipantUserID ]];
    query.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES] ];
    
    NSError *error;
    NSOrderedSet *conversations = [self.layerClient executeQuery:query error:&error];
    if (!error) {
        NSLog(@"%tu conversations with participants %@", conversations.count, @[ LQSCurrentUserID, LQSParticipantUserID ]);
    } else {
        NSLog(@"Query failed with error %@", error);
    }
    
    // Retrieve the last conversation
    if (conversations.count) {
        self.conversation = [conversations lastObject];
        NSLog(@"Get last conversation object: %@",self.conversation.identifier);
        // setup query controller with messages from last conversation
        [self setupQueryController];
    }
}

-(void)setupQueryController
{
    // For more information about the Query Controller, check out https://developer.layer.com/docs/integration/ios#querying
    
    // Query for all the messages in conversation sorted by index
    LYRQuery *query = [LYRQuery queryWithClass:[LYRMessage class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"conversation" operator:LYRPredicateOperatorIsEqualTo value:self.conversation];
    query.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO]];
    
    // Set up query controller
    self.queryController = [self.layerClient queryControllerWithQuery:query];
    self.queryController.delegate = self;
    
    NSError *error;
    BOOL success = [self.queryController execute:&error];
    if (success) {
        NSLog(@"Query fetched %tu message objects", [self.queryController numberOfObjectsInSection:0]);
    } else {
        NSLog(@"Query failed with error: %@", error);
    }
    
    // Mark all conversations as read on launch
    [self.conversation markAllMessagesAsRead:nil];
}

#pragma - mark Table View Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return number of objects in queryController
    return [self.queryController numberOfObjectsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set up custom ChatMessageCell for displaying message
    LQSChatMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:LQSChatMessageCellReuseIdentifier forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LQSChatMessageCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get Message Object from queryController
    LYRMessage *message = [self.queryController objectAtIndexPath:indexPath];
    
    // Set Message Text
    LYRMessagePart *messagePart = message.parts[0];
    cell.messageLabel.text = [[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding];
    
    // Set Sender Info
    cell.deviceLabel.text = message.sentByUserID;
    
    // If the message was sent by current user, show Receipent Status Indicators
    if ([message.sentByUserID isEqualToString:LQSCurrentUserID]) {
        switch ([message recipientStatusForUserID:LQSParticipantUserID]) {
            case LYRRecipientStatusSent:
                [cell.messageStatus setImage:[UIImage imageNamed:LQSMessageSentImageName]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Sent: %@",[LQSDateFormatter() stringFromDate:message.sentAt]];
                break;
                
            case LYRRecipientStatusDelivered:
                [cell.messageStatus setImage:[UIImage imageNamed:LQSMessageDeliveredImageName]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Delivered: %@",[LQSDateFormatter() stringFromDate:message.sentAt]];
                break;
                
            case LYRRecipientStatusRead:
                [cell.messageStatus setImage:[UIImage imageNamed:LQSMessageReadImageName]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Read: %@",[LQSDateFormatter() stringFromDate:message.receivedAt]];
                break;
                
            case LYRRecipientStatusInvalid:
                NSLog(@"Participant: Invalid");
                break;
                
            default:
                break;
        }
    } else {
        cell.timestampLabel.text = [NSString stringWithFormat:@"Sent: %@",[LQSDateFormatter() stringFromDate:message.sentAt]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 78;
}

#pragma mark - Receiving Typing Indicator

- (void)didReceiveTypingIndicator:(NSNotification *)notification
{
    // For more information about Typing Indicators, check out https://developer.layer.com/docs/integration/ios#typing-indicator
    
    NSString *participantID = notification.userInfo[LYRTypingIndicatorParticipantUserInfoKey];
    LYRTypingIndicator typingIndicator = [notification.userInfo[LYRTypingIndicatorValueUserInfoKey] unsignedIntegerValue];
    
    if (typingIndicator == LYRTypingDidBegin) {
        self.typingIndicatorLabel.alpha = 1;
        self.typingIndicatorLabel.text = [NSString stringWithFormat:@"%@ is typing...",participantID];
    } else {
        self.typingIndicatorLabel.alpha = 0;
        self.typingIndicatorLabel.text = @"";
    }
}

#pragma - IBActions

- (IBAction)sendMessageAction:(id)sender
{
    // Send Message
    [self sendMessage:self.inputTextView.text];
    
    // Lower the keyboard
    [self moveViewUpToShowKeyboard:NO];
    [self.inputTextView resignFirstResponder];
}

- (void)sendMessage:(NSString *)messageText{

    // Send a Message
    // See "Quick Start - Send a Message" for more details
    // https://developer.layer.com/docs/quick-start/ios#send-a-message
    
    // If no conversations exist, create a new conversation object with a single participant
    if (!self.conversation) {
        NSError *error = nil;
        self.conversation = [self.layerClient newConversationWithParticipants:[NSSet setWithArray:@[ LQSCurrentUserID, LQSParticipantUserID ]] options:nil error:&error];
        if (!self.conversation) {
            NSLog(@"New Conversation creation failed: %@", error);
        }
    }
    
    // Creates a message part with text/plain MIME Type
    LYRMessagePart *messagePart = [LYRMessagePart messagePartWithText:messageText];
    
    // Creates and returns a new message object with the given conversation and array of message parts
    LYRMessage *message = [self.layerClient newMessageWithParts:@[messagePart] options:@{LYRMessageOptionsPushNotificationAlertKey: messageText} error:nil];
    
    // Sends the specified message
    NSError *error;
    BOOL success = [self.conversation sendMessage:message error:&error];
    if (success) {
        // If the message was sent by the participant, show the sentAt time and mark the message as read
        NSLog(@"Message queued to be sent: %@", messageText);
        self.inputTextView.text = @"";
    } else {
        NSLog(@"Message send failed: %@", error);
    }
}

#pragma - mark Set up for Shake

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // If user shakes the phone, change the navbar color and set metadata
    if (motion == UIEventSubtypeMotionShake) {
        UIColor *newNavBarBackgroundColor = LSRandomColor();
        self.navigationController.navigationBar.barTintColor = newNavBarBackgroundColor;

        CGFloat redFloat = 0.0, greenFloat = 0.0, blueFloat = 0.0, alpha = 0.0;
        [newNavBarBackgroundColor getRed:&redFloat green:&greenFloat blue:&blueFloat alpha:&alpha];

        // For more information about Metadata, check out https://developer.layer.com/docs/integration/ios#metadata
        NSDictionary *metadata = @{ LQSBackgroundColorMetadataKey : @{
                                            LQSRedBackgroundColor : [[NSNumber numberWithFloat:redFloat] stringValue],
                                            LQSGreenBackgroundColor : [[NSNumber numberWithFloat:greenFloat] stringValue],
                                            LQSBlueBackgroundColor : [[NSNumber numberWithFloat:blueFloat] stringValue]}
                                    };
        [self.conversation setValuesForMetadataKeyPathsWithDictionary:metadata merge:YES];
    }
}

#pragma - mark TextView Delegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // For more information about Typing Indicators, check out https://developer.layer.com/docs/integration/ios#typing-indicator
    
    // Sends a typing indicator event to the given conversation.
    [self.conversation sendTypingIndicator:LYRTypingDidBegin];
    [self moveViewUpToShowKeyboard:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    // Sends a typing indicator event to the given conversation.
    [self.conversation sendTypingIndicator:LYRTypingDidFinish];
}

// Move up the view when the keyboard is shown
- (void)moveViewUpToShowKeyboard:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];

    CGRect rect = self.view.frame;
    if (movedUp) {
        if (rect.origin.y == 0) {
            rect.origin.y = self.view.frame.origin.y - LQSKeyboardHeight;
        }
    } else {
        if (rect.origin.y < 0) {
            rect.origin.y = self.view.frame.origin.y + LQSKeyboardHeight;
        }
    }
    self.view.frame = rect;
    [UIView commitAnimations];
}

// If the user hits Return then dismiss the keyboard and move the view back down
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self.inputTextView resignFirstResponder];
        [self moveViewUpToShowKeyboard:NO];
        return NO;
    }
    return YES;
}

#pragma mark - Query Controller Delegate Methods

- (void)queryControllerWillChangeContent:(LYRQueryController *)queryController
{
    [self.tableView beginUpdates];
}

- (void)queryController:(LYRQueryController *)controller
        didChangeObject:(id)object
            atIndexPath:(NSIndexPath *)indexPath
          forChangeType:(LYRQueryControllerChangeType)type
           newIndexPath:(NSIndexPath *)newIndexPath
{
    // Automatically update tableview when there are change events
    switch (type) {
        case LYRQueryControllerChangeTypeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case LYRQueryControllerChangeTypeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case LYRQueryControllerChangeTypeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case LYRQueryControllerChangeTypeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

- (void)queryControllerDidChangeContent:(LYRQueryController *)queryController
{
    [self.tableView endUpdates];
}

#pragma - mark LYRQueryControllerDelegate Delegate Methods

- (void)didReceiveLayerClientWillBeginSynchronizationNotification:(NSNotification *)notification
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didReceiveLayerClientDidFinishSynchronizationNotification:(NSNotification *)notification
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Layer Object Change Notification Handler

- (void)didReceiveLayerObjectsDidChangeNotification:(NSNotification *)notification;
{
    // For more information about Synchronization, check out https://developer.layer.com/docs/integration/ios#synchronization
    if (!self.conversation) {
        [self fetchLayerConversation];
        [self setupQueryController];
        [self.tableView reloadData];
    }
    // Get nav bar colors from conversation metadata
    [self setNavbarColorFromConversationMetadata:self.conversation.metadata];
}

#pragma - mark General Helper Methods

-(void)setNavbarColorFromConversationMetadata:(NSDictionary *)metadata
{
    // For more information about Metadata, check out https://developer.layer.com/docs/integration/ios#metadata
    if (![metadata valueForKey:LQSBackgroundColorMetadataKey]) {
        return;
    }
    CGFloat redColor = (CGFloat)[[metadata valueForKeyPath:LQSRedBackgroundColorMetadataKeyPath] floatValue];
    CGFloat blueColor = (CGFloat)[[metadata valueForKeyPath:LQSBlueBackgroundColorMetadataKeyPath] floatValue];
    CGFloat greenColor = (CGFloat)[[metadata valueForKeyPath:LQSGreenBackgroundColorMetadataKeyPath] floatValue];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:redColor
                                                                           green:greenColor
                                                                            blue:blueColor
                                                                           alpha:1.0f];
}

@end
