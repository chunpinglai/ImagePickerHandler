//
//  QLPreviewHandler.m
//  TestTool
//
//  Created by AbbyLai on 2016/12/14.
//  Copyright © 2016年 AbbyLai. All rights reserved.
//

#import "QLPreviewHandler.h"
#import <Photos/Photos.h>

@implementation QLPreviewHandler

- (id)init {
    self = [super init];
    if (self) {
        _previewVC = [[QLPreviewController alloc] init];
        _previewVC.dataSource = self;
        _previewVC.delegate = self;
        _previewVC.currentPreviewItemIndex = 1;
    }
    
    return self;
}

- (void)showPreviewVC:(UIViewController *)currentVC {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
    [currentVC presentViewController:_previewVC animated:true completion:nil];
}

- (NSURL *)getFilePathAtIndex:(int)index {
    __block NSURL *fileURL = nil;
    if (_assetsArray.count < index) {
        return nil;
    }
    
    PHAsset *asset = [_assetsArray objectAtIndex:index];
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info)
         {
             if ([asset isKindOfClass:[AVURLAsset class]])
             {
                 fileURL = [(AVURLAsset*)asset URL];
                 dispatch_semaphore_signal(semaphore);
             }
         }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    else {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            fileURL = [info objectForKey:@"PHImageFileURLKey"];
        }];
    }
    return fileURL;
}

#pragma mark - QLPreviewController

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return _assetsArray.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [self getFilePathAtIndex:(int)index];
}

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

@end
