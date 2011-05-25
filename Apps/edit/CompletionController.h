//
//  CompletionController.h
//  edit
//
//  Created by Uri Baghin on 5/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECPatriciaTrie;
@class ECCodeCompletionResult;

@interface CompletionController : UITableViewController
@property (nonatomic, retain) NSString *match;
@property (nonatomic, retain) ECPatriciaTrie *results;
@property (nonatomic, copy) void(^resultSelectedBlock)(ECCodeCompletionResult *result);
@end
