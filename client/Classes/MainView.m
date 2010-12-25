//
//  MainView.m
//  RealityCheck
//
//  Created by Lida Tang on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainView.h"


@implementation MainView


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
      imageLock = [[NSLock alloc] init];
    }
    return self;
}

- (void) setImage:(CGImageRef)image
{
  [imageLock lock];
  CGImageRelease(nextImageRef);
  nextImageRef = image;
  [imageLock unlock];
  [self performSelectorOnMainThread:@selector(setNeedsDisplay)
                         withObject:NULL
                      waitUntilDone:NO];  
}

static inline double radians (double degrees) {return degrees * M_PI/180;}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();  
	CGContextScaleCTM(context, 1.0, -1.0);  
  CGContextRotateCTM(context, radians(-90));
  [imageLock lock];
  if (nextImageRef)
  {
    CGImageRelease(imageRef);
    imageRef = nextImageRef;
    nextImageRef = nil;
  }
  CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef) ), imageRef);  
  [imageLock unlock];
}

- (void)dealloc {
    [super dealloc];
}


@end
