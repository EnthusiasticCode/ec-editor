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
    ECDiagnostic_Ignored = 0,
    ECDiagnostic_Note = 1,
    ECDiagnostic_Warning = 2,
    ECDiagnostic_Error = 3, 
    ECDiagnostic_Fatal = 4 
} ECDiagnosticSeverity;

@interface ECDiagnostic : NSObject {

}
@property (nonatomic, readonly) ECDiagnosticSeverity severity;
@property (nonatomic, readonly, retain) ECSourceLocation *location;
@property (nonatomic, readonly, retain) NSString *spelling;
@property (nonatomic, readonly, retain) NSString *category;
@property (nonatomic, readonly, retain) NSArray *sourceRanges;
@property (nonatomic, readonly, retain) NSArray *fixIts;

- (id)initWithSeverity:(ECDiagnosticSeverity)severity location:(ECSourceLocation *)location spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts;
+ (id)diagnosticWithSeverity:(ECDiagnosticSeverity)severity location:(ECSourceLocation *)location spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts;

@end
