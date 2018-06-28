//
//  ViewController.m
//  CoreML
//
//  Created by yvan on 2018/6/25.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "ViewController.h"
#import <CoreML/CoreML.h>
#import "Inceptionv3.h"
#import <Photos/Photos.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (nonatomic, strong) Inceptionv3 *model;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.model  = [[Inceptionv3 alloc] init];
}

- (IBAction)selectImage:(UIButton *)sender {
    UIAlertController *action = [UIAlertController alertControllerWithTitle: @"读取图片" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle: @"取消" style:UIAlertActionStyleCancel handler:nil];
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    
    UIAlertAction *takePhotoAction = [UIAlertAction actionWithTitle: @"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authorizationStatus == AVAuthorizationStatusRestricted || authorizationStatus == AVAuthorizationStatusDenied) {
                NSLog(@"无拍照权限");
            } else {
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:imagePicker animated:YES completion:nil];
            }
        }
    }];
    
    UIAlertAction *choosePhoto = [UIAlertAction actionWithTitle: @"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
            if (authorizationStatus == PHAuthorizationStatusRestricted || authorizationStatus == PHAuthorizationStatusDenied) {
                NSLog(@"无相册权限");
            } else {
                imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                [self presentViewController:imagePicker animated:YES completion:nil];
            }
        }
    }];
    
    [action addAction:cancelAction];
    [action addAction:takePhotoAction];
    [action addAction:choosePhoto];
    [self presentViewController:action animated:YES completion:nil];
}

#pragma mark - UIImagePicker 代理

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        //得到一张299 * 299的图片
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(299, 299), true, [UIScreen mainScreen].scale);
        [image drawInRect:CGRectMake(0, 0, 299, 299)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        CVPixelBufferRef pxbuffer = NULL;
        pxbuffer = [self CVPixelBufferRefFromUiImage:newImage];
        self.photoImageView.image = newImage;

        NSError *error;
        Inceptionv3Output *output = [self.model predictionFromImage:pxbuffer error:&error];
        NSLog(@"%@,%@",output.classLabelProbs,error);
        if (error) {
            self.resultLabel.text = error.localizedDescription;
        }else{
            self.resultLabel.text = output.classLabel;
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

static OSType inputPixelFormat(){
    //注意CVPixelBufferCreate函数不支持 kCVPixelFormatType_32RGBA 等格式 不知道为什么。
    //支持kCVPixelFormatType_32ARGB和kCVPixelFormatType_32BGRA等 iPhone为小端对齐因此kCVPixelFormatType_32ARGB和kCVPixelFormatType_32BGRA都需要和kCGBitmapByteOrder32Little配合使用
    //注意当inputPixelFormat为kCVPixelFormatType_32BGRA时bitmapInfo不能是kCGImageAlphaNone，kCGImageAlphaLast，kCGImageAlphaFirst，kCGImageAlphaOnly。
    //注意iPhone的大小端对齐方式为小段对齐 可以使用宏 kCGBitmapByteOrder32Host 来解决大小端对齐 大小端对齐必须设置为kCGBitmapByteOrder32Little。
    //return kCVPixelFormatType_32RGBA;//iPhone不支持此输入格式!!!
//    return kCVPixelFormatType_32BGRA;
    return kCVPixelFormatType_32ARGB;
}


static uint32_t bitmapInfoWithPixelFormatType(OSType inputPixelFormat){
    /*
     CGBitmapInfo的设置
     uint32_t bitmapInfo = CGImageAlphaInfo | CGBitmapInfo;
     
     当inputPixelFormat=kCVPixelFormatType_32BGRA CGBitmapInfo的正确的设置 只有如下两种正确设置
     uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
     uint32_t bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
     
     typedef CF_ENUM(uint32_t, CGImageAlphaInfo) {
     kCGImageAlphaNone,                For example, RGB.
     kCGImageAlphaPremultipliedLast,   For example, premultiplied RGBA
     kCGImageAlphaPremultipliedFirst,  For example, premultiplied ARGB
     kCGImageAlphaLast,                For example, non-premultiplied RGBA
     kCGImageAlphaFirst,               For example, non-premultiplied ARGB
     kCGImageAlphaNoneSkipLast,        For example, RBGX.
     kCGImageAlphaNoneSkipFirst,       For example, XRGB.
     kCGImageAlphaOnly                 No color data, alpha data only
     };
     
     当inputPixelFormat=kCVPixelFormatType_32ARGB CGBitmapInfo的正确的设置 只有如下两种正确设置
     uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
     uint32_t bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big;
     */
    if (inputPixelFormat == kCVPixelFormatType_32BGRA) {
        //uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
        //此格式也可以
        uint32_t bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
        return bitmapInfo;
    }else if (inputPixelFormat == kCVPixelFormatType_32ARGB){
//        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
        //此格式也可以
        uint32_t bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big;
        return bitmapInfo;
    }else{
        NSLog(@"不支持此格式");
        return 0;
    }
}

/** UIImage covert to CVPixelBufferRef */
//方法1 此方法能还原真实的图片
- (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img {
    CGSize size = img.size;
    CGImageRef image = [img CGImage];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, inputPixelFormat(), (__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    //CGBitmapInfo的设置
    //uint32_t bitmapInfo = CGImageAlphaInfo | CGBitmapInfo;
    
    //当inputPixelFormat=kCVPixelFormatType_32BGRA CGBitmapInfo的正确的设置
    //uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
    //uint32_t bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
    
    //当inputPixelFormat=kCVPixelFormatType_32ARGB CGBitmapInfo的正确的设置
    //uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
    //uint32_t bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big;
    
    uint32_t bitmapInfo = bitmapInfoWithPixelFormatType(inputPixelFormat());
    
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, bitmapInfo);
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    return pxbuffer;
}
@end
