//
//  ProgressTableViewCell.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/10/12.
//
//

#import "ProgressTableViewCell.h"

@implementation ProgressTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }
  if (!self.progressView) {
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.accessoryView = self.progressView;
    self.editingAccessoryView = self.progressView;
  }
  self.textLabel.textColor = [UIColor grayColor];
  return self;
}

- (void)setProgressSignal:(RACSignal *)progressSignal {
  @weakify(self);
  [progressSignal subscribeNext:^(id x) {
    @strongify(self);
    if ([x isKindOfClass:[NSNumber class]]) {
      [self.progressView setProgress:(float)[x intValue] / 100.0 animated:YES];
    }
  }];
}

@end
