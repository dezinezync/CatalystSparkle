//
//  FolderCell.m
//  Elytra
//
//  Created by Nikhil Nigade on 08/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FolderCell.h"

@interface FolderCell ()

@property (nonatomic, copy, readwrite) NSNumber *folderID;

@end

@implementation FolderCell

- (void)configure:(Folder *)item indexPath:(NSIndexPath *)indexPath {
    
    self.folder = item;
    
    if (self.folder == nil) {
        return;
    }
    
    UIListContentConfiguration *content = [UIListContentConfiguration sidebarSubtitleCellConfiguration];
    
    content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    content.text = item.title;
    
    if (SharedPrefs.showUnreadCounts == YES) {
        
        item.unreadCountObservor = self;
        
        if (item.unreadCount.unsignedIntegerValue > 0) {
            
            content.secondaryText = item.unreadCount.stringValue;
            
        }
        
    }
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomMac) {
        content.textProperties.color = UIColor.secondaryLabelColor;
    }
    else {
        content.textProperties.color = UIColor.labelColor;
    }
    
    content.secondaryTextProperties.color = UIColor.secondaryLabelColor;
    
    content.prefersSideBySideTextAndSecondaryText = YES;
    
    NSDiffableDataSourceSectionSnapshot *snapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
    
    NSString *imageName = [snapshot isExpanded:item] ? @"folder" : @"folder.fill";
    
    content.image = [UIImage systemImageNamed:imageName];
    
    content.imageProperties.maximumSize = CGSizeMake(24.f, 24.f);
    
    self.contentConfiguration = content;
    
    UICellAccessoryOutlineDisclosure *disclosure = [UICellAccessoryOutlineDisclosure new];
    
    disclosure.style = UICellAccessoryOutlineDisclosureStyleHeader;
    
#if TARGET_OS_MACCATALYST
    disclosure.actionHandler = ^{
        
        NSDiffableDataSourceSectionSnapshot *snapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
        
        if ([snapshot isExpanded:item]) {
            
            NSLogDebug(@"item was expanded");
            
            [snapshot collapseItems:@[item]];
        }
        else {
            
            NSLogDebug(@"item was collapsed");
            
            [snapshot expandItems:@[item]];
        }
        
        [self.DS applySnapshot:snapshot toSection:@(NSUIntegerMax - 200) animatingDifferences:YES];
        
    };
#endif
    
    self.accessories = @[disclosure];
    
}

- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    
    UIListContentConfiguration *updatedContent = (id)[self contentConfiguration];
    
    if (state.isExpanded == YES) {
        
        updatedContent.image = [UIImage systemImageNamed:@"folder"];
        
    }
    else {
        
        updatedContent.image = [UIImage systemImageNamed:@"folder.fill"];
        
    }
    
    self.contentConfiguration = updatedContent;
    
}

- (void)unreadCountChangedFor:(Folder *)folder to:(NSNumber *)count {
    
    /*
     * in iOS 14 - Beta 4, when a cell is expanded,
     * the primary cell is hidden and replaced with
     * with a visible cell at the same index path.
     * Because of this, we cannot reference *self* here.
     */
       
    FolderCell *cell = (id)[(UICollectionView *)[self.DS valueForKey:@"collectionView"] cellForItemAtIndexPath:[self.DS indexPathForItemIdentifier:folder]];

    if (cell == nil) {
       return;
    }
    
    UIListContentConfiguration *content = (id)[cell contentConfiguration];
        
    if (count.unsignedIntegerValue > 0) {
        content.secondaryText = count.stringValue;
    }
    else {
        content.secondaryText = nil;
    }
    
    cell.contentConfiguration = content;
    
}

@end
