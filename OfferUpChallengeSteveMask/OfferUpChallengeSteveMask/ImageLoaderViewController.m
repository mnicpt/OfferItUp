//
//  ImageLoaderViewController.m
//  OfferUpChallengeSteveMask
//
//  Created by Steven Mask on 7/23/15.
//  Copyright (c) 2015 Steven Mask. All rights reserved.
//

#import "ImageLoaderViewController.h"

@interface ImageLoaderViewController ()

@property (strong, nonatomic) IBOutlet UIButton *firstImageBtn;
@property (strong, nonatomic) IBOutlet UIButton *secondImageBtn;
@property (strong, nonatomic) IBOutlet UIButton *thirdImageBtn;
@property (strong, nonatomic) IBOutlet UIButton *fourthImageBtn;
@property (strong, nonatomic) IBOutlet UIButton *uploadBtn;
@property (strong, nonatomic) IBOutlet UIView *loadingView;

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) NSArray *buttons;
@property int selectedButton;

@end

@implementation ImageLoaderViewController

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buttons = @[self.firstImageBtn, self.secondImageBtn, self.thirdImageBtn, self.fourthImageBtn];
    self.selectedButton = 0;
    
    [self loadImages];
}

-(void)viewWillDisappear:(BOOL)animated {
    self.loadingView.hidden = YES;
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    NSError *error = [self uploadPhotos];
    
    if (error) {
        return NO;
    }
    
    return YES;
}


#pragma mark - Actions

- (IBAction)loadImage:(UIButton *)sender {
    self.selectedButton = (int)sender.tag;
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Choose image capture option" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *photoLibraryAction = [UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [self pickPhotoFromLibrary];
    }];
    UIAlertAction *takePictureAction = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [self takePhotoFromCamera];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];

    [actionSheet addAction:photoLibraryAction];
    [actionSheet addAction:takePictureAction];
    [actionSheet addAction:cancelAction];
    
    UIPopoverPresentationController *popOverController = actionSheet.popoverPresentationController;
    popOverController.sourceView = self.buttons[self.selectedButton];
    popOverController.sourceRect = ((UIButton*)self.buttons[self.selectedButton]).bounds;
    popOverController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage;
    
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo) {
        
        originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
  
        if (originalImage) {
            [self addNewAssetWithImage:originalImage toAlbum:@"OfferUp"];
            
            NSData *thumbnail = UIImageJPEGRepresentation(originalImage, 1.0);
            [self.buttons[self.selectedButton] setBackgroundImage:[UIImage imageWithData:thumbnail ] forState:UIControlStateNormal];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
            break;
            
        case 1:
            [self uploadPhotos];
            break;
            
        default:
            break;
    }
}

#pragma mark - Private methods

-(UIImagePickerController *)imagePickerController {
    if (self.imagePicker) {
        return self.imagePicker;
    } else {
        self.imagePicker = [[UIImagePickerController alloc] init];
        return self.imagePicker;
    }
}

- (void)addNewAssetWithImage:(UIImage *)image toAlbum:(NSString *)album {
//  UNCOMMENT WHEN READY TO SUPPORT iOS 9 since ALAssetsLibrary will be deprecated
    
//    if ([PHPhotoLibrary respondsToSelector:@selector(sharedPhotoLibrary)]) {
//        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//            // Fetch album
//            PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
//            
//            __block PHAssetCollection *assetCollection = nil;
//            
//            [fetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop) {
//                if ([obj.localizedTitle isEqualToString:album]) {
//                    assetCollection = obj;
//                    *stop = YES;
//                }
//            }];
//            
//            PHAssetCollectionChangeRequest *albumChangeRequest;
//
//            if (assetCollection) {
//                // Request editing the album.
//                albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
//            } else {
//                // Request new album if not present
//                albumChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:album];
//            }
//            // remove asset of one exists
//            if (assetCollection.estimatedAssetCount > self.selectedButton) {
//                [albumChangeRequest removeAssetsAtIndexes:[NSIndexSet indexSetWithIndex:self.selectedButton]];
//            }
//            
//            // Request creating an asset from the image.
//            PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
//            
//            // Get a placeholder for the new asset and add it to the album editing request.
//            PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
//            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
//            
//            [self.uploadBtn setEnabled:YES];
//            
//        } completionHandler:^(BOOL success, NSError *error) {
//            NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
//        }];
//    } else {


    ALAssetsLibrary * assetsLibrary = [ImageLoaderViewController defaultAssetsLibrary];
    // create album
    [assetsLibrary addAssetsGroupAlbumWithName:album resultBlock:^(ALAssetsGroup *group) {
        if (group) {
            NSLog(@"Album %@ created.", album);
        } else {
            NSLog(@"Album %@ was already created.", album);
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to create album");
    }];
    
    // get the album
    __block ALAssetsGroup *albumGroup;
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:album]) {
            albumGroup = group;
            
            if (albumGroup.numberOfAssets > self.selectedButton) {
                [albumGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    
                    if (result != nil && index == self.selectedButton) {
                        [result setImageData:UIImageJPEGRepresentation(image, 1.0) metadata:nil completionBlock:nil];
                    }
                }];
                
            } else {
                // write image to group
                [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
                    
                    [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        [albumGroup addAsset:asset];
                    } failureBlock:^(NSError *error) {
                        NSLog(@"Failed to save image to album.");
                    }];
                }];
            }
            self.selectedButton++;
            if ((self.buttons.count - 1) >= self.selectedButton) {
                [self.buttons[self.selectedButton] setEnabled:YES];
            }
            [self.uploadBtn setEnabled:YES];
        }
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to enumerate over assets library.");
    }];
//    }
}

-(void)pickPhotoFromLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {

        UIImagePickerController *mediaUI = [self imagePickerController];
        mediaUI.delegate = self;
        mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

        mediaUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];

        mediaUI.allowsEditing = NO;
        
        [self presentViewController:mediaUI animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"We're sorry." message:@"Photo Library is not available" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)takePhotoFromCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIImagePickerController *cameraUI = [self imagePickerController];
        cameraUI.delegate = self;
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        
        cameraUI.allowsEditing = NO;
        
        [self presentViewController:cameraUI animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"We're sorry." message:@"Camera is not available" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)loadImages {
    ALAssetsLibrary * assetsLibrary = [ImageLoaderViewController defaultAssetsLibrary];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"OfferUp"]) {
            
            __block int i = 0;
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result != nil) {
                    [self.buttons[i] setBackgroundImage:[UIImage imageWithCGImage:result.thumbnail] forState:UIControlStateNormal];
                    [self.buttons[i] setEnabled:YES];
                    
                    if (i <= (self.buttons.count - 2)) {
                        [self.buttons[i + 1] setEnabled:YES];
                    }
                    
                    i++;
                    self.selectedButton++;
                }
            }];
            
            [self.uploadBtn setEnabled:YES];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to enumerate over assets library.");
    }];
}

-(NSError*)uploadPhotos {
    NSError *error = nil;
    self.loadingView.hidden = NO;
    
    ALAssetsLibrary * assetsLibrary = [ImageLoaderViewController defaultAssetsLibrary];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"OfferUp"]) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result != nil) {
                    
                    NSDictionary *params = @{@"source" : [UIImage imageWithCGImage:result.thumbnail]};
                    
                    // post images
                    FBSDKGraphRequest *albumRequest = [[FBSDKGraphRequest alloc]
                                                       initWithGraphPath:@"me/photos"
                                                       parameters:params
                                                       HTTPMethod:@"POST"];
                    [albumRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                               id result,
                                                               NSError *error) {
                        if (!error) {
                            NSLog(@"Photo uploaded successfully in Facebook.");
                        } else {
                            NSLog(@"Error posting photo to Facebook.");
                            error = [[NSError alloc] init];
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Error"
                                                                            message:@"Would you like to try again?"
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Cancel"
                                                                  otherButtonTitles:@"Retry", nil];
                            [alert show];
                        }
                        
                    }];
                }

            }];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to enumerate over assets library.");
    }];
    
    return error;
}

@end
