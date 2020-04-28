//
//  CodeParser.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/1/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import "CodeParser.h"
#import "HTMLUtils.h"

CodeParser *MyCodeParser;

@interface CodeParser ()

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong, readwrite) CodeTheme *theme;
@property (nonatomic, strong) NSRegularExpression *htmlEscape;
@property (nonatomic, copy) NSString *script;

@end

@implementation CodeParser

+ (instancetype)sharedCodeParser
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MyCodeParser = [[CodeParser alloc] init];
    });
    
    return MyCodeParser;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _bundle = [NSBundle bundleForClass:[self class]];
        
        NSString *hlpath = [self.bundle pathForResource:@"hljs" ofType:@"js"];
        
        [self loadTheme:@"light"];
        
        NSError *error = nil;
        
        NSString *script = [[NSString alloc] initWithContentsOfFile:hlpath encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"%@", error);
        }
        else {
            _script = script;
        }
        
        _htmlEscape = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9]+?;" options:NSRegularExpressionCaseInsensitive error:nil];
        
    }
    
    return self;
}

- (void)loadTheme:(NSString *)name {
    NSString *themePath = [self.bundle pathForResource:name ofType:@"css"];
    
    _theme = [[CodeTheme alloc] initWithThemePath:themePath];
}

static NSString *const hljs = @"window.hljs";

- (NSAttributedString *)parse:(NSString *)code language:(NSString *)language
{
    
    code = [self neatifyCode:code];
    
    if (!language || !language.length)
        return [self parse:code];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-escape-sequence"
    NSString *command = formattedString(@"%@.fixMarkup(%@.highlightAuto(\"%@\").value);", hljs, hljs, code);
#pragma clang diagnostic pop
    JSContext *context = [[JSContext alloc] init];
    [context setExceptionHandler:^(JSContext *aContext, JSValue * aVal) {
        NSLogDebug(@"%@", aVal);
    }];
    
    __unused JSValue *winVal = [context evaluateScript:@"var window = {};"];
    __unused JSValue *value = [context evaluateScript:self.script];
    __unused JSValue *styleVal = [context evaluateScript:@"%@.configure({tabReplace: '    ', useBr: true})"];
    
    JSValue *retval = [context evaluateScript:command];
    NSString *parsed = [retval toString];
    
    context = nil;
    retval = nil;
    
    if (!parsed)
        parsed = code;
    
    return [self processHTMLString:parsed];
}

- (NSAttributedString *)parse:(NSString *)code
{
    
    code = [self neatifyCode:code];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-escape-sequence"
    
    NSString *command = formattedString(@"%@.fixMarkup(%@.highlightAuto(\`%@\`).value);", hljs, hljs, code);
    
#pragma clang diagnostic pop
    
    JSContext *context = [[JSContext alloc] init];
    [context setExceptionHandler:^(JSContext *aContext, JSValue * aVal) {
        NSLogDebug(@"%@", aVal);
    }];
    
    __unused JSValue *winVal = [context evaluateScript:@"var window = {};"];
    __unused JSValue *value = [context evaluateScript:self.script];
    __unused JSValue *styleVal = [context evaluateScript:@"%@.configure({tabReplace: '    ', useBr: true})"];
    
    JSValue *retval = [context evaluateScript:command];
    NSString *parsed = [retval toString];
    
    context = nil;
    retval = nil;
    
    if (!parsed)
        parsed = code;
    
    return [self processHTMLString:parsed];
}

#pragma mark - Utils

- (NSString *)neatifyCode:(NSString *)code
{
    if (!code)
        return @"";
    
    code = [code stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
    code = [code stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return code;
}

static NSString * const htmlString = @"<";
static NSString * const spanStart = @"span class=\"";
static NSString * const spanStartClose = @"\">";
static NSString * const spanEnd = @"/span>";

- (NSAttributedString *)processHTMLString:(NSString *)string
{
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    
    NSString *scannedString = nil;
    
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    NSMutableArray *propStack = @[@"hljs"].mutableCopy;
    
    while (!scanner.isAtEnd) {
        BOOL ended = NO;
        if ([scanner scanUpToString:htmlString intoString:&scannedString]) {
            if (scanner.isAtEnd)
                ended = YES;
        }
        
        if (scannedString != nil && scannedString.length) {
            NSAttributedString * attrScannedString = [self.theme applyStyle:propStack toString:scannedString];
            [resultString appendAttributedString:attrScannedString];
            
            if (ended)
                continue;
        }
        
        scanner.scanLocation += 1;
        
        NSString *string = scanner.string;
        NSString *nextChar = [string substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
        
        if ([nextChar isEqualToString:@"s"]) {
            scanner.scanLocation += spanStart.length;
            [scanner scanUpToString:spanStartClose intoString:&scannedString];
            scanner.scanLocation += spanStartClose.length;
            [propStack addObject:scannedString];
        }
        else if ([nextChar isEqualToString:@"/"]) {
            scanner.scanLocation += spanEnd.length;
            [propStack removeLastObject];
        }
        else {
            NSAttributedString *attrScannedString = [self.theme applyStyle:propStack toString:@"<"];
            [resultString appendAttributedString:attrScannedString];
            scanner.scanLocation += 1;
        }
        
        scannedString = nil;
        
    }
    
    NSArray <NSTextCheckingResult *> * results = [self.htmlEscape matchesInString:resultString.string options:NSMatchingReportCompletion range:NSMakeRange(0, resultString.length)];
    
    NSUInteger locOffset = 0;
    
    for (NSTextCheckingResult *result in results) {
        NSRange fixedRange = NSMakeRange(result.range.location - locOffset, result.range.length);
        NSString *entity = [resultString.string substringWithRange:fixedRange];
        NSString *decodedEntity = [MyHTMLUtils decode:entity];
        if (decodedEntity) {
            [resultString replaceCharactersInRange:fixedRange withString:decodedEntity];
            locOffset += result.range.length-1;
        }
    }
    
    return resultString.copy;
    
}

@end
