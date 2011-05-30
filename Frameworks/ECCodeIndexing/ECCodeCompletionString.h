//
//  ECCodeCompletionString.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeCompletionChunk;

@interface ECCodeCompletionString : NSObject
@property (nonatomic, readonly, copy) NSArray *completionChunks;

- (id)initWithCompletionChunks:(NSArray *)completionChunks;
+ (id)stringWithCompletionChunks:(NSArray *)completionChunks;
- (NSString *)typedText;

@end
