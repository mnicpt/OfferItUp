//
//  LoginViewController.m
//  OfferUpChallengeSteveMask
//
//  Created by Steven Mask on 7/23/15.
//  Copyright (c) 2015 Steven Mask. All rights reserved.
//

#import "LoginViewController.h"
#import "ImageLoaderViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface LoginViewController ()

@property (strong, nonatomic) IBOutlet UIButton *loginBtn;
@property (strong, nonatomic) IBOutlet UIButton *uploadBtn;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([FBSDKAccessToken currentAccessToken]) {
        [self.loginBtn setTitle:@"Logout" forState:UIControlStateNormal];
        self.uploadBtn.enabled = YES;
    }
}


#pragma mark - Actions

- (IBAction)login:(UIButton *)sender {
    
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    
    if ([sender.titleLabel.text isEqualToString:@"Logout"]) {
        [self.loginBtn setTitle:@"Login to Facebook" forState:UIControlStateNormal];
        self.uploadBtn.enabled = false;
        
        [loginManager logOut];
        
    } else {
        [loginManager logInWithPublishPermissions:@[@"publish_actions"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                                message:@"Would you like to try again?"
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Retry", nil];
                [alert show];
            } else {
                [self.loginBtn setTitle:@"Logout" forState:UIControlStateNormal];
                self.uploadBtn.enabled = YES;
            }
        }];
    }
}


#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
            break;
            
        case 1:
            [self login:self.loginBtn];
            break;
            
        default:
            break;
    }
}


#pragma mark - Unwind Seque
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    // needed to unwind from confirmation page
}

@end
