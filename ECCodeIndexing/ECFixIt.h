//
//  ECFixIt.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECSourceRange;

@interface ECFixIt : NSObject {

}
@property (nonatomic, readonly, retain) NSString *string;
@property (nonatomic, readonly, retain) ECSourceRange *replacementRange;

- (id)initWithString:(NSString *)string replacementRange:(ECSourceRange *)replacementRange;
+ (id)fixItWithString:(NSString *)string replacementRange:(ECSourceRange *)replacementRange;

@end
