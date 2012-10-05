//
//  QuickFileHighlightTableController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/08/12.
//
//

#import "QuickFileHighlightTableController.h"

#import "CodeFileController.h"
#import "TMUnit.h"
#import "TMSyntaxNode.h"
#import "FileSystemItem+TextFile.h"
#import "RACPropertySyncSubject.h"

@interface QuickFileHighlightTableController ()

@property (nonatomic, strong, readonly) NSArray *syntaxNames;
@property (nonatomic, strong) NSString *currentSyntaxName;

@end

@implementation QuickFileHighlightTableController {
  NSArray *_syntaxNames;
}

- (NSArray *)syntaxNames {
  if (!_syntaxNames) {
    _syntaxNames = [@[ @"Automatic" ] arrayByAddingObjectsFromArray:[[TMSyntaxNode allSyntaxesNames].allKeys sortedArrayUsingSelector:@selector(compare:)]];
  }
  return _syntaxNames;
}

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self) {
    return nil;
  }
  __weak QuickFileHighlightTableController *weakSelf = self;
  [RACAble(self.codeFileController.textFile) subscribeNext:^(FileSystemItem *textFile) {
    QuickFileHighlightTableController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [textFile.explicitSyntaxIdentifier syncProperty:RAC_KEYPATH(strongSelf, currentSyntaxName) ofObject:strongSelf];
  }];
  [RACAble(self.currentSyntaxName) subscribeNext:^(id x) {
    QuickFileHighlightTableController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.tableView reloadData];
  }];
  
  return self;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.syntaxNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
  cell.textLabel.text = [self.syntaxNames objectAtIndex:indexPath.row];
  if ((indexPath.row == 0 && self.currentSyntaxName == nil) || [cell.textLabel.text isEqualToString:self.currentSyntaxName]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
    
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    self.currentSyntaxName = nil;
  } else {
    self.currentSyntaxName = [self.syntaxNames objectAtIndex:indexPath.row];
  }
}

@end
