//
//  RootViewController.m
//  bac_01
//
//  Created by Christoph Hechenblaikner on 22.02.12.
//  Copyright (c) 2012 Graz University of Technology. All rights reserved.
//

#import "RootViewController.h"
#import "SecureContainer.h"
#import "ContainerDetailViewController.h"
#import "BluetoothConnectionHandler.h"
#import <Security/Security.h>
#import "KeyChainManager.h"
#import "FilePathFactory.h"
#import "NSData+CommonCrypto.h"
#import "CreateCertificateViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <GameKit/GameKit.h>
#import "Crypto.h"
#import "ZipArchive.h"
#import "ChooseContainerViewController.h"
#import "Base64.h"
#import "Validation.h"
#import "UserSettingsViewController.h"
#import "TextProvider.h"
#import "XMLParser.h"
#import "CertificateRequest.h"


#define SECTION_CONTAINERS 0
#define SECTION_ACTIONS 1
#define NUMBER_SECTIONS 2
#define ROW_ACTION_SEND_BT 0
#define ROW_ACTION_RECEIVE_BT 1
#define ROW_ACTION_SEND_MAIL 2
#define ROW_ACTION_SEND_REQUEST 3
#define NUMBER_ROWS_CREATE 1
#define NUMBER_ROWS_ACTIONS 4
#define TEST_CERTIFICAT_OWNER @"Christof"
#define USERS_DEFAULT_EMAIL @"default_email_property"


@interface RootViewController() {
@private
    NSInteger rowAddContainer;
}
@end


@implementation RootViewController

@synthesize btConnectionHandler = _btConnectionHandler;
@synthesize receivedCertificateData = _receivedCertificateData;
@synthesize containers = _containers;
@synthesize certData = _certData;
@synthesize receivedFileURL = _receivedFileURL;
@synthesize phoneNumber = _phoneNumber;

-(id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        
        self.containers = [FilePathFactory getContainersOfFileStructure];
        
        //[KeyChainManager deleteCertificatewithOwner:CERT_ID_USER];
        
        //[KeyChainManager deleteUsersPrivateKey];

        
        //creating Handler for Bluetooth-Connection
        BluetoothConnectionHandler* tempbt = [[BluetoothConnectionHandler alloc] init];
        self.btConnectionHandler = tempbt;
    }
    
    return self;
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"linenbg.png"]];
    CGRect background_frame = self.tableView.frame;
    background_frame.origin.x = 0;
    background_frame.origin.y = 0;
    background.frame = background_frame;
    background.contentMode = UIViewContentModeTop;
    self.tableView.backgroundView = background;

    
    //checking if a certificate has to be created
    if([KeyChainManager getCertificateofOwner:CERT_ID_USER] == nil)
    {
        [self performSegueWithIdentifier:SEGUE_TO_CREATE_CERT sender:nil];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self showEditBarButtonItem];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUMBER_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == SECTION_CONTAINERS)
    {
        rowAddContainer = [self.containers count];
        return rowAddContainer+1;
    }
    else if(section == SECTION_ACTIONS)
        return NUMBER_ROWS_ACTIONS;
    
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == SECTION_CONTAINERS && indexPath.row != rowAddContainer)
        return YES;
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.containers removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    
    if([self.containers count] == 0)
    {
        [self endEditTableView];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if(indexPath.section == SECTION_CONTAINERS)
    {
        if(indexPath.row == rowAddContainer)
        {
            cell.textLabel.text = NSLocalizedString(@"Create Container", @"Text for create a new container in the root view");
        }
        else
        {
            cell.textLabel.text = [[self.containers objectAtIndex:indexPath.row] name];
        }
        
    }
    else if(indexPath.section == SECTION_ACTIONS)
    {
        if(indexPath.row == ROW_ACTION_SEND_BT)
        {
            cell.textLabel.text = NSLocalizedString(@"Send Certificate via Bluetooth", @"Button for sending a certificate via bluetooth in the root view");
        }
        else if(indexPath.row == ROW_ACTION_RECEIVE_BT)
        {
            cell.textLabel.text = NSLocalizedString(@"Receive Certificate via Bluetooth", @"Button for receiving a certificate via bluetooth in the root view");
        }
        else if(indexPath.row == ROW_ACTION_SEND_MAIL)
        {
            cell.textLabel.text = NSLocalizedString(@"Send Certificate via Email/SMS", @"Button for sending certificate via two-way exchange (Email/SMS) in the root view");
        }
        else if(indexPath.row == ROW_ACTION_SEND_REQUEST)
        {
            cell.textLabel.text = NSLocalizedString(@"Send a Certificate-Request", @"Button for sending a certificate-request to another user in the roow view");
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    if(section == SECTION_CONTAINERS)
        return NSLocalizedString(@"Containers", @"Cell headline for containers section in the root view");
    else if(section == SECTION_ACTIONS)
        return NSLocalizedString(@"Actions", @"Cell headline for actions section in the root view");
    
    return NSLocalizedString(@"ERROR", @"Cell headline for error (this should not appear in productive environment");
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *hView = [[UIView alloc] initWithFrame:CGRectZero];
    hView.backgroundColor=[UIColor clearColor];
    
    UILabel *hLabel=[[UILabel alloc] initWithFrame:CGRectMake(19,10,301,21)];
    
    hLabel.backgroundColor=[UIColor clearColor];
    hLabel.shadowColor = [UIColor blackColor];
    hLabel.shadowOffset = CGSizeMake(0.5,1);
    hLabel.textColor = [UIColor whiteColor];
    hLabel.font = [UIFont boldSystemFontOfSize:17];
    hLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    [hView addSubview:hLabel];
    
    
    return hView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == SECTION_CONTAINERS)
    {
        if(indexPath.row == rowAddContainer)
        {
            NSError* directory_creation_error = nil;
            
            NSString* path = [FilePathFactory getUniquePathInFolder:[FilePathFactory applicationDocumentsDirectory] forFileExtension:nil];
            
            NSLog(@"Path: %@",path);
            
            NSDictionary* attributes = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:attributes error:&directory_creation_error];
            if(directory_creation_error != nil)
            {
                NSLog(@"Problem creating directory!!");
            }
            
            SecureContainer* newcontainer = [[SecureContainer alloc] init];
            newcontainer.basePath = path;
            newcontainer.name = [path lastPathComponent];
            newcontainer.creationDate = [NSDate date];
            [self.containers addObject:newcontainer];
                        
            [self performSegueWithIdentifier:SEGUE_TO_DETAIL sender:[self.containers lastObject]];
        }
        else
        {
            [self performSegueWithIdentifier:SEGUE_TO_DETAIL sender:[self.containers objectAtIndex:indexPath.row]];
        }
    }
   /* else if(indexPath.section == SECTION_ACTIONS)
    {
        if(indexPath.row == ROW_ACTION_SEND_BT)
        {
            [self sendCertificateBluetooth];
            
        } 
        else if (indexPath.row == ROW_ACTION_RECEIVE_BT)
        {
            [self.btConnectionHandler receiveDataWithHandlerDelegate:self];
        }
        else if(indexPath.row == ROW_ACTION_SEND_MAIL)
        {
            [self performSegueWithIdentifier:SEGUE_TO_CERT_ASS sender:nil]; 
        }
        else if(indexPath.row == ROW_ACTION_SEND_REQUEST)
        {
            [self sendCertificateRequest]; 
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];   
    }*/
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - BluetoothConnectionHandlerDelegate methods

- (void) receivedBluetoothData: (NSData*) data
{
    
    self.receivedCertificateData = data;
    
    //showing people picker do identify owner of the certificate
    ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self presentModalViewController:picker animated:YES];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    
    return NO;
}

#pragma mark - methods to send certificate

-(void) sendCertificateBluetooth
{
    NSData* sendData = [KeyChainManager getCertificateofOwner:CERT_ID_USER];
    
    [self.btConnectionHandler sendDataToAll:sendData];
}

-(void) sendCertificateMailTextMessage
{
    [self performSegueWithIdentifier:SEGUE_TO_CERT_ASS sender:nil];
}

#pragma mark - methods for provide editing BarButtonItem
-(void) editTableView
{
    [self.tableView setEditing:YES animated:YES];
    [self showDoneBarButtonItem];
}

-(void) endEditTableView
{
    [self.tableView setEditing:NO animated:YES];
    [self showEditBarButtonItem];
}

-(void) showEditBarButtonItem
{
    
    [self.navigationItem setRightBarButtonItem:nil];
    
    if([self.containers count] > 0)
    {
        UIBarButtonItem* editbutton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTableView)];
        [self.navigationItem setRightBarButtonItem:editbutton animated:YES];
    }
}

-(void) showDoneBarButtonItem
{
    
    UIBarButtonItem* donebutton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditTableView)];
    [self.navigationItem setRightBarButtonItem:donebutton animated:YES];    
}


#pragma mark - segue control methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:SEGUE_TO_DETAIL])
    {
        ContainerDetailViewController* detail = (ContainerDetailViewController*) [segue destinationViewController];
        
        SecureContainer* container = (SecureContainer*) sender;
        
        [detail setContainer:container];
        
        if(self.receivedFileURL != nil)
        {
            NSString* filename = [[self.receivedFileURL lastPathComponent] stringByDeletingPathExtension];
            
            NSString* path = [FilePathFactory getUniquePathInFolder:container.basePath forFileExtension:[self.receivedFileURL pathExtension] andFileName:filename];
            
            NSData* recfile = [NSData dataWithContentsOfURL:self.receivedFileURL];
            
            BOOL success = [recfile writeToFile:path options:NSDataWritingFileProtectionComplete error:nil];
            
            if(success == NO)
            {
                NSLog(@"error saving file");
            }
            
            [detail addFilesToContainer:[NSArray arrayWithObject:path]];
            
            [[NSFileManager defaultManager] removeItemAtURL:self.receivedFileURL error:nil];
        }
        
        self.receivedFileURL = nil;
    }
    else if([segue.identifier isEqualToString:SEGUE_TO_CHOOSE_CONTROLLER])
    {
        self.receivedFileURL = (NSURL*)sender;
        
        UINavigationController* nav = (UINavigationController*) segue.destinationViewController;
        
        ChooseContainerViewController* choose = (ChooseContainerViewController*) [nav.viewControllers objectAtIndex:0];
        
        choose.containers = self.containers;
        
        choose.delegate = self;
    }
    else if([segue.identifier isEqualToString:SEGUE_TO_DEFAULT_EMAIL])
    {
        UINavigationController *nav = (UINavigationController*)segue.destinationViewController;
        UserSettingsViewController *settings = (UserSettingsViewController*)[nav.viewControllers objectAtIndex:0];
        settings.sender = self;
    }
}

#pragma mark - methods for decrypting container

-(void) decryptContainer:(NSData*) encryptedContainer
{
    NSData* usercert = [KeyChainManager getCertificateofOwner:CERT_ID_USER];
    
    NSData* userprivateKey = [KeyChainManager getUsersPrivateKey];
    
    if(usercert == nil || userprivateKey == nil)
    {
        NSLog(@"Could not decrypt container because of missing key / certificate");
        return;
    }
    
    NSData* zippedcontainer;
    
    @try 
    {
        zippedcontainer = [[Crypto getInstance] decryptBinaryFile:encryptedContainer withUserCertificate:usercert privateKey:userprivateKey];
    }
    @catch (NSException *exception) 
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not decrypt", @"Title of alert in root view. The container could not be decrypted") 
                                                        message:NSLocalizedString(@"The container was not encrypted using your certificate", @"Message of alert in root view. The container could not be decrypted") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    @finally 
    {
        
    }
    
    NSFileManager* filemanager = [NSFileManager defaultManager];
    
    //creating incoming directory
    NSString* incoming = [[FilePathFactory applicationDocumentsDirectory] stringByAppendingPathComponent:NAME_INCOMING_DIRECTORY];
    [filemanager createDirectoryAtPath:incoming withIntermediateDirectories:NO attributes:nil error:nil];
    
    //creating path for zip-file
    NSString* zippath = [[incoming stringByAppendingPathComponent:NAME_TEMP_INCOMING_ZIP] stringByAppendingPathExtension:@"zip"];
    
    //writing zipfile
    [zippedcontainer writeToFile:zippath atomically:YES];
    
    //creating zipper and extracting zip
    ZipArchive* archive = [[ZipArchive alloc] init];
    
    if([archive UnzipOpenFile:zippath])
    {        
        [archive UnzipFileTo:incoming overWrite:YES];
    }
    
    [archive UnzipCloseFile];
        
    NSLog(@"documents: %@",[filemanager contentsOfDirectoryAtPath:[FilePathFactory applicationDocumentsDirectory] error:nil]);
    
    //deleting zip-file
    BOOL successdeletion = [filemanager removeItemAtPath:zippath error:nil];
    
    if(successdeletion == NO)
    {
        NSLog(@"error deleting zip-file!!");
    }
    
    //listing contents if incoming
    NSArray* incomingcontent = [filemanager contentsOfDirectoryAtPath:incoming error:nil];
    
    NSLog(@"incoming: %@",incomingcontent.description);
    
    //generating new unique name for folder
    NSString* pathindoc = [FilePathFactory getUniquePathInFolder:[FilePathFactory applicationDocumentsDirectory] forFileExtension:nil];
    
    [filemanager createDirectoryAtPath:pathindoc withIntermediateDirectories:NO attributes:nil error:nil];
    
    //moving files to new folder and determining container name
    NSString* newcontainername = nil;
    for(NSString* subpath in incomingcontent)
    {
        NSString* fullpath = [incoming stringByAppendingPathComponent:subpath];
        if([[subpath pathExtension] isEqualToString:DIRECTORY_EXTENSION])
        {
            newcontainername = [subpath stringByDeletingPathExtension];
        }
        else
        {
            BOOL successmove = [filemanager moveItemAtPath:fullpath toPath:[pathindoc stringByAppendingPathComponent:subpath] error:nil];
            if(successmove == NO)
            {
                NSLog(@"problem moving file into new directory!!");
            }
        }
    }
    
    //defining new containerpath (with correct name)
    NSString* newcontainerpath = [[FilePathFactory applicationDocumentsDirectory] stringByAppendingPathComponent:newcontainername];
    
    //ensuring unique name
    newcontainerpath = [FilePathFactory getUniquePathInFolder:[FilePathFactory applicationDocumentsDirectory] forFileExtension:nil andFileName:newcontainername];
    
    //renaming directory
    [filemanager moveItemAtPath:pathindoc toPath:newcontainerpath error:nil];
    
    NSLog(@"content of new folder %@",newcontainerpath);
    
    
    //parsing new container in container-structure
    SecureContainer* newcontainer = [FilePathFactory parseContainerAtPath:newcontainerpath];
    
    [self.containers addObject:newcontainer];
    
    //reloading tableview
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_CONTAINERS] withRowAnimation:UITableViewRowAnimationRight];
    
    //deleting incoming
    [filemanager removeItemAtPath:incoming error:nil];
    
}


#pragma mark - UIAlertViewDelegateMethods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != 0)
    {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"checksum_verification"] == 1)
        {
            NSString *sms = [alertView textFieldAtIndex:0].text;
            NSArray *hashArray = [sms componentsSeparatedByString:@"is: "];
            if ([hashArray count] <= 1)
            {
                hashArray = [sms componentsSeparatedByString:@"ist: "];
            }
            NSString *hash = [hashArray lastObject];
            hash = [hash stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; //stripping whitespaces
            
            //hash from sms
            NSLog(@"base64 hash: %@", hash);
            NSData *decoded = [Base64 decode:hash];
            NSLog(@"decoded: %@", decoded);
            
            
            //hash from received cert
            NSMutableData *macOut = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH]; //CC_SHA256_DIGEST_LENGTH];
            
            //CC_SHA256(dataIn.bytes, dataIn.length,  macOut.mutableBytes);
            CC_SHA1(self.certData.bytes, self.certData.length, macOut.mutableBytes);
            
            NSLog(@"orig hash: %@", macOut);
            
            NSLog(@"hash from sms: %@", [Base64 encode:decoded]);
            NSLog(@"hash from cert: %@", [Base64 encode:macOut]);
            
            if ([[Base64 encode:decoded] isEqualToString:[Base64 encode:macOut]])
            {
                
            }
            else {
                self.certData = nil;
            }
        }
        
        if (self.certData == nil)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error opening certificate", @"Title of alert view in root view. The certificate could not be opened") message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            
            [alert show];
        }
        else 
        {
            self.receivedCertificateData = self.certData;
            
            ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];
            picker.peoplePickerDelegate = self;
            
            [self presentModalViewController:picker animated:YES];
        }
        
        self.certData = nil;   
    }
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    
}

#pragma mark - ChoosedContainerDelegate methods

-(void) choosedContainer:(NSInteger) index
{
    
    [self dismissModalViewControllerAnimated:YES];
    
    [self performSegueWithIdentifier:SEGUE_TO_DETAIL sender:[self.containers objectAtIndex:index]];
}



// -------------------------------------
// CURRENTLY NOT IN USE?????????????????
// -------------------------------------
-(BOOL) isDataProtectionEnabled
{
    
    NSString *testFilePath = [[[FilePathFactory applicationDocumentsDirectory] stringByAppendingPathComponent:@"dptest"] stringByAppendingPathExtension:@"txt"];
    
    NSData* testdata = [[NSData alloc] initWithData:[@"testtest" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError* savingerror = [[NSError alloc] init];
    
    if([testdata writeToFile:testFilePath options:NSDataWritingFileProtectionComplete error:&savingerror])
    {
        NSLog(@"writing to file failed");
    }// obviously, do better error handling
    
    NSArray* doccontentes = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[FilePathFactory applicationDocumentsDirectory] error:nil];
    
    NSLog(@"%@",doccontentes.description);
    
    NSDictionary *testFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:testFilePath error:NULL];
    
    NSLog(@"testfileattr: %@",testFileAttributes.description);
    
    BOOL fileProtectionEnabled = [NSFileProtectionNone isEqualToString:[testFileAttributes objectForKey:NSFileProtectionKey]];
    
    return fileProtectionEnabled;
}

-(void) dealloc
{
    self.containers = nil;
    self.btConnectionHandler = nil;
    self.receivedFileURL = nil;
}


#pragma mark - certificate request
- (void)manageCertificateRequest:(NSData*)request
{    
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:request];
    
    XMLParser *parser = [[XMLParser alloc] initXMLParser];
    [xmlParser setDelegate:parser];
    
    BOOL success = [xmlParser parse];
    
    if(success)
        NSLog(@"XML parser succeeded!");
    else
        NSLog(@"A XML parser ERROR occured!");
    
    CertificateRequest *certRequest = parser.certRequest;
    
    NSLog(@"emailaddress: %@", certRequest.emailAddress);
    NSLog(@"phone number: %@", certRequest.phoneNumber);
    self.phoneNumber = certRequest.phoneNumber;
    
    MFMailComposeViewController* composer = [[MFMailComposeViewController alloc] init];
    [composer setToRecipients:[NSArray arrayWithObject:certRequest.emailAddress]];
    [composer setSubject:NSLocalizedString(@"My Certificate", @"Subject for certificate email in root view")];
    [composer setMessageBody:NSLocalizedString(@"You will receive the chechsum for my certificate shortly via SMS or iMessage", @"Body for certificate email in root view") isHTML:NO];
    composer.mailComposeDelegate = self;
    
    
    NSData *cert = [KeyChainManager getCertificateofOwner:CERT_ID_USER];
    NSMutableData *macOut = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cert.bytes, cert.length, macOut.mutableBytes);
    NSString *encoded =  [Base64 encode:macOut];
    self.hash = encoded;
    
    [composer addAttachmentData:cert mimeType:@"application/iaikencryption" fileName:@"cert.iaikcert"];
    
    self.certMailSent = YES;
    [self presentModalViewController:composer animated:YES];
    
}


@end
