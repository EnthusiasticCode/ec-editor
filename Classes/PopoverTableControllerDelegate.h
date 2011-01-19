//
//  CompletionListControllerDelegate.h
//  edit
//
//  Created by Uri Baghin on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

/*! \brief Protocol describing methods a PopoverTableController must implement. */
@protocol PopoverTableControllerDelegate <NSObject>

/*! \brief Tells the delegate to execute the completion with the specified string. */
- (void)completeWithString:(NSString *)string;

@end