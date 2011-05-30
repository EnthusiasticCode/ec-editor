//
//  ECCodeDiagnostic.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    ECCodeDiagnosticSeverityIgnored = 0,
    ECCodeDiagnosticSeverityNote = 1,
    ECCodeDiagnosticSeverityWarning = 2,
    ECCodeDiagnosticSeverityError = 3, 
    ECCodeDiagnosticSeverityFatal = 4 
} ECCodeDiagnosticSeverity;

@interface ECCodeDiagnostic : NSObject
@property (nonatomic, readonly) ECCodeDiagnosticSeverity severity;
@property (nonatomic, readonly, copy) NSString *file;
@property (nonatomic, readonly) NSUInteger offset;
@property (nonatomic, readonly, copy) NSString *spelling;
@property (nonatomic, readonly, copy) NSString *category;
@property (nonatomic, readonly, copy) NSArray *sourceRanges;
@property (nonatomic, readonly, copy) NSArray *fixIts;

- (id)initWithSeverity:(ECCodeDiagnosticSeverity)severity file:(NSString *)file offset:(NSUInteger)offset spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts;
+ (id)diagnosticWithSeverity:(ECCodeDiagnosticSeverity)severity file:(NSString *)file offset:(NSUInteger)offset spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts;

@end
