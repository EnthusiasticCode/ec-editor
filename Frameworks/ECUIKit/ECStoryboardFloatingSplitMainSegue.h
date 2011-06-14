//
//  ECStoryboardFloatingSplitMainSegue.h
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CATransition;

@interface ECStoryboardFloatingSplitMainSegue : UIStoryboardSegue
@property (nonatomic, strong) CATransition *transition; 
@end
