//
//  QLPreviewHandler.h
//  TestTool
//
//  Created by AbbyLai on 2016/12/14.
//  Copyright © 2016年 AbbyLai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

@interface QLPreviewHandler : NSObject <QLPreviewControllerDataSource,QLPreviewControllerDelegate>
@property (nonatomic, strong) NSArray *assetsArray;
@property (nonatomic, strong) QLPreviewController *previewVC;
- (void)showPreviewVC:(UIViewController *)currentVC;
@end
