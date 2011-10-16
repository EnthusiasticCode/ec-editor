//
//  ECCodeCompletionString.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeScope.h"

@protocol ECCodeCompletion <ECCodeScope>

@property (nonatomic, readonly, copy) NSString *completionTypedText;

@end
