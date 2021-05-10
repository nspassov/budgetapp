//
//  BudgetFirstViewController.h
//  Budget
//
//  Created by Nikolay Spassov on 15.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddAmount.h"
#import "CMPopTipView.h"

@interface BudgetFirstViewController : UIViewController <AddAmountDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, CMPopTipViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView* table;
@property (weak, nonatomic) IBOutlet UINavigationBar *nav;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *incomeExpensesToggle;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)addAmount:(id)sender;

@end
