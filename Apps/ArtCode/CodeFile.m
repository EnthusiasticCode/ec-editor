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

@interface CodeFile ()
{
    NSMutableAttributedString *_contents;
    NSMutableArray *_presenters;
    NSArray *_symbolList;
}
- (void)_markPlaceholderWithName:(NSString *)name range:(NSRange)range;

@end

@interface CodeFileSymbol ()

- (id)initWithTitle:(NSString *)title icon:(UIImage *)icon range:(NSRange)range;

@end

#pragma mark - Impementations

@implementation CodeFile

@synthesize codeUnit = _codeUnit;
@synthesize theme = _theme;

#pragma mark - Public Properties

- (TMTheme *)theme
{
    if (!_theme)
        _theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
    return _theme;
}

#pragma mark - UIDocument Methods

- (id)initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    if (!self)
        return nil;
    _contents = [[NSMutableAttributedString alloc] init];
    _presenters = [[NSMutableArray alloc] init];
    return self;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [[_contents string] dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    _contents = [[NSMutableAttributedString alloc] initWithString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding]];
    return YES;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(TextRenderer *)sender
{
    return [self length];
}

- (NSAttributedString *)textRenderer:(TextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringInRange:stringRange]];
    // Add text coloring
    [attributedString addAttributes:[self.theme commonAttributes] range:NSMakeRange(0, [attributedString length])];
    [self.codeUnit visitScopesInRange:stringRange withBlock:^TMUnitVisitResult(TMScope *scope, NSRange range) {
        NSDictionary *attributes = [self.theme attributesForScope:scope];
        if ([attributes count])
            [attributedString addAttributes:attributes range:range];
        return TMUnitVisitResultRecurse;
    }];
    // Add placeholders styles
    static NSRegularExpression *placeholderRegExp = nil;
    if (!placeholderRegExp)
        placeholderRegExp = [NSRegularExpression regularExpressionWithPattern:@"<#(.+?)#>" options:0 error:NULL];
    for (NSTextCheckingResult *placeholderMatch in [self matchesOfRegexp:placeholderRegExp options:0])
    {
#warning TODO NIK fix this, the method modify the file buffer, not attributedString.
        [self _markPlaceholderWithName:[self stringInRange:[placeholderMatch rangeAtIndex:1]] range:placeholderMatch.range];
    }
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
    return [_contents length];
}

- (NSString *)stringInRange:(NSRange)range
{
    return [[_contents string] substringWithRange:range];
}

- (NSString *)string
{
    return [[_contents string] copy];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[self stringInRange:range]])
        return;

    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string];
    for (id<CodeFilePresenter>presenter in _presenters)
    {
        if ([presenter respondsToSelector:@selector(codeFile:willReplaceCharactersInRange:withString:)])
            [presenter codeFile:self willReplaceCharactersInRange:range withString:string];
        if ([presenter respondsToSelector:@selector(codeFile:willReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self willReplaceCharactersInRange:range withAttributedString:attributedString];
    }
    if ([string length])
        [_contents replaceCharactersInRange:range withString:string];
    else
        [_contents deleteCharactersInRange:range];
    [self updateChangeCount:UIDocumentChangeDone];
    for (id<CodeFilePresenter>presenter in _presenters)
    {
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withString:string];
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
    }
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range
{
    return [_contents attributedSubstringFromRange:range];
}

- (NSAttributedString *)attributedString
{
    return [_contents copy];
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![attributedString length])
        return;
    // replacing a substring with an equal string, no change required
    if ([attributedString isEqualToAttributedString:[self attributedStringInRange:range]])
        return;
    NSString *string = [attributedString string];
    for (id<CodeFilePresenter> presenter in _presenters)
    {
        if ([presenter respondsToSelector:@selector(codeFile:willReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self willReplaceCharactersInRange:range withAttributedString:attributedString];
        if ([presenter respondsToSelector:@selector(codeFile:willReplaceCharactersInRange:withString:)])
            [presenter codeFile:self willReplaceCharactersInRange:range withString:string];
    }
    if ([attributedString length])
        [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    else
        [_contents deleteCharactersInRange:range];
    [self updateChangeCount:UIDocumentChangeDone];
    for (id<CodeFilePresenter> presenter in _presenters)
    {
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withString:string];
    }
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributes count] || !range.length)
        return;
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:willAddAttributes:range:)])
            [presenter codeFile:self willAddAttributes:attributes range:range];
    [_contents addAttributes:attributes range:range];
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:didAddAttributes:range:)])
            [presenter codeFile:self didAddAttributes:attributes range:range];
}

- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributeNames count] || !range.length)
        return;
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:willRemoveAttributes:range:)])
            [presenter codeFile:self willRemoveAttributes:attributeNames range:range];
    for (NSString *attributeName in attributeNames)
        [_contents removeAttribute:attributeName range:range];
    for (id<CodeFilePresenter> presenter in _presenters)
        if ([presenter respondsToSelector:@selector(codeFile:didRemoveAttributes:range:)])
            [presenter codeFile:self didRemoveAttributes:attributeNames range:range];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range
{
    ECASSERT(location < [_contents length]);
    id attribute = nil;
    NSRange longestEffectiveRange = NSMakeRange(NSNotFound, 0);
    attribute = [_contents attribute:attrName atIndex:location longestEffectiveRange:(NSRangePointer)&longestEffectiveRange inRange:NSMakeRange(0, [_contents length])];
    if (range)
        *range = longestEffectiveRange;
    return attribute;
}

- (NSRange)lineRangeForRange:(NSRange)range
{
    return [[_contents string] lineRangeForRange:range];
}

-(NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    return [regexp numberOfMatchesInString:[_contents string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    return [regexp matchesInString:[_contents string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options
{
    return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate
{
    return [result.regularExpression replacementStringForResult:result inString:[_contents string] offset:offset template:replacementTemplate];
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

- (CodeFileTextKind)kindOfTextInRange:(NSRange)range
{
    __block CodeFileTextKind result = CodeFileNormalTextKind;
    [self.codeUnit visitScopesInRange:range withBlock:^TMUnitVisitResult(TMScope *scope, NSRange scopeRange) {
        if (scopeRange.length <= 2)
            return TMUnitVisitResultRecurse;
        if ([scope.qualifiedIdentifier rangeOfString:@"preprocessor"].location != NSNotFound)
        {
            result = CodeFilePreprocessorTextKind;
            return TMUnitVisitResultBreak;
        }
        if ([[TMPreference preferenceValueForKey:TMPreferenceShowInSymbolListKey scope:scope] boolValue])
        {
            result = CodeFileSymbolTextKind;
            return TMUnitVisitResultBreak;
        }
        if ([scope.qualifiedIdentifier rangeOfString:@"comment"].location != NSNotFound)
        {
            result = CodeFileCommentTextKind;
            return TMUnitVisitResultBreak;
        }
        return TMUnitVisitResultRecurse;
    }];
    return result;
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
