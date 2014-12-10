//
//  ViewController.m
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "ViewController.h"
#import "ChatMessageCell.h"

@interface ViewController () <UITextViewDelegate, LYRClientDelegate, LYRQueryControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Initialize view
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
    self.navigationItem.hidesBackButton = YES;
    self.title = @"";
    self.inputTextView.delegate=self;
    self.inputTextView.text = kInitialMessage;

/*
    // Removing Console button for now.
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *butImage = [[UIImage imageNamed:@"Console"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    [button setBackgroundImage:butImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openConsole:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 22, 22);
    UIBarButtonItem *consoleButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = consoleButton;
*/
    
    // Fetches all conversations between the authenticated user and the supplied user
    NSArray *participants = @[kUserID, kParticipant];
    LYRQuery *query = [LYRQuery queryWithClass:[LYRConversation class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"participants" operator:LYRPredicateOperatorIsEqualTo value:participants];
    
    NSError *error;
    NSOrderedSet *conversations = [self.layerClient executeQuery:query error:&error];
    if (!error) {
        NSLog(@"%tu conversations with participants %@", conversations.count, participants);
    } else {
        NSLog(@"Query failed with error %@", error);
    }
    
    if (conversations.count == 0) {
        // If no conversations exist, create a new conversation object with a single participant
        LYRConversation *conversation = [self.layerClient newConversationWithParticipants:[NSSet setWithArray:@[kUserID,kParticipant]] options:nil error:nil];
        self.conversation = conversation;
        [self logMessage:[NSString stringWithFormat:@"Creating First Conversation"]];
    }
    else
    {
        // Retrieve the last conversation
        self.conversation = [conversations lastObject];
        [self logMessage:[NSString stringWithFormat:@"Get last conversation object: %@",self.conversation.identifier]];
    }
    
    // Retrieve all the messages in conversation
    query = [LYRQuery queryWithClass:[LYRMessage class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"conversation" operator:LYRPredicateOperatorIsEqualTo value:self.conversation];
    query.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO]];

    // Set up query controller
    self.queryController = [self.layerClient queryControllerWithQuery:query];
    self.queryController.delegate = self;
    
    BOOL success = [self.queryController execute:&error];
    if (success) {
        NSLog(@"Query fetched %tu message objects", [self.queryController numberOfObjectsInSection:0]);
    } else {
        NSLog(@"Query failed with error %@", error);
    }
    
    // Mark all conversations as read on launch
    [self.conversation markAllMessagesAsRead:nil];

    // Get initial nav bar colors from conversation metadata
    [self setNavbarColorFromConversationMetadata:self.conversation.metadata];

    // Set up Layer Client delegate and Layer Change Notification
    self.layerClient.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLayerObjectsDidChangeNotification:) name:LYRClientObjectsDidChangeNotification object:self.layerClient];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Setup for Shake
    [self becomeFirstResponder];
    
    // Register for typing indicator notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTypingIndicator:)
                                                 name:LYRConversationDidReceiveTypingIndicatorNotification object:self.conversation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Setup for Shake
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
    
    self.queryController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LYRConversationDidReceiveTypingIndicatorNotification
                                                  object:self.conversation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Receiving Typing Indicator Method

- (void)didReceiveTypingIndicator:(NSNotification *)notification
{
    NSString *participantID = notification.userInfo[LYRTypingIndicatorParticipantUserInfoKey];
    LYRTypingIndicator typingIndicator = [notification.userInfo[LYRTypingIndicatorValueUserInfoKey] unsignedIntegerValue];
    
    if (typingIndicator == LYRTypingDidBegin) {
        self.typingIndicatorLabel.alpha = 1;
        self.typingIndicatorLabel.text = [NSString stringWithFormat:@"%@ is typing...",participantID];
    }
    else {
        self.typingIndicatorLabel.alpha = 0;
        self.typingIndicatorLabel.text = @"";
    }
}

#pragma - IBActions

-(IBAction)openConsole:(id)sender
{
    // Open Console Window
    ConsoleViewController *consoleViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ConsoleViewController"];
    consoleViewController.layerClient = self.layerClient;
    [self.navigationController pushViewController: consoleViewController animated:YES];
}


- (IBAction)sendMessageAction:(id)sender
{
    // Send Message
    [self sendMessage:self.inputTextView.text];
    
    // Lower the keyboard
    [self setViewMovedUp:NO];
    [self.inputTextView resignFirstResponder];
}

- (void)sendMessage:(NSString*) messageText{
    
    // Creates a message part with text/plain MIME Type
    LYRMessagePart *messagePart = [LYRMessagePart messagePartWithText:messageText];
    
    // Creates and returns a new message object with the given conversation and array of message parts
    LYRMessage *message = [self.layerClient newMessageWithParts:@[messagePart] options:@{LYRMessageOptionsPushNotificationAlertKey: messageText} error:nil];
    
    // Sends the specified message
    NSError *e;
    BOOL success = [self.conversation sendMessage:message error:&e];
    if (success) {
        [self logMessage:[NSString stringWithFormat: @"Message Queued Up to Be Sent: %@",messageText]];
    }
    else {
        [self logMessage:[NSString stringWithFormat: @"Message Send Failed: %@",e]];
    }
}

#pragma - Set up for Shake

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // If user shakes the phone, change the navbar color and set metadata
    if (motion == UIEventSubtypeMotionShake)
    {
        UIColor *newNavBarBackgroundColor = [self getRandomColor];
        self.navigationController.navigationBar.barTintColor = newNavBarBackgroundColor;

        CGFloat redFloat = 0.0, greenFloat = 0.0, blueFloat = 0.0, alpha =0.0;
        [newNavBarBackgroundColor getRed:&redFloat green:&greenFloat blue:&blueFloat alpha:&alpha];
        
        NSDictionary *metadata = @{@"backgroundColorRed" : [[NSNumber numberWithFloat:redFloat] stringValue],
                                   @"backgroundColorGreen" : [[NSNumber numberWithFloat:greenFloat] stringValue],
                                   @"backgroundColorBlue" : [[NSNumber numberWithFloat:blueFloat] stringValue]};
        [self.conversation setValuesForMetadataKeyPathsWithDictionary:metadata merge:YES];
    }
}

#pragma - mark TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return number of objects in queryController
    return [self.queryController numberOfObjectsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get Message Object from queryController
    self.message = [self.queryController objectAtIndexPath:indexPath];

    // Set up custom ChatMessageCell for displaying message
    static NSString *simpleTableIdentifier = @"ChatMessageCell";
    ChatMessageCell *cell = (ChatMessageCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ChatMessageCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    // Set Message Text
    LYRMessagePart *messagePart = self.message.parts[0];
    if ([messagePart.MIMEType isEqualToString:kMIMETypeTextPlain]) {
        cell.messageLabel.text = [[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding];
    } else {
        cell.messageLabel.text = [NSString stringWithFormat:@"Cannot display '%@'", messagePart.MIMEType];
    }
    
    // Set Sender Info
    cell.deviceLabel.text = self.message.sentByUserID;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];

    // If the message was sent by current user, show Receipent Status Indicators
    if ([self.message.sentByUserID isEqualToString:kUserID]) {
        switch ([self.message recipientStatusForUserID:kParticipant]) {
            case LYRRecipientStatusSent:
                [cell.messageStatus setImage:[UIImage imageNamed:@"message-sent.jpg"]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Sent: %@",[formatter stringFromDate:self.message.sentAt]];
                break;
                
            case LYRRecipientStatusDelivered:
                [cell.messageStatus setImage:[UIImage imageNamed:@"message-delivered.jpg"]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Delivered: %@",[formatter stringFromDate:self.message.sentAt]];
                break;
                
            case LYRRecipientStatusRead:
                [cell.messageStatus setImage:[UIImage imageNamed:@"message-read.jpg"]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Read: %@",[formatter stringFromDate:self.message.receivedAt]];
                break;
                
            case LYRRecipientStatusInvalid:
                NSLog(@"Participant: Invalid");
                break;
                
            default:
                break;
        }
    }
    // If the message was sent by the participant, show the sentAt time and mark the message as read
    else{
        cell.timestampLabel.text = [NSString stringWithFormat:@"Sent: %@",[formatter stringFromDate:self.message.sentAt]];
        [self.message markAsRead:nil];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 78;
}

#pragma - mark TextView Delegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // Sends a typing indicator event to the given conversation.
    [self.conversation sendTypingIndicator:LYRTypingDidBegin];
    [self setViewMovedUp:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    // Sends a typing indicator event to the given conversation.
    [self.conversation sendTypingIndicator:LYRTypingDidFinish];
}

// Move up the view when the keyboard is shown
- (void)setViewMovedUp:(BOOL)movedUp{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];

    CGRect rect = self.view.frame;
    if (movedUp){
        if(rect.origin.y == 0)
            rect.origin.y = self.view.frame.origin.y - 255;
    }
    else{
        if(rect.origin.y < 0)
            rect.origin.y = self.view.frame.origin.y + 255;
    }
    self.view.frame = rect;
    [UIView commitAnimations];
}

// If the user hits Return then dismiss the keyboard and move the view back down
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [self.inputTextView resignFirstResponder];
        [self setViewMovedUp:NO];
        return NO;
    }
    return YES;
}

#pragma - mark LYRClientDelegate Delegate Methods
- (void)layerClient:(LYRClient *)client didReceiveAuthenticationChallengeWithNonce:(NSString *)nonce
{
    NSLog(@"Layer Client did recieve authentication challenge with nonce: %@", nonce);
}

- (void)layerClient:(LYRClient *)client didAuthenticateAsUserID:(NSString *)userID
{
    NSLog(@"Layer Client did recieve authentication nonce");
}

- (void)layerClientDidDeauthenticate:(LYRClient *)client
{
    NSLog(@"Layer Client did deauthenticate");
}

- (void)layerClient:(LYRClient *)client didFinishSynchronizationWithChanges:(NSArray *)changes
{
    NSLog(@"Layer Client did finish sychronization");
}

- (void)layerClient:(LYRClient *)client didFailSynchronizationWithError:(NSError *)error
{
    NSLog(@"Layer Client did fail synchronization with error: %@", error);
}

- (void)layerClient:(LYRClient *)client willAttemptToConnect:(NSUInteger)attemptNumber afterDelay:(NSTimeInterval)delayInterval maximumNumberOfAttempts:(NSUInteger)attemptLimit
{
    NSLog(@"Layer Client will attempt to connect");
}

- (void)layerClientDidConnect:(LYRClient *)client
{
    NSLog(@"Layer Client did connect");
}

- (void)layerClient:(LYRClient *)client didLoseConnectionWithError:(NSError *)error
{
    NSLog(@"Layer Client did lose connection with error: %@", error);
}

- (void)layerClientDidDisconnect:(LYRClient *)client
{
    NSLog(@"Layer Client did disconnect with error");
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

- (void) didReceiveLayerObjectsDidChangeNotification:(NSNotification *)notification;
{
    // Listen for Conversation Updates
    NSArray *changes = [notification.userInfo objectForKey:LYRClientObjectChangesUserInfoKey];
    for (NSDictionary *change in changes) {
        id changeObject = [change objectForKey:LYRObjectChangeObjectKey];
        if ([[change objectForKey:LYRObjectChangeObjectKey] isKindOfClass:[LYRConversation class]]) {
            NSLog(@"Conversation Updated");
            
            LYRConversation *changedConversation = (LYRConversation*)changeObject;

            // Get RBG for NavBar from metadata and change it's color
            // Get initial nav bar colors from conversation metadata
            [self setNavbarColorFromConversationMetadata:changedConversation.metadata];

        }
        
        if ([[change objectForKey:LYRObjectChangeObjectKey]isKindOfClass:[LYRMessage class]]) {
            NSLog(@"Message Updated");
        }
    }
}

#pragma - mark General Helper Methods

- (void)logMessage:(NSString*) messageText{
    NSLog(@"MSG: %@",messageText);
    //    [self.textView performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%@\n%@", self.textView.text, messageText] waitUntilDone:YES];
    
}

- (UIColor *) getRandomColor
{
    float redFloat = arc4random() % 100 / 100.0f;
    float greenFloat = arc4random() % 100 / 100.0f;
    float blueFloat = arc4random() % 100 / 100.0f;
    
    return [UIColor colorWithRed:redFloat
                           green:greenFloat
                            blue:blueFloat
                           alpha:1.0f];
}

-(void) setNavbarColorFromConversationMetadata:(NSDictionary *)metadata
{
    float redColor = (float)[[metadata valueForKey:@"backgroundColorRed"] floatValue];
    float blueColor = (float)[[metadata valueForKey:@"backgroundColorBlue"] floatValue];
    float greenColor = (float)[[metadata valueForKey:@"backgroundColorGreen"] floatValue];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:redColor
                                                                           green:greenColor
                                                                            blue:blueColor
                                                                           alpha:1.0f];
}

@end
