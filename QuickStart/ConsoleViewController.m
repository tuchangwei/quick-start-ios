//
//  ConsoleViewController.m
//  QuickStart
//
//  Created by Abir Majumdar on 12/3/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "ConsoleViewController.h"

@interface ConsoleViewController ()

@end

@implementation ConsoleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"self.appIDLabel.text: %@",self.appIDLabel.text);
    NSLog(@"self.authenticatedUserIDLabel.text: %@",self.appIDLabel.text);

    if([self.appIDLabel.text isEqual: @""])
    {
        self.appIDLabel.text = [self.layerClient.appID UUIDString];
        self.authenticatedUserIDLabel.text = kUserID;
    }
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
    
    self.title = @"";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *butImage = [[UIImage imageNamed:@"Chat"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    [button setBackgroundImage:butImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openMessages:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 22, 22);
    UIBarButtonItem *consoleButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = consoleButton;
}

-(IBAction)openMessages:(id)sender
{
    NSLog(@"Back to Messages!");
    UIViewController *myController = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    [self.navigationController pushViewController: myController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
