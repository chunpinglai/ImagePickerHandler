//
//  ImagePickerHandler.m
//  TestTool
//
//  Created by Abby Lai on 1/27/16.
//  Copyright © 2016 Abby Lai. All rights reserved.
//

#import "ImagePickerHandler.h"
#import <AVFoundation/AVFoundation.h> //detect mic phone
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

static int const defulatUploadVideoMaxLength = 15;
static NSString * const displayString_uploadImageFileLimitMax = @"Can not upload more image.";
static NSString * const displayString_uploadVideoFileLimitMax = @"Can not upload more video.";
static NSString * const AlertViewOKBtnString = @"OK";
static NSString * const AlertViewCancelBtnString = @"Cancel";
static NSString * const displayString_SelectedOverLimit = @"Please don't select more than %d media";
static NSString * const displayString_NoPermission_Camera = @"Please check the permission of camera.";
static NSString * const displayString_NoPermission_Photos = @"Please check the permission of photos access.";

@interface ImagePickerHandler()<CTAssetsPickerControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>  {
    UIImagePickerController *camera;
    NSDictionary *previousNavigationText;
}
@property (nonatomic, assign) int selectedImageCount;
@property (nonatomic, assign) int selectedVideoCount;
@end

@implementation ImagePickerHandler

- (IBAction)showActionSheetInView:(UIView *)view {
    
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:nil
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* button0 = [UIAlertAction
                              actionWithTitle:@"Cancel"
                              style:UIAlertActionStyleCancel
                              handler:^(UIAlertAction * action) {
                                  //  UIAlertController will automatically dismiss the view
                              }];
    
    UIAlertAction* button1 = [UIAlertAction
                              actionWithTitle:@"Camera"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action) {
                                  [self createCamera];
                              }];
    
    UIAlertAction* button2 = [UIAlertAction
                              actionWithTitle:@"Gallery"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action) {
                                  [self startAction:nil];
                              }];
    
    alert.popoverPresentationController.permittedArrowDirections = 0;
    alert.popoverPresentationController.sourceView = _vc.view;
    alert.popoverPresentationController.sourceRect = _vc.view.frame;
    
    [alert addAction:button0];
    [alert addAction:button1];
    [alert addAction:button2];
    [_vc presentViewController:alert animated:YES completion:nil];
}

- (IBAction)showCamera {
    [self createCamera];
}

- (IBAction)chooseFromGallery {
    [self startAction:nil];
}

#pragma mark - camera

- (void)createCamera {
    //依據限制數量，設定是否能夠上傳、選取
    self.selectedImageCount=0;
    self.selectedVideoCount=0;
    
    for (int i=0; i<[_assets count]; i++) {
        PHAsset *assetResult = [_assets objectAtIndex:i];
        if ([self checkIsVideo:assetResult]) {
            self.selectedVideoCount += 1;
        }
        else{
            self.selectedImageCount += 1;
        }
    }
    
    BOOL isSupportVideo = (_maxNumberOfVideos > 0) ? YES : NO;
    
    if ( self.selectedImageCount >= _maxNumberOfImages ) {
        NSLog(displayString_uploadImageFileLimitMax);
        return;
    } else if (( self.selectedVideoCount >= _maxNumberOfVideos ) && isSupportVideo) {
        NSLog(displayString_uploadVideoFileLimitMax);
        return;
    } else if (self.selectedImageCount + self.selectedVideoCount >= _mediaSelectLimit) {
        NSString *message = [NSString stringWithFormat:displayString_SelectedOverLimit, _mediaSelectLimit];
        NSLog(message);
        return;
    }
    
    [self checkCameraPermissionWithMediaType:AVMediaTypeVideo completionHandler:^(BOOL isSuccessful) {
        if (isSuccessful) {
        camera = [[UIImagePickerController alloc] init];
        camera.delegate = self;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            camera.sourceType=UIImagePickerControllerSourceTypeCamera;
            
            if (isSupportVideo) {
                NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:camera.sourceType];
                camera.mediaTypes = mediaTypes;
                [camera setVideoQuality:UIImagePickerControllerQualityTypeMedium];  //設定影片品質
                int maxLength = _uploadVideoMaxLength ? _uploadVideoMaxLength : defulatUploadVideoMaxLength;
                [camera setVideoMaximumDuration:maxLength];  //設定最大錄影時間(秒)
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(detectMicphone:)];
                [camera.view addGestureRecognizer:tap];
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                [_vc presentViewController:camera animated:YES completion:nil];
            });
        }
        } else {
            NSLog(displayString_NoPermission_Camera);
        }
    }];
}

-(void)detectMicphone:(id)sender {
    //show warning label when mic phone is turn off
    
    if ([camera startVideoCapture]) {
        NSLog(@"Video capturing started...");
        //判斷有沒有開
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (granted) {
                    NSLog(@"can use audio");
                } else {
                    NSLog(@"not allow audio");
                    UILabel *lbWarning = [[UILabel alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 80, [UIScreen mainScreen].bounds.size.width, 80)];
                    lbWarning.backgroundColor = [UIColor blackColor];
                    lbWarning.text = @"Please turn on microphone.";
                    lbWarning.textAlignment = NSTextAlignmentCenter;
                    lbWarning.textColor = [UIColor whiteColor];
                    lbWarning.alpha = 0.8;
                    [camera.view addSubview:lbWarning];
                    [UIView animateWithDuration:2 animations:^(void){
                        lbWarning.alpha = 0.6;
                    } completion:^(BOOL finished){
                        [lbWarning removeFromSuperview];
                    }];
                }
            }];
        }
    } else {
        NSLog(@"Video STOP");
    }
}

#pragma mark- imagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.movie"]) {  //來源為影片
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        __block NSString *assetId = nil;
        __block PHObjectPlaceholder *placeholder;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
            placeholder = [createAssetRequest placeholderForCreatedAsset];
            assetId = placeholder.localIdentifier;
        } completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                if (assetId) {
                    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                    [self saveToAssets:asset];
                }
            }
            else {
                NSLog(@"%@", error);
            }
        }];
    } else if ([mediaType isEqualToString:@"public.image"]) {  //來源為圖片
        
        [self checkPhotosPermissionWithCompletionHandler:^(BOOL isSuccess) {
            if (isSuccess) {
                //save image to camera roll
                UIImage *img = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
                if ([PHAssetCreationRequest respondsToSelector:@selector(creationRequestForAssetFromImage:)]) {
                    [self saveImageIOS9:img];
                }
                else {
                    [self saveImageIOS8:img];
                }
            } else {
                NSLog(displayString_NoPermission_Photos);
            }
        }];
    }
    
    [_vc dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [_vc dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - picker CTAssetsPickerController

- (IBAction)startAction:(id)sender {
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    //picker.assetsFilter         = nil;[ALAssetsFilter allAssets];
    //    picker.showsCancelButton    = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
    picker.showsCancelButton    = YES;
    picker.delegate             = self;//_vc
    picker.selectedAssets       = [NSMutableArray arrayWithArray:self.assets];
    picker.showsSelectionIndex = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        picker.modalPresentationStyle = UIModalPresentationFormSheet;
    
    previousNavigationText = [UINavigationBar appearance].titleTextAttributes;
    [[UINavigationBar appearance]setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [_vc presentViewController:picker animated:YES completion:nil];
    });
}

#pragma mark - Assets Picker Delegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [[UINavigationBar appearance]setTitleTextAttributes:previousNavigationText];
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.assets = [NSMutableArray arrayWithArray:assets];
    if(_imagePickerDelegate != nil && [_imagePickerDelegate respondsToSelector:@selector(photoSelected:)]) {
        [_imagePickerDelegate photoSelected:assets];
    }
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldEnableAsset:(PHAsset *)asset {
    //    if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo]) {
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        
        BOOL isSupportVideo = (_maxNumberOfVideos > 0) ? YES : NO;
        if (isSupportVideo) {
            NSTimeInterval duration = asset.duration;
            int maxLength = _uploadVideoMaxLength ? _uploadVideoMaxLength : defulatUploadVideoMaxLength;
            return lround(duration) < maxLength;
        } else {
            return NO;
        }
    } else { //image
        BOOL isSupportImage = (_maxNumberOfImages > 0) ? YES : NO;
        return isSupportImage;
    }
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(PHAsset *)asset
{
    BOOL isOverLimit = [self checkMediaLimit:picker.selectedAssets andNowSelect:asset];
    
    return (!isOverLimit);
}

#pragma mark

- (UIImage *)generateThumbImage:(NSString *)filepath {
    NSURL *url = [NSURL fileURLWithPath:filepath];
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    CMTime time = [asset duration];
    time.value = 0; //capture image time
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    if (thumbnail == NULL){
        thumbnail = [[UIImage alloc]init];
    }
    
    return thumbnail;
}

- (BOOL)checkIsVideo:(PHAsset *)asset {
    return (asset.mediaType == PHAssetMediaTypeVideo);
}

- (BOOL)checkMediaLimit:(NSArray *)assets andNowSelect:(PHAsset *)asset{
    
    BOOL isOverLimit = NO;
    
    self.selectedImageCount=0;
    self.selectedVideoCount=0;
    
    for (int i=0; i<[assets count]; i++) {
        PHAsset *assetResult = [assets objectAtIndex:i];
        if ([self checkIsVideo:assetResult]) {
            self.selectedVideoCount += 1;
        }
        else{
            self.selectedImageCount += 1;
        }
    }
    
    if ( ![self checkIsVideo:asset] && (self.selectedImageCount >= _maxNumberOfImages || self.selectedImageCount + self.selectedVideoCount >= _mediaSelectLimit) ) {
        isOverLimit = YES;
        NSString *message;
        message = [NSString stringWithFormat:displayString_uploadImageFileLimitMax];
        NSLog(message);
    }
    if ( [self checkIsVideo:asset] && (self.selectedVideoCount >= _maxNumberOfVideos || self.selectedImageCount + self.selectedVideoCount >= _mediaSelectLimit) ) {
        isOverLimit = YES;
        NSString *message;
        message = [NSString stringWithFormat:displayString_uploadVideoFileLimitMax];
        NSLog(message);
    }
    
    return isOverLimit;
}

#pragma mark - save

- (void)saveToAssets:(PHAsset *)asset {
    if (asset) {
        NSArray *old = nil;
        old = [[NSArray alloc]initWithArray:self.assets];
        NSMutableArray *new = [[NSMutableArray alloc]initWithArray:old];
        [new addObject:asset];
        self.assets = [NSMutableArray arrayWithArray:new];
    }
    
    if(_imagePickerDelegate != nil && [_imagePickerDelegate respondsToSelector:@selector(photoSelected:)]) {
        [_imagePickerDelegate photoSelected:self.assets];
    }
}

- (void)saveImageIOS8:(UIImage *)img {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:[img CGImage] orientation:(ALAssetOrientation)[img imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"error");
        } else {
            [self saveURLToAssets:assetURL library:library];
        }
    }];
}

- (void)saveURLToAssets:(NSURL*)assetURL library:(ALAssetsLibrary *)library {
    [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        [self saveToAssets:asset];
    } failureBlock:^(NSError* error) {
        NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
    }];
}

- (void)saveImageIOS9:(UIImage *)img {
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //ios9
//        id imgRequest = [PHAssetCreationRequest creationRequestForAssetFromImage:img];
        assetId = [PHAssetCreationRequest creationRequestForAssetFromImage:img].placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            NSLog(error.description);
        } else {
            PHAsset *asset = nil;
            if (assetId) {
                asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
            }
            [self saveToAssets:asset];
        }
    }];
}


#pragma mark - selected Image

- (UIImage *)grabImageFromAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    __block UIImage *returnImage;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:targetSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:
     ^(UIImage *result, NSDictionary *info) {
         returnImage = result;
     }];
    return returnImage;
}

- (void)changeImageContentByAsset:(PHAsset *)assetResult imageView:(UIImageView *)imageView {
    PHImageManager *manager = PHImageManager.defaultManager;
    //targetSize:PHImageManagerMaximumSize
    [manager requestImageForAsset:assetResult targetSize:CGSizeMake(imageView.frame.size.width, imageView.frame.size.height) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage *result, NSDictionary *info){
        imageView.image = result;
    }];
}

#pragma mark - check permission

- (void)checkCameraPermissionWithMediaType:(NSString *)mediaType completionHandler:(void (^)(BOOL isSuccessful))completionBlock {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        // do your logic
        if (completionBlock) {
            completionBlock(YES);
        }
    } else if(authStatus == AVAuthorizationStatusDenied){
        // denied
        if (completionBlock) {
            completionBlock(NO);
        }
    } else if(authStatus == AVAuthorizationStatusRestricted){
        // restricted, normally won't happen
        if (completionBlock) {
            completionBlock(NO);
        }
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if(granted){
                NSLog(@"Granted access to %@", mediaType);
                if (completionBlock) {
                    completionBlock(YES);
                }
            } else {
                NSLog(@"Not granted access to %@", mediaType);
                if (completionBlock) {
                    completionBlock(NO);
                }
            }
        }];
    } else {
        // impossible, unknown authorization status
        if (completionBlock) {
            completionBlock(NO);
        }
    }
}

- (void)checkPhotosPermissionWithCompletionHandler:(void (^)(BOOL isSuccessful))completionBlock {
    //Check Photos Access allowed or not
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        if (completionBlock) {
            completionBlock(YES);
        }
    }
    else if (status == PHAuthorizationStatusDenied) {
        // Access has been denied.
        if (completionBlock) {
            completionBlock(NO);
        }
    }
    else if (status == PHAuthorizationStatusNotDetermined) {
        // Access has not been determined.
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                if (completionBlock) {
                    completionBlock(YES);
                }
            }
            else {
                if (completionBlock) {
                    completionBlock(NO);
                }
            }
        }];
    }
    else if (status == PHAuthorizationStatusRestricted) {
        // Restricted access - normally won't happen.
        if (completionBlock) {
            completionBlock(NO);
        }
    } else {
        if (completionBlock) {
            completionBlock(NO);
        }
    }
}

@end
