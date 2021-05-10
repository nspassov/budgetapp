//
//  ReportViewController.m
//  Budget
//
//  Created by Nikolay Spassov on 20.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReportViewController.h"
#import "BudgetAppDelegate.h"
#import "Amounts.h"

@interface ReportViewController() {
    NSString* _mainCurrency;
    NSMutableArray* _monthlyBudget;
    NSMutableDictionary* _tooltips;
}

@end

@implementation ReportViewController
@synthesize nav = _nav;
@synthesize managedObjectContext = _managedObjectContext;

@synthesize monthlyIncome  = _monthlyIncome;
@synthesize monthlySavings = _monthlySavings;
@synthesize monthlyExpenses = _monthlyExpenses;
@synthesize monthlyBalance = _monthlyBalance;
@synthesize chartCanvas = _chartCanvas;
@synthesize chartLoading = _chartLoading;
@synthesize monthlyBalanceLabel = _monthlyBalanceLabel;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
 */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":@"Budget"} timed:YES];
#endif

    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription 
                                   entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *filter;
    NSArray* buf;
    NSError *error;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[NSLocale currentLocale]];
    _mainCurrency = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        _mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    [df setDateFormat:@"MMMM yyyy"];
    [self.navigationItem setTitle:[[df stringFromDate:[cal dateFromComponents:components]] capitalizedString]];
    [df setDateFormat:@"yyyyMM"];

    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount >= 0 AND (dateOccurs == '' OR dateOccurs == '%@')", [df stringFromDate:[cal dateFromComponents:components]]]];
    [fetchRequest setPredicate:filter];
    buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSDecimalNumber* dIncome = [buf valueForKeyPath:@"@sum.amount"];
    double income = [dIncome doubleValue];
    self.monthlyIncome = dIncome;
    
    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount < 0 AND (dateOccurs == '' OR dateOccurs == '%@')", [df stringFromDate:[cal dateFromComponents:components]]]];
    [fetchRequest setPredicate:filter];
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"amount" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSSortDescriptor* sort2 = [[NSSortDescriptor alloc] initWithKey:@"amount" ascending:YES];
    _monthlyBudget = [[NSMutableArray alloc] initWithArray:buf];
    [_monthlyBudget sortUsingDescriptors:[NSArray arrayWithObject:sort2]];
    NSDecimalNumber* dExpenses = [buf valueForKeyPath:@"@sum.amount"];
    double expenses = fabs([dExpenses doubleValue]);

    self.monthlySavings = [dIncome decimalNumberByAdding:dExpenses];
    
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    
    self.monthlyExpenses.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[dExpenses decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];

    if(income < expenses) {
        self.monthlyBalance.text = [NSString stringWithFormat:@"(%@ %@)", [formatter stringFromNumber:[[dIncome decimalNumberByAdding:dExpenses] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
    }
    else {
        self.monthlyBalance.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[dIncome decimalNumberByAdding:dExpenses]], _mainCurrency];
    }
    if(income <= expenses) {
        self.monthlyBalance.textColor = [UIColor colorWithRed:0xaa/255.f green:0x00/255.f blue:0x00/255.f alpha:1];
        self.monthlyBalanceLabel.text = @"Expected Balance";
    }
    else {
        self.monthlyBalance.textColor = [UIColor colorWithRed:0x00/255.f green:0xaa/255.f blue:0x00/255.f alpha:1];
        self.monthlyBalanceLabel.text = @"Expected Savings";
    }

    NSString* fpath = [[NSBundle mainBundle] pathForResource:@"chart/monthly" ofType: @"html"];
    NSString* s = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:&error];
    s = [s stringByReplacingOccurrencesOfString:@"CUSTOM_HEIGHT" withString:[NSString stringWithFormat:@"%.0f", self.chartCanvas.frame.size.height+32]];
    s = [s stringByAppendingString:@"series: [{type: 'pie', name: 'Monthly Expenses', data: ["];
    for (Amounts* a in buf) {
        s = [s stringByAppendingFormat:@"{name:'%@', y:%.2f, sliced:true},", a.note, fabs([a.amount doubleValue])];
    }
    if(income > expenses) {
        s = [s stringByAppendingFormat:@"{name:'Savings', y:%.2f, sliced:true},", income-expenses];
    }
    s = [s stringByAppendingString:@"]}]});});</script></body>"];
    s = [s stringByReplacingOccurrencesOfString:@"mainCurrency" withString:_mainCurrency];
    [self.chartCanvas loadHTMLString:s baseURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/chart", [[NSBundle mainBundle] bundlePath]]]];

    [self.monthlyTable reloadData];
}

-(void) viewWillDisappear:(BOOL)animated {
#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":@"Budget"}];
#endif
    [super viewWillDisappear:animated];
}

-(void) viewDidDisappear:(BOOL)animated {
    [[_tooltips objectForKey:@"tooltipPieChartTapPossible"] dismissAnimated:YES];

    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tooltips = [NSMutableDictionary dictionary];

    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState integerForKey:@"showMonthlyReportTable"] == 1) {
        [self showTable:nil];
    }
}

- (void)viewDidUnload
{
    [self setNav:nil];
    [self setMonthlyIncome:nil];
    [self setMonthlyExpenses:nil];
    [self setMonthlyBalance:nil];
    [self setChartCanvas:nil];
    [self setMonthlyBalanceLabel:nil];
    [self setChartLoading:nil];
    [self setMonthlyTable:nil];
    [self setShowTableButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.chartLoading startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.chartLoading stopAnimating];

    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if(![lastState objectForKey:@"tooltipPieChartTapPossible"]) {
        CMPopTipView* tip1 = [[CMPopTipView alloc] initWithMessage:@"Tap portions to see percentages"];
        tip1.delegate = self;
        tip1.backgroundColor = [UIColor blackColor];
        tip1.textColor = [UIColor whiteColor];
        [tip1 setDismissTapAnywhere:YES];
        [tip1 setPreferredPointDirection:PointDirectionDown];
        [tip1 presentPointingAtView:self.chartCanvas inView:self.view animated:YES];
        [_tooltips setObject:tip1 forKey:@"tooltipPieChartTapPossible"];
        [lastState setInteger:1 forKey:@"tooltipPieChartTapPossible"];
    }
}


- (IBAction)showTable:(UIBarButtonItem*)sender {
    [[_tooltips objectForKey:@"tooltipPieChartTapPossible"] dismissAnimated:YES];

    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    
    if([self.monthlyTable isHidden]) {
        [self.monthlyTable setHidden:NO];
        [self.showTableButton setStyle:UIBarButtonItemStyleDone];
        [lastState setInteger:1 forKey:@"showMonthlyReportTable"];
    }
    else {
        [self.monthlyTable setHidden:YES];
        [self.showTableButton setStyle:UIBarButtonItemStyleBordered];
        [lastState setInteger:0 forKey:@"showMonthlyReportTable"];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];

    if(indexPath.section == 0) {
        NSString* cellIdentifier = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [cell.textLabel setText:@"Income"];
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:self.monthlyIncome], _mainCurrency]];
    }
    if(indexPath.section == 1) {
        NSString* cellIdentifier = @"Cell 2";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [(UILabel*)[cell viewWithTag:1] setText:[[_monthlyBudget objectAtIndex:indexPath.row] note]];
        [(UILabel*)[cell viewWithTag:2] setText:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[[_monthlyBudget objectAtIndex:indexPath.row] amount] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], [[_monthlyBudget objectAtIndex:indexPath.row] currency]]];
        if([self.monthlyIncome doubleValue] == 0) {
            [(UILabel*)[cell viewWithTag:3] setText:[NSString stringWithFormat:@"%2.f%% of Income", [[[[[_monthlyBudget objectAtIndex:indexPath.row] amount] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] doubleValue]]];
        }
        else {
            [(UILabel*)[cell viewWithTag:3] setText:[NSString stringWithFormat:@"%2.f%% of Income", [[[[[[_monthlyBudget objectAtIndex:indexPath.row] amount] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] decimalNumberByDividingBy:self.monthlyIncome] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] doubleValue]]];
        }
    }
    if(indexPath.section == 2) {
        NSString* cellIdentifier = @"Cell 3";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [(UILabel*)[cell viewWithTag:1] setText:self.monthlyBalanceLabel.text];
        [(UILabel*)[cell viewWithTag:2] setText:self.monthlyBalance.text];
        if([self.monthlySavings compare:@0] != NSOrderedAscending && [self.monthlyIncome compare:@0] != NSOrderedSame) {
            [(UILabel*)[cell viewWithTag:3] setText:[NSString stringWithFormat:@"%2.f%% of Income", [[[self.monthlySavings decimalNumberByDividingBy:self.monthlyIncome] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] doubleValue]]];
        }
        else {
            [(UILabel*)[cell viewWithTag:3] setText:@"0% of Income"];
        }
    }

    return cell;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0 || section == 2) {
        return 1;
    }
    if(section == 1) {
        return [_monthlyBudget count];
    }

    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 1 && [_monthlyBudget count] > 0) {
        return @"Planned Expenses";
    }

    return nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(section == 1) {
        return [NSString stringWithFormat:@"Budgeted %@", self.monthlyExpenses.text];
    }
    return nil;
}

@end
