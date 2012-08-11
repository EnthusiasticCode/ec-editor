//
//  ImagePopoverBackgroundView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/08/12.
//
//

#import "ImagePopoverBackgroundView.h"

#define IMAGE_POPOVER_BACKGORUD_ARROW_BASE 24
#define IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT 12

@implementation ImagePopoverBackgroundView {
  UIImageView *_backgroundView;
  UIImageView *_arrowView;
}

@synthesize arrowOffset = _arrowOffset, arrowDirection = _arrowDirection;

- (void)setArrowOffset:(CGFloat)arrowOffset {
  _arrowOffset = arrowOffset;
  [self layoutSubviews];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {
  _arrowDirection = arrowDirection;
  [self layoutSubviews];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
  [_backgroundView removeFromSuperview];
  _backgroundView = [UIImageView.alloc initWithImage:backgroundImage];
  [self insertSubview:_backgroundView atIndex:0];
}

- (void)setUpArrowImage:(UIImage *)upArrowImage {
  [_arrowView removeFromSuperview];
  _arrowView = [UIImageView.alloc initWithImage:upArrowImage];
  [self insertSubview:_arrowView atIndex:1];
}

- (void)layoutSubviews {
  CGRect backgroundFrame = self.bounds;
  
  if (_arrowView) {
    CGRect arrowFrame;
    switch (_arrowDirection) {
      case UIPopoverArrowDirectionUp:
        backgroundFrame.origin.y += IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT;
        backgroundFrame.size.height -= IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT;
        arrowFrame = CGRectMake(CGRectGetMidX(backgroundFrame) + _arrowOffset - IMAGE_POPOVER_BACKGORUD_ARROW_BASE/2, _arrowInsets.top, IMAGE_POPOVER_BACKGORUD_ARROW_BASE, IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT);
        if (arrowFrame.origin.x < _arrowLimitsInsets.left) {
          arrowFrame.origin.x = _arrowLimitsInsets.left;
        } else if (CGRectGetMaxX(arrowFrame) > backgroundFrame.size.width - _arrowLimitsInsets.right) {
          arrowFrame.origin.x = backgroundFrame.size.width - _arrowLimitsInsets.right - IMAGE_POPOVER_BACKGORUD_ARROW_BASE;
        }
        _arrowView.transform = CGAffineTransformIdentity;
        break;
        
      case UIPopoverArrowDirectionDown:
        backgroundFrame.size.height -= IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT;
        arrowFrame = CGRectMake(CGRectGetMidX(backgroundFrame) + _arrowOffset - IMAGE_POPOVER_BACKGORUD_ARROW_BASE/2, backgroundFrame.size.height - _arrowInsets.bottom, IMAGE_POPOVER_BACKGORUD_ARROW_BASE, IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT);
        if (arrowFrame.origin.x < _arrowLimitsInsets.left) {
          arrowFrame.origin.x = _arrowLimitsInsets.left;
        } else if (CGRectGetMaxX(arrowFrame) > backgroundFrame.size.width - _arrowLimitsInsets.right) {
          arrowFrame.origin.x = backgroundFrame.size.width - _arrowLimitsInsets.right - IMAGE_POPOVER_BACKGORUD_ARROW_BASE;
        }
        _arrowView.transform = CGAffineTransformMakeRotation(M_PI);
        break;
        
      case UIPopoverArrowDirectionLeft:
        backgroundFrame.origin.x -= IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT;
        backgroundFrame.size.width -= IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT;
        arrowFrame = CGRectMake(_arrowInsets.left, CGRectGetMidY(backgroundFrame) + _arrowOffset - IMAGE_POPOVER_BACKGORUD_ARROW_BASE/2, IMAGE_POPOVER_BACKGORUD_ARROW_BASE, IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT);
        _arrowView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        break;
        
      case UIPopoverArrowDirectionRight:
        backgroundFrame.size.width -= IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT;
        arrowFrame = CGRectMake(backgroundFrame.size.width - _arrowInsets.right, CGRectGetMidY(backgroundFrame) + _arrowOffset - IMAGE_POPOVER_BACKGORUD_ARROW_BASE/2, IMAGE_POPOVER_BACKGORUD_ARROW_BASE, IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT);
        _arrowView.transform = CGAffineTransformMakeRotation(M_PI_2);
        break;
        
      default:
        ASSERT(NO); // It should never reach this point
        break;
    }
    _arrowView.frame = arrowFrame;
  }
  
  _backgroundView.frame = UIEdgeInsetsInsetRect(backgroundFrame, _backgroundInsets);
}

#pragma mark - UIPopoverBackgroundView Methods

+ (UIEdgeInsets)contentViewInsets {
  return UIEdgeInsetsMake(5, 5, 5, 5);
}

+ (CGFloat)arrowBase {
  return IMAGE_POPOVER_BACKGORUD_ARROW_BASE;
}

+ (CGFloat)arrowHeight {
  return IMAGE_POPOVER_BACKGORUD_ARROW_HEIGHT;
}

@end
