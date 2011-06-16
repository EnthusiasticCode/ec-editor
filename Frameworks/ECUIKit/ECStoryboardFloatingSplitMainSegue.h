//
//  ECStoryboardFloatingSplitMainSegue.h
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CATransition;

/// A storyboard segue that replaces the \c mainController of the \c sourceViewController's \c floatingSplitViewController with the \c destinationViewController.
@interface ECStoryboardFloatingSplitMainSegue : UIStoryboardSegue
/// An optional transition to animate the replacement.
@property (nonatomic, strong) CATransition *transition; 
@end
