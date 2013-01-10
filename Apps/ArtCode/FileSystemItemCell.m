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
#import "NSString+Utilities.h"
#import "ArtCodeProjectSet.h"

@implementation FileSystemItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }
  @weakify(self);
  [[RACSignal combineLatest:@[[[RACAble(item) map:^RACSignal *(FileSystemItem *x) {
    return [RACSignal combineLatest:@[x.name, x.type, x.url]];
  }] switchToLatest], RACAbleWithStart(hitMask)]] subscribeNext:^(RACTuple *xs) {
    ASSERT_MAIN_QUEUE();
    @strongify(self);
    RACTuple *ys = xs.first;
    NSString *itemName = ys.first;
    NSString *type = ys.second;
		NSURL *url = ys.third;
    NSIndexSet *hitMask = xs.second;
    UITableViewCellAccessoryType accessoryType = self.accessoryType;
    UITableViewCellAccessoryType editingAccessoryType = self.editingAccessoryType;
    self.textLabel.text = itemName;
    self.textLabelHighlightedCharacters = hitMask;
		if (style == UITableViewCellStyleSubtitle) {
			self.detailTextLabel.text = [[[ArtCodeProjectSet defaultSet] relativePathForFileURL:url] prettyPath];
		}
    // Crazy hack because UITableViewCell doesn't redraw properly if you change certain properties after it was inserted in a table view, unless you change it's accessoryType
    if (type == NSURLFileResourceTypeDirectory) {
      self.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
      if (accessoryType != UITableViewCellAccessoryNone) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryType = accessoryType;
      } else {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      if (editingAccessoryType != UITableViewCellAccessoryNone) {
        self.editingAccessoryType = UITableViewCellAccessoryNone;
        self.editingAccessoryType = editingAccessoryType;
      } else {
        self.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
      }
    } else {
      self.imageView.image = [UIImage styleDocumentImageWithFileExtension:itemName.pathExtension];
      if (accessoryType != UITableViewCellAccessoryNone) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryType = accessoryType;
      } else {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
        self.accessoryType = UITableViewCellAccessoryNone;
      }
      if (editingAccessoryType != UITableViewCellAccessoryNone) {
        self.editingAccessoryType = UITableViewCellAccessoryNone;
        self.editingAccessoryType = editingAccessoryType;
      } else {
        self.editingAccessoryType = UITableViewCellAccessoryCheckmark;
        self.editingAccessoryType = UITableViewCellAccessoryNone;
      }
    }
  }];
  return self;
}

- (void)prepareForReuse {
  self.accessoryType = UITableViewCellAccessoryNone;
  self.editingAccessoryType = UITableViewCellAccessoryNone;
}

@end
