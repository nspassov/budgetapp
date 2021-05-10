//
//  BudgetSettings.m
//  Budget
//
//  Created by Nikolay Spassov on 26.10.12.
//
//

#import "BudgetSettings.h"

@interface BudgetSettings () {
    NSMutableArray *_pickerData;
    NSArray* _currencies;
}
@end

@implementation BudgetSettings


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [textField setHidden:YES];
    UIPickerView* currencyPicker = [[UIPickerView alloc] init];
    currencyPicker.dataSource = self;
    currencyPicker.delegate = self;
    currencyPicker.showsSelectionIndicator = YES;
    textField.inputView = currencyPicker;
    UIToolbar* toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleDefault];
    [toolbar sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self.view action:@selector(endEditing:)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolbar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    textField.inputAccessoryView = toolbar;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
//    int i = [(UIPickerView*)[(UITextField*)[(UITableViewCell*)[[textField superview] superview] viewWithTag:3] inputView] selectedRowInComponent:0];
//    [(UILabel*)[(UITableViewCell*)[[textField superview] superview] viewWithTag:2] setText:[[_pickerData objectAtIndex:i] valueForKey:@"code"]];
    [textField setText:@""];
    [textField setHidden:NO];
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    [lastState setObject:[[_pickerData objectAtIndex:row] valueForKey:@"code"] forKey:@"mainCurrency"];
    if (![lastState synchronize]) {
        NSLog(@"Error Synchronizing NSUserDefaults");
    }
    [(UITextField*)[self.mainCurrencyCell viewWithTag:2] setText:[[_pickerData objectAtIndex:row] valueForKey:@"code"]];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[_pickerData objectAtIndex:row] valueForKey:@"name"];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _pickerData.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString* mainCurrency = @"";
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }
    else {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setLocale:[NSLocale currentLocale]];
        mainCurrency = [formatter currencyCode];
    }
    [(UITextField*)[self.mainCurrencyCell viewWithTag:2] setText:mainCurrency];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _pickerData = [NSMutableArray array];
    _currencies = [[NSArray alloc] initWithArray:[NSLocale ISOCurrencyCodes]];
    for(NSString* lc in _currencies) {
        NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]];
        NSString* s = [loc displayNameForKey:NSLocaleCurrencyCode value:lc];
        if(s != nil) {
            NSMutableDictionary* item = [NSMutableDictionary dictionary];
            [item setObject:lc forKey:@"code"];
            [item setObject:s forKey:@"name"];
            [_pickerData addObject:item];
        }
    }
    _pickerData = [[_pickerData sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
        return [[a valueForKey:@"name"] compare:[b valueForKey:@"name"]];
    }] mutableCopy];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return 1;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
}

- (void)viewDidUnload {
    [self setMainCurrencyCell:nil];
    [super viewDidUnload];
}
@end
