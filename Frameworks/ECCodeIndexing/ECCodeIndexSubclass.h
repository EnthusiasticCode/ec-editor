//
//  ECCodeIndexSubclass.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"

@interface ECCodeIndex (Subclass)

/// Registers a subclass as an extension of the receiver
/// Subclasses do not need to implement this method
+ (void)registerExtension:(Class)extensionClass;

/// Return a number in range [0.0, 1.0[ depending on how well the code index implements a given protocol for a given scope, in a given language, in a given file
/// The file must exist, but it can be empty
/// If the language or scope are not specified, they will be autodetected
/// Scope takes precedence over language
/// Return 0.0 if the protocol is not implemented. Never return 1.0.
+ (float)implementsProtocol:(Protocol *)protocol forFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope;

@end
