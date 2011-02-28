//
//  ECDiagnostic.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECSourceLocation;
@class ECSourceRange;

typedef enum ECDiagnosticSeverity
{
    ECDiagnosticSeverityIgnored = 0,
    ECDiagnosticSeverityNote = 1,
    ECDiagnosticSeverityWarning = 2,
    ECDiagnosticSeverityError = 3, 
    ECDiagnosticSeverityFatal = 4 
} ECDiagnosticSeverity;

@interface ECDiagnostic : NSObject
@property (nonatomic, readonly) ECDiagnosticSeverity severity;
@property (nonatomic, readonly) ECSourceLocation *location;
@property (nonatomic, readonly) NSString *spelling;
@property (nonatomic, readonly) NSString *category;
@property (nonatomic, readonly) NSArray *sourceRanges;
@property (nonatomic, readonly) NSArray *fixIts;

- (id)initWithSeverity:(ECDiagnosticSeverity)severity location:(ECSourceLocation *)location spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts;
+ (id)diagnosticWithSeverity:(ECDiagnosticSeverity)severity location:(ECSourceLocation *)location spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts;

@end
