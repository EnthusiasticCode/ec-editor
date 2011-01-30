//
//  ECCompletionChunk.h
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ECCompletionChunk : NSObject {

}
@property (nonatomic, readonly) int kind;
@property (nonatomic, readonly) NSString *string;

- (id)initWithKind:(int)kind string:(NSString *)string;
- (id)initWithString:(NSString *)string;

@end
