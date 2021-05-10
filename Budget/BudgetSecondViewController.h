//
//  BudgetSecondViewController.h
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//import "AddAmount.h"

@interface BudgetSecondViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITableView* table;
@property (weak, nonatomic) IBOutlet UINavigationBar *nav;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

//- (void)addAmount:(id)sender;

@end
