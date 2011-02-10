//
//  ECSourceLocation.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ECSourceLocation : NSObject {

}
@property (nonatomic, readonly) NSString *file;
@property (nonatomic, readonly) unsigned int line;
@property (nonatomic, readonly) unsigned int column;
@property (nonatomic, readonly) unsigned int offset;

- (id)initWithFile:(NSString *)file line:(unsigned int)line column:(unsigned int)column offset:(unsigned int)offset;
+ (id)locationWithFile:(NSString *)file line:(unsigned int)line column:(unsigned int)column offset:(unsigned int)offset;

@end
