//
//  ECCompletionString.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCompletionChunk;
/*! Object representing any possible completion. */
@interface ECCompletionString : NSObject {
    
}
@property (nonatomic,readonly,copy) NSArray *completionChunks;

- (id)initWithCompletionChunks:(NSArray *)completionChunks;

+ (id)stringWithCompletionChunks:(NSArray *)completionChunks;

- (ECCompletionChunk *)firstChunkWithKind:(int)kind;
- (ECCompletionChunk *)firstChunk;

@end
