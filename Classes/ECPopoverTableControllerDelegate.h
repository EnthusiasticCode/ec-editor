//
//  CompletionListControllerDelegate.h
//  edit
//
//  Created by Uri Baghin on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

/*! \brief Protocol describing messages a ECPopoverTableController will send to it's delegate. */
@protocol ECPopoverTableControllerDelegate <NSObject>

@optional
/*! \brief Tells the delegate that a row with the specified text as label is now selected. */
- (void)popoverTableDidSelectRowWithText:(NSString *)string;
@end