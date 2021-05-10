//
//  ExpenseTracker.h
//  Budget
//
//  Created by Nikolay Spassov on 28.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddTrackedAmount.h"
#import "TKCalendarMonthView.h"

@interface ExpenseTracker : UIViewController <AddTrackedAmountDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,TKCalendarMonthViewDelegate,TKCalendarMonthViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView* table;
@property (weak, nonatomic) IBOutlet UITableView *table2;
@property (weak, nonatomic) IBOutlet UINavigationBar *nav;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) UIView* calendarBackground;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *groupsToggle;

@property (strong,nonatomic) TKCalendarMonthView *monthView;

- (void)addTrackedAmount:(id)sender;
- (IBAction)segmentedControlValueChanged:(id)sender;

@property (strong,nonatomic) UITableView *tableView;
- (void) updateTableOffset:(BOOL)animated;

@end
