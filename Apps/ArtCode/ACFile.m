//
//  ACFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFile.h"
#import "ECCodeUnit.h"
#import "ECCodeIndex.h"

@interface ACFile ()

@property (nonatomic, strong) ECCodeUnit *codeUnit;

@end

@implementation ACFile

@synthesize codeUnit = _codeUnit;

- (NSString *)contentString
{
    return [NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:NULL];
}

- (void)loadCodeUnitWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ECCodeIndex *index = [[ECCodeIndex alloc] init];
        self.codeUnit = [index unitForFile:[self.fileURL path]];
        completionHandler(true);
    });
}

@end
