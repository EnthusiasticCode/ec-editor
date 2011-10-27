//
//  ACTopBarTitleControl.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTopBarTitleControl.h"

@implementation ACTopBarTitleControl {
    UIActivityIndicatorView *_activityIndicatorView;
}

@synthesize loadingMode;

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

@end
