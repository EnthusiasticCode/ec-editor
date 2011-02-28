//
//  ECSourceLocation.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ECSourceLocation : NSObject
@property (nonatomic, readonly) NSString *file;
@property (nonatomic, readonly) unsigned line;
@property (nonatomic, readonly) unsigned column;
@property (nonatomic, readonly) unsigned offset;

- (id)initWithFile:(NSString *)file line:(unsigned)line column:(unsigned)column offset:(unsigned)offset;
+ (id)locationWithFile:(NSString *)file line:(unsigned)line column:(unsigned)column offset:(unsigned)offset;

@end
