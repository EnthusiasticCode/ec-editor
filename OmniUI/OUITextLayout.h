// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <Foundation/Foundation.h>
#import <UIKit/UIGeometry.h>
#import <CoreText/CTFramesetter.h>
#import <CoreText/CTFont.h>


extern CGRect OUITextLayoutMeasureFrame(CTFrameRef frame, BOOL includeTrailingWhitespace);
extern CGPoint OUITextLayoutOrigin(CGRect typographicFrame, UIEdgeInsets textInset, // in text coordinates
                                   CGRect bounds, // view rect we want to draw in
                                   CGFloat scale); // scale factor from text to view
extern void OUITextLayoutDrawFrame(CGContextRef ctx, CTFrameRef frame, CGRect bounds, CGPoint layoutOrigin);
extern void OUITextLayoutFixupParagraphStyles(NSMutableAttributedString *content);

extern CTFontRef OUIGlobalDefaultFont(void);
