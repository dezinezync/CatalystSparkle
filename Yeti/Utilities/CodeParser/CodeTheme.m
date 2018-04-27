//
//  CodeTheme.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/1/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import "CodeTheme.h"
#import "UIColor+HEX.h"

typedef NSDictionary <NSString *, NSDictionary <NSString *, NSString *> *> ThemeStringDict;
typedef NSMutableDictionary <NSString *, NSDictionary <NSString *, NSString *> *> MutableStringThemeDict;

typedef NSDictionary <NSString *, NSDictionary <NSString *, id> *> ThemeDict;
typedef NSMutableDictionary <NSString *, NSDictionary <NSString *, id> *> MutableThemeDict;

@interface CodeTheme ()

@property (nonatomic, copy, readwrite) NSString * themePath;

@property (nonatomic, strong) UIFont * boldCodeFont;
@property (nonatomic, strong) UIFont * italicCodeFont;
@property (nonatomic, strong) UIFont * codeFont;

@property (nonatomic, strong) ThemeDict * themeDict;
@property (nonatomic, strong) ThemeStringDict * strippedTheme;

// default background colour for the theme.
@property (nonatomic, copy) UIColor *backgroundColor;

@property (nonatomic, strong) NSString *theme;

@end

@implementation CodeTheme

- (instancetype)initWithThemePath:(NSString *)path
{
    if (self = [super init]) {
        self.themePath = path;
        
        self.codeFont = [UIFont fontWithName:@"Menlo" size:16.f];
        self.codeFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:self.codeFont];
        
        self.strippedTheme = [self stripTheme];
        self.themeDict = [self strippedThemeToTheme:self.strippedTheme];
        
        NSString *bgHex = nil;
        
        if (self.strippedTheme[@".hljs"]) {
            if (self.strippedTheme[@".hljs"][@"background"]) {
                bgHex = (NSString *)(self.strippedTheme[@".hljs"][@"background"]);
            }
            else if (self.strippedTheme[@".hljs"][@"background-color"])
                bgHex = (NSString *)(self.strippedTheme[@".hljs"][@"background-color"]);
        }
        
        if (bgHex) {
            if ([bgHex isEqualToString:@"white"]) {
                self.backgroundColor = [UIColor whiteColor];
            }
            else if ([bgHex isEqualToString:@"black"]) {
                self.backgroundColor = [UIColor blackColor];
            }
            else
                self.backgroundColor = [UIColor colorFromHexString:bgHex];
        }
        
        if (!self.backgroundColor)
            self.backgroundColor = [UIColor whiteColor];
        
    }
    
    return self;
}

- (NSAttributedString *)applyStyle:(NSArray <NSString *> *)styleList toString:(NSString *)string {
    
    NSAttributedString *returnString = nil;
    
    if (styleList.count > 0) {
        
        NSMutableDictionary <NSString *, id>* attrs = @{}.mutableCopy;
        attrs[NSFontAttributeName] = self.codeFont;
        
        for (NSString *style in styleList) {
            NSDictionary <NSString *, id>* themeStyle = self.themeDict[style];
            if (themeStyle) {
                [themeStyle enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [attrs setObject:obj forKey:key];
                }];
            }
        }
        
        if (!attrs[NSBackgroundColorAttributeName])
            attrs[NSBackgroundColorAttributeName] = self.backgroundColor;
        
        returnString = [[NSAttributedString alloc] initWithString:string attributes:attrs.copy];
        
    }
    else {
        returnString = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName : self.codeFont}];
    }
    
    return returnString;
    
}

#pragma mark - Utils

- (ThemeStringDict *)stripTheme
{
    NSRegularExpression *cssRegex = [[NSRegularExpression alloc] initWithPattern:@"(?:(\\.[a-zA-Z0-9\\-_]*(?:[, ]\\.[a-zA-Z0-9\\-_]*)*)\\{([^\\}]*?)\\})" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray <NSTextCheckingResult *> * results = [cssRegex matchesInString:self.theme options:NSMatchingReportProgress range:NSMakeRange(0, self.theme.length)];
    
    MutableStringThemeDict *resultDict = @{}.mutableCopy;
    
    for (NSTextCheckingResult *result in results) {
        if (result.numberOfRanges == 3) {
            NSMutableDictionary *attributes = @{}.mutableCopy;
            NSArray <NSString *> *cssPairs = [[self.theme substringWithRange:[result rangeAtIndex:2]] componentsSeparatedByString:@";"];
            
            for (NSString *pair in cssPairs) {
                NSArray *cssPropComp = [pair componentsSeparatedByString:@":"];
                if (cssPropComp.count == 2) {
                    attributes[cssPropComp[0]] = cssPropComp[1];
                }
            }
            
            if (attributes.count)
                resultDict[[self.theme substringWithRange:[result rangeAtIndex:1]]] = attributes.copy;
        }
    }
    
    return resultDict.copy;
    
}

- (ThemeDict *)strippedThemeToTheme:(ThemeStringDict *)theme
{
    __block MutableThemeDict *returnTheme = @{}.mutableCopy;
    
    [theme enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull className, NSDictionary<NSString *,NSString *> * _Nonnull props, BOOL * _Nonnull stop) {
       
        NSMutableDictionary <NSString *, id> * keyProps = @{}.mutableCopy;
        
        [props enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull prop, BOOL * _Nonnull stop) {
           
            if ([key isEqualToString:@"color"]) {
                keyProps[NSForegroundColorAttributeName] = [UIColor colorFromHexString:prop];
            }
            else if ([key isEqualToString:@"font-style"]) {
                keyProps[NSFontAttributeName] = [self fontForCSSStyle:prop];
            }
            else if ([key isEqualToString:@"font-weight"]) {
                keyProps[NSFontAttributeName] = [self fontForCSSStyle:prop];
            }
            else if ([key isEqualToString:@"background-color"]) {
                keyProps[NSBackgroundColorAttributeName] = [UIColor colorFromHexString:prop];
            }
            else {}
            
        }];
        
        if (keyProps.count) {
            NSString *key = [className stringByReplacingOccurrencesOfString:@"." withString:@""];
            NSArray *keys = [key componentsSeparatedByString:@","];
            for (NSString *name in keys) {
                returnTheme[name] = keyProps;
            }
        }
        
    }];
    
    return returnTheme.copy;
}

- (ThemeStringDict *)strippedThemeToString:(ThemeDict *)theme
{
    __block NSMutableString *resultString = @"".mutableCopy;
    
    [theme enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *,id> * _Nonnull props, BOOL * _Nonnull stop) {
       
        [resultString appendFormat:@"%@{", key];
        
        [props enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull cssProp, id  _Nonnull val, BOOL * _Nonnull stop) {
           
            if(![key isEqualToString:@".hljs"] || (![[cssProp lowercaseString] isEqualToString:@"background-color"] && ![[cssProp lowercaseString] isEqualToString:@"background"]))
            {
                [resultString appendFormat:@"%@:%@;", cssProp, val];
            }
            
            [resultString appendString:@"}"];
            
        }];
        
    }];
    
    return resultString.copy;
}

- (UIFont *)fontForCSSStyle:(NSString *)f
{
    NSArray <NSString *> * bold = @[@"bold", @"bolder", @"600", @"700", @"800", @"900"];
    NSArray <NSString *> * italic = @[@"italic", @"oblique"];
    
    if ([bold containsObject:f])
        return self.boldCodeFont;
    else if ([italic containsObject:f])
        return self.italicCodeFont;
    else
        return self.codeFont;
}

#pragma mark - Setters

- (void)setCodeFont:(UIFont *)codeFont
{
    _codeFont = codeFont;
    
    if (_codeFont) {
        UIFontDescriptor *boldDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute : codeFont.familyName,
                                                                                                UIFontDescriptorFaceAttribute : @"Bold"}];
        
        UIFontDescriptor *italicDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute : codeFont.familyName,
                                                                                                UIFontDescriptorFaceAttribute : @"Italic"}];
        UIFontDescriptor *obliqueDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute : codeFont.familyName,
                                                                                                  UIFontDescriptorFaceAttribute : @"Oblique"}];
        
        _boldCodeFont = [UIFont fontWithDescriptor:boldDescriptor size:codeFont.pointSize];
        _italicCodeFont = [UIFont fontWithDescriptor:italicDescriptor size:codeFont.pointSize];
        
        if (!_italicCodeFont || (![_italicCodeFont.familyName isEqualToString:codeFont.familyName]))
        {
            _italicCodeFont = [UIFont fontWithDescriptor:obliqueDescriptor size:codeFont.pointSize];
        }
        else if (!_italicCodeFont)
            _italicCodeFont = codeFont;
        
        if (!_boldCodeFont)
            _boldCodeFont = codeFont;
        
        if (!_themeDict)
            _themeDict = [self stripTheme];
        
    }
    
}

- (void)setThemePath:(NSString *)themePath
{
    _themePath = themePath;
    if (themePath) {
        _theme = [[NSString alloc] initWithContentsOfFile:themePath encoding:NSUTF8StringEncoding error:nil];
    }
}

@end
