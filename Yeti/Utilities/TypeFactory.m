//
//  TypeFactory.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "TypeFactory.h"
#import <DZAppdelegate/UIApplication+KeyWindow.h>
#import "YetiConstants.h"

BOOL IS_PAD (UIViewController *viewController) {
    return viewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

static TypeFactory * sharedTypeFactory;

@interface TypeFactory ()

@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, weak) UIViewController *rootController;

@end

@implementation TypeFactory

+ (NSArray <NSString *> *)mappedProperties {
    
    return @[propSel(titleFont),
             propSel(caption1Font),
             propSel(caption2Font),
             propSel(subtitleFont),
             propSel(footnoteFont),
             propSel(bodyFont),
             propSel(boldBodyFont),
             propSel(italicBodyFont),
             propSel(boldItalicBodyFont),
             propSel(codeFont),
             propSel(boldCodeFont),
             propSel(italicCodeFont)];
    
}

+ (instancetype)shared {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTypeFactory = [[TypeFactory alloc] init];
    });
    
    return sharedTypeFactory;
}

#pragma mark - Lifecycle

- (instancetype)init {
    
    if (self = [super init]) {
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(didUpdateContentCategory) name:UIContentSizeCategoryDidChangeNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(didUpdateContentCategory) name:UIAccessibilityBoldTextStatusDidChangeNotification object:nil];
    }
    
    return self;
    
}

- (void)dealloc {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    [notificationCenter removeObserver:self name:UIAccessibilityBoldTextStatusDidChangeNotification object:nil];
    
}

#pragma mark - Utilities

- (UIFont *)scaledFontForStyle:(UIFontTextStyle)style maximumPointSize:(CGFloat)pointSize {
    
    UIFont *font = [UIFont preferredFontForTextStyle:style];
    
    pointSize = pointSize * self.scale;
    
    if ([style isEqualToString:UIFontTextStyleCaption1]
        || [style isEqualToString:UIFontTextStyleCaption2]
        || [style isEqualToString:UIFontTextStyleFootnote]) {
        
        if (pointSize > 13.f) {
            pointSize = pointSize - 2.f;
        }
        else {
            pointSize = pointSize / self.scale;
        }
        
    }
    else {
        pointSize = pointSize * self.scale;
    }
    
    pointSize = floor(pointSize);
    
    if(UIAccessibilityIsBoldTextEnabled()) {
        UIFontDescriptor *descriptor = [font fontDescriptor];
        [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        
        font = [UIFont fontWithDescriptor:descriptor size:font.pointSize];
    }
    
    UIFont *scaled = [[UIFontMetrics defaultMetrics] scaledFontForFont:font maximumPointSize:pointSize compatibleWithTraitCollection:self.rootController.traitCollection];
    
    return scaled;
}

#pragma mark - Notifications

- (void)didUpdateContentCategory {
 
    // set all our mapped properties to nil so they can be reloaded
    for (NSString *keypath in [TypeFactory mappedProperties]) {
        [self setValue:nil forKeyPath:keypath];
    }
    
    self.scale = 0.f;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdatedPreferredFontMetrics object:nil];
    });
    
}

#pragma mark - Getters

- (CGFloat)scale {
    if (_scale == 0.f) {
        _scale = [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] pointSize] / 17.f;
    }
    
    return _scale;
}

- (UIViewController *)rootController {
    
    if (!_rootController) {
        _rootController = [UIApplication.keyWindow rootViewController];
    }
    
    return _rootController;
    
}


- (UIFont *)titleFont {
    
    UIFontTextStyle const style = UIFontTextStyleHeadline;
    CGFloat maximumPointSize = 32.f;
    
    if (_titleFont == nil) {
        if (IS_PAD(self.rootController)) {
            _titleFont = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
        }
        else {
            _titleFont = [UIFont preferredFontForTextStyle:style];
        }
    }
    
    return _titleFont;
    
}

- (UIFont *)caption1Font {
    
    UIFontTextStyle const style = UIFontTextStyleCaption1;
    CGFloat maximumPointSize = 13.f;
    
    if (_caption1Font == nil) {
        if (IS_PAD(self.rootController)) {
            _caption1Font = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
        }
        else {
            _caption1Font = [UIFont preferredFontForTextStyle:style];
        }
    }
    
    return _caption1Font;
    
}

- (UIFont *)caption2Font {
    UIFontTextStyle const style = UIFontTextStyleCaption2;
    CGFloat maximumPointSize = 12.f;
    
    if (_caption2Font == nil) {
        if (IS_PAD(self.rootController)) {
            _caption2Font = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
        }
        else {
            _caption2Font = [UIFont preferredFontForTextStyle:style];
        }
    }
    
    return _caption2Font;
}

- (UIFont *)footnoteFont {
    UIFontTextStyle const style = UIFontTextStyleFootnote;
    CGFloat maximumPointSize = 11.f;

    if (_footnoteFont == nil) {
        if (IS_PAD(self.rootController)) {
            _footnoteFont = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
        }
        else {
            _footnoteFont = [UIFont preferredFontForTextStyle:style];
        }
    }

    return _footnoteFont;
}

- (UIFont *)subtitleFont {
    UIFontTextStyle const style = UIFontTextStyleSubheadline;
    CGFloat maximumPointSize = 16.f;
    
    if (_subtitleFont == nil) {
        if (IS_PAD(self.rootController)) {
            _subtitleFont = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
        }
        else {
            _subtitleFont = [UIFont preferredFontForTextStyle:style];
        }
    }
    
    return _subtitleFont;
}

- (UIFont *)bodyFont {
    UIFontTextStyle const style = UIFontTextStyleBody;
    CGFloat maximumPointSize = 17.f;
    
    if (_bodyFont == nil) {
        if (IS_PAD(self.rootController)) {
            _bodyFont = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
        }
        else {
            _bodyFont = [UIFont preferredFontForTextStyle:style];
        }
    }

    return _bodyFont;
}

- (UIFont *)boldBodyFont {
    
    if (_boldBodyFont == nil) {
        UIFont *font = [self bodyFont];
        UIFontDescriptor *descriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        
        font = [UIFont fontWithDescriptor:descriptor size:font.pointSize];
        font = [[UIFontMetrics defaultMetrics] scaledFontForFont:font maximumPointSize:font.pointSize compatibleWithTraitCollection:self.rootController.traitCollection];
        
        _boldBodyFont = font;
    }
    
    return _boldBodyFont;
}

- (UIFont *)italicBodyFont {
    
    if (_italicBodyFont == nil) {
        UIFont *font = [self bodyFont];
        UIFontDescriptor *descriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        
        font = [UIFont fontWithDescriptor:descriptor size:font.pointSize];
        font = [[UIFontMetrics defaultMetrics] scaledFontForFont:font maximumPointSize:font.pointSize compatibleWithTraitCollection:self.rootController.traitCollection];
        
        _italicBodyFont = font;
    }
    
    return _italicBodyFont;
}

- (UIFont *)boldItalicBodyFont {
    
    if (_boldItalicBodyFont == nil) {
        UIFont *font = [self bodyFont];
        UIFontDescriptor *descriptor = [[[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        
        font = [UIFont fontWithDescriptor:descriptor size:font.pointSize];
        font = [[UIFontMetrics defaultMetrics] scaledFontForFont:font maximumPointSize:font.pointSize compatibleWithTraitCollection:self.rootController.traitCollection];
        
        _boldItalicBodyFont = font;
    }
    
    return _boldItalicBodyFont;
}

- (UIFont *)codeFont {
    
    CGFloat maximumPointSize = 17.f;
    
    if (_codeFont == nil) {
        UIFont *font = self.bodyFont;
        font = [UIFont monospacedDigitSystemFontOfSize:font.pointSize weight:UIFontWeightRegular];
        font = [[UIFontMetrics defaultMetrics] scaledFontForFont:font maximumPointSize:maximumPointSize compatibleWithTraitCollection:self.rootController.traitCollection];
        
        _codeFont = font;
    }
    
    return _codeFont;
    
}

- (UIFont *)boldCodeFont {
    
    if (_boldCodeFont == nil) {
        UIFont *font = [self codeFont];
        UIFontDescriptor *descriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        
        font = [UIFont fontWithDescriptor:descriptor size:font.pointSize];
        font = [[UIFontMetrics defaultMetrics] scaledFontForFont:font maximumPointSize:font.pointSize compatibleWithTraitCollection:self.rootController.traitCollection];
        
        _boldCodeFont = font;
    }
    
    return _boldCodeFont;
}

- (UIFont *)italicCodeFont {
    
    if (_italicCodeFont == nil) {
        UIFont *font = [self codeFont];
        UIFontDescriptor *descriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        
        font = [UIFont fontWithDescriptor:descriptor size:font.pointSize];
        font = [[UIFontMetrics defaultMetrics] scaledFontForFont:font maximumPointSize:font.pointSize compatibleWithTraitCollection:self.rootController.traitCollection];
        
        _italicCodeFont = font;
    }
    
    return _italicCodeFont;
}

/*
 - (UIFont *)<#keyname#> {
     UIFontTextStyle const style = <#TextStyle#>;
     CGFloat maximumPointSize = <#pointSize#>;
 
     if (<#keyName#> == nil) {
         if (IS_PAD(self.rootController)) {
            <#keyName#> = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
         }
         else {
            <#keyName#> = [UIFont preferredFontForTextStyle:style];
         }
     }
 
     return <#keyname#>;
 }
 */

@end
