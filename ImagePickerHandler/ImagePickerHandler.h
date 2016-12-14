//
//  ImagePickerHandler.h
//  TestTool
//
//  Created by Abby Lai on 1/27/16.
//  Copyright © 2016 Abby Lai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CTAssetsPickerController.h>

@protocol ImagePickerHandlerDelegate;

@interface ImagePickerHandler : NSObject
@property (nonatomic, assign) UIViewController *vc;
@property (nonatomic, copy) NSMutableArray *assets;
@property (nonatomic, assign) int mediaSelectLimit;
@property (nonatomic, assign) int maxNumberOfImages;
@property (nonatomic, assign) int maxNumberOfVideos;
@property (nonatomic, assign) int uploadVideoMaxLength;
@property (nonatomic, assign) NSObject <ImagePickerHandlerDelegate> *imagePickerDelegate;

- (IBAction)showActionSheetInView:(UIView *)view;
- (IBAction)showCamera;
- (IBAction)chooseFromGallery;

/*
 * After photoSelected, you can use the method as below to display the image by PHAsset.
 */
//You can use targetSize:PHImageManagerMaximumSize to get the maximumSize image
- (UIImage *)grabImageFromAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;
//imageView will change image content from asset with original imageView size
- (void)changeImageContentByAsset:(PHAsset *)assetResult imageView:(UIImageView *)imageView;

/*
 * Check Photos/Camera permission, if AuthorizationStatusNotDetermined, send requestAuthorization to user.
 */
- (void)checkPhotosPermissionWithCompletionHandler:(void (^)(BOOL isSuccessful))completionBlock;
- (void)checkCameraPermissionWithMediaType:(NSString *)mediaType completionHandler:(void (^)(BOOL isSuccessful))completionBlock;
@end


@protocol ImagePickerHandlerDelegate
@optional
/*
 *  Tells the delegate that the user finish picking photos or videos.
 *  @param assets An array containing picked `PHAsset` objects.
 *
 *  Use:PHAsset *assetResult = [assets objectAtIndex:x];
 */
- (void)photoSelected:(NSArray *)assets;
@end
