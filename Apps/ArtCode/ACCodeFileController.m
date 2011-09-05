//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileController.h"
#import "ECCodeView.h"
#import "ECCodeStringDataSource.h"

#import "ECCodeUnit.h"
#import "ECCodeToken.h"
#import "ECCodeCursor.h"

#import "AppStyle.h"
#import "ACState.h"

#import <QuartzCore/QuartzCore.h>

@implementation ACCodeFileController

static NSRange intersectionOfRangeRelativeToRange(NSRange range, NSRange inRange)
{
    NSRange intersectionRange = NSIntersectionRange(range, inRange);
    intersectionRange.location -= inRange.location;
    return intersectionRange;
}

@synthesize codeView;

- (ECCodeView *)codeView
{
    if (!codeView)
    {
        codeView = [ECCodeView new];
        codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        codeView.backgroundColor = [UIColor whiteColor];
        codeView.caretColor = [UIColor styleThemeColorOne];
        codeView.selectionColor = [[UIColor styleThemeColorOne] colorWithAlphaComponent:0.3];
        codeView.textInsets = UIEdgeInsetsMake(10, 40, 10, 10);
        
        codeView.lineNumberWidth = 30;
        codeView.lineNumberFont = [UIFont systemFontOfSize:10];
        codeView.lineNumberColor = [UIColor colorWithWhite:0.8 alpha:1];
        // TODO maybe is not the best option to draw the line number in an external block
        codeView.lineNumberRenderingBlock = ^(CGContextRef context, CGRect lineNumberBounds, CGFloat baseline, NSUInteger lineNumber, BOOL isWrappedLine) {
            CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1].CGColor);
            CGContextMoveToPoint(context, lineNumberBounds.size.width + 3, 0);
            CGContextAddLineToPoint(context, lineNumberBounds.size.width + 3, lineNumberBounds.size.height);
            CGContextStrokePath(context);
            
//            if (!isWrappedLine)
//                return;
//
//            CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
//            CGContextFillRect(context, lineNumberBounds);
        };
        
        codeView.renderer.preferredLineCountPerSegment = 500;
    }
    return codeView;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tool Target Protocol Implementation

+ (id)newNavigationTargetController
{
    return [ACCodeFileController new];
}

- (void)openURL:(NSURL *)url
{
    // TODO handle error
    id<ACStateNode> node = [[ACState localState] nodeForURL:url];
    
    // TODO start loading animation
    ECCodeStringDataSource *dataSource = (ECCodeStringDataSource *)self.codeView.datasource;
    [node loadCodeUnitWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            ECTextStyle *keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" font:nil color:[UIColor blueColor]];
            ECTextStyle *commentStyle = [ECTextStyle textStyleWithName:@"Comment" font:nil color:[UIColor greenColor]];
            ECTextStyle *referenceStyle = [ECTextStyle textStyleWithName:@"Reference" font:nil color:[UIColor purpleColor]];
            ECTextStyle *literalStyle = [ECTextStyle textStyleWithName:@"Literal" font:nil color:[UIColor redColor]];
            ECTextStyle *declarationStyle = [ECTextStyle textStyleWithName:@"Declaration" font:nil color:[UIColor brownColor]];
            ECTextStyle *preprocessingStyle = [ECTextStyle textStyleWithName:@"Preprocessing" font:nil color:[UIColor orangeColor]];
            
            dataSource.stylingBlock = ^(NSMutableAttributedString *string, NSRange stringRange)
            {
                for (ECCodeToken *token in [node.codeUnit tokensInRange:stringRange withCursors:YES])
                {
                    switch (token.kind)
                    {
                        case ECCodeTokenKindKeyword:
                            [string addAttributes:keywordStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                            break;
                            
                        case ECCodeTokenKindComment:
                            [string addAttributes:commentStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                            break;
                            
                        case ECCodeTokenKindLiteral:
                            [string addAttributes:literalStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                            break;
                            
                        default:
                        {
                            if (token.cursor.kind >= ECCodeCursorKindFirstDecl && token.cursor.kind <= ECCodeCursorKindLastDecl)
                                [string addAttributes:declarationStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                            else if (token.cursor.kind >= ECCodeCursorKindFirstRef && token.cursor.kind <= ECCodeCursorKindLastRef)
                                [string addAttributes:referenceStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                            else if (token.cursor.kind >= ECCodeCursorKindFirstPreprocessing && token.cursor.kind <= ECCodeCursorKindLastPreprocessing)
                                [string addAttributes:preprocessingStyle.CTAttributes range:intersectionOfRangeRelativeToRange(token.extent, stringRange)];
                            break;
                        }
                    }
                }
            };
            
            [self.codeView updateAllText];
        }
        // TODO else report error
    }];
    
    self.codeView.text = node.contentString;
}

- (BOOL)enableTabBar
{
    return YES;
}

- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier
{
    return YES;
}

- (BOOL)shouldShowTabBar
{
    return YES;
}

- (BOOL)shouldShowToolPanelController:(ACToolController *)toolController
{
    return YES;
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = self.codeView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
