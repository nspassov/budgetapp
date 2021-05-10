//
//  BudgetAppDelegate.h
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RageIAPHelper.h"

@interface BudgetAppDelegate : UIResponder <UIApplicationDelegate>
{
    NSManagedObjectModel *managedObjectModel;   
    NSManagedObjectContext *managedObjectContext;       
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) RageIAPHelper* inAppHelper;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
