//
//  TMSyntax.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMSyntax.h"

static NSString * const _syntaxNameKey = @"name";
static NSString * const _syntaxScopeKey = @"scopeName";
static NSString * const _syntaxFileTypesKey = @"fileTypes";
static NSString * const _syntaxFirstLineMatchKey = @"firstLineMatch";

@interface TMSyntax ()
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *scope;
@property (nonatomic, strong) NSArray *fileTypes;
@property (nonatomic, strong) NSRegularExpression *firstLineMatch;
@property (nonatomic, strong) NSDictionary *plist;
@end

@implementation TMSyntax

@synthesize fileURL = _fileURL;
@synthesize name = _name;
@synthesize scope = _scope;
@synthesize fileTypes = _fileTypes;
@synthesize firstLineMatch = _firstLineMatch;
@synthesize plist = _plist;

- (id)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (!self)
        return nil;
    NSDictionary *syntaxPlist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    NSString *syntaxName = [syntaxPlist objectForKey:_syntaxNameKey];
    if (!syntaxName)
        return nil;
    self.fileURL = fileURL;
    self.name = syntaxName;
    self.scope = [syntaxPlist objectForKey:_syntaxScopeKey];
    self.fileTypes = [syntaxPlist objectForKey:_syntaxFileTypesKey];
    NSString *firstLineMatchRegex = [syntaxPlist objectForKey:_syntaxFirstLineMatchKey];
    if (firstLineMatchRegex)
        self.firstLineMatch = [NSRegularExpression regularExpressionWithPattern:firstLineMatchRegex options:0 error:NULL];
    self.plist = syntaxPlist;
    return self;
}

@end