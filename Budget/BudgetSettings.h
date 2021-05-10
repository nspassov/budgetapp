//
//  BudgetSettings.h
//  Budget
//
//  Created by Nikolay Spassov on 26.10.12.
//
//

#import <UIKit/UIKit.h>

@interface BudgetSettings : UITableViewController <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UITableViewCell *mainCurrencyCell;

@end
