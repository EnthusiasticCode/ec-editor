//
//  InstantGestureRecognizer.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Trivial gesture recognizer that recognize any touch immediatly without 
/// canceling it.
@interface InstantGestureRecognizer : UIGestureRecognizer

@property (nonatomic, copy) NSArray *passTroughViews;

@end
