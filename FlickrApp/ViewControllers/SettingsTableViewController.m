//
//  SettingsTableViewController.m
//  FlickrApp
//
//  Created by Nikita Rodin on 11/17/14.
//  Copyright (c) 2014 Artezio. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Localization.h"

typedef NS_ENUM(NSUInteger, Languages) {
    LanguageEnglish,
    LanguageRussian,
    LanguagesCount
};

@interface SettingsTableViewController ()

@property (nonatomic, assign) Languages selectedLocale;

@end

NSString* const kEventChangedLocale = @"languageChanged";

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // setup view
    self.title = MYLocalizedString(@"Settings",);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:MYLocalizedString(@"Save",) style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    NSString* locale = [[NSUserDefaults standardUserDefaults] stringForKey:@"locale"];
    self.selectedLocale = [locale isEqualToString:@"en"]? LanguageEnglish : LanguageRussian;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return LanguagesCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    

    
    // Configure the cell...
    if (indexPath.row == LanguageEnglish) {
        cell.textLabel.text = @"Engilsh";
    } else
    {
        cell.textLabel.text = @"Русский";
    }
    cell.accessoryType = indexPath.row == self.selectedLocale? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    self.selectedLocale = indexPath.row;
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return MYLocalizedString(@"Choose language", );
}

#pragma mark - actions

- (void)saveTapped {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* locale = self.selectedLocale == LanguageEnglish? @"en" : @"ru";
    [defaults setValue:locale forKey:@"locale"];
    [defaults synchronize];
    [Localization setLanguage:locale];
    [[NSNotificationCenter defaultCenter] postNotificationName:kEventChangedLocale object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
