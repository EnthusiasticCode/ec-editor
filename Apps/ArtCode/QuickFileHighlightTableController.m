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
#import "TextFile.h"

@interface QuickFileHighlightTableController ()

@property (nonatomic, strong, readonly) NSArray *syntaxNames;
@property (nonatomic, strong) NSString *currentSyntaxName;

@end

@implementation QuickFileHighlightTableController {
  NSArray *_syntaxNames;
}

- (NSArray *)syntaxNames {
  if (!_syntaxNames) {
    _syntaxNames = [[TMSyntaxNode allSyntaxesNames].allKeys sortedArrayUsingSelector:@selector(compare:)];
  }
  return _syntaxNames;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.currentSyntaxName = self.codeFileController.codeUnit.syntax.name;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.syntaxNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
  cell.textLabel.text = [self.syntaxNames objectAtIndex:indexPath.row];
  if ([cell.textLabel.text isEqualToString:self.currentSyntaxName]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
    
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.currentSyntaxName = [self.syntaxNames objectAtIndex:indexPath.row];
  self.codeFileController.textFile.explicitSyntaxIdentifier = [[TMSyntaxNode allSyntaxesNames] objectForKey:self.currentSyntaxName];
  [self.tableView reloadData];
}

@end
