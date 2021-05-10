//
//  SpendingHistory.m
//  Budget
//
//  Created by Nikolay Spassov on 18.10.12.
//
//

#import "BudgetAppDelegate.h"
#import "SpendingHistory.h"
#import "SpendingHistoryDetail.h"
#import "TrackedAmounts.h"
#import "Balance.h"

@interface SpendingHistory () {
    NSDecimalNumber* _b;
    NSString* _mainCurrency;
}
@end

#define MONTHS 0
#define GROUPS 1

@implementation SpendingHistory

- (void) populateTableContents
{
    NSError* error = nil;
    NSFetchRequest* fetchRequest = nil;
    NSEntityDescription* entity = nil;
    NSSortDescriptor* sort = nil;
    NSSortDescriptor* sort2 = nil;
    NSArray* buffer = nil;

//    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
//    [formatter setLocale:[NSLocale currentLocale]];
//    NSString* mainCurrency = [formatter currencyCode];
//    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
//    if([lastState valueForKey:@"mainCurrency"]) {
//        mainCurrency = [lastState valueForKey:@"mainCurrency"];
//    }

    if(self.groupsToggle.selectedSegmentIndex == MONTHS) {
        fetchRequest = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"Balance" inManagedObjectContext:_managedObjectContext];
        [fetchRequest setEntity:entity];
        NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"name == 'Savings' AND currency == '%@'", _mainCurrency]];
        [fetchRequest setPredicate:filter];
        
        buffer = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if(error) {
            NSLog(@"%@", error);
        }
        _b = [[buffer lastObject] valueForKey:@"balance"];
        
        fetchRequest = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        sort = [[NSSortDescriptor alloc] initWithKey:@"year" ascending:NO];
        sort2 = [[NSSortDescriptor alloc] initWithKey:@"month" ascending:NO];
        
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort, sort2, nil]];
        NSExpression* exx = [NSExpression expressionWithFormat:@"@sum.amount"];
        NSExpressionDescription* ed = [[NSExpressionDescription alloc] init];
        [ed setExpression:exx];
        [ed setExpressionResultType:NSDecimalAttributeType];
        [ed setName:@"summedamounts"];
        [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"year", @"month", ed, nil]];
        [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObjects:@"year", @"month", nil]];
        [fetchRequest setResultType:NSDictionaryResultType ];
        if (error) {
            NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
        }

        buffer = [NSArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    }

    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        fetchRequest = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        NSExpression* exx = [NSExpression expressionWithFormat:@"@sum.amount"];
        NSExpressionDescription* ed = [[NSExpressionDescription alloc] init];
        [ed setExpression:exx];
        [ed setExpressionResultType:NSDecimalAttributeType];
        [ed setName:@"summedamounts"];
        [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"year", @"note", ed, nil]];
        [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObjects:@"year", @"note", nil]];
        [fetchRequest setResultType:NSDictionaryResultType ];
        sort = [[NSSortDescriptor alloc] initWithKey:@"summedamounts" ascending:YES];
        if (error) {
            NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
        }
        buffer = [NSArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
        buffer = [buffer sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    }

    self.tableSections = [buffer valueForKeyPath:@"@distinctUnionOfObjects.year"];
    self.tableSections = [[self.tableSections sortedArrayUsingComparator:^NSComparisonResult(NSNumber* a, NSNumber* b) {
        return ([a intValue] == [b intValue]) ? 0 : (([a intValue] > [b intValue]) ? -1 : 1);
    }] mutableCopy];
    self.tableContents = [NSMutableArray array];
    for (NSNumber* year in self.tableSections) {
        [self.tableContents addObject:[buffer filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"year = %@", year]]]];
    }
    
    [self.table reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState objectForKey:@"historyTrackerToggleState"]) {
        [self.groupsToggle setSelectedSegmentIndex:[[lastState objectForKey:@"historyTrackerToggleState"] integerValue]];
    }

    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    _mainCurrency = [formatter currencyCode];

    if([lastState valueForKey:@"mainCurrency"]) {
        _mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }


    [self populateTableContents];
}

- (void)viewDidUnload
{
    [self setTable:nil];
    [self setMonthlyChartCanvas:nil];
    [self setChartLoading:nil];
    [self setGroupsToggle:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0xaa/255.f green:0x00/255.f blue:0xaa/255.f alpha:1]];
    if ([self.table indexPathForSelectedRow] != nil) {
        [self.table deselectRowAtIndexPath:[self.table indexPathForSelectedRow] animated:YES];
    }
    else {
        [self.table reloadData];
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setEditing:NO animated:animated];
    [self.navigationController.navigationBar setTintColor:nil];

#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
    [super viewWillDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Go To"]) {
        SpendingHistoryDetail * dvc = [segue destinationViewController];
        [dvc setTitle:[(UITableViewCell*)sender textLabel].text];
        [dvc setSelectedItem:[self.table indexPathForSelectedRow]];
    }
}

- (IBAction)segmentedControlValueChanged:(id)sender {
    if(self.groupsToggle.selectedSegmentIndex == MONTHS) {
        
    }

    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        
    }
    [self populateTableContents];
    
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    [lastState setInteger:[self.groupsToggle selectedSegmentIndex] forKey:@"historyTrackerToggleState"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableContents count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.tableContents objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    [df setDateFormat:@"yyyy"];
    [components setYear:[[self.tableSections objectAtIndex:section] intValue]];
    return [df stringFromDate:[cal dateFromComponents:components]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];

    return [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[[self.tableContents objectAtIndex:section] valueForKeyPath:@"@sum.summedamounts"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = nil;
    if(self.groupsToggle.selectedSegmentIndex == MONTHS) {
        cellIdentifier = @"Cell";
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        cellIdentifier = @"Group Cell";
    }
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    NSDictionary* d = [[self.tableContents objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    if(self.groupsToggle.selectedSegmentIndex == MONTHS) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [df setDateFormat:@"MMMM yyyy"];
        [components setYear:[[d valueForKey:@"year"] intValue]];
        [components setMonth:[[d valueForKey:@"month"] intValue]];
        [components setDay:1];
        [cell.textLabel setText:[[df stringFromDate:[cal dateFromComponents:components]] capitalizedString]];
    }

    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        [cell.textLabel setText:[d valueForKey:@"note"]];
    }

    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[d valueForKey:@"summedamounts"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency]];

    return cell;
}


//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return YES;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//
//        [[self.tableContents objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
//
//        if ([[self.tableContents objectAtIndex:indexPath.section] count] == 0) {
//            [self.tableContents removeObjectAtIndex:indexPath.section];
//            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:YES];
//        }
//    }
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        
//    }
//}
//
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return YES;
//}
//
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
//{
//    NSObject* o = [[self.tableContents objectAtIndex:fromIndexPath.section] objectAtIndex:fromIndexPath.row];
//
//    [[self.tableContents objectAtIndex:fromIndexPath.section] removeObjectAtIndex:fromIndexPath.row];
//    [[self.tableContents objectAtIndex:toIndexPath.section] insertObject:o atIndex:toIndexPath.row];
//
//    if ([[self.tableContents objectAtIndex:fromIndexPath.section] count] == 0) {
//        [self.tableContents removeObjectAtIndex:fromIndexPath.section];
//        [tableView reloadData];
//    }
//}

@end
