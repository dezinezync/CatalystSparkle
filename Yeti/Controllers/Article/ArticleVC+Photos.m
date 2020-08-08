//
//  ArticleVC+Photos.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Photos.h"

#import <DZTextKit/Image.h>
#import <DZTextKit/Gallery.h>
//#import "ArticlePhoto.h"

#import <DZKit/NSArray+RZArrayCandy.h>

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImage+MultiFormat.h>

@implementation ArticleVC (Photos)

- (void)didTapOnImage:(UITapGestureRecognizer *)sender {
    
    /*
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
    
    NSUInteger index = NSNotFound, counter = -1;
    
    NSMutableArray <ArticlePhoto *> *_images = [NSMutableArray new];
        
    for (id image in images) {
        
        if ([image isKindOfClass:Image.class]) {
            
            ArticlePhoto *photo = [ArticlePhoto new];
            photo.referenceView = image;
            photo.placeholderImage = [(Image *)image imageView].image;
            photo.URL = [(Image *)image URL];
            
            Content *content = [(Image *)image content];
            
            if (content != nil) {
                
                NSString *title = nil;
                
                if (content.attributes != nil
                    && (content.attributes[@"title"] || content.attributes[@"alt"])) {
                    
                    title = content.attributes[@"alt"] ?: content.attributes[@"title"];
                    
                    photo.attributedCaptionSummary = [self captionForText:title];
                }
                
            }
            else if ([(Image *)image accessibilityValue] != nil) {
                photo.attributedCaptionSummary = [self captionForText:[(Image *)image accessibilityValue]];
            }
            
            [_images addObject:photo];
            counter++;
            
            if (sender.view == image && index == NSNotFound) {
                index = counter;
            }
            
        }
        else if ([image isKindOfClass:Gallery.class]) {
            
            for (Content *img in [(Gallery *)image images]) {
                
                ArticlePhoto *photo = [ArticlePhoto new];
                photo.referenceView = image;
                photo.URL = [NSURL URLWithString:img.url];
                
                NSString *title = nil;
                
                if (img.attributes != nil
                    && (img.attributes[@"title"] || img.attributes[@"alt"])) {
                    
                    title = img.attributes[@"alt"] ?: img.attributes[@"title"];
                    
                    photo.attributedCaptionSummary = [self captionForText:title];
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
    
    self.photosDS = [NYTPhotoViewerArrayDataSource dataSourceWithPhotos:_images];
    
    ArticlePhoto *initialPhoto = nil;
    
    if (index != NSNotFound && index < _images.count) {
        initialPhoto = [_images objectAtIndex:index];
    }
    
    NYTPhotosViewController *photosViewController = [[NYTPhotosViewController alloc] initWithDataSource:self.photosDS initialPhoto:initialPhoto delegate:self];
    
    weakify(self);

    [self presentViewController:photosViewController animated:YES completion:^{
        
        strongify(self);
        
        [self photosViewController:photosViewController didNavigateToPhoto:_images.firstObject atIndex:0];
        
    }];
     */
    
}

#if TARGET_OS_MACCATALYST

- (void)ct_didTapOnImage:(Image *)image {
    /*
    
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
     */
    
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
