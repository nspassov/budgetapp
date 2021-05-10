//
//  BudgetStore.h
//  Budget
//
//  Created by Nikolay Spassov on 16.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

#ifndef SINGLETON_GCD
/*!
 * @function Singleton GCD Macro
 */
#define SINGLETON_GCD(classname) \
+ (classname*)shared##classname { \
    static dispatch_once_t pred; \
    __strong static classname* shared##classname = nil; \
    dispatch_once( &pred, ^{ \
        shared##classname = [[self alloc] init]; \
    }); \
    return shared##classname; \
}
#endif

@interface BudgetStore : NSObject

- (void) initBudgetStore;
- (BOOL) saveContext;
- (NSManagedObjectContext*) getContext;

@end
