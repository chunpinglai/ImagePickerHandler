# ImagePickerHandler
ImagePickerHandler helps you to choose pictures from camera roll, and show camera, also can preview media data.

## INSTALL
- Drag ImagePickerHandler.h & ImagePickerHandler.m
- pod 'CTAssetsPickerController', '~> 3.3.1'

## INTERFACE

```
@property (nonatomic, assign) int mediaSelectLimit;
@property (nonatomic, assign) int maxNumberOfImages;
@property (nonatomic, assign) int maxNumberOfVideos;
@property (nonatomic, assign) int uploadVideoMaxLength;

- (IBAction)showActionSheetInView:(UIView *)view;
- (IBAction)showCamera;
- (IBAction)chooseFromGallery;
```

###ImagePickerHandlerDelegate 
ImagePickerHandlerDelegate returns the media data user selected.

@param assets An array containing picked `PHAsset` objects.
 
```
- (void)photoSelected:(NSArray *)assets;
```

Use:

```
PHAsset *assetResult = [assets objectAtIndex:i];
```


## USAGE
```
    #import "ImagePickerHandler.h"
    
    if (!_imagePicker) {
        _imagePicker = [[ImagePickerHandler alloc]init];
        _imagePicker.imagePickerDelegate = self;
        _imagePicker.vc = self;
        _imagePicker.maxNumberOfImages = 5;
        _imagePicker.maxNumberOfVideos = 1;
        _imagePicker.uploadVideoMaxLength = 15;
        _imagePicker.mediaSelectLimit = _imagePicker.maxNumberOfImages + _imagePicker.maxNumberOfVideos;
    }
    [_imagePicker showActionSheetInView:self.view];
```

### QLPreviewHandler
Use QuickLook.framework to preview PHAsset media data.

## USAGE

```
#import <QuickLook/QuickLook.h>

QLPreview = [[QLPreviewHandler alloc]init];
QLPreview.assetsArray = assets;
[QLPreview showPreviewVC:self];
```