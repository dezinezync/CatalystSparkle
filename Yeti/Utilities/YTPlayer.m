//
//  YTPlayer.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YTPlayer.h"

@interface YTPlayer () <UIContextMenuInteractionDelegate>

@end

@implementation YTPlayer

- (void)setRate:(float)rate {
    [super setRate:rate];
    
    if (rate > 0.f && self.playerViewController != nil) {
        
        // check if the cover is being shown.
        if ([self.playerViewController.contentOverlayView subviews].count > 0) {
            
            for (UIView *subview in self.playerViewController.contentOverlayView.subviews) {
                
                if ([subview isKindOfClass:UIImageView.class]) {
                
                    [UIView animateWithDuration:0.25 animations:^{
                    
                        subview.alpha = 0.f;
                        
                    } completion:^(BOOL finished) {
                        
                        if (finished) {
                            [subview removeFromSuperview];
                        }
                        
                    }];
                    
                }
                else if ([subview isKindOfClass:UIButton.class]) {
                    
                    [subview removeFromSuperview];
                    
                }
                
            }
            
        }
        // ensure this does not run again
        self.playerViewController = nil;
        
    }
    
}

- (void)addContextMenus {
    
    if (self.playerViewController == nil) {
        return;
    }
    
    UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    
    [self.playerViewController.view addInteraction:interaction];
    
}

#pragma mark - <UIContextMenuInteraction>

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
       
        return [self makeContextMenu];
        
    }];
    
}

- (UIMenu *)makeContextMenu {
    
    BOOL isPlaying = self.rate > 0.f;
    NSString *title = isPlaying ? @"Pause" : @"Play";
    NSString *imageName = isPlaying ? @"pause.fill" : @"play.fill";
    
    UIAction *playPause = [UIAction actionWithTitle:title image:[UIImage systemImageNamed:imageName] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
        if (isPlaying) {
            [self pause];
        }
        else {
            [self play];
        }
        
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[playPause]];
    
    return menu;
    
}

@end
