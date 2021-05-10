//
//  SpendingHistory.m
//  Budget
//
//  Created by Nikolay Spassov on 18.10.12.
//
//

#import "BudgetAppDelegate.h"
#import "SpendingHistoryDetail.h"
#import "TrackedAmounts.h"
#import "Balance.h"
#import "CHCSVParser.h"

@interface SpendingHistoryDetail () {
    NSDecimalNumber* _b;
    NSString* _mainCurrency;
    NSArray* _monthlyExpenses;
    NSOutputStream* _st;
}
@end

@implementation SpendingHistoryDetail

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
    self.tableSections = [buffer valueForKeyPath:@"@distinctUnionOfObjects.year"];
    self.tableSections = [[self.tableSections sortedArrayUsingComparator:^NSComparisonResult(NSNumber* a, NSNumber* b) {
        return ([a intValue] == [b intValue]) ? 0 : (([a intValue] > [b intValue]) ? -1 : 1);
    }] mutableCopy];
    self.tableContents = [NSMutableArray array];
    for (NSNumber* year in self.tableSections) {
        [self.tableContents addObject:[buffer filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"year = %@", year]]]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    _mainCurrency = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        _mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }


    [self populateTableContents];
    if(self.monthlyChartCanvas != nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription
                                       entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *filter;
        NSArray* buf;
        NSError *error;
        
        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"year = %@ AND month = %@",
                                                   [[[self.tableContents objectAtIndex:[self.selectedItem section]] objectAtIndex:[self.selectedItem row]] valueForKey:@"year"],
                                                   [[[self.tableContents objectAtIndex:[self.selectedItem section]] objectAtIndex:[self.selectedItem row]] valueForKey:@"month"] ]];
        [fetchRequest setPredicate:filter];
        NSExpression* exx = [NSExpression expressionWithFormat:@"@sum.amount"];
        NSExpressionDescription* ed = [[NSExpressionDescription alloc] init];
        [ed setExpression:exx];
        [ed setExpressionResultType:NSDecimalAttributeType];
        [ed setName:@"summedamounts"];
        [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"note", ed, nil]];
        [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObjects:@"note", nil]];
        [fetchRequest setResultType:NSDictionaryResultType ];
        buf = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        buf = [buf sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
            return ([[a valueForKey:@"summedamounts"] doubleValue] == [[b valueForKey:@"summedamounts"] doubleValue]) ? 0 : (([[a valueForKey:@"summedamounts"] doubleValue] > [[b valueForKey:@"summedamounts"] doubleValue]) ? -1 : 1);
        }];
        _monthlyExpenses = buf;
        
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        [formatter setMinimumFractionDigits:2];

        NSString* fpath = [[NSBundle mainBundle] pathForResource:@"chart/monthly" ofType: @"html"];
        NSString* s = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:&error];
        s = [s stringByReplacingOccurrencesOfString:@"CUSTOM_HEIGHT" withString:[NSString stringWithFormat:@"%.0f", self.monthlyChartCanvas.frame.size.height-82]];
        s = [s stringByAppendingString:@"series: [{type: 'pie', name: 'Spendings', data: ["];
        for (NSDictionary* a in buf) {
            s = [s stringByAppendingFormat:@"{name:'%@', y:%.2f, sliced:true},", [a valueForKey:@"note"], fabs([[a valueForKey:@"summedamounts"] doubleValue])];
        }
        s = [s stringByAppendingString:@"]}]});});</script></body>"];
        s = [s stringByReplacingOccurrencesOfString:@"mainCurrency" withString:_mainCurrency];
        [self.monthlyChartCanvas loadHTMLString:s baseURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/chart", [[NSBundle mainBundle] bundlePath]]]];

        [(UILabel*)[self.view viewWithTag:1] setText:[NSString stringWithFormat:@"Total Spent"]];
        [(UILabel*)[self.view viewWithTag:2] setText:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[[[self.tableContents objectAtIndex:[self.selectedItem section]] objectAtIndex:[self.selectedItem row]] valueForKey:@"summedamounts"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency]];
    }
}

- (void)viewDidUnload
{
    [self setTable:nil];
    [self setMonthlyChartCanvas:nil];
    [self setChartLoading:nil];
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
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":@"Spending Detail"} timed:YES];
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
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":@"Spending Detail"}];
#endif
    [super viewWillDisappear:animated];
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
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    NSDictionary* d = [[self.tableContents objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    [df setDateFormat:@"MMMM yyyy"];
    [components setYear:[[d valueForKey:@"year"] intValue]];
    [components setMonth:[[d valueForKey:@"month"] intValue]];
    [cell.textLabel setText:[[df stringFromDate:[cal dateFromComponents:components]] capitalizedString]];

    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[d valueForKey:@"summedamounts"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency]];

    return cell;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.chartLoading startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.chartLoading stopAnimating];
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

- (IBAction)exportSpendingData:(id)sender {
    NSOutputStream* st1 = [[NSOutputStream alloc] initToMemory];
    NSOutputStream* st2 = [[NSOutputStream alloc] initToMemory];
    
    [self makeCSV:st1 andDelimiter:','];
    [self makeCSV:st2 andDelimiter:';'];

    [self showEmail:st1 andAnother:st2];
}

- (void)makeCSV:(NSOutputStream*)st andDelimiter:(unichar)delim
{
    CHCSVWriter* csvw = [[CHCSVWriter alloc] initWithOutputStream:st encoding:NSUTF8StringEncoding delimiter:delim];
    [csvw writeComment:[NSString stringWithFormat:@"Spendings Report for %@", self.navigationItem.title]];
    [csvw writeField:@"Category"];
    [csvw writeField:@"Amount Spent"];
    [csvw writeField:@"Currency"];
    [csvw finishLine];
    for(NSDictionary* d in _monthlyExpenses) {
        [csvw writeField:[d objectForKey:@"note"]];
        [csvw writeField:[[[d objectForKey:@"summedamounts"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] stringValue]];
        [csvw writeField:_mainCurrency];
        [csvw finishLine];
    }
    [csvw writeComment:@"---"];
    [csvw writeField:@"Total Spent"];
    [csvw writeField:[[[_monthlyExpenses valueForKeyPath:@"@sum.summedamounts"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] stringValue]];
    [csvw writeField:_mainCurrency];
    [csvw finishLine];
    
    [csvw closeStream];
}

- (void)showEmail:(NSOutputStream*)st1 andAnother:(NSOutputStream*)st2 {
    
    NSString *emailTitle = [NSString stringWithFormat:@"Spendings Report"];
    NSString *messageBody = [NSString stringWithFormat:@"Spendings Report for %@", self.navigationItem.title];
//    NSArray *toRecipents = [NSArray arrayWithObject:@"support@appcoda.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    
    // Add attachment
    [mc addAttachmentData:[st1 propertyForKey:NSStreamDataWrittenToMemoryStreamKey] mimeType:@"text/csv" fileName:[NSString stringWithFormat:@"Spendings%@%02d-MSExcel", [[[self.tableContents objectAtIndex:[self.selectedItem section]] objectAtIndex:[self.selectedItem row]] valueForKey:@"year"], [[[[self.tableContents objectAtIndex:[self.selectedItem section]] objectAtIndex:[self.selectedItem row]] valueForKey:@"month"] integerValue]]];
    [mc addAttachmentData:[st2 propertyForKey:NSStreamDataWrittenToMemoryStreamKey] mimeType:@"text/csv" fileName:[NSString stringWithFormat:@"Spendings%@%02d-Numbers", [[[self.tableContents objectAtIndex:[self.selectedItem section]] objectAtIndex:[self.selectedItem row]] valueForKey:@"year"], [[[[self.tableContents objectAtIndex:[self.selectedItem section]] objectAtIndex:[self.selectedItem row]] valueForKey:@"month"] integerValue]]];
//    [mc addAttachmentData:fileData mimeType:mimeType fileName:filename];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
