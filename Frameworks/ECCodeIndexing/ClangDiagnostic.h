//
//  ECClangCodeDiagnostic.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangIndexExtension.h"

@interface ClangDiagnostic : NSObject <ECCodeDiagnostic>

- (id)initWithClangDiagnostic:(CXDiagnostic)clangDiagnostic;

@end
