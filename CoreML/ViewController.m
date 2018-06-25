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

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (nonatomic, strong) Inceptionv3 *model;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.model  = [[Inceptionv3 alloc] init];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectImage:(UIButton *)sender {
    UIAlertController *action = [UIAlertController alertControllerWithTitle: @"读取图片" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle: @"取消" style:UIAlertActionStyleCancel handler:nil];
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    
    UIAlertAction *takePhotoAction = [UIAlertAction actionWithTitle: @"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }];
    
    UIAlertAction *choosePhoto = [UIAlertAction actionWithTitle: @"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePicker animated:YES completion:nil];
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
        UIImage *newImage = image;//[image zy_resizeImageFitSize:CGSizeMake(800, 800)];
        NSData *data = UIImageJPEGRepresentation(newImage, 0.7);
        self.photoImageView.image = newImage;
        NSString *DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:@"/image.png"] contents:data attributes:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
