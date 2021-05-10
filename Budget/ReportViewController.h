//
//  ReportViewController.h
//  Budget
//
//  Created by Nikolay Spassov on 20.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMPopTipView.h"

@interface ReportViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate, CMPopTipViewDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *nav;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSDecimalNumber* monthlyIncome;
@property (strong, nonatomic) NSDecimalNumber* monthlySavings;
@property (weak, nonatomic) IBOutlet UILabel *monthlyExpenses;
@property (weak, nonatomic) IBOutlet UILabel *monthlyBalance;
@property (weak, nonatomic) IBOutlet UIWebView *chartCanvas;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *chartLoading;
@property (weak, nonatomic) IBOutlet UILabel *monthlyBalanceLabel;
@property (weak, nonatomic) IBOutlet UITableView *monthlyTable;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showTableButton;
- (IBAction)showTable:(UIBarButtonItem*)sender;

@end
