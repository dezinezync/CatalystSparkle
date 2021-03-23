//
//  Paragraph.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LayoutConstants.h"

#import "TypeFactory.h"
#import "PrefsManager.h"

@class ContentRange;

@interface Link : NSObject

@property (nonatomic, copy) NSURL * _Nonnull url;
@property (nonatomic, assign) NSUInteger location;
@property (nonatomic, assign) NSUInteger length;

+ (instancetype _Nonnull)withURL:(NSURL * _Nonnull)url location:(NSUInteger)location length:(NSUInteger)length;

@end

@class Paragraph;

@protocol TextSharing <NSObject>

- (void)shareText:(NSString * _Nonnull)text paragraph:(Paragraph * _Nonnull)paragraph rect:(CGRect)rect;

@end

@interface Paragraph : UITextView 

@property (nonatomic, assign, getter=isAppearing) BOOL appearing;

@property (nonatomic, assign) BOOL avoidsLazyLoading;

@property (nonatomic, strong) UIFont * _Nullable bodyFont;

// these are automatically updated when the bodyFont changes
@property (nonatomic, strong) UIFont * _Nullable italicsFont, * _Nullable boldFont, * _Nullable boldItalicsFont;

@property (nonatomic, assign) BOOL afterHeading;
@property (nonatomic, assign, getter=isCaption) BOOL caption;

@property (nonatomic, strong, class) NSParagraphStyle * _Nullable paragraphStyle;

@property (nonatomic, strong) NSLayoutConstraint * _Nullable leading, * _Nullable trailing;

// All the links contained in this paragraph.
@property (nonatomic, strong, readonly) NSMutableSet <Link *> * _Nonnull links;

- (void)viewWillAppear;
- (void)viewDidDisappear;

- (void)setText:(NSString * _Nonnull)text ranges:(NSArray <ContentRange *> * _Nullable)ranges attributes:(NSDictionary * _Nullable)attributes;

+ (NSLocaleLanguageDirection)languageDirectionForText:(NSString * _Nonnull)text;

- (void)updateStyle:(id _Nullable)animated;

+ (BOOL)canPresentContextMenus API_AVAILABLE(ios(13.0));

/**
 Process the given text and ranges and returns an Attributed String. Processes on the thread it is called on. Returns on the same thread.

 @param text The base NSString to process
 @param ranges The appliable ranges
 @return An attributed string
 */
- (NSAttributedString * _Nullable )processText:(NSString * _Nonnull)text ranges:(NSArray <ContentRange *> * _Nonnull)ranges attributes:(NSDictionary * _Nonnull)attributes;

- (NSArray <UIView *> * _Nonnull)ignoreSubviewsFromLayouting;

#pragma mark -

/**
  Set this to true when appending multiple paragraphs to the same Interface. Affects Voice Over and enables paragraph by paragraph control.
 */
@property (nonatomic, assign, getter=isBigContainer) BOOL bigContainer;

@property (nonatomic, strong) NSMutableArray * _Nullable accessibileElements;

#pragma mark -

+ (CGRect)boundingRectIn:(UITextView * _Nonnull)textview forCharacterRange:(NSRange)range;

#pragma mark

@property (nonatomic, weak) id<TextSharing> _Nullable textSharingDelegate;

@end
