// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUI/UIView-OUIExtensions.h>
#import <OmniUI/OUILoadedImage.h>
#import <OmniQuartz/OQDrawing.h>
#import <UIKit/UIView.h>
#import <OmniBase/assertions.h>
#import <OmniBase/OBUtilities.h>
#import <OmniBase/macros.h>

#import <QuartzCore/CALayer.h>


@implementation UIView (OUIExtensions)

#if defined(OMNI_ASSERTIONS_ON)

static CGRect (*_original_convertRectFromView)(UIView *self, SEL _cmd, CGRect rect, UIView *view) = NULL;
static CGRect (*_original_convertRectToView)(UIView *self, SEL _cmd, CGRect rect, UIView *view) = NULL;
static CGPoint (*_original_convertPointFromView)(UIView *self, SEL _cmd, CGPoint point, UIView *view) = NULL;
static CGPoint (*_original_convertPointToView)(UIView *self, SEL _cmd, CGPoint point, UIView *view) = NULL;

// -window on UIWindow returns nil instead of self. Also, though the documentation doesn't allow it, we currently want to allow the case that two views just have a common ancestor and aren't in a window at all (yet).
static UIView *_rootView(UIView *view)
{
    while (YES) {
        UIView *container = view.superview;
        if (!container)
            return view;
        view = container;
    }
}

static BOOL _viewsCompatible(UIView *self, UIView *otherView)
{
    if (!otherView) {
        // "If aView is nil, this method instead converts to/from window base coordinates"
#ifdef OMNI_ASSERTIONS_ON
        // Not sure what UIKit does in this case. It might just not do any transform, but until we need it we'll stick to requiring a window.
        UIView *root = _rootView(self);
        OBASSERT([root isKindOfClass:[UIWindow class]]);
#endif
        return YES;
    }
    
    // "Otherwise, both view and the receiver must belong to the same UIWindow object."
    // We just require that they have a common ancestor view, though.
    UIView *root1 = _rootView(self);
    UIView *root2 = _rootView(otherView);
    
    OBASSERT(root1 == root2);
    return YES;
}

static CGRect _replacement_convertRectFromView(UIView *self, SEL _cmd, CGRect rect, UIView *view)
{
    OBPRECONDITION(_viewsCompatible(self, view));
    return _original_convertRectFromView(self, _cmd, rect, view);
}

static CGRect _replacement_convertRectToView(UIView *self, SEL _cmd, CGRect rect, UIView *view)
{
    OBPRECONDITION(_viewsCompatible(self, view));
    return _original_convertRectToView(self, _cmd, rect, view);
}

static CGPoint _replacement_convertPointFromView(UIView *self, SEL _cmd, CGPoint point, UIView *view)
{
    OBPRECONDITION(_viewsCompatible(self, view));
    return _original_convertPointFromView(self, _cmd, point, view);
}

static CGPoint _replacement_convertPointToView(UIView *self, SEL _cmd, CGPoint point, UIView *view)
{
    OBPRECONDITION(_viewsCompatible(self, view));
    return _original_convertPointToView(self, _cmd, point, view);
}

static void OUIViewPerformPosing(void) __attribute__((constructor));
static void OUIViewPerformPosing(void)
{
    Class viewClass = NSClassFromString(@"UIView");
    _original_convertRectFromView = (typeof(_original_convertRectFromView))OBReplaceMethodImplementation(viewClass, @selector(convertRect:fromView:), (IMP)_replacement_convertRectFromView);
    _original_convertRectToView = (typeof(_original_convertRectToView))OBReplaceMethodImplementation(viewClass, @selector(convertRect:toView:), (IMP)_replacement_convertRectToView);
    _original_convertPointFromView = (typeof(_original_convertPointFromView))OBReplaceMethodImplementation(viewClass, @selector(convertPoint:fromView:), (IMP)_replacement_convertPointFromView);
    _original_convertPointToView = (typeof(_original_convertPointToView))OBReplaceMethodImplementation(viewClass, @selector(convertPoint:toView:), (IMP)_replacement_convertPointToView);
}

#endif

- (UIImage *)snapshotImage;
{
    UIImage *image;
    CGRect bounds = self.bounds;
    
    UIGraphicsBeginImageContext(bounds.size);
    {
        [self drawRect:bounds];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return image;
}

- (id)containingViewOfClass:(Class)cls; // can return self
{
    UIView *view = self;
    while (view) {
        if ([view isKindOfClass:cls])
            return view;
        view = view.superview;
    }
    return nil;
}

@end


#pragma mark -
#pragma mark Rectangular shadows

static struct {
    OUILoadedImage top;
    OUILoadedImage bottom;
    OUILoadedImage left;
    OUILoadedImage right;
} ShadowImages;

static void LoadShadowImages(void)
{
    if (ShadowImages.top.image)
        return;
    

    
    OUILoadImage(@"OUIShadowBorderBottom.png", &ShadowImages.bottom);
    OUILoadImage(@"OUIShadowBorderTop.png", &ShadowImages.top);
    OUILoadImage(@"OUIShadowBorderLeft.png", &ShadowImages.left);
    OUILoadImage(@"OUIShadowBorderRight.png", &ShadowImages.right);
    
}

static void _addShadowEdge(UIView *self, const OUILoadedImage *imageInfo, NSMutableArray *edges)
{
    UIView *edge = [[UIView alloc] init];
    edge.layer.needsDisplayOnBoundsChange = NO;
    [self addSubview:edge];
    
    edge.layer.contents = (id)[imageInfo->image CGImage];
    
    // Exactly one dimension should have an odd pixel count. This center column or row will get stretched via the contentsCenter property on the layer.
#ifdef OMNI_ASSERTIONS_ON
    CGSize imageSize = imageInfo->size;
#endif
    OBASSERT(imageSize.width == rint(imageSize.width));
    OBASSERT(imageSize.height == rint(imageSize.height));
    OBASSERT(((int)imageSize.width & 1) ^ ((int)imageSize.height & 1));
    
    //edge.layer.magnificationFilter = kCAFilterNearest;
    //edge.layer.contentsGravity = kCAGravityResize;
    //edge.layer.contentsRect = CGRectMake(0, 0, 1.0, 1.0);
    
    /*
     contentsCenter is in normalized [0,1] coordinates, but the header also says:
     
     "As a special case, if the width or height is zero, it is implicitly adjusted to the width or height of a single source pixel centered at that position."
     
     */
    edge.layer.contentsCenter = CGRectMake(0.5, 0.5, 0, 0);
    
    [edges addObject:edge];
    [edge release];
}

//static void _addShadowEdge(UIView *self, const OUILoadedImage *imageInfo, NSMutableArray *edges)
//{
//    // Exactly one dimension should have an odd pixel count. This center column or row will get stretched via the contentsCenter property on the layer.
//#ifdef OMNI_ASSERTIONS_ON
//    CGSize imageSize = imageInfo->size;
//#endif
//    OBASSERT(imageSize.width == rint(imageSize.width));
//    OBASSERT(imageSize.height == rint(imageSize.height));
//    OBASSERT(((int)imageSize.width & 1) ^ ((int)imageSize.height & 1));
//    
//    UIImageView *edge = [[UIImageView alloc] initWithImage:imageInfo->image];
//    [self addSubview:edge];
//    
//    edge.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
//    
//    [edges addObject:edge];
//    [edge release];
//}

NSArray *OUIViewAddShadowEdges(UIView *self)
{
    NSMutableArray *edges = [NSMutableArray array];
    
    LoadShadowImages();
    
    _addShadowEdge(self, &ShadowImages.bottom, edges);
    _addShadowEdge(self, &ShadowImages.top, edges);
    _addShadowEdge(self, &ShadowImages.left, edges);
    _addShadowEdge(self, &ShadowImages.right, edges);
    
    return edges;
}

void OUIViewLayoutShadowEdges(UIView *self, NSArray *shadowEdges, BOOL flipped)
{
    if ([shadowEdges count] != 4) {
        OBASSERT_NOT_REACHED("What sort of crazy geometry is this?");
        return;
    }
    
    struct {
        UIView *bottom;
        UIView *top;
        UIView *left;
        UIView *right;
    } edges;
    
    [shadowEdges getObjects:(id *)&edges];
    
    
    CGRect bounds = self.bounds;
    

    // TODO: We'll want one or more multi-part images that have the shadow pre rendered and offset.
    static const CGFloat kShadowSize = 16;
    
    CGRect topRect = CGRectMake(CGRectGetMinX(bounds) - kShadowSize, CGRectGetMaxY(bounds), CGRectGetWidth(bounds) + 2*kShadowSize, kShadowSize);
    CGRect bottomRect = CGRectMake(CGRectGetMinX(bounds) - kShadowSize, CGRectGetMinY(bounds) - kShadowSize, CGRectGetWidth(bounds) + 2*kShadowSize, kShadowSize);
    
    if (flipped)
        SWAP(topRect, bottomRect);
    
    // These cover the corners too.
    edges.bottom.frame = bottomRect;
    edges.top.frame = topRect;
    
    edges.left.frame = CGRectMake(CGRectGetMinX(bounds) - kShadowSize, CGRectGetMinY(bounds), kShadowSize, CGRectGetHeight(bounds));
    edges.right.frame = CGRectMake(CGRectGetMaxX(bounds), CGRectGetMinY(bounds), kShadowSize, CGRectGetHeight(bounds));
}

#ifdef NS_BLOCKS_AVAILABLE

void OUIWithoutAnimating(void (^actions)(void))
{
    BOOL wasAnimating = [UIView areAnimationsEnabled];
    @try {
        if (wasAnimating)
            [UIView setAnimationsEnabled:NO];
        actions();
    } @finally {
        OBASSERT(![UIView areAnimationsEnabled]); // Make sure something hasn't turned it on again, like -[UIToolbar setItem:] (Radar 8496247)
        if (wasAnimating)
            [UIView setAnimationsEnabled:YES];
    }
}

#endif

