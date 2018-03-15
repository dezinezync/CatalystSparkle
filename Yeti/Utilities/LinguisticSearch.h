//
//  LinguisticSearch.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSDictionary <NSLinguisticTag, NSString *> *LinguisticTagPair;
typedef NSString *LinguisticPairType;

FOUNDATION_EXPORT LinguisticPairType const _Nonnull LinguisticPairTypeDates;
FOUNDATION_EXPORT LinguisticPairType const _Nonnull LinguisticPairTypeContext;
FOUNDATION_EXPORT LinguisticPairType const _Nonnull LinguisticPairTypeOthers;

@interface LinguisticSearch : NSObject

@property (nonatomic, copy, class) NSArray <NSString *> * _Nonnull knownDateTags;

+ (NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> * _Nonnull)processText:(NSString * _Nonnull)text;

+ (NSDate * _Nullable)dateFromText:(NSString * _Nonnull)text;

+ (NSArray <NSDate *> * _Nullable)timePeriodFromText:(NSString * _Nonnull)text;

@end
