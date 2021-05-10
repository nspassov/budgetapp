//
//  MonthlyBalances.h
//  Budget
//
//  Created by Nikolay Spassov on 03.09.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MonthlyBalances : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * balance;
@property (nonatomic, retain) NSString * date;

@end
