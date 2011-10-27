//
//  TMSyntax.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMSyntax.h"
#import "TMPattern.h"

#import "OnigRegexp.h"

static NSString * const _syntaxNameKey = @"name";
static NSString * const _syntaxScopeKey = @"scopeName";
static NSString * const _syntaxFileTypesKey = @"fileTypes";
static NSString * const _syntaxFirstLineMatchKey = @"firstLineMatch";
static NSString * const _syntaxPatternsKey = @"patterns";
static NSString * const _syntaxRepositoryKey = @"repository";
static NSString * const _patternScopeKey = @"name";
static NSString * const _patternsPatternsKey = @"patterns";

@interface TMSyntax ()
{
    NSInteger _contentAccessCount;
}
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *scope;
@property (nonatomic, strong) NSArray *fileTypes;
@property (nonatomic, strong) NSRegularExpression *firstLineMatch;
@property (nonatomic, strong) NSDictionary *repository;
@property (nonatomic, strong) NSDictionary *plist;
@end

@implementation TMSyntax

@synthesize fileURL = _fileURL;
@synthesize name = _name;
@synthesize scope = _scope;
@synthesize fileTypes = _fileTypes;
@synthesize firstLineMatch = _firstLineMatch;
@synthesize pattern = _pattern;
@synthesize repository = _repository;
@synthesize plist = _plist;

- (TMPattern *)pattern
{
    ECASSERT(_contentAccessCount > 0);
    if (!_pattern)
    {
        ECASSERT([self.plist objectForKey:_syntaxPatternsKey]);
        _pattern = [[TMPattern alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:self.scope, _patternScopeKey, [self.plist objectForKey:_syntaxPatternsKey], _patternsPatternsKey, nil]];
    }
    return _pattern;
}

- (NSDictionary *)repository
{
    ECASSERT(_contentAccessCount > 0);
    if (!_repository)
    {
        NSMutableDictionary *repository = [NSMutableDictionary dictionary];
        [[self.plist objectForKey:_syntaxRepositoryKey] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [repository setObject:[[TMPattern alloc] initWithDictionary:obj] forKey:key];
        }];
        _repository = [repository copy];
    }
    return _repository;
}

- (NSDictionary *)plist
{
    ECASSERT(_contentAccessCount > 0);
    if (!_plist)
        _plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:self.fileURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    return _plist;
}

- (id)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (!self)
        return nil;
    self.fileURL = fileURL;
    [self beginContentAccess];
    self.name = [self.plist objectForKey:_syntaxNameKey];
    if (!self.name)
        return nil;
    self.scope = [self.plist objectForKey:_syntaxScopeKey];
    self.fileTypes = [self.plist objectForKey:_syntaxFileTypesKey];
    NSString *firstLineMatchRegex = [self.plist objectForKey:_syntaxFirstLineMatchKey];
    if (firstLineMatchRegex)
        self.firstLineMatch = [OnigRegexp compile:firstLineMatchRegex ignorecase:NO multiline:YES];
    [self endContentAccess];
    return self;
}

- (BOOL)beginContentAccess
{
    ECASSERT(_contentAccessCount >= 0);
    ++_contentAccessCount;
    return YES;
}

- (void)endContentAccess
{
    ECASSERT(_contentAccessCount > 0);
    --_contentAccessCount;
}

- (void)discardContentIfPossible
{
    ECASSERT(_contentAccessCount >= 0);
    if (_contentAccessCount > 0)
        return;
    _pattern = nil;
    _repository = nil;
    _plist = nil;
}

- (BOOL)isContentDiscarded
{
    return !_pattern && !_repository && !_plist;
}

@end
