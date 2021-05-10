//
//  CurrencyConverter.h
//  Budget
//
//  Created by Nikolay Spassov on 26.09.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CurrencyUtil : NSObject

+(NSDecimalNumber*) getCurrencyRateFor:(NSString*)inputCurrency to:(NSString*)outputCurrency;
+(NSDecimalNumber*) convertAmount:(NSDecimalNumber*)amount ofCurrency:(NSString*)inputCurrency toCurrency:(NSString*)outputCurrency;
+(void) av;
@end
