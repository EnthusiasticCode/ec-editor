//
//  TMDiagnostics.h
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CodeDiagnostic <NSObject>

- (enum CXDiagnosticSeverity)severity;
- (NSString *)spelling;
- (NSUInteger)line;
- (NSRange)range;

@end
