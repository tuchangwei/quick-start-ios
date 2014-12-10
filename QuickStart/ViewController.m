//
//  ViewController.m
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Abir Majumdar. All rights reserved.
//

#import "ViewController.h"
#import "ChatMessageCell.h"

@interface ViewController () <UITextViewDelegate, LYRClientDelegate, LYRQueryControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Initialize table data
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
    self.navigationItem.hidesBackButton = YES;
    
    self.title = @"";
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
    self.inputTextView.delegate=self;
    self.layerClient.delegate = self;
    
    self.inputTextView.text = kInitialMessage;
    
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
        // Creates and returns a new conversation object with a single participant represented by
        // your backend's user identifier for the participant
        LYRConversation *conversation = [self.layerClient newConversationWithParticipants:[NSSet setWithArray:@[kUserID,kParticipant]] options:nil error:nil];
        self.conversation = conversation;
        [self logMessage:[NSString stringWithFormat:@"Creating First Conversation"]];
    }
    else
    {
        self.conversation = [conversations lastObject];
        [self logMessage:[NSString stringWithFormat:@"Get last conversation object: %@",self.conversation.identifier]];
    }
    
    query = [LYRQuery queryWithClass:[LYRMessage class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"conversation" operator:LYRPredicateOperatorIsEqualTo value:self.conversation];
    query.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
    self.queryController = [self.layerClient queryControllerWithQuery:query];
    self.queryController.delegate = self;
    
    BOOL success = [self.queryController execute:&error];
    if (success) {
        NSLog(@"Query fetched %tu message objects", [self.queryController numberOfObjectsInSection:0]);
    } else {
        NSLog(@"Query failed with error %@", error);
    }
    
    [self markAllMessagesAsRead];
    
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLayerObjectsDidChangeNotification:) name:LYRClientObjectsDidChangeNotification object:self.layerClient];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Register for typing indicator notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTypingIndicator:)
                                                 name:LYRConversationDidReceiveTypingIndicatorNotification object:self.conversation];
}

- (void)viewWillDisappear:(BOOL)animated
{
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


-(IBAction)openConsole:(id)sender
{
    NSLog(@"Open Console!");
    ConsoleViewController *consoleViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ConsoleViewController"];
    consoleViewController.layerClient = self.layerClient;    
    [self.navigationController pushViewController: consoleViewController animated:YES];
}


- (IBAction)sendMessageAction:(id)sender
{
    [self sendMessage:self.inputTextView.text];
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

- (void)logMessage:(NSString*) messageText{
    NSLog(@"MSG: %@",messageText);
    //    [self.textView performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%@\n%@", self.textView.text, messageText] waitUntilDone:YES];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.queryController numberOfObjectsInSection:section];
}

#pragma - mark TableView Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"ChatMessageCell";
    
    self.message = [self.queryController objectAtIndexPath:indexPath];

    ChatMessageCell *cell = (ChatMessageCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ChatMessageCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    LYRMessagePart *messagePart = self.message.parts[0];
    if ([messagePart.MIMEType isEqualToString:@"text/plain"]) {
        cell.messageLabel.text = [[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding];
    } else {
        cell.messageLabel.text = [NSString stringWithFormat:@"Cannot display '%@'", messagePart.MIMEType];
    }
    
    cell.deviceLabel.text = self.message.sentByUserID;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    
    if ([self.message.sentByUserID isEqualToString:kUserID]) {
        switch ([self.message recipientStatusForUserID:kParticipant]) {
            case LYRRecipientStatusSent:
                NSLog(@"Participant: Sent");
                [cell.messageStatus setImage:[UIImage imageNamed:@"message-sent.jpg"]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Sent: %@",[formatter stringFromDate:self.message.sentAt]];
                break;
                
            case LYRRecipientStatusDelivered:
                NSLog(@"Participant: Delivered");
                [cell.messageStatus setImage:[UIImage imageNamed:@"message-delivered.jpg"]];
                cell.timestampLabel.text = [NSString stringWithFormat:@"Delivered: %@",[formatter stringFromDate:self.message.sentAt]];
                break;
                
            case LYRRecipientStatusRead:
                NSLog(@"Participant: Read");
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

- (void)setViewMovedUp:(BOOL)movedUp{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    // Make changes to the view's frame inside the animation block. They will be animated instead
    // of taking place immediately.
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

- (void)textViewDidEndEditing:(UITextView *)textView{
    // Sends a typing indicator event to the given conversation.
    [self.conversation sendTypingIndicator:LYRTypingDidFinish];
}

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
    NSArray *changes = [notification.userInfo objectForKey:LYRClientObjectChangesUserInfoKey];
    for (NSDictionary *change in changes) {
        
        if ([[change objectForKey:LYRObjectChangeObjectKey] isKindOfClass:[LYRConversation class]]) {
            NSLog(@"Conversation Updated");
        }
        
        if ([[change objectForKey:LYRObjectChangeObjectKey]isKindOfClass:[LYRMessage class]]) {
            NSLog(@"Message Updated");
        }
    }
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



#pragma mark - Mark All Messages Read Method

- (void)markAllMessagesAsRead
{
    [self.conversation markAllMessagesAsRead:nil];
}


@end
