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

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) NSArray *buttons;
@property int selectedButton;

@end

@implementation ImageLoaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buttons = @[self.firstImageBtn, self.secondImageBtn, self.thirdImageBtn, self.fourthImageBtn];
    self.selectedButton = 0;
    
    [self loadImages];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"OfferUp"]) {
            [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, group.numberOfAssets)] options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (index <= (self.buttons.count - 1)) {
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
                        }
                        
                    }];
                }
            }];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to enumerate over assets library.");
    }];
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

            UIImage *thumbnail = [[UIImage alloc] initWithData:UIImageJPEGRepresentation(originalImage, 1.0)];
            [self.buttons[self.selectedButton] setBackgroundImage:thumbnail forState:UIControlStateNormal];
            
            self.selectedButton++;
            if ((self.buttons.count - 1) >= self.selectedButton) {
                [self.buttons[self.selectedButton] setEnabled:YES];
            }
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addNewAssetWithImage:(UIImage *)image toAlbum:(NSString *)album
{
    if ([PHPhotoLibrary respondsToSelector:@selector(sharedPhotoLibrary)]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            // Fetch album
            PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
            
            __block PHAssetCollection *assetCollection = nil;
            
            [fetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop) {
                if ([obj.localizedTitle isEqualToString:album]) {
                    assetCollection = obj;
                    *stop = YES;
                }
            }];
            
            PHAssetCollectionChangeRequest *albumChangeRequest;

            if (assetCollection) {
                // Request editing the album.
                albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
            } else {
                // Request new album if not present
                albumChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:album];
            }
            // remove asset of one exists
            if (assetCollection.estimatedAssetCount > self.selectedButton) {
                [albumChangeRequest removeAssetsAtIndexes:[NSIndexSet indexSetWithIndex:self.selectedButton]];
            }
            
            // Request creating an asset from the image.
            PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            
            // Get a placeholder for the new asset and add it to the album editing request.
            PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
            
            [self.uploadBtn setEnabled:YES];
            
        } completionHandler:^(BOOL success, NSError *error) {
            NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
        }];
    } else {
        __block ALAssetsGroup *groupAlbum = nil;
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:album]) {
                groupAlbum = group;
                *stop = YES;
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"Failed to enumerate over assets library.");
        }];
        
        if (groupAlbum) {
            ALAsset *asset = [[ALAsset alloc] init];
            [asset setImageData:UIImagePNGRepresentation(image) metadata:nil completionBlock:nil];
            [groupAlbum addAsset:asset];
            
            [self.uploadBtn setEnabled:YES];
            
        } else {
            [assetsLibrary addAssetsGroupAlbumWithName:album resultBlock:^(ALAssetsGroup *group) {
                
                ALAsset *asset = [[ALAsset alloc] init];
                [asset setImageData:UIImagePNGRepresentation(image) metadata:nil completionBlock:nil];
                [group addAsset:asset];
                
                [self.uploadBtn setEnabled:YES];
                
            } failureBlock:^(NSError *error) {
                NSLog(@"Failed to create album");
            }];
        }
    }
}

#pragma mark - Private methods

-(UIImagePickerController *)imagePickerController {
    if (self.imagePicker) {
        return self.imagePicker;
    } else {
        self.imagePicker = [[UIImagePickerController alloc] init];
        return  self.imagePicker;
    }
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
    ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"OfferUp"]) {
            [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, group.numberOfAssets)] options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                    if (index <= (self.buttons.count - 1)) {
                        [self.buttons[index] setBackgroundImage:[UIImage imageWithCGImage:result.thumbnail] forState:UIControlStateNormal];
                        [self.buttons[index] setEnabled:YES];
                        
                        if (index <= (self.buttons.count - 2)) {
                            [self.buttons[index + 1] setEnabled:YES];
                        }
                        
                        self.selectedButton++;
                    }
            }];
            [self.uploadBtn setEnabled:YES];
            [self.view updateConstraints];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed to enumerate over assets library.");
    }];
}

@end
