//
//  ProgressTableViewCell.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/10/12.
//
//

#import "ProgressTableViewCell.h"

@implementation ProgressTableViewCell

- (void)setProgressSubscribable:(RACSubscribable *)progressSubscribable {
  @weakify(self);
  [progressSubscribable subscribeNext:^(id x) {
    @strongify(self);
    if ([x isKindOfClass:[NSNumber class]]) {
      [self.progressView setProgress:(float)[x intValue] / 100.0 animated:YES];
    }
  }];
}

@end
