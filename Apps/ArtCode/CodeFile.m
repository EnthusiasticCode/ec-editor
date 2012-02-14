//
//  CodeFile.m
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFile.h"
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
    int32_t _contentsGenerationCounter;
    // spin lock to access the contents. always call contents within this lock
    OSSpinLock _contentsLock;
    NSMutableArray *_presenters;
    NSOperationQueue *_parserQueue;
    NSArray *_symbolList;
}
@property (nonatomic, strong) TMUnit *codeUnit;
- (id)_initWithFileURL:(NSURL *)url;
- (void)_replaceCharactersInRange:(NSRange)range string:(NSString *)string attributedString:(NSAttributedString *)attributedString;
- (void)_reparseFile;
- (void)_markPlaceholderWithName:(NSString *)name range:(NSRange)range;
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
    self = [super initWithFileURL:url];
    if (!self)
        return nil;
    _contents = [[NSMutableAttributedString alloc] init];
    _contentsLock = OS_SPINLOCK_INIT;
    _presenters = [[NSMutableArray alloc] init];
    _parserQueue = [[NSOperationQueue alloc] init];
    _parserQueue.maxConcurrentOperationCount = 1;
    return self;
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super openWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            __weak CodeFile *this = self;
            [_parserQueue addOperationWithBlock:^{
                if (!this)
                    return;
                TMUnit *codeUnit = [[[TMIndex alloc] init] codeUnitForCodeFile:this rootScopeIdentifier:nil];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    this.codeUnit = codeUnit;
                    [this _reparseFile];
                }];
            }];
        }
        completionHandler(success);
    }];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
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
    return [self attributedStringInRange:stringRange];
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
    [_presenters addObject:presenter];
}

- (void)removePresenter:(id<CodeFilePresenter>)presenter
{
    ECASSERT([_presenters containsObject:presenter]);
    [_presenters removeObject:presenter];
}

- (NSArray *)presenters
{
    return [_presenters copy];
}

- (NSUInteger)length
{
    OSSpinLockLock(&_contentsLock);
    NSUInteger length = [_contents length];
    OSSpinLockUnlock(&_contentsLock);
    return length;
}

- (NSString *)stringInRange:(NSRange)range
{
    OSSpinLockLock(&_contentsLock);
    NSString *string = [[_contents string] substringWithRange:range];
    OSSpinLockUnlock(&_contentsLock);
    return string;
}

- (NSString *)string
{
    OSSpinLockLock(&_contentsLock);
    NSString *string = [[_contents string] copy];
    OSSpinLockUnlock(&_contentsLock);
    return string;
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    [self _replaceCharactersInRange:range string:string attributedString:[[NSAttributedString alloc] initWithString:string]];
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range
{
    OSSpinLockLock(&_contentsLock);
    NSAttributedString *attributedString = [_contents attributedSubstringFromRange:range];
    OSSpinLockUnlock(&_contentsLock);
    return attributedString;
}

- (NSAttributedString *)attributedString
{
    OSSpinLockLock(&_contentsLock);
    NSAttributedString *attributedString = [_contents copy];
    OSSpinLockUnlock(&_contentsLock);
    return attributedString;
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString
{
    [self _replaceCharactersInRange:range string:[attributedString string] attributedString:attributedString];
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    if (![attributes count] || !range.length)
        return;
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:willAddAttributes:range:)])
            [presenter codeFile:self willAddAttributes:attributes range:range];
    OSSpinLockLock(&_contentsLock);
    [_contents addAttributes:attributes range:range];
    OSSpinLockUnlock(&_contentsLock);
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:didAddAttributes:range:)])
            [presenter codeFile:self didAddAttributes:attributes range:range];
}

- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range
{
    if (![attributeNames count] || !range.length)
        return;
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:willRemoveAttributes:range:)])
            [presenter codeFile:self willRemoveAttributes:attributeNames range:range];
    OSSpinLockLock(&_contentsLock);
    for (NSString *attributeName in attributeNames)
        [_contents removeAttribute:attributeName range:range];
    OSSpinLockUnlock(&_contentsLock);
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:didRemoveAttributes:range:)])
            [presenter codeFile:self didRemoveAttributes:attributeNames range:range];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range
{
    id attribute = nil;
    NSRange longestEffectiveRange = NSMakeRange(NSNotFound, 0);
    attribute = [self attribute:attrName atIndex:location longestEffectiveRange:(NSRangePointer)&longestEffectiveRange inRange:NSMakeRange(0, [self length])];
    if (range)
        *range = longestEffectiveRange;
    return attribute;
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
    id attribute = nil;
    NSRange longestEffectiveRange = NSMakeRange(NSNotFound, 0);
    OSSpinLockLock(&_contentsLock);
    attribute = [_contents attribute:attrName atIndex:location longestEffectiveRange:(NSRangePointer)&longestEffectiveRange inRange:rangeLimit];
    OSSpinLockUnlock(&_contentsLock);
    if (range)
        *range = longestEffectiveRange;
    return attribute;
}

- (NSRange)lineRangeForRange:(NSRange)range
{
    OSSpinLockLock(&_contentsLock);
    NSRange lineRange = [[_contents string] lineRangeForRange:range];
    OSSpinLockUnlock(&_contentsLock);
    return lineRange;
}

-(NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    return [regexp numberOfMatchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    return [regexp matchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options
{
    return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate
{
    return [result.regularExpression replacementStringForResult:result inString:[self string] offset:offset template:replacementTemplate];
}

- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset
{
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

- (void)_replaceCharactersInRange:(NSRange)range string:(NSString *)string attributedString:(NSAttributedString *)attributedString
{
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[self stringInRange:range]])
        return;
    
    for (id<CodeFilePresenter>presenter in _presenters)
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
        OSSpinLockUnlock(&_contentsLock);
    }
    else
    {
        OSSpinLockLock(&_contentsLock);
        [_contents deleteCharactersInRange:range];
        OSAtomicIncrement32Barrier(&_contentsGenerationCounter);
        OSSpinLockUnlock(&_contentsLock);
    }
    [self updateChangeCount:UIDocumentChangeDone];
    for (id<CodeFilePresenter>presenter in _presenters)
    {
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withString:string];
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
    }
    [self _reparseFile];
}

- (void)_reparseFile
{
    int32_t currentGeneration = _contentsGenerationCounter;
#warning TODO this code is a mess, reading and writing the contents without checking generation or locking, it's also using a strong self which could lead to retain cycles, even though short, a better solution would be to pass in a weak self, pass it to a strong variable again, and check variable for null before dereferencing like we did in that other file, I'm leaving it as it is for now since it's only temporary code
    [_parserQueue addOperationWithBlock:^{
        if (self->_contentsGenerationCounter != currentGeneration)
            return;
        [self addAttributes:self.theme.commonAttributes range:NSMakeRange(0, [self length])];
        // Add text coloring
        [self.codeUnit visitScopesWithBlock:^TMUnitVisitResult(TMScope *scope, NSRange range) {
            NSDictionary *attributes = [self.theme attributesForScope:scope];
            if ([attributes count])
            {
                if (self->_contentsGenerationCounter != currentGeneration)
                    return TMUnitVisitResultBreak;
                [self addAttributes:attributes range:range];
                if (self->_contentsGenerationCounter != currentGeneration)
                    return TMUnitVisitResultBreak;
            }
            return TMUnitVisitResultRecurse;
        }];
        if (self->_contentsGenerationCounter != currentGeneration)
            return;
        // Add placeholders styles
        static NSRegularExpression *placeholderRegExp = nil;
        if (!placeholderRegExp)
            placeholderRegExp = [NSRegularExpression regularExpressionWithPattern:@"<#(.+?)#>" options:0 error:NULL];
        if (self->_contentsGenerationCounter != currentGeneration)
            return;
        for (NSTextCheckingResult *placeholderMatch in [self matchesOfRegexp:placeholderRegExp options:0])
        {
            if (self->_contentsGenerationCounter != currentGeneration)
                return;
            [self _markPlaceholderWithName:[self stringInRange:[placeholderMatch rangeAtIndex:1]] range:placeholderMatch.range];
            if (self->_contentsGenerationCounter != currentGeneration)
                return;
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            for (id<CodeFilePresenter>presenter in self.presenters)
                if ([presenter respondsToSelector:@selector(codeFile:willAddAttributes:range:)])
                    [presenter codeFile:self willAddAttributes:nil range:NSMakeRange(0, [self length])];
        }];
    }];
}

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

- (void)_markPlaceholderWithName:(NSString *)name range:(NSRange)range
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
    [self addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:placeHolderBodyBlock, TextRendererRunUnderlayBlockAttributeName, [UIColor blackColor].CGColor, kCTForegroundColorAttributeName, nil] range:NSMakeRange(range.location + 2, range.length - 4)];
    
    // Opening and Closing style
    
    //
    CGFontRef font = (__bridge CGFontRef)[[TMTheme sharedAttributes] objectForKey:(__bridge id)kCTFontAttributeName];
    ECASSERT(font);
    CTRunDelegateRef delegateRef = CTRunDelegateCreate(&placeholderEndingsRunCallbacks, font);
    
    [self addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderLeftBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(range.location, 2)];
    [self addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderRightBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(NSMaxRange(range) - 2, 2)];
    
    CFRelease(delegateRef);
    
    // Placeholder behaviour
    [self addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:name, CodeViewPlaceholderAttributeName, nil] range:range];
}

@end

@implementation CodeFileSymbol

@synthesize title, icon, range;

- (id)initWithTitle:(NSString *)_title icon:(UIImage *)_icon range:(NSRange)_range
{
    self = [super init];
    if (!self)
        return nil;
    title = _title;
    icon = _icon;
    range = _range;
    return self;
}

@end
