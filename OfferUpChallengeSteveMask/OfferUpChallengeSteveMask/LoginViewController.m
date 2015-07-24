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

@property (strong, nonatomic) FBSDKLoginManager *loginManager;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loginManager = [[FBSDKLoginManager alloc] init];
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [self.loginBtn setTitle:@"Logout" forState:UIControlStateNormal];
        self.uploadBtn.enabled = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}



#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
            break;
            
        case 1:
            [self login:nil];
            break;
            
        default:
            break;
    }
}

#pragma mark - Actions

- (IBAction)login:(UIButton *)sender {
    
    if ([sender.titleLabel.text isEqualToString:@"Logout"]) {
        [self.loginBtn setTitle:@"Login to Facebook" forState:UIControlStateNormal];
        self.uploadBtn.enabled = false;
        
        [self.loginManager logOut];
    } else {
        [self.loginManager logInWithPublishPermissions:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                                message:@""
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

- (IBAction)uploadImages:(UIButton *)sender {
}

@end
