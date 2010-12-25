//
//  MainView.h
//  RealityCheck
//
//  Created by Lida Tang on 12/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainView : UIView {
  CGImageRef imageRef;
  CGImageRef nextImageRef;
  NSLock * imageLock;
}

- (void) setImage:(CGImageRef)image;

@end
