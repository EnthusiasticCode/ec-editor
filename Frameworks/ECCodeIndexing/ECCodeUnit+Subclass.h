//
//  ECCodeUnit+Subclass.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"
@class ECFileBuffer;

/// The base ECCodeUnit class does not provide any functionality other than initializing the values of index and fileURL.
/// Extensions of ECCodeIndex should return instances of subclasses of ECCodeUnit.
/// The subclasses can override any combination of methods.

@interface ECCodeUnit (Internal)

/// Designated initializer
- (id)initWithIndex:(ECCodeIndex *)index fileBuffer:(ECFileBuffer *)fileBuffer scope:(NSString *)scope;

@end