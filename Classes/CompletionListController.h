//
//  CompletionListController.h
//  edit
//
//  Created by Uri Baghin on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CompletionListControllerDelegate <NSObject>

- (void)completeWithString:(NSString *)string;

@end

@interface CompletionListController : UITableViewController{
    NSArray *_resultsList;
}
@property (nonatomic,retain) NSArray *resultsList;
@property (nonatomic,assign) id <CompletionListControllerDelegate> delegate;

@end
