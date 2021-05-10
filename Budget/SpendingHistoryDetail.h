//
//  SpendingHistory.h
//  Budget
//
//  Created by Nikolay Spassov on 18.10.12.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SpendingHistoryDetail : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIWebView *monthlyChartCanvas;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *chartLoading;
@property (strong, nonatomic) NSMutableArray* tableContents;
@property (strong, nonatomic) NSMutableArray* tableSections;
@property (strong, nonatomic) NSIndexPath* selectedItem;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
- (IBAction)exportSpendingData:(id)sender;

@end
