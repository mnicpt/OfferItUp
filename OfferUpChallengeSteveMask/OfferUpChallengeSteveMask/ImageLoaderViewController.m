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

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) NSArray *buttons;
@property int selectedButton;

@end

@implementation ImageLoaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buttons = @[self.firstImageBtn, self.secondImageBtn, self.thirdImageBtn, self.fourthImageBtn];
    self.selectedButton = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}


#pragma mark - Actions

- (IBAction)loadImage:(UIButton *)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Choose image capture option" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *photoLibraryAction = [UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [self pickPhotoFromLibrary];
    }];
    UIAlertAction *takePictureAction = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
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
            [self.buttons[self.selectedButton] setEnabled:YES];
            
            if ((self.buttons.count - 1) <= self.selectedButton + 1) {
                [self.buttons[self.selectedButton + 1] setBackgroundImage:[UIImage imageNamed:@"icon_ImageBox" ]];
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

            // Request creating an asset from the image.
            PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            
            // Get a placeholder for the new asset and add it to the album editing request.
            PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
            
        } completionHandler:^(BOOL success, NSError *error) {
            NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
        }];
    } else {
        ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            
        }];
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
        // sorry you deleted your Photos app
    }
}

@end
