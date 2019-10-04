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
#import "ArticlePhoto.h"

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZNetworking/ImageLoader.h>

@implementation ArticleVC (Photos)

- (void)didTapOnImage:(UITapGestureRecognizer *)sender {
    
    NSLog(@"Sender state: %@", @(sender.state));
    
    NSArray *images = self.images.allObjects;
    
    if (images.count == 0) {
        return;
    }
    
    NSUInteger index = NSNotFound, counter = -1;
    
    NSMutableArray <ArticlePhoto *> *_images = [NSMutableArray new];
        
    for (id image in images) {
        
        if ([image isKindOfClass:Image.class]) {
            
            Content *content = [(Image *)image content];
            
            if (content != nil) {
                
                ArticlePhoto *photo = [ArticlePhoto new];
                photo.referenceView = image;
                photo.placeholderImage = [(Image *)image imageView].image;
                photo.URL = [NSURL URLWithString:content.url];
                
                NSString *title = nil;
                
                if (content.attributes != nil
                    && (content.attributes[@"title"] || content.attributes[@"alt"])) {
                    
                    title = content.attributes[@"alt"] ?: content.attributes[@"title"];
                    
                    photo.attributedCaptionSummary = [self captionForText:title];
                }
                
                [_images addObject:photo];
                counter++;
                
                if (sender.view == image && index == NSNotFound) {
                    index = counter;
                }
                
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
    
}

- (void)didTapOnImageWithURL:(UITapGestureRecognizer *)sender {
    
    Image *view = (Image *)[sender view];
    NSString *url = [[view URL] absoluteString];
    
    NSURL *formatted = formattedURL(@"yeti://external?link=%@", url);
    
    [UIApplication.sharedApplication openURL:formatted options:@{} completionHandler:nil];
    
}

#pragma mark - <NYTPhotosViewControllerDelegate>

- (NSAttributedString *)captionForText:(NSString *)text {
    
    if (text == nil) {
        return nil;
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: UIColor.labelColor, NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]}];
    
}

- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToPhoto:(ArticlePhoto *)photo atIndex:(NSUInteger)photoIndex {
    
    if (photo.image == nil && photo.task == nil) {
        
        photo.task = [SharedImageLoader downloadImageForURL:photo.URL success:^(UIImage * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            photo.image = responseObject;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [photosViewController updatePhoto:photo];
            });
            
            photo.task = nil;
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
#ifdef DEBUG
            NSLog(@"Error downloading image: %@", photo.URL);
#endif
            
            NSString *errorString = [[NSString alloc] initWithFormat:@"Error downloading: %@", error.localizedDescription];
            
            photo.attributedCaptionSummary = [self captionForText:errorString];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [photosViewController updatePhoto:photo];
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

@end
