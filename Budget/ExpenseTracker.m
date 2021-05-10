//
//  ExpenseTracker.m
//  Budget
//
//  Created by Nikolay Spassov on 28.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExpenseTracker.h"
#import "BudgetAppDelegate.h"
#import "TrackedAmounts.h"
#import "Balance.h"
#import "Amounts.h"
#import "MonthlyBalances.h"
#import "ExpenseCategoryDetail.h"
#import "TKCalendarMonthView.h"
#import "NSDate+TKCategory.h"

#define DATES 1
#define GROUPS 0
#define SECTION_BUDGETSPENT 0
#define SECTION_BUDGETED 1
#define SECTION_EXTRA 2
#define SECTION_TOTALSPENT 3

@interface ExpenseTracker() <AddTrackedAmountDelegate> {
    NSMutableArray *_objects;
    NSMutableArray* _others;
    NSMutableArray* _sections;
    NSString* _mainCurrency;
    NSDecimalNumber* _monthlyIncome;
    UITextField* _activeField;
    NSMutableArray* _selectedDateSpendings;
    NSMutableArray* _numberStack;
}
@end

@implementation ExpenseTracker
@synthesize table = _table;
@synthesize nav = _nav;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize addButton = _addButton;
@synthesize groupsToggle = _groupsToggle;
@synthesize tableView = _tableView;

-(void) recalculateCurrentBalance:(NSDecimalNumber*)amount ofCurrency:(NSString*)currency {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Balance" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"name == 'Savings' AND currency == '%@'", currency]];
    [fetchRequest setPredicate:filter];

    NSError* error;
    NSArray* buf = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(error) {
        NSLog(@"%@", error);
    }
    if(buf.count == 1) {
        if([[[[buf objectAtIndex:0] valueForKey:@"balance"] decimalNumberByAdding:amount] doubleValue] < 0) {
            [[buf objectAtIndex:0] setValue:[NSDecimalNumber zero] forKey:@"balance"];
        }
        else {
            [[buf objectAtIndex:0] setValue:[[[buf objectAtIndex:0] valueForKey:@"balance"] decimalNumberByAdding:amount] forKey:@"balance"];
        }
    }
    if(buf.count == 0) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [df setDateFormat:@"yyyyMM"];
        entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:_managedObjectContext];
        [fetchRequest setEntity:entity];
        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount > 0 AND (dateOccurs == '' OR dateOccurs MATCHES '%@.{0,2}')", [df stringFromDate:[cal dateFromComponents:components]]]];
        [fetchRequest setPredicate:filter];
        NSDecimalNumber* monthlyincome = [[_managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"];
        Balance* a = (Balance*)[NSEntityDescription insertNewObjectForEntityForName:@"Balance" inManagedObjectContext:_managedObjectContext];
        [a setName:[NSString stringWithFormat:@"Savings"]];
        if([[monthlyincome decimalNumberByAdding:amount] doubleValue] < 0) {
            [a setBalance:[NSDecimalNumber zero]];
        }
        else {
            [a setBalance:[monthlyincome decimalNumberByAdding:amount]];
        }
        [a setCurrency:currency];
    }
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", error);
    }
    
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
//    [df setDateFormat:@"yyyyMM"];
//    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:_managedObjectContext];
//    [fetchRequest setEntity:entity];
//    NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"dateOccurs MATCHES '%@.{0,2}'", [df stringFromDate:[cal dateFromComponents:components]]]];
//    [fetchRequest setPredicate:filter];
//    double monthlyexpenses = [[[_managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"] doubleValue];
//    
//    entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:_managedObjectContext];
//    [fetchRequest setEntity:entity];
//    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount > 0 AND (dateOccurs == '' OR dateOccurs MATCHES '%@.{0,2}')", [df stringFromDate:[cal dateFromComponents:components]]]];
//    [fetchRequest setPredicate:filter];
//    double monthlyincome = [[[_managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"] doubleValue];
//    fetchRequest = [[NSFetchRequest alloc] init];
//    entity = [NSEntityDescription entityForName:@"MonthlyBalances" inManagedObjectContext:_managedObjectContext];
//    [fetchRequest setEntity:entity];
//    filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"date == '%@'", [df stringFromDate:[cal dateFromComponents:components]]]];
//    [fetchRequest setPredicate:filter];
//    NSArray* buf = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
//    if(buf.count == 1) {
//        [[buf objectAtIndex:0] setValue:[NSDecimalNumber numberWithDouble:(monthlyincome-monthlyexpenses)] forKey:@"balance"];
//    }
//    if(buf.count == 0) {
//        MonthlyBalances* b = (MonthlyBalances*)[NSEntityDescription insertNewObjectForEntityForName:@"MonthlyBalances" inManagedObjectContext:_managedObjectContext];
//        [b setDate:[df stringFromDate:[cal dateFromComponents:components]]];
//        [b setBalance:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(monthlyincome+monthlyexpenses)]];
//        if (![_managedObjectContext save:&error]) {
//            NSLog(@"%@", error);
//        }
//    }
//    NSLog(@"%.2f ...", monthlyincome+monthlyexpenses);
}


-(void) showTrackedAmounts {
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[NSLocale currentLocale]];
    _mainCurrency = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        _mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }

    if(self.groupsToggle.selectedSegmentIndex == DATES) {
//        [self.table2 setHidden:NO];
//        [self.table setHidden:YES];

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"dateOccurs" ascending:NO];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        NSError *error;
        _objects = [NSMutableArray array];
        
        NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        
        _sections = [NSMutableArray array];
        
        //    for (int i = 11; i != -1; i--) {
//        int i = 0;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [components setYear:[components year]];
        [components setMonth:[components month]];
        [components setDay:[components day]];
        [df setDateFormat:@"yyyyMM"];
        NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount <= 0 AND dateOccurs MATCHES '%@.{0,2}'", [df stringFromDate:[cal dateFromComponents:components]]]];
        [fetchRequest setPredicate:filter];
        
        NSMutableArray* a = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
        
        //        if([a count] > 0) {
        [_objects addObject:a];
        [df setDateFormat:@"MMMM ’yy"];
        [_sections addObject:[df stringFromDate:[cal dateFromComponents:components]]];
        //        }
        
        //    }
        [self.table2 reloadData];
        [self.monthView selectDate:[NSDate date]];
        [self loadTableForDate:[NSDate date]];
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
//        [self.table2 setHidden:YES];
//        [self.table setHidden:NO];

        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
        [df setDateFormat:@"yyyyMM"];

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Amounts" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"note" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        NSError *error;
        _objects = [NSMutableArray array];
        NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount > 0 AND (dateOccurs == '' OR dateOccurs == '%@')", [df stringFromDate:[cal dateFromComponents:components]]]];
        [fetchRequest setPredicate:filter];
        _monthlyIncome = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"];
        if (error) {
            NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
        }
        
        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount < 0 AND (dateOccurs == '' OR dateOccurs == '%@')", [df stringFromDate:[cal dateFromComponents:components]]]];
        [fetchRequest setPredicate:filter];
        if (error) {
            NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
        }
        _others = [NSMutableArray array];
        [_others addObject:[NSArray array]];
        [_others addObject:[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy]];
        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount = 0 AND (dateOccurs == '' OR dateOccurs == '%@')", [df stringFromDate:[cal dateFromComponents:components]]]];
        [fetchRequest setPredicate:filter];
        [_others addObject:[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy]];
        NSArray* a1 = [[[_others objectAtIndex:SECTION_BUDGETED] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"amount <> 0"]] valueForKeyPath:@"note"];
        NSArray* a2 = [[[_others objectAtIndex:SECTION_EXTRA] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"amount = 0"]] valueForKeyPath:@"note"];
        [_others addObject:[NSArray array]];
        
        entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount <= 0 AND dateOccurs MATCHES '%@.{2}' AND note IN $A1", [df stringFromDate:[cal dateFromComponents:components]]]];
        fetchRequest.predicate = [filter predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:a1 forKey:@"A1"]];
//        [fetchRequest setPredicate:filter];
        NSExpressionDescription* ed = [[NSExpressionDescription alloc] init];
        NSExpression* exx = [NSExpression expressionWithFormat:@"@sum.amount"];
        [ed setExpression:exx];
        [ed setExpressionResultType:NSDecimalAttributeType];
        [ed setName:@"summedamounts"];
        [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"note", ed, nil]];
        [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObject:@"note"]];
        [fetchRequest setResultType:NSDictionaryResultType ];
        //    @try {
        NSArray* d = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        [_objects addObject:[NSArray array]];
        [_objects addObject:d];
        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount <= 0 AND dateOccurs MATCHES '%@.{2}' AND note IN $A2", [df stringFromDate:[cal dateFromComponents:components]]]];
        fetchRequest.predicate = [filter predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:a2 forKey:@"A2"]];
//        [fetchRequest setPredicate:filter];
        d = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        [_objects addObject:d];
        [_objects addObject:[NSArray array]];
        //    } @catch (NSException* e) {
        //        NSLog(@": eho? %@ %@", e, error);
        //    }
//        for(NSDictionary* t in d) {
//            NSLog(@": %@ %@", [t objectForKey:@"note"], [t objectForKey:@"summedamounts"]);
//        }
//        NSLog(@"ob: %@", _objects);
//        
//        NSLog(@": %@", _others);
        //    for(NSString* s in _others) {
        //        entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
        //        [fetchRequest setEntity:entity];
        //        filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@'", s]];
        //        [fetchRequest setPredicate:filter];
        //        NSLog(@"%@",[[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] valueForKeyPath:@"@sum.amount"]);
        //    }
        //    }
        //    @catch (NSException* e) {
        //        NSLog(@": %@", error);
        //    }
        //    _others = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
        //    NSLog(@": %@", _objects);
        if (error) {
            NSLog(@"fdsfdsfdsfdsfdsdfs");// Handle the error.
        }
        _sections = [NSMutableArray array];
        [_sections addObject:@"Spent / Budgeted This Month"];
        
        [components setYear:[components year]];
        [components setMonth:[components month]];
        [components setDay:[components day]];
        [df setDateFormat:@"MMMM"];
        [_sections addObject:@"Budgeted Spendings"];// [NSString stringWithFormat:@"%@", [df stringFromDate:[cal dateFromComponents:components]]]];
        
        [_sections addObject:@"Unbudgeted Spendings"];
        [_sections addObject:@"Spent / Saved This Month"];
        
        [self.table reloadData];
    }

}

-(void) addTrackedAmount:(id)sender {
    TrackedAmounts* amount = (TrackedAmounts*)[NSEntityDescription insertNewObjectForEntityForName:@"TrackedAmounts" inManagedObjectContext:_managedObjectContext];
    
    [amount setCurrency:[[sender currency] text]];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    [amount setAmount:(NSDecimalNumber*)[formatter numberFromString:[NSString stringWithFormat:@"-%@", [[sender amount] text]]]];
    [amount setNote:[[sender note] text]];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    [components setYear:[components year]];
    [components setMonth:[components month]];
    [components setDay:[components day]];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyyMMdd"];
    [amount setDateOccurs:[df stringFromDate:[cal dateFromComponents:components]]];
    [amount setYear:[NSNumber numberWithInt:[components year]]];
    [amount setMonth:[NSNumber numberWithInt:[components month]]];
    [amount setDay:[NSNumber numberWithInt:[components day]]];
    [amount setVenue:[sender venueName]];
    [amount setLatitude:[sender lat]];
    [amount setLongitude:[sender lng]];
    [amount setWhen:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", error);
    }

    [self recalculateCurrentBalance:[amount amount] ofCurrency:[amount currency]];
    
    if(self.groupsToggle.selectedSegmentIndex == DATES) {
        int section = 0;
        [df setDateFormat:@"MMMM ’yy"];
        if([_sections containsObject:[df stringFromDate:[cal dateFromComponents:components]]] == NO) {
            [_sections insertObject:[df stringFromDate:[cal dateFromComponents:components]] atIndex:0];
        }
        [[_objects objectAtIndex:section] insertObject:amount atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        [self.table insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        [self showTrackedAmounts];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier;
    Amounts* a = nil;
    if(self.groupsToggle.selectedSegmentIndex == DATES) {
        if(tableView == self.tableView) {
            CellIdentifier = @"Cell";
        }
        else {
            CellIdentifier = @"Tracked Amount";
        }
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        if(indexPath.section == SECTION_BUDGETSPENT || indexPath.section == SECTION_TOTALSPENT) {
            CellIdentifier = @"Monthly Amount";
        }
        else {
            a = [[_others objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            if([a.amount doubleValue] == 0) {
                CellIdentifier = @"Unbudgeted Summed Tracked Amount";
            }
            else {
                CellIdentifier = @"Summed Tracked Amount";
            }
        }
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        if(tableView == self.tableView) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
        else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
    }
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];

    if(self.groupsToggle.selectedSegmentIndex == DATES) {
        if(tableView == self.tableView) {
            TrackedAmounts* info = (TrackedAmounts*)[_selectedDateSpendings objectAtIndex:indexPath.row];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
//            NSLog(@"e %@", [_selectedDateSpendings objectAtIndex:indexPath.row]);
            [cell setText:[(TrackedAmounts*)[_selectedDateSpendings objectAtIndex:indexPath.row] note]];
            UILabel* spent = (UILabel*)[cell viewWithTag:2];
            if(!spent) {
                spent = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width-130, 2, 120, 25)];
                [spent setTag:2];
                [cell addSubview:spent];
                [spent setTextColor:[UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
                [spent setBackgroundColor:[UIColor clearColor]];
                [spent setTextAlignment:NSTextAlignmentRight];
                [spent setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin];
            }
            [spent setText:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[info amount]], [info currency]]];
        }
        else {
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            TrackedAmounts *info = [[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            UILabel* title = (UILabel*)[cell viewWithTag:1];
            title.text = info.note;
            
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyyMMdd"];
            NSDate* d = [df dateFromString:info.dateOccurs];
            [df setDoesRelativeDateFormatting:YES];
            [df setTimeStyle:NSDateFormatterNoStyle];
            [df setDateStyle:NSDateFormatterFullStyle];
            UILabel* subtitle = (UILabel*)[cell viewWithTag:3];
            subtitle.text = [df stringFromDate:d];
            
            UITextField* detail = (UITextField*)[cell viewWithTag:2];
            detail.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:info.amount], info.currency ];
        }
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        if(indexPath.section == SECTION_BUDGETSPENT) {
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
            UIProgressView* bar = (UIProgressView*)[cell viewWithTag:1];
            NSDecimalNumber* totalbudgetedspendings = [[_objects objectAtIndex:SECTION_BUDGETED] valueForKeyPath:@"@sum.summedamounts"];
            totalbudgetedspendings = [totalbudgetedspendings decimalNumberByAdding:[[_objects objectAtIndex:SECTION_EXTRA] valueForKeyPath:@"@sum.summedamounts"]];
            NSDecimalNumber* totalbudgetedexpenses = [[_others objectAtIndex:SECTION_BUDGETED] valueForKeyPath:@"@sum.amount"];
            double ratio = 0;
            if(![totalbudgetedexpenses isEqualToNumber:[NSDecimalNumber zero]]) {
                ratio = [[totalbudgetedspendings decimalNumberByDividingBy:totalbudgetedexpenses] doubleValue];
            }
            bar.progress = ratio;
            [bar setProgressTintColor:[UIColor colorWithHue:127*(1-ratio)/255.f saturation:.9 brightness:.75 alpha:1]];
            UILabel* title = (UILabel*)[cell viewWithTag:2];
            UILabel* detail = (UILabel*)[cell viewWithTag:3];
            title.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[totalbudgetedspendings decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
            detail.text = [NSString stringWithFormat:@"(%@ %@)", [formatter stringFromNumber:[totalbudgetedexpenses decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
            [title setTextColor:[UIColor colorWithRed:0x33/255.f green:0x33/255.f blue:0x33/255.f alpha:1]];
            [title setFont:[UIFont boldSystemFontOfSize:17]];
            [detail setTextColor:[UIColor colorWithRed:0x66/255.f green:0x66/255.f blue:0x66/255.f alpha:1]];
        }
        else if(indexPath.section == SECTION_TOTALSPENT) {
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
            UIProgressView* bar = (UIProgressView*)[cell viewWithTag:1];
            NSDecimalNumber* totalspendings = [[_objects objectAtIndex:SECTION_BUDGETED] valueForKeyPath:@"@sum.summedamounts"];
            totalspendings = [totalspendings decimalNumberByAdding:[[_objects objectAtIndex:SECTION_EXTRA] valueForKeyPath:@"@sum.summedamounts"]];
            NSDecimalNumber* saved = [_monthlyIncome decimalNumberByAdding:totalspendings];
            UILabel* title = (UILabel*)[cell viewWithTag:2];
            UILabel* detail = (UILabel*)[cell viewWithTag:3];
            title.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[totalspendings decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
            [title setTextColor:[UIColor colorWithRed:0x33/255.f green:0x33/255.f blue:0x33/255.f alpha:1]];
            [title setFont:[UIFont boldSystemFontOfSize:17]];
            if([saved doubleValue] > 0) {
                [detail setTextColor:[UIColor colorWithRed:0x00/255.f green:0x66/255.f blue:0x00/255.f alpha:1]];
                detail.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:saved], _mainCurrency];
            }
            else {
                [detail setTextColor:[UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1]];
                detail.text = [NSString stringWithFormat:@"(%@ %@)", [formatter stringFromNumber:[saved decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
            }
            double ratio = 0;
            if(![_monthlyIncome isEqualToNumber:[NSDecimalNumber zero]]) {
                ratio = [[[totalspendings decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] decimalNumberByDividingBy:_monthlyIncome] doubleValue];
            }
            bar.progress = ratio;
            [bar setProgressTintColor:[UIColor colorWithHue:127*(1-ratio)/255.f saturation:.9 brightness:.75 alpha:1]];
        }
        else {
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            NSPredicate *f = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"note == '%@'", a.note]];
            NSDictionary* info = [[[_objects objectAtIndex:indexPath.section] filteredArrayUsingPredicate:f] lastObject];

            UILabel* title = (UILabel*)[cell viewWithTag:1];
            title.text = a.note;
            UIProgressView* bar = (UIProgressView*)[cell viewWithTag:2];
            double ratio = (info == nil) ? 0 : fabs([[(NSDictionary*)info objectForKey:@"summedamounts"] doubleValue] / [a.amount doubleValue]);
            UILabel* subtitle1 = (UILabel*)[cell viewWithTag:4];
            UILabel* subtitle2 = (UILabel*)[cell viewWithTag:5];
            if(ratio > 1 || [a.amount doubleValue] == 0) {
                [bar setHidden:YES];
                [subtitle1 setHidden:NO];
                [subtitle2 setHidden:NO];
                if([a.amount doubleValue] == 0) {
                    subtitle1.text = [NSString stringWithFormat:@"Not Budgeted"];
                }
                else {
                    subtitle1.text = [NSString stringWithFormat:@"Overspent"];
                }
                double diff = [a.amount doubleValue] - [[(NSDictionary*)info objectForKey:@"summedamounts"] doubleValue];
                subtitle2.text = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[[(NSDictionary*)info objectForKey:@"summedamounts"] decimalNumberBySubtracting:a.amount] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] ], _mainCurrency];
                if(diff == 0) {
                    subtitle1.textColor = [UIColor colorWithRed:0x66/255.f green:0x66/255.f blue:0x66/255.f alpha:1];
                    subtitle2.textColor = [UIColor colorWithRed:0x66/255.f green:0x66/255.f blue:0x66/255.f alpha:1];
                }
                else {
                    subtitle1.textColor = [UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1];
                    subtitle2.textColor = [UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1];
                }
            }
            else {
                [bar setHidden:NO];
                [subtitle1 setHidden:YES];
                [subtitle2 setHidden:YES];
                bar.progress = ratio;
                [bar setProgressTintColor:[UIColor colorWithHue:127*(1-ratio)/255.f saturation:.9 brightness:.75 alpha:1]];
            }
    //        UIView* r = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
    //        [r setBackgroundColor:[UIColor colorWithHue:127*(1-ratio)/255.f saturation:.9 brightness:.75 alpha:.25]];
    //        [cell insertSubview:r atIndex:0];
    //        [bar setHidden:YES];
            UILabel* detail = (UILabel*)[cell viewWithTag:3];
            NSDecimalNumber* spent = [(NSDictionary*)info objectForKey:@"summedamounts"];
            if (spent == nil) {
                spent = [NSDecimalNumber zero];
            }
            detail.text = [[NSString alloc] initWithFormat:@"%@ %@", [formatter stringFromNumber:[spent decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
            if([a.amount doubleValue] == 0 && [[(NSDictionary*)info objectForKey:@"summedamounts"] doubleValue] != 0) {
                detail.textColor = [UIColor colorWithRed:0x66/255.f green:0x00/255.f blue:0x00/255.f alpha:1];
            }
            else {
                detail.textColor = [UIColor colorWithRed:0x66/255.f green:0x66/255.f blue:0x66/255.f alpha:1];
            }
    //        NSLog(@"%f", ratio);
        }
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == _tableView) {
        return 30;
    }
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(self.groupsToggle.selectedSegmentIndex == DATES) {
        if(tableView == _tableView) {
            return [_selectedDateSpendings count];
        }
        else {
            return [[_objects objectAtIndex:section] count];
        }
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        if(section == SECTION_BUDGETSPENT || section == SECTION_TOTALSPENT) {
            return 1;
        }
        else {
            return [[_others objectAtIndex:section] count];
        }
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.groupsToggle.selectedSegmentIndex == DATES) {
        if(tableView == _tableView) {
            return 1;
        }
        else {
            return [_objects count];
        }
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        return [_others count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(self.groupsToggle.selectedSegmentIndex == DATES) {
        if(tableView == _tableView) {
            return nil;
        }
        else {
            return [[_sections objectAtIndex:section] capitalizedString];
        }
    }
    else {
        if([[_others objectAtIndex:section] count] == 0
        && (section == SECTION_BUDGETED || section == SECTION_EXTRA)) {
            return @"";
        }
        else {
            return [_sections objectAtIndex:section];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    if(self.groupsToggle.selectedSegmentIndex == DATES) {
        if(tableView == _tableView) {
            return [NSString stringWithFormat:@"Total %@ %@", [formatter stringFromNumber:[[_selectedDateSpendings valueForKeyPath:@"@sum.amount"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];;
        }
        else {
            return [NSString stringWithFormat:@"Total %@ %@", [formatter stringFromNumber:[[[_objects objectAtIndex:0] valueForKeyPath:@"@sum.amount"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
        }
    }
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        if([[_objects objectAtIndex:section] count] == 0) {
            return @"";
        }
        else {
            if(section == SECTION_BUDGETSPENT || section == SECTION_TOTALSPENT) {
                return @"";
            }
            else {
                return [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[[_objects objectAtIndex:section] valueForKeyPath:@"@sum.summedamounts"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
            }
        }
    }
    return @"";
}




- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [_activeField resignFirstResponder];
	if ([segue.identifier isEqualToString:@"Add Tracked Amount"]) {
		UINavigationController *navigationController = segue.destinationViewController;
		AddTrackedAmount *AddTrackedAmount = [[navigationController viewControllers] objectAtIndex:0];
		AddTrackedAmount.delegate = self;
        AddTrackedAmount.amountType = @"Spending";
	}
    if([segue.identifier isEqualToString:@"Add Tracked Amount for Category"] || [segue.identifier isEqualToString:@"Add Tracked Amount for Category 2"]) {
		UINavigationController *navigationController = segue.destinationViewController;
		AddTrackedAmount *AddTrackedAmount = [[navigationController viewControllers] objectAtIndex:0];
		AddTrackedAmount.delegate = self;
        AddTrackedAmount.amountType = @"Spending";
        AddTrackedAmount.expenseCategory = [(UILabel*)[(UITableViewCell*)[sender superview] viewWithTag:1] text];
//        AddTrackedAmount.budgetedAmount = [(UILabel*)[(UITableViewCell*)[sender superview] viewWithTag:3] text];
    }
	if ([segue.identifier isEqualToString:@"Spendings Detail"] || [segue.identifier isEqualToString:@"Spendings Detail 2"]) {
//        [(ExpenseCategoryDetail*)[segue destinationViewController] setExpenseCategoryName:[(NSDictionary*)[[_objects objectAtIndex:[row section]] objectAtIndex:[row row]] objectForKey:@"note"]];
        [(ExpenseCategoryDetail*)[segue destinationViewController] setExpenseCategoryName:[(UILabel*)[(UITableViewCell*)[sender superview] viewWithTag:1] text]];

	}
}

- (void)addTrackedAmountDidCancel:(AddTrackedAmount *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addTrackedAmountDidSave:(AddTrackedAmount *)controller
{
    [self addTrackedAmount:controller];
    [self.table reloadData];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.groupsToggle.selectedSegmentIndex == GROUPS) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_activeField resignFirstResponder];
        if(tableView == _tableView) {
            TrackedAmounts* todelete = [_selectedDateSpendings objectAtIndex:indexPath.row];
            [self recalculateCurrentBalance:[[todelete amount] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] ofCurrency:[todelete currency]];
            
            [self.managedObjectContext deleteObject:todelete];
            NSError* error;
            if(![self.managedObjectContext save:&error]) {
                NSLog(@"%@", error);
            }
            
            [_selectedDateSpendings removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]  withRowAnimation:YES];
            
            [self.tableView reloadData];
        }
        else {
            TrackedAmounts* todelete = [[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            
            [self recalculateCurrentBalance:[[todelete amount] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]] ofCurrency:[todelete currency]];

            [self.managedObjectContext deleteObject:todelete];
            NSError* error;
            if(![self.managedObjectContext save:&error]) {
                NSLog(@"%@", error);
            }
            
            [[_objects objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]  withRowAnimation:YES];
            [self.table2 reloadData];
        }
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)determineUIState
{
    [_activeField resignFirstResponder];

    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState objectForKey:@"trackertogglestate"]) {
        [self.groupsToggle setSelectedSegmentIndex:[lastState integerForKey:@"trackertogglestate"]];
    }
    
    if([lastState integerForKey:@"calendartogglestate"] == 0) {
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"83-calendar"]];
    }
    else {
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"259-list"]];
    }

    if([lastState integerForKey:@"trackertogglestate"] == DATES) {
        [self.table2 setHidden:NO];
        [self.table setHidden:YES];

        if([lastState integerForKey:@"calendartogglestate"] == 0) {
            [self.calendarBackground setHidden:YES];
            [self.tableView setHidden:YES];
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
        }
        else {
            [self.calendarBackground setHidden:NO];
            [self.tableView setHidden:NO];
            [_monthView selectDate:[NSDate date]];
            [self loadTableForDate:[NSDate date]];
            [_monthView reload]; // dots on months
            [self.navigationItem.leftBarButtonItem setEnabled:NO];
        }
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    if([lastState integerForKey:@"trackertogglestate"] == GROUPS) {
        [self.table2 setHidden:YES];
        [self.table setHidden:NO];
        [super setEditing:NO animated:NO];
        [self.table2 setEditing:NO animated:NO];

        [self.calendarBackground setHidden:YES];
        [self.tableView setHidden:YES];
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}

- (IBAction)segmentedControlValueChanged:(id)sender
{
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    [lastState setInteger:[self.groupsToggle selectedSegmentIndex] forKey:@"trackertogglestate"];
    if(![lastState synchronize]) {
        NSLog(@"error");
    }

    [self determineUIState];
    [self showTrackedAmounts];
}


- (IBAction)toggleCalendar:(id)sender
{
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    [lastState setInteger:!(BOOL)[lastState integerForKey:@"calendartogglestate"] forKey:@"calendartogglestate"];
    if(![lastState synchronize]) {
        NSLog(@"error");
    }

    [self determineUIState];
    [self showTrackedAmounts];
}

- (void)loadTableForDate:(NSDate*)d
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    _selectedDateSpendings = [[NSMutableArray alloc] initWithArray:[[_objects objectAtIndex:0] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"day == %d", [[calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:d] day]]]]];
    [self.tableView reloadData];
}

- (NSArray*) calendarMonthView:(TKCalendarMonthView*)monthView marksFromDate:(NSDate*)startDate toDate:(NSDate*)lastDate{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSMutableArray* currMonth = [NSMutableArray array];
    
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[_monthView dateSelected]];
    [components setYear:[components year]];
    [components setMonth:[components month]];
    [components setDay:[components day]];
    [df setDateFormat:@"yyyyMM"];
    NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount <= 0 AND dateOccurs MATCHES '%@.{0,2}'", [df stringFromDate:[cal dateFromComponents:components]]]];
    [fetchRequest setPredicate:filter];
    
    currMonth = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
//    NSLog(@"%@", currMonth);
    
	NSMutableArray* dataArray = [NSMutableArray array];
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
//    NSInteger monthShown = [[currentCalendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[_monthView dateSelected]] month];
	NSDate *d = startDate;
	while([d compare:lastDate] != NSOrderedDescending){
		NSDateComponents* cur = [currentCalendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:d];
//        NSLog(@"сум %@", [[currMonth filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"day == %d",[cur day]]]] valueForKeyPath:@"@sum.amount"]);
        if(![[[currMonth filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"day == %d AND month == %d AND year == %d",[cur day],[cur month],[cur year]]]] valueForKeyPath:@"@sum.amount"] isEqual:@0]) {
            [dataArray addObject:[NSNumber numberWithBool:YES]];
        }
        else {
            [dataArray addObject:[NSNumber numberWithBool:NO]];
        }
		
		TKDateInformation info = [d dateInformationWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		info.day++;
		d = [NSDate dateFromDateInformation:info timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	}
    return dataArray;
}
- (BOOL) calendarMonthView:(TKCalendarMonthView*)monthView monthShouldChange:(NSDate*)month animated:(BOOL)animated
{
//    if([month compare:[NSDate date]] != NSOrderedDescending) {
//        return YES;
//    }
    return NO;
}
- (void) calendarMonthView:(TKCalendarMonthView*)monthView didSelectDate:(NSDate*)d{
    [self loadTableForDate:d];
}
- (void) calendarMonthView:(TKCalendarMonthView*)monthView monthDidChange:(NSDate*)month animated:(BOOL)animated{
	[self updateTableOffset:animated];
}
- (void) updateTableOffset:(BOOL)animated{
	
	
	if(animated){
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.4];
		[UIView setAnimationDelay:0.1];
	}
    
	
	float y = self.monthView.frame.origin.y + self.monthView.frame.size.height;
	self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, y, self.tableView.frame.size.width, self.view.frame.size.height - y );
	
	if(animated) [UIView commitAnimations];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.calendarBackground = [UIView new];
    self.calendarBackground.backgroundColor = [UIColor colorWithRed:0xbd/255.f green:0x55/255.f blue:0x00/255.f alpha:1];
    _monthView = [[TKCalendarMonthView alloc] initWithSundayAsFirst:!(BOOL)([[NSCalendar currentCalendar] firstWeekday]-1)];
	_monthView.delegate = self;
	_monthView.dataSource = self;
    [self.calendarBackground addSubview:self.monthView];
    [self.view addSubview:self.calendarBackground];
    
    self.tableView.backgroundColor = [UIColor whiteColor];
	
	float y,height;
	y = self.monthView.frame.origin.y + self.monthView.frame.size.height;
	height = self.view.frame.size.height - y;
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, y, self.view.bounds.size.width, height) style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_tableView];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
//    self.addButton = nil;
    self.navigationItem.rightBarButtonItem = self.addButton;
    [self.nav pushNavigationItem:self.navigationItem animated:YES];
    self.navigationItem.titleView = self.groupsToggle;

    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;

    //    self.table.dataSource = self.managedObjectContext;
        	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.calendarBackground setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.monthView.frame))];
    [self.monthView setCenter:CGPointMake(self.calendarBackground.center.x, self.monthView.center.y)];
}

-(void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.table2 setEditing:editing animated:animated];
}

- (void)viewDidUnload
{
    [self setNav:nil];
    [self setAddButton:nil];
    [self setGroupsToggle:nil];
    [self setTable:nil];
    [self setTable2:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0xbd/255.f green:0x55/255.f blue:0x00/255.f alpha:1]];
    [self.groupsToggle setTintColor:[UIColor colorWithRed:0xbd/255.f green:0x55/255.f blue:0x00/255.f alpha:1]];

    [self determineUIState];

    if ([self.table indexPathForSelectedRow] != nil) {
        [self.table deselectRowAtIndexPath:[self.table indexPathForSelectedRow] animated:YES];
    }
    else {
        [self showTrackedAmounts];
        [self.monthView selectDate:[NSDate date]];
        [self loadTableForDate:[NSDate date]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [super setEditing:NO animated:NO];
    [self.table2 setEditing:NO animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    UIToolbar* numpadToolbar = [[UIToolbar alloc] init];
    [numpadToolbar setBarStyle:UIBarStyleDefault];
    [numpadToolbar sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self.view action:@selector(endEditing:)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [numpadToolbar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    textField.inputAccessoryView = numpadToolbar;
    _activeField = textField;
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSIndexPath* indexPath = [self.table2 indexPathForCell:(UITableViewCell*)[[[textField superview] superview] superview]];
    if(IS_GT_IOS71) {
        indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    }
    TrackedAmounts* a = (TrackedAmounts*)[[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    
    textField.text = [formatter stringFromNumber:[a amount]];
    CGRect frame = [self.table2 frame];
    [self.table2 setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-210)];
    [self.table2 scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSIndexPath* indexPath = [self.table2 indexPathForCell:(UITableViewCell*)[[[textField superview] superview] superview]];
    if(IS_GT_IOS71) {
        indexPath = [self.table indexPathForCell:(UITableViewCell*)[[textField superview] superview]];
    }
    TrackedAmounts* a = (TrackedAmounts*)[[_objects objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    
    [a setAmount:(NSDecimalNumber*)[formatter numberFromString:textField.text]];
    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        NSLog(@"%@", error);
    }
    
    textField.text = [NSString stringWithFormat:@"%@ %@", textField.text, [a currency]];
    CGRect frame = [self.table2 frame];
    [self.table2 setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height+210)];
    [_numberStack removeAllObjects];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(_numberStack == nil) {
        _numberStack = [NSMutableArray arrayWithObject:@"0"];
    }
    if(string.length == 0 && _numberStack.count != 0) {
        [_numberStack removeObjectAtIndex:0];
    }
    if(string.length == 1) {
        [_numberStack insertObject:string atIndex:0];
    }
    double r = 0.00;
    double k = 0.01;
    int i = 0;
    for(i = 0, k = .01; i != [_numberStack count]; i++, k *= 10) {
        r += ([[_numberStack objectAtIndex:i] doubleValue] * k);
    }
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];
    textField.text = [NSString stringWithFormat:@"-%@", [formatter stringFromNumber:[NSNumber numberWithDouble:r]] ];
    
    return NO;
}

@end
