//
//  ECCodeFixIt.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECCodeFixIt : NSObject
@property (nonatomic, readonly, copy) NSString *string;
@property (nonatomic, readonly, strong) NSURL *fileURL;
@property (nonatomic, readonly) NSRange replacementRange;

@end
