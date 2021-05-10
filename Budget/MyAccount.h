//
//  Account.h
//  Budget
//
//  Created by Nikolay Spassov on 03.10.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MyAccount : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDecimalNumber * balance;
@property (nonatomic, retain) NSString * currency;

@end
