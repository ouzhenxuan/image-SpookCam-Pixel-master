//
//  ViewController.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ViewController.h"
#import "ImageProcessor.h"
#import "UIImage+OrientationFix.h"

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImageProcessorDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;

@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (strong, nonatomic) UIImage * workingImage;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - Custom Accessors

- (UIImagePickerController *)imagePickerController {
  if (!_imagePickerController) { /* Lazy Loading */
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.allowsEditing = NO;
    _imagePickerController.delegate = self;
  }
  return _imagePickerController;
}

#pragma mark - IBActions

- (IBAction)takePhotoFromCamera:(UIBarButtonItem *)sender {
  self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)takePhotoFromAlbum:(UIBarButtonItem *)sender {
  self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)savePhoto:(UIBarButtonItem *)sender {
    UIImage * image = [UIImage imageNamed:@"ghost"];
    CGImageRef inputCGImage = [image CGImage];
    NSUInteger width =                 CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    // 2.
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel *     width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 * pixels;
    pixels = (UInt32 *) calloc(height * width,     sizeof(UInt32));
    
    // 3.
    CGColorSpaceRef colorSpace =     CGColorSpaceCreateDeviceRGB();
    CGContextRef context =     CGBitmapContextCreate(pixels, width, height,     bitsPerComponent, bytesPerRow, colorSpace,     kCGImageAlphaPremultipliedLast |     kCGBitmapByteOrder32Big);
    
    // 4.
    CGContextDrawImage(context, CGRectMake(0,     0, width, height), inputCGImage);
    
    NSLog(@"Brightness of image:");
    // 2.
    UInt32 * currentPixel = pixels;
    for (NSUInteger j = 0; j < height; j++) {
        for (NSUInteger i = 0; i < width; i++) {
            // 3.
            UInt32 color = *currentPixel;
            printf("%3.0f ",     (R(color)+G(color)+B(color))/3.0);
            // 4.
            currentPixel++; 
        } 
        printf("\n"); 
    }
    
    
    // 5. Cleanup
    CGColorSpaceRelease(colorSpace); 
    CGContextRelease(context);
    
//  if (!self.workingImage) {
//    return;
//  }
//  UIImageWriteToSavedPhotosAlbum(self.workingImage, nil, nil, nil);
}

#pragma mark - Private

- (void)setupWithImage:(UIImage*)image {
  UIImage * fixedImage = [image imageWithFixedOrientation];
  self.workingImage = fixedImage;
  
  // Commence with processing!
  [ImageProcessor sharedProcessor].delegate = self;
  [[ImageProcessor sharedProcessor] processImage:fixedImage];
}

#pragma mark - Protocol Conformance

#pragma mark - ImageProcessorDelegate

- (void)imageProcessorFinishedProcessingWithImage:(UIImage *)outputImage {
  self.workingImage = outputImage;
  self.mainImageView.image = outputImage;
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  // Dismiss the imagepicker
  [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
  [self setupWithImage:info[UIImagePickerControllerOriginalImage]];
}

@end
