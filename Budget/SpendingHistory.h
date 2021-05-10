//
//  SpendingHistory.h
//  Budget
//
//  Created by Nikolay Spassov on 18.10.12.
//
//

#import <UIKit/UIKit.h>

@interface SpendingHistory : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIWebView *monthlyChartCanvas;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *chartLoading;
@property (strong, nonatomic) NSMutableArray* tableContents;
@property (strong, nonatomic) NSMutableArray* tableSections;
@property (strong, nonatomic) NSIndexPath* selectedItem;
@property (weak, nonatomic) IBOutlet UISegmentedControl *groupsToggle;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
- (IBAction)segmentedControlValueChanged:(id)sender;

@end
