//
//  MainViewController.m
//  RealityCheck
//
//  Created by Lida Tang on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
@implementation MainViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self capturePhoto];
}


- (void)setupCaptureSession 
{
  NSError *error = nil;
  
  // Create the session
  session = [[AVCaptureSession alloc] init];
  
  // Configure the session to produce lower resolution video frames, if your 
  // processing algorithm can cope. We'll specify medium quality for the
  // chosen device.
  session.sessionPreset = AVCaptureSessionPresetMedium;
  
  // Find a suitable AVCaptureDevice
  AVCaptureDevice *device = [AVCaptureDevice
                             defaultDeviceWithMediaType:AVMediaTypeVideo];
  
  // Create a device input with the device and add it to the session.
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
                                                                      error:&error];
  if (!input) {
    // Handling the error appropriately.
  }
  [session addInput:input];
  /*
  // Create a VideoDataOutput and add it to the session
  AVCaptureVideoDataOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
  [session addOutput:output];
  
  // Configure your output.
  dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
  [output setSampleBufferDelegate:self queue:queue];
  dispatch_release(queue);
  
  // Specify the pixel format
  output.videoSettings = 
  [NSDictionary dictionaryWithObject:
   [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                              forKey:(id)kCVPixelBufferPixelFormatTypeKey];

  output.alwaysDiscardsLateVideoFrames = TRUE;
  
  // If you wish to cap the frame rate to a known value, such as 15 fps, set 
  // minFrameDuration.
  output.minFrameDuration = CMTimeMake(1, 15);
  */
  stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
  [session addOutput:stillImageOutput];
  
  stillImageOutput.outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  AVVideoCodecJPEG, AVVideoCodecKey, nil];

  // Start the session running to start the flow of data
  [session startRunning];  

}


- (void)postPhoto: (NSData *)imageData
{
  NSString *boundary = @"----FOO";
  NSString *host = @"http://192.168.0.122:8080/";
  NSURL *url = [NSURL URLWithString:host];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
  [req setHTTPMethod:@"POST"];
  
  
  NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", boundary];
  [req setValue:contentType forHTTPHeaderField:@"Content-type"];
    
  //adding the body:
  NSMutableData *postBody = [NSMutableData data];
  [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[@"Content-Disposition: form-data; name=\"some_name\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[@"some_value" dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[@"Content-Disposition: form-data; name=\"image_file\"; filename=\"test.jpeg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:imageData];
  [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[@"Content-Disposition: form-data; name=\"some_other_name\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[@"some_other_value" dataUsingEncoding:NSUTF8StringEncoding]];
  [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [req setHTTPBody:postBody];
  [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];     
  /*
  [self performSelectorOnMainThread:@selector(capturePhoto)
                         withObject:NULL
                      waitUntilDone:NO];  
   */
}

- (void)capturePhoto
{
  AVCaptureConnection *videoConnection = nil;
  for (AVCaptureConnection *connection in stillImageOutput.connections) {
    for (AVCaptureInputPort *port in [connection inputPorts]) {
      if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
        videoConnection = connection;
        break;
      }
    }
    if (videoConnection) { break; }
  }
  
  void (^block)(CMSampleBufferRef imageDataSampleBuffer, NSError *error);
  block = ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
    NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
    [self postPhoto:data];    
  };
  
  [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:block];
}


// Create a UIImage from sample buffer data
- (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer 
{
  // Get a CMSampleBuffer's Core Video image buffer for the media data
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
  // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0); 
  
  // Get the number of bytes per row for the pixel buffer
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
  
  // Get the number of bytes per row for the pixel buffer
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
  // Get the pixel buffer width and height
  size_t width = CVPixelBufferGetWidth(imageBuffer); 
  size_t height = CVPixelBufferGetHeight(imageBuffer); 
  
  // Create a device-dependent RGB color space
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
  
  // Create a bitmap graphics context with the sample buffer data
  CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, 
                                               bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
  // Create a Quartz image from the pixel data in the bitmap graphics context
  CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
  // Unlock the pixel buffer
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
  
  // Free up the context and color space
  CGContextRelease(context); 
  CGColorSpaceRelease(colorSpace);
  
  return (quartzImage);
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection
{ 
  // Create a UIImage from the sample buffer data
  [self.view setImage:[self imageFromSampleBuffer:sampleBuffer]];
  
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)dealloc {
    [super dealloc];
}


@end
