//
//  ViewController.m
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Abir Majumdar. All rights reserved.
//

#import "ViewController.h"
#import "ChatMessageCell.h"

@interface ViewController ()

@end

@implementation ViewController
{
    NSArray *recipes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Initialize table data
    recipes = [NSArray arrayWithObjects:@"Egg Benedict", @"Mushroom Risotto", @"Full Breakfast", @"Hamburger", @"Ham and Egg Sandwich", @"Creme Brelee", @"White Chocolate Donut", @"Starbucks Coffee", @"Vegetable Curry", @"Instant Noodle with Egg", @"Noodle with BBQ Pork", @"Japanese Noodle with Pork", @"Green Tea", @"Thai Shrimp Cake", @"Angry Birds Cake", @"Ham and Cheese Panini", nil];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
    self.navigationItem.hidesBackButton = YES;
    
    self.title = @"";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *butImage = [[UIImage imageNamed:@"Console"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    [button setBackgroundImage:butImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openConsole:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 22, 22);
    UIBarButtonItem *consoleButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = consoleButton;
    
    self.textField.delegate=self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)openConsole:(id)sender
{
    NSLog(@"Open Console!");
    UIViewController *myController = [self.storyboard instantiateViewControllerWithIdentifier:@"ConsoleViewController"];
    [self.navigationController pushViewController: myController animated:YES];
}


- (IBAction)sendMessageAction:(id)sender
{
    //    [self sendMessage:self.textField.text];
    NSLog(@"Send!");
    [self.textField resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [recipes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"ChatMessageCell";
    
    ChatMessageCell *cell = (ChatMessageCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ChatMessageCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    cell.messageLabel.text = [recipes objectAtIndex:indexPath.row];
    //cell.imageView.image = [UIImage imageNamed:@"creme_brelee.jpg"];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 78;
}

#pragma - mark TextField Delegate Methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidBeginEditing!");
    //    [self animateTextView: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidEndEditing!");
    //    [self animateTextView:NO];
}
/*
 - (void) animateTextView:(BOOL) up
 {
 const int movementDistance =10; // tweak as needed
 const float movementDuration = 0.3f; // tweak as needed
 int movement= movement = (up ? -movementDistance : movementDistance);
 NSLog(@"%d",movement);
 
 [UIView beginAnimations: @"anim" context: nil];
 [UIView setAnimationBeginsFromCurrentState: YES];
 [UIView setAnimationDuration: movementDuration];
 self.view.frame = CGRectOffset(self.inputView.frame, 0, movement);
 [UIView commitAnimations];
 }
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

@end
