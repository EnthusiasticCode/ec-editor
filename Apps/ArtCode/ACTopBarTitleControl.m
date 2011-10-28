//
//  ACTopBarTitleControl.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTopBarTitleControl.h"


@interface ACTopBarTitleControl () {
    NSArray *_preViews;
    NSArray *_postViews;
    
    UIActivityIndicatorView *_activityIndicatorView;
}

- (void)_setupTitle;
- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes;

@end


@implementation ACTopBarTitleControl

#pragma mark - Properties

@synthesize loadingMode;
@synthesize titleFragments, selectedTitleFragments;

- (void)setTitleFragments:(NSArray *)fragments
{
    if (fragments == titleFragments)
        return;
    
    [self willChangeValueForKey:@"titleFragments"];
    
    titleFragments = fragments;
    [self _setupTitle];
    
    [self didChangeValueForKey:@"titleFragments"];
}

- (void)setSelectedTitleFragments:(NSIndexSet *)fragments
{
    if (fragments == selectedTitleFragments)
        return;
    
    [self willChangeValueForKey:@"selectedTitleFragments"];
    
    selectedTitleFragments = fragments;
    [self _setupTitle];
    
    [self didChangeValueForKey:@"selectedTitleFragments"];
}

- (void)setLoadingMode:(BOOL)mode
{
    if (mode == loadingMode)
        return;
    
    [self willChangeValueForKey:@"loadingMode"];
    
    loadingMode = mode;
    
    if (loadingMode)
    {
//        UIImage *loadingBackgroundImage = [self backgroundImageForState:ACControlStateLoading];
        if (!_activityIndicatorView)
        {
            _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        }
        [self addSubview:_activityIndicatorView];
        _activityIndicatorView.center = CGPointMake(20, self.bounds.size.height / 2);
        [_activityIndicatorView startAnimating];
    }
    else
    {
        [_activityIndicatorView stopAnimating];
        [_activityIndicatorView removeFromSuperview];
    }
    
    [self didChangeValueForKey:@"loadingMode"];
}

#pragma mark - View Methods

- (void)layoutSubviews
{
    [super layoutSubviews];
    
#warning TODO NIK do layout of segments
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    ECASSERT(0 && "Should not be called, use titleFragments instead");
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    ECASSERT(0 && "Should not be called, use titleFragments instead");
}

#pragma mark - Private Methods

- (void)_setupTitle
{
    NSIndexSet *selected = selectedTitleFragments ? selectedTitleFragments : [NSIndexSet indexSetWithIndex:[titleFragments count] - 1];
    
    [_preViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _preViews = ([selected firstIndex] > 0) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [selected firstIndex])]] : nil;
    
    [_postViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _postViews = ([selected lastIndex] < [titleFragments count] - 1) ? [self _setupViewArrayFromTitleFragmentIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([selected lastIndex], [titleFragments count] - [selected lastIndex])]] : nil;
    
    [super setTitle:nil forState:UIControlStateNormal];
    [super setImage:nil forState:UIControlStateNormal];
    [titleFragments enumerateObjectsAtIndexes:selected options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]])
        {
            [super setTitle:(NSString *)obj forState:UIControlStateNormal];
        }
        else if ([obj isKindOfClass:[UIImage class]])
        {
            [super setImage:(UIImage *)obj forState:UIControlStateNormal];
        }
    }];
}

- (NSArray *)_setupViewArrayFromTitleFragmentIndexes:(NSIndexSet *)fragmentIndexes
{
    if ([fragmentIndexes count] == 0)
        return nil;
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[fragmentIndexes count]];
    [titleFragments enumerateObjectsAtIndexes:fragmentIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]])
        {
            UILabel *label = [UILabel new];
            label.text = (NSString *)obj;
            [result addObject:label];
        }
        else if ([obj isKindOfClass:[UIImage class]])
        {
            [result addObject:[[UIImageView alloc] initWithImage:(UIImage *)obj]];
        }
        else if ([obj isKindOfClass:[UIView class]])
        {
            [result addObject:obj];
        }
        else return;
        [self addSubview:[result lastObject]];
    }];
    return result;
}

@end
