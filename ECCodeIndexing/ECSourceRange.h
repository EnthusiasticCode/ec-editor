//
//  ECSourceRange.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECSourceLocation;

@interface ECSourceRange : NSObject {

}
@property (nonatomic, readonly) ECSourceLocation *start;
@property (nonatomic, readonly) ECSourceLocation *end;

- (id)initWithStart:(ECSourceLocation *)start end:(ECSourceLocation *)end;
+ (id)rangeWithStart:(ECSourceLocation *)start end:(ECSourceLocation *)end;

@end
