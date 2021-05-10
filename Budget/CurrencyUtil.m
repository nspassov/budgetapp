//
//  CurrencyConverter.m
//  Budget
//
//  Created by Nikolay Spassov on 26.09.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CurrencyUtil.h"

@implementation CurrencyUtil

+(void) av {
//    NSLog(@"%@" ,[NSLocale ISOCurrencyCodes]);
//    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
//    for(NSString* lc in [NSLocale availableLocaleIdentifiers]) {
//        if([[lc description] length] == 5) {
//        if(lc != nil) {
//            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        
//            [formatter setLocale:];
//            NSLog(@"%@", [formatter performSelector:@selector(currencyCode)]);
//            NSLog(@"%@", [NSLocale localeIdentifierFromWindowsLocaleCode:[NSLocale windowsLocaleCodeFromLocaleIdentifier:lc]]);
//        }
//    }
//    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
//    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
//    [formatter setLocale:[NSLocale currentLocale]];
//    NSLog(@"%@ %@", [formatter currencyCode], [[NSLocale currentLocale] localeIdentifier]);
}

+(NSDecimalNumber*) getCurrencyRateFor:(NSString*)inputCurrency to:(NSString*)outputCurrency {
    NSString* inputValue = @"";
    NSString* outputValue = @"";
    NSString* errorValue = @"";
    NSError* error = nil;
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/ig/calculator?hl=en&q=1%@%%3D%%3F%@", inputCurrency, outputCurrency]];
    const char* jsonData = [[NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error] UTF8String];
    unsigned int len = strlen(jsonData);
    unsigned int q = 0; // odd means we're inside quotes, even means outside quotes
    for(int i = 0; i != len; i++) {
        if(jsonData[i] == '"') {
            q ++;
        }
        else if(q % 2 == 1) {
            switch(q) {
                case 1:
                    inputValue = [NSString stringWithFormat:@"%@%c", inputValue, jsonData[i]];
                    break;
                case 3:
                    outputValue = [NSString stringWithFormat:@"%@%c", outputValue, jsonData[i]];
                    break;
                case 5:
                    errorValue = [NSString stringWithFormat:@"%@%c", errorValue, jsonData[i]];
                    break;
            }
        }
    }
    if(![errorValue isEqualToString:@""])
        return [NSDecimalNumber zero];
    else
        return [NSDecimalNumber decimalNumberWithString:outputValue];
}

+(NSDecimalNumber*) convertAmount:(NSDecimalNumber*)amount ofCurrency:(NSString*)inputCurrency toCurrency:(NSString*)outputCurrency {
    return [amount decimalNumberByMultiplyingBy:[self getCurrencyRateFor:inputCurrency to:outputCurrency]];
}

@end
