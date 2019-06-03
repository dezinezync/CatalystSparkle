//
//  ArticleAuthorView.h
//  Yeti
//
//  Created by Nikhil Nigade on 28/03/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ArticleAuthorViewDelegate <NSObject>

- (void)didTapMercurialButton:(id)sender completion:(void (^_Nullable)(BOOL completed))completionHandler;

@end

@interface ArticleAuthorView : NibView

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *blogLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;

@property (nonatomic, assign) BOOL mercurialed;

@property (weak, nonatomic) IBOutlet UIButton *mercurialButton;

- (IBAction)mercurialButton:(id)sender;

@property (weak, nonatomic) id<ArticleAuthorViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
