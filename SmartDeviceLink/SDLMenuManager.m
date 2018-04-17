//
//  SDLMenuManager.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 4/9/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "SDLMenuManager.h"

#import "SDLAddCommand.h"
#import "SDLAddSubMenu.h"
#import "SDLArtwork.h"
#import "SDLConnectionManagerType.h"
#import "SDLDeleteCommand.h"
#import "SDLDeleteSubMenu.h"
#import "SDLError.h"
#import "SDLFileManager.h"
#import "SDLImage.h"
#import "SDLLogMacros.h"
#import "SDLMenuCell.h"
#import "SDLMenuParams.h"
#import "SDLOnCommand.h"
#import "SDLOnHMIStatus.h"
#import "SDLRegisterAppInterfaceResponse.h"
#import "SDLRPCNotificationNotification.h"
#import "SDLRPCResponseNotification.h"
#import "SDLSetDisplayLayoutResponse.h"
#import "SDLVoiceCommand.h"


NS_ASSUME_NONNULL_BEGIN

@interface SDLMenuCell()

@property (assign, nonatomic) UInt32 parentCellId;
@property (assign, nonatomic) UInt32 cellId;

@end

@interface SDLVoiceCommand()

@property (assign, nonatomic) UInt32 commandId;

@end

@interface SDLMenuManager()

@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) SDLFileManager *fileManager;

@property (copy, nonatomic, nullable) SDLHMILevel currentLevel;
@property (strong, nonatomic, nullable) SDLDisplayCapabilities *displayCapabilities;

@property (strong, nonatomic, nullable) NSArray<SDLRPCRequest *> *inProgressUpdate;
@property (copy, nonatomic, nullable) SDLMenuUpdateCompletionHandler inProgressHandler;
@property (assign, nonatomic) BOOL hasQueuedUpdate;
@property (copy, nonatomic, nullable) SDLMenuUpdateCompletionHandler queuedUpdateHandler;
@property (assign, nonatomic) BOOL waitingOnHMILevelUpdate;

@property (assign, nonatomic) UInt32 lastMenuId;
@property (copy, nonatomic) NSArray<SDLMenuCell *> *oldMenuCells;
@property (assign, nonatomic) BOOL needsUpdate;

@end

UInt32 const ParentIdNotFound = UINT32_MAX;

@implementation SDLMenuManager

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    _lastMenuId = 0;
    _menuCells = @[];
    _voiceCommands = @[];
    _oldMenuCells = @[];
    _needsUpdate = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_registerResponse:) name:SDLDidReceiveRegisterAppInterfaceResponse object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_displayLayoutResponse:) name:SDLDidReceiveSetDisplayLayoutResponse object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_hmiStatusNotification:) name:SDLDidChangeHMIStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_commandNotification:) name:SDLDidReceiveCommandNotification object:nil];

    return self;
}

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager fileManager:(SDLFileManager *)fileManager {
    self = [self init];
    if (!self) { return nil; }

    _connectionManager = connectionManager;
    _fileManager = fileManager;

    return self;
}

#pragma mark - Updating System

- (void)sdl_updateWithCompletionHandler:(nullable SDLMenuUpdateCompletionHandler)completionHandler {
    if (self.currentLevel == nil || [self.currentLevel isEqualToString:SDLHMILevelNone] || !self.needsUpdate) {
        return;
    }

    if (self.inProgressUpdate != nil) {
        // There's an in progress update, we need to put this on hold
        self.hasQueuedUpdate = YES;
        return;
    }

    [self sdl_sendDeleteCurrentMenu:^(NSError * _Nullable error) {
        [self sdl_sendCurrentMenu:^(NSError * _Nullable error) {
            self.needsUpdate = NO;
            self.inProgressUpdate = nil;

            if (completionHandler != nil) {
                completionHandler(error);
            }

            if (self.hasQueuedUpdate) {
                [self sdl_updateWithCompletionHandler:nil];
            }
        }];
    }];
}

- (void)sdl_sendDeleteCurrentMenu:(nullable SDLMenuUpdateCompletionHandler)completionHandler {
    if (self.oldMenuCells.count == 0) {
        if (completionHandler != nil) {
            completionHandler(nil);
        }
        return;
    }

    NSArray<SDLRPCRequest *> *deleteMenuCommands = [self sdl_deleteCommandsForCells:self.oldMenuCells];
    self.oldMenuCells = @[];

    [self.connectionManager sendRequests:deleteMenuCommands progressHandler:nil completionHandler:^(BOOL success) {
        if (!success) {
            SDLLogE(@"Error deleting old menu commands");
        }

        SDLLogD(@"Finished deleting old menu");
        if (completionHandler != nil) {
            completionHandler(nil);
        }
    }];
}

- (void)sdl_sendCurrentMenu:(nullable SDLMenuUpdateCompletionHandler)completionHandler {
    if (self.menuCells.count == 0) {
        SDLLogD(@"No main menu to send");
        if (completionHandler != nil) {
            completionHandler(nil);
        }
        return;
    }

    NSArray<SDLRPCRequest *> *mainMenuCommands = nil;
    NSArray<SDLRPCRequest *> *subMenuCommands = nil;
    if ([self sdl_findAllArtworksToBeUploadedFromCells:self.menuCells].count > 0) {
        // Send artwork-less menu
        mainMenuCommands = [self sdl_mainMenuCommandsForCells:self.menuCells withArtwork:NO];
        subMenuCommands = [self sdl_subMenuCommandsForCells:self.menuCells withArtwork:NO];
    } else {
        // Send full artwork menu
        mainMenuCommands = [self sdl_mainMenuCommandsForCells:self.menuCells withArtwork:YES];
        subMenuCommands = [self sdl_subMenuCommandsForCells:self.menuCells withArtwork:YES];
    }

    self.inProgressUpdate = [mainMenuCommands arrayByAddingObjectsFromArray:subMenuCommands];

    __block NSMutableDictionary<SDLRPCRequest *, NSError *> *errors = [NSMutableDictionary dictionary];
    __weak typeof(self) weakSelf = self;
    [self.connectionManager sendRequests:mainMenuCommands progressHandler:^(__kindof SDLRPCRequest * _Nonnull request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error, float percentComplete) {
        if (error != nil) {
            errors[request] = error;
        }
    } completionHandler:^(BOOL success) {
        if (!success) {
            SDLLogE(@"Failed to send main menu commands: %@", errors);
            if (completionHandler != nil) {
                completionHandler([NSError sdl_menuManager_failedToUpdateWithDictionary:errors]);
            }
            return;
        }

        weakSelf.oldMenuCells = weakSelf.menuCells;

        [weakSelf.connectionManager sendRequests:subMenuCommands progressHandler:^(__kindof SDLRPCRequest * _Nonnull request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error, float percentComplete) {
            if (error != nil) {
                errors[request] = error;
            }
        } completionHandler:^(BOOL success) {
            if (!success) {
                SDLLogE(@"Failed to send sub menu commands: %@", errors);
                if (completionHandler != nil) {
                    completionHandler([NSError sdl_menuManager_failedToUpdateWithDictionary:errors]);
                }
                return;
            }

            SDLLogD(@"Finished updating menu");
            if (completionHandler != nil) {
                completionHandler(nil);
            }
        }];
    }];
}

#pragma mark - Setters

- (void)setMenuCells:(NSArray<SDLMenuCell *> *)menuCells {
    if (self.currentLevel == nil || [self.currentLevel isEqualToString:SDLHMILevelNone]) {
        _waitingOnHMILevelUpdate = YES;
        _menuCells = menuCells;
        return;
    }

    // TODO: Check for duplicates / duplicate titles? What will fail here?

    // Set the ids
    self.lastMenuId = 0;
    [self sdl_updateIdsOnMenuCells:menuCells parentId:ParentIdNotFound];

    _needsUpdate = YES;
    _oldMenuCells = _menuCells;
    _menuCells = menuCells;

    // Upload the artworks
    NSArray<SDLArtwork *> *artworksToBeUploaded = [self sdl_findAllArtworksToBeUploadedFromCells:self.menuCells];
    if (artworksToBeUploaded.count > 0) {
        [self.fileManager uploadArtworks:artworksToBeUploaded completionHandler:^(NSArray<NSString *> * _Nonnull artworkNames, NSError * _Nullable error) {
            if (error != nil) {
                SDLLogE(@"Error uploading menu artworks: %@", error);
            }

            SDLLogD(@"Menu artworks uploaded");
            self.needsUpdate = YES;
            [self sdl_updateWithCompletionHandler:nil];
        }];
    }

    [self sdl_updateWithCompletionHandler:nil];
}

- (void)setVoiceCommands:(NSArray<SDLVoiceCommand *> *)voiceCommands {
    if (self.currentLevel == nil || [self.currentLevel isEqualToString:SDLHMILevelNone]) {
        _waitingOnHMILevelUpdate = YES;
        _voiceCommands = voiceCommands;
        return;
    }

    // Set the ids

    _needsUpdate = YES;
    _voiceCommands = voiceCommands;

    [self sdl_updateWithCompletionHandler:nil];
}

#pragma mark - Helpers

#pragma mark Artworks

- (NSArray<SDLArtwork *> *)sdl_findAllArtworksToBeUploadedFromCells:(NSArray<SDLMenuCell *> *)cells {
    NSMutableArray<SDLArtwork *> *mutableArtworks = [NSMutableArray array];
    for (SDLMenuCell *cell in cells) {
        if (cell.icon != nil && ![self.fileManager hasUploadedFile:cell.icon]) {
            [mutableArtworks addObject:cell.icon];
        }

        if (cell.subCells.count > 0) {
            [mutableArtworks addObjectsFromArray:[self sdl_findAllArtworksToBeUploadedFromCells:cell.subCells]];
        }
    }

    return [mutableArtworks copy];
}

#pragma mark IDs

- (void)sdl_updateIdsOnMenuCells:(NSArray<SDLMenuCell *> *)menuCells parentId:(UInt32)parentId {
    for (SDLMenuCell *cell in menuCells) {
        cell.cellId = self.lastMenuId++;
        cell.parentCellId = parentId;
        if (cell.subCells.count > 0) {
            [self sdl_updateIdsOnMenuCells:cell.subCells parentId:cell.cellId];
        }
    }
}

#pragma mark Deletes

- (NSArray<SDLRPCRequest *> *)sdl_deleteCommandsForCells:(NSArray<SDLMenuCell *> *)cells {
    NSMutableArray<SDLRPCRequest *> *mutableDeletes = [NSMutableArray array];
    for (SDLMenuCell *cell in cells) {
        if (cell.subCells == nil) {
            SDLDeleteCommand *delete = [[SDLDeleteCommand alloc] initWithId:cell.cellId];
            [mutableDeletes addObject:delete];
        } else {
            SDLDeleteSubMenu *delete = [[SDLDeleteSubMenu alloc] initWithId:cell.cellId];
            [mutableDeletes addObject:delete];
        }
    }

    return [mutableDeletes copy];
}

- (NSArray<SDLDeleteCommand *> *)sdl_deleteCommandsForVoiceCommands:(NSArray<SDLVoiceCommand *> *)voiceCommands {
    NSMutableArray<SDLDeleteCommand *> *mutableDeletes = [NSMutableArray array];
    for (SDLVoiceCommand *command in self.voiceCommands) {
        SDLDeleteCommand *delete = [[SDLDeleteCommand alloc] initWithId:command.commandId];
        [mutableDeletes addObject:delete];
    }

    return [mutableDeletes copy];
}

#pragma mark Commands / SubMenu RPCs

- (NSArray<SDLRPCRequest *> *)sdl_mainMenuCommandsForCells:(NSArray<SDLMenuCell *> *)cells withArtwork:(BOOL)shouldHaveArtwork {
    NSMutableArray<SDLRPCRequest *> *mutableCommands = [NSMutableArray array];
    for (SDLMenuCell *cell in cells) {
        if (cell.subCells.count > 0) {
            [mutableCommands addObject:[self sdl_subMenuCommandForMenuCell:cell]];
        } else {
            [mutableCommands addObject:[self sdl_commandForMenuCell:cell withArtwork:shouldHaveArtwork]];
        }
    }

    return [mutableCommands copy];
}

- (NSArray<SDLRPCRequest *> *)sdl_subMenuCommandsForCells:(NSArray<SDLMenuCell *> *)cells withArtwork:(BOOL)shouldHaveArtwork {
    NSMutableArray<SDLRPCRequest *> *mutableCommands = [NSMutableArray array];
    for (SDLMenuCell *cell in cells) {
        if (cell.subCells.count > 0) {
            [mutableCommands addObjectsFromArray:[self sdl_allCommandsForCells:cell.subCells withArtwork:shouldHaveArtwork]];
        }
    }

    return [mutableCommands copy];
}

- (NSArray<SDLRPCRequest *> *)sdl_allCommandsForCells:(NSArray<SDLMenuCell *> *)cells withArtwork:(BOOL)shouldHaveArtwork {
    NSMutableArray<SDLRPCRequest *> *mutableCommands = [NSMutableArray array];
    for (SDLMenuCell *cell in cells) {
        if (cell.subCells.count > 0) {
            [mutableCommands addObject:[self sdl_subMenuCommandForMenuCell:cell]];
            [mutableCommands addObjectsFromArray:[self sdl_allCommandsForCells:cell.subCells withArtwork:shouldHaveArtwork]];
        } else {
            [mutableCommands addObject:[self sdl_commandForMenuCell:cell withArtwork:shouldHaveArtwork]];
        }
    }

    return [mutableCommands copy];
}

- (SDLAddCommand *)sdl_commandForMenuCell:(SDLMenuCell *)cell withArtwork:(BOOL)shouldHaveArtwork {
    SDLAddCommand *command = [[SDLAddCommand alloc] init];

    SDLMenuParams *params = [[SDLMenuParams alloc] init];
    params.menuName = cell.title;
    params.parentID = cell.parentCellId != UINT32_MAX ? @(cell.parentCellId) : nil;

    command.menuParams = params;
    command.vrCommands = cell.voiceCommands;
    command.cmdIcon = (cell.icon && shouldHaveArtwork) ? [[SDLImage alloc] initWithName:cell.icon.name] : nil;
    command.cmdID = @(cell.cellId);

    return command;
}

- (SDLAddSubMenu *)sdl_subMenuCommandForMenuCell:(SDLMenuCell *)cell {
    return [[SDLAddSubMenu alloc] initWithId:cell.cellId menuName:cell.title];
}

- (SDLAddCommand *)sdl_commandForVoiceCommand:(SDLVoiceCommand *)voiceCommand {
    SDLAddCommand *command = [[SDLAddCommand alloc] init];
    command.vrCommands = voiceCommand.voiceCommands;
    command.cmdID = @(voiceCommand.commandId);

    return command;
}

#pragma mark - Observers

- (void)sdl_commandNotification:(SDLRPCNotificationNotification *)notification {
    SDLOnCommand *onCommand = (SDLOnCommand *)notification.notification;

    NSArray<id> *allCommands = [self.menuCells arrayByAddingObjectsFromArray:self.voiceCommands];
    for (id object in allCommands) {
        if ([object isKindOfClass:[SDLMenuCell class]]) {
            SDLMenuCell *cell = (SDLMenuCell *)object;
            if (onCommand.cmdID.unsignedIntegerValue != cell.cellId) { continue; }

            cell.handler();
            break;
        } else if ([object isKindOfClass:[SDLVoiceCommand class]]) {
            SDLVoiceCommand *voiceCommand = (SDLVoiceCommand *)object;
            if (onCommand.cmdID.unsignedIntegerValue != voiceCommand.commandId) { continue; }

            voiceCommand.handler();
            break;
        }
    }

}

- (void)sdl_registerResponse:(SDLRPCResponseNotification *)notification {
    SDLRegisterAppInterfaceResponse *response = (SDLRegisterAppInterfaceResponse *)notification.response;
    self.displayCapabilities = response.displayCapabilities;
}

- (void)sdl_displayLayoutResponse:(SDLRPCResponseNotification *)notification {
    SDLSetDisplayLayoutResponse *response = (SDLSetDisplayLayoutResponse *)notification.response;
    self.displayCapabilities = response.displayCapabilities;
}

- (void)sdl_hmiStatusNotification:(SDLRPCNotificationNotification *)notification {
    SDLOnHMIStatus *hmiStatus = (SDLOnHMIStatus *)notification.notification;

    SDLHMILevel oldHMILevel = self.currentLevel;
    self.currentLevel = hmiStatus.hmiLevel;

    // Auto-send an updated show if we were in NONE and now we are not
    if ([oldHMILevel isEqualToString:SDLHMILevelNone] && ![self.currentLevel isEqualToString:SDLHMILevelNone]) {
        if (self.waitingOnHMILevelUpdate) {
            [self setMenuCells:_menuCells];
            [self setVoiceCommands:_voiceCommands];
        } else {
            [self sdl_updateWithCompletionHandler:nil];
        }
    }
}

@end

NS_ASSUME_NONNULL_END
