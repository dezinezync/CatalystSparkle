//
//  FeedVC+ContextMenus.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+ContextMenus.h"
#import "AuthorVC.h"
#import "AppDelegate.h"

#import <DZKit/NSString+Extras.h>

@implementation FeedVC (ContextMenus)

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    
    FeedItem *item = [self itemForIndexPath:indexPath];
    
    if (item == nil) {
        return nil;
    }
    
    UIContextMenuConfiguration *config = [UIContextMenuConfiguration configurationWithIdentifier:formattedString(@"feedItem-%@", @(item.hash)) previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        
        UIAction *read = nil;
        
        if (item.isRead == YES) {
            
            read = [UIAction actionWithTitle:@"Unread" image:[UIImage systemImageNamed:@"circle"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self userMarkedArticle:item read:NO];
                
            }];
            
        }
        else {
            read = [UIAction actionWithTitle:@"Read" image:[UIImage systemImageNamed:@"largecircle.fill.circle"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self userMarkedArticle:item read:YES];
                
            }];
        }
        
        UIAction *bookmark = nil;
        
        if (item.isBookmarked == YES) {
            
            bookmark = [UIAction actionWithTitle:@"Unbookmark" image:[UIImage systemImageNamed:@"bookmark"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
                [self userMarkedArticle:item bookmarked:NO];
                
            }];
            
        }
        else {
            bookmark = [UIAction actionWithTitle:@"Bookmark" image:[UIImage systemImageNamed:@"bookmark.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self userMarkedArticle:item bookmarked:YES];
                
            }];
        }
        
        UIAction *browser = [UIAction actionWithTitle:@"Open in Browser" image:[UIImage systemImageNamed:@"safari"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
#if TARGET_OS_OSX
            [MyAppDelegate.sharedGlue openURL:[NSURL URLWithString:item.articleURL] inBackground:YES];
            return;
#endif
        
            NSURL *URL = formattedURL(@"yeti://external?link=%@", item.articleURL);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
                
            });
            
        }];
        
        UIAction *share = [UIAction actionWithTitle:@"Share Article" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
            [self wantsToShare:item indexPath:indexPath];
            
        }];
        
        if (self.type == FeedVCTypeNatural) {
            
            NSString *author;
            
            if ([item.author isKindOfClass:NSString.class]) {
                
                if ([item.author isBlank] == NO) {
                    
                    author = [(item.author ?: @"") stringByStrippingHTML];
                    
                }
                
            }
            else {
                
                author = [([item.author valueForKey:@"name"] ?: @"") stringByStrippingHTML];
                
            }
            
            if (author != nil && author.length > 0) {
                
                NSString *title = [NSString stringWithFormat:@"Articles by %@", author];
                
                UIAction *authorAction = [UIAction actionWithTitle:title image:[UIImage systemImageNamed:@"person.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                   
                    [self showAuthorVC:author];
                    
                }];
                
                return [UIMenu menuWithTitle:@"Article Actions" children:@[read, bookmark, browser, share, authorAction]];
                
            }
            
        }
        
        return [UIMenu menuWithTitle:@"Article Actions" children:@[read, bookmark, browser, share]];
        
    }];
    
    return config;
    
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *item = [self itemForIndexPath:indexPath];
    
    if (item == nil) {
        return nil;
    }
    
    NSMutableArray <UIContextualAction *> *actions = [NSMutableArray arrayWithCapacity:2];
    
    UIContextualAction *read = nil;
    
    if (item.isRead == YES) {
        
        read = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Unread" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            [self userMarkedArticle:item read:NO];
            
            completionHandler(YES);
            
        }];
        
        read.image = [UIImage systemImageNamed:@"circle"];
        
    }
    else {
        
        read = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Read" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            [self userMarkedArticle:item read:YES];
            
            completionHandler(YES);
            
        }];
        
        read.image = [UIImage systemImageNamed:@"largecircle.fill.circle"];
        
    }
    
    read.backgroundColor = UIColor.systemBlueColor;
    
    [actions addObject:read];
    
    UIContextualAction *bookmark = nil;
    
    if (item.isBookmarked == YES) {
        
        bookmark = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Unbookmark" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            [self userMarkedArticle:item bookmarked:NO];
            
            completionHandler(YES);
            
        }];
        
        bookmark.image = [UIImage systemImageNamed:@"bookmark"];
        
    }
    else {
        
        bookmark = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Bookmark" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            [self userMarkedArticle:item bookmarked:YES];
            
            completionHandler(YES);
            
        }];
        
        bookmark.image = [UIImage systemImageNamed:@"bookmark.fill"];
        
    }
    
    bookmark.backgroundColor = UIColor.systemOrangeColor;
    
    [actions addObject:bookmark];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:actions];
    
    return config;
    
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *item = [self itemForIndexPath:indexPath];
    
    if (item == nil) {
        return nil;
    }
    
    NSMutableArray <UIContextualAction *> *actions = [NSMutableArray arrayWithCapacity:2];
    
    UIContextualAction *browser = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Browser" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        completionHandler(YES);
        
#if TARGET_OS_OSX
            [MyAppDelegate.sharedGlue openURL:[NSURL URLWithString:item.articleURL] inBackground:YES];
            return;
#endif
        
        NSURL *URL = formattedURL(@"yeti://external?link=%@", item.articleURL);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
            
        });
        
    }];
    
    browser.image = [UIImage systemImageNamed:@"safari"];
    
    browser.backgroundColor = UIColor.systemTealColor;
    
    [actions addObject:browser];
    
    UIContextualAction *share = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        completionHandler(YES);
        
        [self wantsToShare:item indexPath:indexPath];
        
    }];
    
    share.image = [UIImage systemImageNamed:@"square.and.arrow.up"];
    
    share.backgroundColor = UIColor.systemGrayColor;
    
    [actions addObject:share];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:actions];
    
    return config;
    
}

#pragma mark -

- (void)wantsToShare:(FeedItem *)item indexPath:(NSIndexPath *)indexPath {
    
    NSString *title = item.articleTitle;
    NSURL *URL = formattedURL(@"%@", item.articleURL);
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[title, URL] applicationActivities:nil];
    
    UIPopoverPresentationController *pvc = avc.popoverPresentationController;
    pvc.sourceView = self.tableView;
    pvc.sourceRect = [[self.tableView cellForRowAtIndexPath:indexPath] frame];
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

- (void)showAuthorVC:(NSString *)author {
    
    if (!author || [author isBlank]) {
        return;
    }
    
    AuthorVC *vc = [[AuthorVC alloc] initWithFeed:self.feed author:author];
    
    [self.navigationController pushViewController:vc animated:YES];
    
}

#pragma mark - <UIAdaptivePresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        return UIModalPresentationPopover;
    }
    
    return UIModalPresentationNone;
}

@end