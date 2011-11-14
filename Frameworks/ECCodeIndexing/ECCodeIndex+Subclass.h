//
//  ECCodeIndex+Subclass.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"

/// ECCodeIndex extensions can be implemented as subclasses.
/// There is no need to override the inherited implementations of either the public methods or the internal methods, however the subclass methods must be overridden.

@interface ECCodeIndex (Internal)

/// Registers a subclass as an extension of ECCodeIndex
/// All extensions should call this method in their +load method.
+ (void)registerExtension:(Class)extensionClass;

@end

@interface ECCodeIndex (Subclass)

/// Return a number in range [0.0, 1.0[ depending on how well the code index supports a given scope
/// Return 0.0 if the scope is not supported at all. Never return 1.0.
- (float)supportForScope:(NSString *)scope;

/// Return a code unit for the given fileURL initialized with the given index and scope
- (ECCodeUnit *)codeUnitWithIndex:(ECCodeIndex *)index forFileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer scope:(NSString *)scope;

@end
