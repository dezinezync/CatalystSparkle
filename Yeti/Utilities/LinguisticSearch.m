//
//  LinguisticSearch.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "LinguisticSearch.h"
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/DZLogger.h>

LinguisticPairType const LinguisticPairTypeDates = @"linguisticPair.dates";
LinguisticPairType const LinguisticPairTypeOthers = @"linguisticPair.others";
LinguisticPairType const LinguisticPairTypeContext = @"linguisticPair.context";

@interface LinguisticSearch ()

@end

@implementation LinguisticSearch

static NSArray<NSString *> *_knownDateTags;

+ (NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *)processText:(NSString *)text
{
    NSArray * schemes = [NSLinguisticTagger availableTagSchemesForLanguage:@"en"];
    NSInteger options = NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerJoinNames;
    NSLinguisticTagger * linguisticTagger = [[NSLinguisticTagger alloc] initWithTagSchemes:schemes options:options];
    
    linguisticTagger.string = text;
    
    NSMutableArray <LinguisticTagPair> *tokens = @[].mutableCopy;
    
    [linguisticTagger enumerateTagsInRange:NSMakeRange(0, text.length) scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass options:options usingBlock:^(NSLinguisticTag  _Nullable tag, NSRange tokenRange, NSRange sentenceRange, BOOL * _Nonnull stop) {
        
        DDLogDebug(@"Tag: %@\nToken: %@\nSentence: %@", tag, [text substringWithRange:tokenRange], [text substringWithRange:sentenceRange]);
        
        [tokens addObject:@{tag: [text substringWithRange:tokenRange]}];
    }];
    
    NSArray <LinguisticTagPair> *dateNouns = [tokens rz_filter:^BOOL(LinguisticTagPair obj, NSUInteger idx, NSArray *array) {
        return [obj valueForKey:@"Noun"] && [[self class].knownDateTags indexOfObject:[[obj valueForKey:@"Noun"] lowercaseString]] != NSNotFound;
    }];
    
    NSArray <LinguisticTagPair> *contexts = [tokens rz_filter:^BOOL(LinguisticTagPair obj, NSUInteger idx, NSArray *array) {
        return [obj valueForKey:@"Adjective"] || [obj valueForKey:@"Determiner"] || [obj valueForKey:@"Number"];
    }];
    
    NSArray <LinguisticTagPair> *others = [tokens rz_filter:^BOOL(LinguisticTagPair obj, NSUInteger idx, NSArray *array) {
        return [dateNouns indexOfObject:obj] == NSNotFound && [contexts indexOfObject:obj] == NSNotFound;
    }];
    
    NSDictionary *retval = @{LinguisticPairTypeDates : dateNouns,
                             LinguisticPairTypeContext : contexts,
                             LinguisticPairTypeOthers : others
                             };
    
    return retval;
}

#pragma mark - Setter

+ (void)setKnownDateTags:(NSArray<NSString *> *)knownDateTags
{
    _knownDateTags = knownDateTags;
}

+ (NSArray <NSString *> *)knownDateTags
{
    if (!_knownDateTags) {
        _knownDateTags = @[@"yesterday",@"today",@"now",@"days ago",@"day ago",@"week",@"year"];
    }
    
    return _knownDateTags;
}

@end
