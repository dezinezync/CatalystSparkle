//
//  TypeFactory.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "TypeFactory.h"
#import <DZAppdelegate/UIApplication+KeyWindow.h>
#import <DZTextKit/Paragraph.h>

BOOL IS_PAD (UIViewController *viewController) {
    return viewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

static TypeFactory * sharedTypeFactory;

@interface TypeFactory () {
    BOOL _firingSelfNotification;
}

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
        
        Paragraph.tk_typeFactory = sharedTypeFactory;
        
    });
    
    return sharedTypeFactory;
}

#pragma mark - Lifecycle

- (instancetype)init {
    
    if (self = [super init]) {
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(didUpdateContentCategory) name:UIContentSizeCategoryDidChangeNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(didUpdateContentCategory) name:UIAccessibilityBoldTextStatusDidChangeNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(userUpdatedContentCategory) name:UserUpdatedPreferredFontMetrics object:nil];
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
    
    // Since the scale is 1 (17pt) and the system font is being preffered
    if (self.scale == 1.f && SharedPrefs.articleFont == ALPSystem) {
        // we can directly return this font.
        return font;
    }
    else {
        
        NSString * fontPref = SharedPrefs.articleFont;
        
        BOOL isSystemFont = [fontPref isEqualToString:ALPSystem];
        
        NSString *fontName = [[fontPref stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""] capitalizedString];
        
        font = isSystemFont ? [UIFont systemFontOfSize:MAX(font.pointSize, pointSize)] : [UIFont fontWithName:fontName size:MAX(font.pointSize, pointSize)];
        
    }
    
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
    
    pointSize = floor(pointSize);
    
    if(UIAccessibilityIsBoldTextEnabled()) {
        UIFontDescriptor *descriptor = [font fontDescriptor];
        [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        
        font = [UIFont fontWithDescriptor:descriptor size:font.pointSize];
    }
    
    UIFont *scaled = [[UIFontMetrics metricsForTextStyle:style] scaledFontForFont:font maximumPointSize:pointSize compatibleWithTraitCollection:self.rootController.traitCollection];
    
    return scaled;
}

#pragma mark - Notifications

- (void)userUpdatedContentCategory {
    
    if (_firingSelfNotification) {
        _firingSelfNotification = NO;
        return;
    }
    
    // set all our mapped properties to nil so they can be reloaded
    for (NSString *keypath in [TypeFactory mappedProperties]) {
        [self setValue:nil forKeyPath:keypath];
    }
    
    // reset the scale so it gets updated.
    _scale = 0.f;
    
}

- (void)didUpdateContentCategory {
 
    [self userUpdatedContentCategory];
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        self->_firingSelfNotification = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdatedPreferredFontMetrics object:nil];
    });
    
}

#pragma mark - Getters

- (CGFloat)scale {
    
    if (_scale == 0.f) {
        
        NSInteger base = 17.f;
        
        if (SharedPrefs.useSystemSize == NO) {
            base = SharedPrefs.fontSize;
        }
        
        _scale = base / [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] pointSize];
        
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
    CGFloat maximumPointSize = SharedPrefs.useSystemSize ? 32.f : floor(SharedPrefs.fontSize  * 32.f / 17.f);
    
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
    CGFloat maximumPointSize = SharedPrefs.useSystemSize ? 13.f : floor(SharedPrefs.fontSize  * 13.f / 17.f);
    
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
    
    CGFloat maximumPointSize = SharedPrefs.useSystemSize ? 12.f : floor(SharedPrefs.fontSize  * 12.f / 17.f);
    
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
    
    CGFloat maximumPointSize = SharedPrefs.useSystemSize ? 11.f : floor(SharedPrefs.fontSize  * 11.f / 17.f);

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
    
    CGFloat maximumPointSize = SharedPrefs.useSystemSize ? 16.f : floor(SharedPrefs.fontSize  * 16.f / 17.f);
    
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
    CGFloat maximumPointSize = SharedPrefs.useSystemSize ? 17.f : SharedPrefs.fontSize;
    
    if (_bodyFont == nil) {
        _bodyFont = [self scaledFontForStyle:style maximumPointSize:maximumPointSize];
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
        UIFontDescriptor *descriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic|UIFontDescriptorTraitBold];
        
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
