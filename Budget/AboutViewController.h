//
//  AboutViewController.h
//  Budget
//
//  Created by Nikolay Spassov on 13.01.13.
//
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView* thankYou;
@property (weak, nonatomic) IBOutlet UIView *trialInfoView;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;
- (IBAction)buyButtonPressed:(id)sender;
- (IBAction)restoreButtonPressed:(id)sender;
- (void)setBought;

@end
