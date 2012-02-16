//
//  CodeFile.m
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFile+Generation.h"
#import "TMTheme.h"
#import "TMIndex.h"
#import "TMUnit.h"
#import "TMScope.h"
#import "TMPreference.h"
#import "WeakDictionary.h"
#import <libkern/OSAtomic.h>

static WeakDictionary *_codeFiles;

@interface CodeFile ()
{
    NSMutableAttributedString *_contents;
    // counter for the contents generation, incremented atomically every time the contents string is changed, but not when the attributes are
    // it's not really necessary to increment it atomically at the moment, because it's only done within the spinlock
    CodeFileGeneration _contentsGenerationCounter;
    // spin lock to access the contents. always call contents within this lock
    OSSpinLock _contentsLock;
    NSMutableArray *_presenters;
    OSSpinLock _presentersLock;
    NSOperationQueue *_parserQueue;
    NSArray *_symbolList;
}
@property (nonatomic, strong) TMUnit *codeUnit;
- (id)_initWithFileURL:(NSURL *)url;
- (void)_markPlaceholderWithName:(NSString *)name inAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range;
// Private content methods
- (BOOL)_replaceCharactersInRange:(NSRange)range string:(NSString *)string attributedString:(NSAttributedString *)attributedString generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
@end

@interface CodeFileSymbol ()

- (id)initWithTitle:(NSString *)title icon:(UIImage *)icon range:(NSRange)range;

@end

#pragma mark - Implementations

@implementation CodeFile

@synthesize codeUnit = _codeUnit;
@synthesize theme = _theme;

+ (void)initialize
{
    if (self != [CodeFile class])
        return;
    _codeFiles = [[WeakDictionary alloc] init];
}

+ (void)codeFileWithFileURL:(NSURL *)fileURL completionHandler:(void (^)(CodeFile *))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(fileURL);
    CodeFile *codeFile = [_codeFiles objectForKey:fileURL];
    if (codeFile)
        return completionHandler(codeFile);
    __block BOOL fileExists;
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
        fileExists = [[[NSFileManager alloc] init] fileExistsAtPath:[newURL path]];
    }];
    codeFile = [[self alloc] _initWithFileURL:fileURL];
    [codeFile openWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            [_codeFiles setObject:codeFile forKey:fileURL];
            completionHandler(codeFile);
        }
        else
        {
            completionHandler(nil);
        }
    }];
}

- (TMTheme *)theme
{
    if (!_theme)
        _theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
    return _theme;
}

#pragma mark - UIDocument Methods

- (id)initWithFileURL:(NSURL *)url
{
    UNIMPLEMENTED();
}

- (id)_initWithFileURL:(NSURL *)url
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    self = [super initWithFileURL:url];
    if (!self)
        return nil;
    _contents = [[NSMutableAttributedString alloc] init];
    _contentsLock = OS_SPINLOCK_INIT;
    _presenters = [[NSMutableArray alloc] init];
    _presentersLock = OS_SPINLOCK_INIT;
    _parserQueue = [[NSOperationQueue alloc] init];
    _parserQueue.maxConcurrentOperationCount = 1;
    return self;
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [super openWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            __weak CodeFile *weakSelf = self;
            [_parserQueue addOperationWithBlock:^{
                // capture self strongly again in this block to make sure it doesn't go nil while creating the code unit
                __strong CodeFile *strongWeakSelf = weakSelf;
                if (!strongWeakSelf)
                    return;
                TMUnit *codeUnit = [[[TMIndex alloc] init] codeUnitForCodeFile:strongWeakSelf rootScopeIdentifier:nil];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // use the weak self again so we don't capture self
                    weakSelf.codeUnit = codeUnit;
                    // fake operation to force updating the codeview, just a temporary hack
                    [weakSelf removeAttributes:[NSArray arrayWithObject:@"FakeAttributeName"] range:NSMakeRange(0, [weakSelf length])];
                }];
            }];
        }
        completionHandler(success);
    }];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [super closeWithCompletionHandler:^(BOOL success) {
        ECASSERT(success);
        [_parserQueue cancelAllOperations];
        self.codeUnit = nil;
        completionHandler(success);
    }];
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    OSSpinLockLock(&_contentsLock);
    NSData *contentsData = [[_contents string] dataUsingEncoding:NSUTF8StringEncoding];
    OSSpinLockUnlock(&_contentsLock);
    return contentsData;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSMutableAttributedString *contentsString = [[NSMutableAttributedString alloc] initWithString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding]];
    OSSpinLockLock(&_contentsLock);
    _contents = contentsString;
    OSAtomicIncrement32Barrier(&_contentsGenerationCounter);
    OSSpinLockUnlock(&_contentsLock);
    return YES;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(TextRenderer *)sender
{
    return [self length];
}

- (NSAttributedString *)textRenderer:(TextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    NSMutableAttributedString *attributedString = [[self attributedStringInRange:stringRange] mutableCopy];
    [attributedString addAttributes:self.theme.commonAttributes range:NSMakeRange(0, [attributedString length])];
    if (self.codeUnit)
    {
        // Add text coloring
        [self.codeUnit visitScopesInRange:stringRange withBlock:^TMUnitVisitResult(TMScope *scope, NSRange range) {
            NSDictionary *attributes = [self.theme attributesForScope:scope];
            if ([attributes count])
                [attributedString addAttributes:attributes range:range];
            return TMUnitVisitResultRecurse;
        }];
    }
    static NSRegularExpression *placeholderRegExp = nil;
    if (!placeholderRegExp)
        placeholderRegExp = [NSRegularExpression regularExpressionWithPattern:@"<#(.+?)#>" options:0 error:NULL];
    // Add placeholders styles
    [placeholderRegExp enumerateMatchesInString:[attributedString string] options:0 range:NSMakeRange(0, [attributedString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [self _markPlaceholderWithName:[self stringInRange:[result rangeAtIndex:1]] inAttributedString:attributedString range:result.range];
    }];
    return attributedString;
}

- (NSDictionary *)defaultTextAttributedForTextRenderer:(TextRenderer *)sender
{
    return [self.theme commonAttributes];
}

- (void)codeView:(CodeView *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    [self replaceCharactersInRange:range withString:commitString];
}

- (id)codeView:(CodeView *)codeView attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange
{
    return [self attribute:attributeName atIndex:index longestEffectiveRange:effectiveRange];
}

#pragma mark - Public methods

- (void)addPresenter:(id<CodeFilePresenter>)presenter
{
    ECASSERT(![_presenters containsObject:presenter]);
    OSSpinLockLock(&_presentersLock);
    [_presenters addObject:presenter];
    OSSpinLockUnlock(&_presentersLock);
}

- (void)removePresenter:(id<CodeFilePresenter>)presenter
{
    ECASSERT([_presenters containsObject:presenter]);
    OSSpinLockLock(&_presentersLock);
    [_presenters removeObject:presenter];
    OSSpinLockUnlock(&_presentersLock);
}

- (NSArray *)presenters
{
    NSArray *presenters;
    OSSpinLockLock(&_presentersLock);
    presenters = [_presenters copy];
    OSSpinLockUnlock(&_presentersLock);
    return presenters;
}

#pragma mark - String content reading methods

#define CONTENT_GETTER_WRAPPER(parameter, value) \
ECASSERT(parameter);\
if (expectedGeneration && *expectedGeneration != _contentsGenerationCounter)\
return NO;\
OSSpinLockLock(&_contentsLock);\
*parameter = value;\
if (generation)\
*generation = _contentsGenerationCounter;\
OSSpinLockUnlock(&_contentsLock);\
return YES;

- (NSUInteger)length
{
    return [self lengthWithGeneration:NULL];
}

- (NSUInteger)lengthWithGeneration:(CodeFileGeneration *)generation
{
    NSUInteger length;
    [self length:&length withGeneration:generation expectedGeneration:NULL];
    return length;
}

- (BOOL)length:(NSUInteger *)length withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(length, [_contents length]);
}

- (NSString *)string
{
    return [self stringWithGeneration:NULL];
}

- (NSString *)stringWithGeneration:(CodeFileGeneration *)generation
{
    NSString *string;
    [self string:&string withGeneration:generation expectedGeneration:NULL];
    return string;
}

- (BOOL)string:(NSString **)string withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(string, [_contents string]);
}

- (NSString *)stringInRange:(NSRange)range
{
    return [self stringInRange:range withGeneration:NULL];
}

- (NSString *)stringInRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation
{
    NSString *string;
    [self string:&string inRange:range withGeneration:generation expectedGeneration:NULL];
    return string;
}

- (BOOL)string:(NSString **)string inRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(string, [[_contents string] substringWithRange:range]);
}

- (NSRange)lineRangeForRange:(NSRange)range
{
    return [self lineRangeForRange:range withGeneration:NULL];
}

- (NSRange)lineRangeForRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation
{
    NSRange lineRange;
    [self lineRange:&lineRange forRange:range withGeneration:generation expectedGeneration:NULL];
    return lineRange;
}

- (BOOL)lineRange:(NSRangePointer)lineRange forRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(lineRange, [[_contents string] lineRangeForRange:range]);
}

#pragma mark - Attributed string content reading methods

- (NSAttributedString *)attributedString
{
    return [self attributedStringWithGeneration:NULL];
}

- (NSAttributedString *)attributedStringWithGeneration:(CodeFileGeneration *)generation
{
    NSAttributedString *attributedString;
    [self attributedString:&attributedString withGeneration:generation expectedGeneration:NULL];
    return attributedString;
}

- (BOOL)attributedString:(NSAttributedString **)attributedString withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attributedString, [_contents copy]);
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range
{
    return [self attributedStringInRange:range withGeneration:NULL];
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation
{
    NSAttributedString *attributedString;
    [self attributedString:&attributedString inRange:range withGeneration:generation expectedGeneration:NULL];
    return attributedString;
}

- (BOOL)attributedString:(NSAttributedString **)attributedString inRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attributedString, [_contents attributedSubstringFromRange:range]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range
{
    return [self attribute:attrName atIndex:location longestEffectiveRange:range withGeneration:NULL];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange withGeneration:(CodeFileGeneration *)generation
{
    id attribute;
    [self attribute:&attrName withName:attrName atIndex:index longestEffectiveRange:effectiveRange withGeneration:generation expectedGeneration:NULL];
    return attribute;
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attribute, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
    return [self attribute:attrName atIndex:location longestEffectiveRange:range inRange:rangeLimit withGeneration:NULL];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit withGeneration:(CodeFileGeneration *)generation
{
    id attribute;
    [self attribute:&attribute withName:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit withGeneration:generation expectedGeneration:NULL];
    return attribute;
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attribute, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

#pragma mark - String content writing methods

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [self replaceCharactersInRange:range withString:string withGeneration:NULL expectedGeneration:NULL];
}

- (BOOL)replaceCharactersInRange:(NSRange)range withString:(NSString *)string withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    return [self _replaceCharactersInRange:range string:string attributedString:[[NSAttributedString alloc] initWithString:string] generation:generation expectedGeneration:expectedGeneration];
}

#pragma mark - Attributed string content writing methods

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [self replaceCharactersInRange:range withAttributedString:attributedString withGeneration:NULL expectedGeneration:NULL];
}

- (BOOL)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    return [self _replaceCharactersInRange:range string:[attributedString string] attributedString:attributedString generation:generation expectedGeneration:expectedGeneration];
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    [self addAttributes:attributes range:range withGeneration:NULL expectedGeneration:NULL];
}

- (BOOL)addAttributes:(NSDictionary *)attributes range:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if (expectedGeneration && *expectedGeneration != _contentsGenerationCounter)
        return NO;
    if (![attributes count] || !range.length)
        return NO;
    for (id<CodeFilePresenter> presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:willAddAttributes:range:)])
            [presenter codeFile:self willAddAttributes:attributes range:range];
    OSSpinLockLock(&_contentsLock);
    [_contents addAttributes:attributes range:range];
    if (generation)
        *generation = _contentsGenerationCounter;
    OSSpinLockUnlock(&_contentsLock);
    for (id<CodeFilePresenter> presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:didAddAttributes:range:)])
            [presenter codeFile:self didAddAttributes:attributes range:range];
    return YES;
}


- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range
{
    [self removeAttributes:attributeNames range:range withGeneration:NULL expectedGeneration:NULL];
}

- (BOOL)removeAttributes:(NSArray *)attributeNames range:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if (expectedGeneration && *expectedGeneration != _contentsGenerationCounter)
        return NO;
    if (![attributeNames count] || !range.length)
        return NO;
    for (id<CodeFilePresenter> presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:willRemoveAttributes:range:)])
            [presenter codeFile:self willRemoveAttributes:attributeNames range:range];
    OSSpinLockLock(&_contentsLock);
    for (NSString *attributeName in attributeNames)
        [_contents removeAttribute:attributeName range:range];
    if (generation)
        *generation = _contentsGenerationCounter;
    OSSpinLockUnlock(&_contentsLock);
    for (id<CodeFilePresenter> presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:didRemoveAttributes:range:)])
            [presenter codeFile:self didRemoveAttributes:attributeNames range:range];
    return YES;
}

#pragma mark - Private content methods

- (BOOL)_replaceCharactersInRange:(NSRange)range string:(NSString *)string attributedString:(NSAttributedString *)attributedString generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if (expectedGeneration && *expectedGeneration != _contentsGenerationCounter)
        return NO;
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return NO;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[self stringInRange:range]])
        return NO;
    
    for (id<CodeFilePresenter>presenter in [self presenters])
    {
        if ([presenter respondsToSelector:@selector(codeFile:willReplaceCharactersInRange:withString:)])
            [presenter codeFile:self willReplaceCharactersInRange:range withString:string];
        if ([presenter respondsToSelector:@selector(codeFile:willReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self willReplaceCharactersInRange:range withAttributedString:attributedString];
    }
    if ([string length])
    {
        OSSpinLockLock(&_contentsLock);
        [_contents replaceCharactersInRange:range withAttributedString:attributedString];
        OSAtomicIncrement32Barrier(&_contentsGenerationCounter);
        if (generation)
            *generation = _contentsGenerationCounter;
        OSSpinLockUnlock(&_contentsLock);
    }
    else
    {
        OSSpinLockLock(&_contentsLock);
        [_contents deleteCharactersInRange:range];
        OSAtomicIncrement32Barrier(&_contentsGenerationCounter);
        if (generation)
            *generation = _contentsGenerationCounter;
        OSSpinLockUnlock(&_contentsLock);
    }
    [self updateChangeCount:UIDocumentChangeDone];
    for (id<CodeFilePresenter>presenter in [self presenters])
    {
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withString:string];
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
    }
    return YES;
}

#pragma mark - Find and replace functionality

-(NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [regexp numberOfMatchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [regexp matchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [result.regularExpression replacementStringForResult:result inString:[self string] offset:offset template:replacementTemplate];
}

- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(match && replacementTemplate);
    
    NSRange replacementRange = match.range;
    NSString *replacementString =  [self replacementStringForResult:match offset:offset template:replacementTemplate];
    
    replacementRange.location += offset;
    [self replaceCharactersInRange:replacementRange withString:replacementString];
    replacementRange.length = replacementString.length;
    
    return replacementRange;
}

- (NSArray *)symbolList
{
    if (!_symbolList)
    {
        NSMutableArray *symbols = [NSMutableArray new];
        [self.codeUnit visitScopesWithBlock:^TMUnitVisitResult(TMScope *scope, NSRange range) {
            if ([[TMPreference preferenceValueForKey:TMPreferenceShowInSymbolListKey scope:scope] boolValue])
            {
                // Transform
                NSString *(^transformation)(NSString *) = ((NSString *(^)(NSString *))[TMPreference preferenceValueForKey:TMPreferenceSymbolTransformationKey scope:scope]);
                NSString *symbol = transformation ? transformation([self stringInRange:range]) : [self stringInRange:range];
                // TODO add preference for icon
                [symbols addObject:[[CodeFileSymbol alloc] initWithTitle:symbol icon:nil range:range]];
                return TMUnitVisitResultContinue;
            }
            return TMUnitVisitResultRecurse;
        }];
        _symbolList = symbols;
    }
    return _symbolList;
}

#pragma mark - Private methods

static CGFloat placeholderEndingsWidthCallback(void *refcon) {
    if (refcon)
    {
        CGFloat height = CTFontGetXHeight(refcon);
        return height / 2.0;
    }
    return 4.5;
}

static CTRunDelegateCallbacks placeholderEndingsRunCallbacks = {
    kCTRunDelegateVersion1,
    NULL,
    NULL,
    NULL,
    &placeholderEndingsWidthCallback
};

- (void)_markPlaceholderWithName:(NSString *)name inAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range
{
    ECASSERT(range.length > 4);
    
    static CGColorRef placeholderFillColor = NULL;
    if (!placeholderFillColor)
        placeholderFillColor = CGColorRetain([UIColor colorWithRed:234.0/255.0 green:240.0/255.0 blue:250.0/255.0 alpha:1].CGColor);
    
    static CGColorRef placeholderStrokeColor = NULL;
    if (!placeholderStrokeColor)
        placeholderStrokeColor = CGColorRetain([UIColor colorWithRed:197.0/255.0 green:216.0/255.0 blue:243.0/255.0 alpha:1].CGColor);
    
    static TextRendererRunBlock placeHolderBodyBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextAddRect(context, rect);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), rect.origin.y);
        CGContextMoveToPoint(context, rect.origin.x, CGRectGetMaxY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    static TextRendererRunBlock placeholderLeftBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    static TextRendererRunBlock placeholderRightBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    // placeholder body style
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:placeHolderBodyBlock, TextRendererRunUnderlayBlockAttributeName, [UIColor blackColor].CGColor, kCTForegroundColorAttributeName, nil] range:NSMakeRange(range.location + 2, range.length - 4)];
    
    // Opening and Closing style
    
    //
    CGFontRef font = (__bridge CGFontRef)[[TMTheme sharedAttributes] objectForKey:(__bridge id)kCTFontAttributeName];
    ECASSERT(font);
    CTRunDelegateRef delegateRef = CTRunDelegateCreate(&placeholderEndingsRunCallbacks, font);
    
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderLeftBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(range.location, 2)];
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderRightBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(NSMaxRange(range) - 2, 2)];
    
    CFRelease(delegateRef);
    
    // Placeholder behaviour
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:name, CodeViewPlaceholderAttributeName, nil] range:range];
}

@end

@implementation CodeFileSymbol

@synthesize title, icon, range, indentation;

- (id)initWithTitle:(NSString *)_title icon:(UIImage *)_icon range:(NSRange)_range
{
    self = [super init];
    if (!self)
        return nil;
    // Get indentation level and modify title
    NSUInteger titleLength = [_title length];
    for (; indentation < titleLength; ++indentation)
    {
        if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[_title characterAtIndex:indentation]])
            break;
    }
    title = indentation ? [_title substringFromIndex:indentation] : _title;
    icon = _icon;
    range = _range;
    return self;
}

@end
