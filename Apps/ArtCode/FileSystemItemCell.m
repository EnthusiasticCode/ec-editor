//
//  FileSystemItemCell.m
//  ArtCode
//
//  Created by Uri Baghin on 10/21/12.
//
//

#import "FileSystemItemCell.h"
#import "FileSystemItem.h"
#import "UIImage+AppStyle.h"


@implementation FileSystemItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }
  @weakify(self);
  [[RACSubscribable combineLatest:@[[[RACAble(item) select:^id<RACSubscribable>(FileSystemItem *x) {
    return [RACSubscribable combineLatest:@[x.name, x.type]];
  }] switch], RACAble(hitMask)]] subscribeNext:^(RACTuple *xs) {
    @strongify(self);
    RACTuple *ys = xs.first;
    NSString *itemName = ys.first;
    NSString *type = ys.second;
    NSIndexSet *hitMask = xs.second;
    self.textLabel.text = itemName;
    self.textLabelHighlightedCharacters = hitMask;
    if (type == NSURLFileResourceTypeDirectory) {
      self.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
      self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
      self.imageView.image = [UIImage styleDocumentImageWithFileExtension:itemName.pathExtension];
      self.accessoryType = UITableViewCellAccessoryNone;
    }
  }];
  return self;
}

@end
