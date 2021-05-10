//
//  BudgetStore.m
//  Budget
//
//  Created by Nikolay Spassov on 16.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BudgetStore.h"

@interface BudgetStore() {
    NSManagedObjectContext* context;
    NSManagedObjectModel* model;
    NSPersistentStoreCoordinator* coordinator;
    NSString* filename;
}
@end

@implementation BudgetStore

SINGLETON_GCD(BudgetStore);

- (void) initBudgetStore {
    filename = @"Budget";
}


- (BOOL) saveContext {
    NSError* error = nil;
    if (context != nil) {
        if ([context hasChanges] && ![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        return YES;
    }
    return NO;
}


// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext*) managedObjectContext {
    if (context != nil) {
        return context;
    }
    
    NSPersistentStoreCoordinator* c = [self persistentStoreCoordinator];
    if (c != nil) {
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:c];
    }
    return context;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel*) managedObjectModel {
    if (model != nil) {
        return model;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:filename withExtension:@"momd"];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return model;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator*) persistentStoreCoordinator {
    if (coordinator != nil) {
        return coordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", filename]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    NSError *error = nil;
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return coordinator;
}

- (NSURL*) applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectContext*) getContext {
    return [self managedObjectContext];
}

@end
