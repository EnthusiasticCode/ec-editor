//
//  ECCodeDiagnostic.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeScope.h"

typedef enum
{
    ECCodeDiagnosticSeverityIgnored = 0,
    ECCodeDiagnosticSeverityNote = 1,
    ECCodeDiagnosticSeverityWarning = 2,
    ECCodeDiagnosticSeverityError = 3, 
    ECCodeDiagnosticSeverityFatal = 4 
} ECCodeDiagnosticSeverity;

@protocol ECCodeDiagnostic <ECCodeScope>
@property (nonatomic, readonly) ECCodeDiagnosticSeverity diagnosticSeverity;
@property (nonatomic, readonly, copy) NSString *diagnosticMessage;
@property (nonatomic, readonly, copy) NSString *diagnosticCategory;

@end
