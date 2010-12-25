//
//  MainViewController.h
//  RealityCheck
//
//  Created by Lida Tang on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
  AVCaptureSession *session;  
  AVCaptureStillImageOutput *stillImageOutput;
}

- (IBAction)showInfo:(id)sender;
- (void)setupCaptureSession;

@end
