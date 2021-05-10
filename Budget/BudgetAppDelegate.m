//
//  BudgetAppDelegate.m
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BudgetAppDelegate.h"
#import <CoreData/CoreData.h>
#import "RageIAPHelper.h"
#import "Amounts.h"
#import "Appirater.h"
#import "AFHTTPClient.h"
//import "Crittercism.h"

@interface NSString (UUID)

+ (NSString *)uuid;

@end
@implementation NSString (UUID)

+ (NSString *)uuid{
    NSString *uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid) {
        uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
    }
    return uuidString;
}

@end


@implementation BudgetAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize inAppHelper = _inAppHelper;

#define TRIAL_PERIOD 1814400

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [Appirater setDaysUntilPrompt:7];
    [Appirater setUsesUntilPrompt:20];
    [Appirater setTimeBeforeReminding:1];
//    [Appirater setDebug:YES];
    
    self.inAppHelper = [RageIAPHelper sharedInstance];
    
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if(![lastState objectForKey:@"deviceID"]) {
        [lastState setObject:[NSString uuid] forKey:@"deviceID"];
        if(![lastState synchronize]) {
            NSLog(@"NSUserDefaults failed.");
        }
    }
//    if(![lastState boolForKey:@"deviceIDRegistered"]) {
//        NSURL *url = [NSURL URLWithString:SERVER_URL];
//        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
//        NSDictionary *params = [NSDictionary dictionaryWithObjects:@[[lastState objectForKey:@"deviceID"]] forKeys:@[@"device_id"]];
//        [httpClient postPath:@"/budgetapp/devices/add" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//            NSLog(@"Request Successful, response '%@'", responseStr);
//            [lastState setBool:YES forKey:@"deviceIDRegistered"];
//            if(![lastState synchronize]) {
//                NSLog(@"NSUserDefaults failed.");
//            }
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"[HTTPClient Error]: %@", error.localizedDescription);
//        }];
//    }

    if(![lastState objectForKey:@"trialDate"]) {
        [lastState setObject:[NSDate dateWithTimeIntervalSinceNow:TRIAL_PERIOD] forKey:@"trialDate"];
        
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        [formatter setLocale:[NSLocale currentLocale]];
        for(NSString* s in @[@"Rent", @"Groceries", @"Eating Out", @"Clothes", @"Utilities", @"Transport", @"Fun"]) {
            Amounts* expense = (Amounts*)[NSEntityDescription insertNewObjectForEntityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
            [expense setAmount:[NSDecimalNumber zero]];
            [expense setNote:s];
            [expense setCurrency:[formatter currencyCode]];
            [expense setDateOccurs:@""];
        }
        Amounts* salary = (Amounts*)[NSEntityDescription insertNewObjectForEntityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
        [salary setAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
        [salary setNote:@"Monthly Salary"];
        [salary setCurrency:[formatter currencyCode]];
        [salary setDateOccurs:@""];
        NSError* error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"%@", error);
        }
    }

    [Appirater appLaunched:YES];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    [lastState setInteger:[(UITabBarController*)self.window.rootViewController selectedIndex] forKey:@"lasttab"];
    if (![lastState synchronize]) {
        NSLog(@"Error Synchronizing NSUserDefaults");
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    [Appirater appEnteredForeground:NO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    
//    if([[RageIAPHelper sharedInstance] productPurchased:@"net.colbis.Budget.full"]
//       || [[NSDate date] compare:[lastState objectForKey:@"trialDate"]] != NSOrderedDescending) {
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:[[lastState valueForKey:@"lasttab"] unsignedIntValue]];
//    }
//    else {
//        // trial has expired and no purchase
//        int vcCount = [[(UITabBarController*)(self.window.rootViewController) viewControllers] count];
//        for(int i = 0; i != vcCount; i++) {
//            if([[[[(UITabBarController*)(self.window.rootViewController) viewControllers] objectAtIndex:i] title] isEqualToString:@"About"]) {
//                [(UITabBarController*)self.window.rootViewController setSelectedIndex:i];
//            }
//            else {
//                UIView* vc = [[[(UITabBarController*)(self.window.rootViewController) viewControllers] objectAtIndex:i] view];
//                [vc setUserInteractionEnabled:NO];
//                CGRect newSize = CGRectMake(0, 0, vc.frame.size.width, vc.frame.size.height);
//                UIView* overlay = [[UIView alloc] initWithFrame:newSize];
//                [overlay setBackgroundColor:[UIColor blackColor]];
//                [overlay setAlpha:.4];
//                [overlay setTag:999];
//                [vc addSubview:overlay];
//            }
//        }
//        [(UITabBarController*)self.window.rootViewController setCustomizableViewControllers:nil];
//    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)saveContext
{
    NSError *error = nil;
 //   NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (self.managedObjectContext != nil) {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Budget" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Budget.sqlite"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
