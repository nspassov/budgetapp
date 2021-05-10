//
//  Amounts.h
//  Budget
//
//  Created by Nikolay Spassov on 27.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Amounts : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSString * dateOccurs;
@property (nonatomic, retain) NSString * note;

@end
