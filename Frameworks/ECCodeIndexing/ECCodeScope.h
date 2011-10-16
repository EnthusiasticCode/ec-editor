//
//  ECCodeScope.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"

@protocol ECCodeScope <NSObject>
/// The full scope identifier, as a period separated string
@property (nonatomic, readonly, copy) NSString *scopeIdentifier;
/// The contents of the scope
@property (nonatomic, readonly, copy) NSString *contents;
/// The scope which directly contains the receiver
@property (nonatomic, readonly, strong) id<ECCodeScope>parentScope;
/// The URL of the file which contains the receiver
@property (nonatomic, readonly, strong) NSURL *fileURL;
/// The scope's range within the containing file
@property (nonatomic, readonly) NSRange absoluteRange;

/// Enumerate the scopes contained in the receiver within the specified range, calling the passed block
- (void)enumerateChildScopesInRange:(NSRange)range withBlock:(ECCodeScopeEnumerationAction(^)(id<ECCodeScope>scope, ECCodeScopeEnumerationStackChange))block;

@end
