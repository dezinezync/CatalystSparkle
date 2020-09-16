//
//  ArticleVC+Photos.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Photos.h"

#import "Image.h"
#import "Gallery.h"

#import "IDMPhotoBrowser.h"

#import <DZKit/NSArray+RZArrayCandy.h>

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImage+MultiFormat.h>

@implementation ArticleVC (Photos)

- (void)didTapOnImage:(UITapGestureRecognizer *)sender {
    
    if (sender.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    Image *image = (Image *)[sender view];
    
#if TARGET_OS_MACCATALYST
    
    [self ct_didTapOnImage:image];
    
    return;
    
#endif
    
    if (image.link != nil) {
        
        [self openLinkExternally:image.link.absoluteString];
        return;
        
    }
    
    NSArray *images = self.images.allObjects;
    
    if (images.count == 0) {
        return;
    }
    
    NSUInteger index = NSNotFound,
               counter = -1;
    
    
    
     NSMutableArray <IDMPhoto *> *_images = [NSMutableArray new];
        
    for (id obj in images) {
        
        if ([obj isKindOfClass:Image.class]) {
            
            Image *image = obj;
            
            NSURL *url = image.URL;
            
            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark
                && image.darkModeURL != nil) {
                
                url = image.darkModeURL;
                
            }
            
            IDMPhoto *photo = [IDMPhoto photoWithURL:url];
            
            photo.placeholderImage = image.imageView.image;
            
            Content *content = [(Image *)image content];
            
            if (content != nil) {
                
                NSString *title = nil;
                
                if (content.attributes != nil
                    && (content.attributes[@"title"] || content.attributes[@"alt"])) {
                    
                    title = content.attributes[@"alt"] ?: content.attributes[@"title"];
                }
                
                photo.caption = title;
                
            }
            else if ([(Image *)image accessibilityValue] != nil) {
                photo.caption = image.accessibilityValue;
            }
            
            [_images addObject:photo];
            counter++;
            
            if (sender.view == image && index == NSNotFound) {
                index = counter;
            }
            
        }
        else if ([image isKindOfClass:Gallery.class]) {
            
            for (Content *img in [(Gallery *)image images]) {
                
                IDMPhoto *photo = [IDMPhoto photoWithURL:[NSURL URLWithString:img.url]];
                
//                photo.referenceView = image;
                
                NSString *title = nil;
                
                if (img.attributes != nil
                    && (img.attributes[@"title"] || img.attributes[@"alt"])) {
                    
                    title = img.attributes[@"alt"] ?: img.attributes[@"title"];
                    
                    photo.caption = title;
                }
                
                [_images addObject:photo];
                
                counter++;
                
                if (sender.view == image && index == NSNotFound) {
                    index = counter;
                }
                
            }
                
        }
        else {
            NSLog(@"Unknown class for image in ImageViewerController :%@", NSStringFromClass([image class]));
//            [_images addObject:img];
        }
    }
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:_images animatedFromView:sender.view];
    
    if (index != NSNotFound) {
        [browser setInitialPageIndex:index];
    }
    
    browser.usePopAnimation = YES;
    
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17.f weight:UIImageSymbolWeightMedium];
    
    UIImage *leftImage = [UIImage systemImageNamed:@"chevron.left" withConfiguration:config];
    UIImage *rightImage = [UIImage systemImageNamed:@"chevron.right" withConfiguration:config];
    UIImage *shareImage = [UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:config];
    
    UIColor *fadedColor = [UIColor colorWithWhite:1.f alpha:0.3f];
    
    browser.leftArrowImage = [leftImage imageWithTintColor:fadedColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    browser.rightArrowImage = [rightImage imageWithTintColor:fadedColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    
    browser.leftArrowSelectedImage = [leftImage imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    browser.rightArrowSelectedImage = [rightImage imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    
    browser.actionButtonImage = [shareImage imageWithTintColor:fadedColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    browser.actionButtonSelectedImage = [shareImage imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [self presentViewController:browser animated:YES completion:nil];
    
}

#if TARGET_OS_MACCATALYST

- (void)ct_didTapOnImage:(Image *)image {
    
    NSUserActivity *viewImageActivity = [[NSUserActivity alloc] initWithActivityType:@"viewImage"];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    if (image.imageView.image != nil) {
        dict[@"image"] = [image.imageView.image sd_imageData];
    }
    
    if (image.URL != nil) {
        dict[@"URL"] = image.URL;
    }
    
    if (image.darkModeURL != nil) {
        dict[@"darkURL"] = image.darkModeURL;
    }
    
    if (image.content != nil && image.content.alt != nil) {
        
        dict[@"alt"] = image.content.alt;
        
    }
    else if (image.content != nil && image.content.attributes[@"alt"] != nil) {
     
        dict[@"alt"] = image.content.attributes[@"alt"];
        
    }
    
    if (dict.keyEnumerator.allObjects.count == 0) {
        return;
    }
    
    [viewImageActivity addUserInfoEntriesFromDictionary:dict];
    
    [UIApplication.sharedApplication requestSceneSessionActivation:nil userActivity:viewImageActivity options:kNilOptions errorHandler:^(NSError * _Nonnull error) {
        
        if (error != nil) {
            
            NSLog(@"Error occurred requesting new window session. %@", error.localizedDescription);
            
        }
        
    }];
    
}

#endif

- (void)didTapOnImageWithURL:(UITapGestureRecognizer *)sender {
    
    Image *view = (Image *)[sender view];
    NSString *url = [[view URL] absoluteString];
    
    NSURL *formatted = formattedURL(@"yeti://external?link=%@", url);
    
    [UIApplication.sharedApplication openURL:formatted options:@{} completionHandler:nil];
    
}

/*
#pragma mark - <NYTPhotosViewControllerDelegate>

- (NSAttributedString *)captionForText:(NSString *)text {
    
    if (text == nil) {
        return nil;
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: UIColor.labelColor, NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]}];
    
}

- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToPhoto:(ArticlePhoto *)photo atIndex:(NSUInteger)photoIndex {
    
    if (photo == nil) {
        return;
    }
    
    if (photo.image == nil && photo.task == nil) {
        
        photo.task = [[SDWebImageManager sharedManager] loadImageWithURL:photo.URL options:kNilOptions progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            
            if (error != nil) {
                
                NSLogDebug(@"Error downloading image: %@", photo.URL);
            
                NSString *errorString = [[NSString alloc] initWithFormat:@"Error downloading: %@", error.localizedDescription];
                
                photo.attributedCaptionSummary = [self captionForText:errorString];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [photosViewController reloadPhotosAnimated:NO];
                });
                
                photo.task = nil;
                
                return;
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                photo.downloadedImage = image;
                
                [photosViewController reloadPhotosAnimated:NO];
                
            });
            
            photo.task = nil;
            
            
        }];
        
    }
    
}

- (CGFloat)photosViewController:(NYTPhotosViewController *)photosViewController maximumZoomScaleForPhoto:(id<NYTPhoto>)photo {
    
    if (photo.image == nil) {
        return 1.f;
    }
    
    CGFloat maxWidth = photosViewController.view.window.frame.size.width;
    CGFloat maxHeight = photosViewController.view.window.frame.size.height;
    
    CGFloat imageWidth = photo.image.size.width/UIScreen.mainScreen.scale;
    CGFloat imageHeight = photo.image.size.height/UIScreen.mainScreen.scale;
    
    CGFloat widthScale = imageWidth/maxWidth;
    CGFloat heightScale = imageHeight/maxHeight;
    
    CGFloat scale = MAX(1.f, MIN(widthScale, heightScale));
    
    return scale;
    
}

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController referenceViewForPhoto:(id<NYTPhoto>)photo {
    
    return [(ArticlePhoto *)photo referenceView];
    
}

- (void)photosViewControllerDidDismiss:(NYTPhotosViewController *)photosViewController {
    
    self.photosDS = nil;
    
}
 */

@end
