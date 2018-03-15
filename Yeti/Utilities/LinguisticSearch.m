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

#import "DTTimePeriod.h"

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

+ (NSDate *)dateFromText:(NSString *)text
{
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [[self class] processText:text];
    
    return [[self class] processDataForDate:results];
}

+ (NSDate *)processDataForDate:(NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *)results {
    
    NSArray <LinguisticTagPair> *dates = [results valueForKey:LinguisticPairTypeDates];
    NSArray <LinguisticTagPair> *context = [results valueForKey:LinguisticPairTypeContext];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:NSDate.date];
    
    if (dates.count > 0 && context.count > 0) {
        // only match the first item
        NSString *countString = [[context.firstObject allValues].firstObject lowercaseString];
        NSTimeInterval count;
        
        if ([countString isEqualToString:@"a"] || [countString isEqualToString:@"last"] || [countString isEqualToString:@"previous"]) {
            count = 1;
        }
        else {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            count = [[formatter numberFromString:countString] floatValue];
        }
        
        NSString *type = [[dates.firstObject valueForKey:@"Noun"] lowercaseString];
        
        NSTimeInterval intervalInDays = [[self class] multiplexedCountFor:type count:count];
        
        components.day -= intervalInDays;
        
        NSDate *requiredDate = [calendar dateFromComponents:components];
        
        return requiredDate;
    }
    else if (dates.count > 0) {
        NSString *type = [[dates.firstObject valueForKey:@"Noun"] lowercaseString];
        
        NSTimeInterval intervalInDays = [[self class] multiplexedCountFor:type count:0];
        
        components.day -= intervalInDays;
        
        NSDate *requiredDate = [calendar dateFromComponents:components];
        
        return requiredDate;
    }
    
    return nil;
}

+ (NSArray <NSDate *> *)timePeriodFromText:(NSString *)text {
    
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [[self class] processText:text];
    
    NSDate * date = [[self class] processDataForDate:results];
    
    if (!date)
        return nil;
    
    
    
    DTTimePeriod *timeperiod = [DTTimePeriod timePeriodWithStartDate:date endDate:NSDate.date];
    
    if (timeperiod.hasStartDate && timeperiod.hasEndDate) {
        return @[timeperiod.StartDate, timeperiod.EndDate];
    }
    
    return nil;
    
}

+ (NSTimeInterval)multiplexedCountFor:(NSString *)type count:(NSTimeInterval)count {
    if ([type isEqualToString:@"day"] || [type isEqualToString:@"days"]) {
        return count;
    }
    else if ([type isEqualToString:@"week"] || [type isEqualToString:@"weeks"]) {
        return count * 7;
    }
    else if ([type isEqualToString:@"month"] || [type isEqualToString:@"months"]) {
        return count * 29; // using 30 as an average.
    }
    else if ([type isEqualToString:@"year"]) {
        return count * 365; // dont base off leap years.
    }
    else if ([type isEqualToString:@"yesterday"]) {
        return 1;
    }
    else {
        return 0;
    }
}

#pragma mark - Setter

+ (void)setKnownDateTags:(NSArray<NSString *> *)knownDateTags
{
    _knownDateTags = knownDateTags;
}

+ (NSArray <NSString *> *)knownDateTags
{
    if (!_knownDateTags) {
        _knownDateTags = @[@"yesterday",@"today",@"now",@"days",@"day",@"week",@"weeks",@"month",@"months",@"year",@"years"];
    }
    
    return _knownDateTags;
}

@end
