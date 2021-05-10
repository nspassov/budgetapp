//
//  Balance.h
//  Budget
//
//  Created by Nikolay Spassov on 01.09.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Balance : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * balance;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSString * name;

@end
