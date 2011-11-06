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

/// Returns the contents of a file, either by reading it from disk or from a buffer.
/// Returns nil if the file does not exist or is not a valid source file.
/// All accesses to files must be done using this method
- (NSString *)contentsForFile:(NSURL *)fileURL;

@end

@interface ECCodeIndex (Subclass)

/// Return a number in range [0.0, 1.0[ depending on how well the code index supports a given file
/// Language or scope can be nil, in which case the index is free to detect them based on file name and contents
/// Scope takes precedence over language if both are specified
/// Return 0.0 if the protocol is not implemented. Never return 1.0.
- (float)supportForFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope;

/// Return a code unit initialized with the passed index and fileURL
- (ECCodeUnit *)codeUnitWithIndex:(ECCodeIndex *)index forFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope;

@end
