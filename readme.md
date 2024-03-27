# UnReal World Backup Utility

## Overview
UnReal World Backup Utility is a PowerShell script designed to streamline the process of managing backups (aka save scumming) for the UnReal World game. This utility provides a user-friendly interface for browsing, creating, restoring, and removing backups, ensuring your game progress is always safe and recoverable.

## Features
- **Browse Backups**: Easily navigate to your backup storage location using the built-in file explorer.
- **Make Backups**: Create backups with custom reasons, allowing for organized and descriptive backup management.
- **Restore Backups**: Quickly restore your game from a selected backup to revert to a previous state.
- **Remove Backups**: Safely delete old or unnecessary backups to free up space and maintain a tidy backup repository.

## Installation
1. Download the `unreal-backup-utility.ps1` script. For best organization, place it in a new, dedicated folder.
2. Ensure PowerShell is installed and configured on your system.
3. Run the script by right-clicking and selecting "Run with PowerShell".

## Usage
Upon launching the script, a GUI will appear with the following options:
- **Make Backup**: Enter a reason for the backup and click to create a new backup.
- **Browse Backups**: View and access all existing backups.
- **Restore Backup**: Select a backup from the list and restore it.
- **Remove Backup**: Choose a backup and remove it from the storage.
The backup tool automatically stores your game data in the same folder as the script. The main input box is where you enter your character's name to either create a backup or search for existing ones. Make sure to use the correct character name; otherwise, the tool will create an empty placeholder folder.

For convenience, the character name field is pre-filled with the name you used last time, thanks to a settings file (INI) that remembers your previous choices.
## Screenshots

- **Starting Fresh**

  ![Starting Fresh](/.screenshots/1.new-character.png)
- **Entering Backup Reason**

  ![Entering Backup Reason](/.screenshots/2.backup-reason.png)
- **Backup Completed**

  ![Backup Completed](/.screenshots/3.backup-completed.png)
- **Selecting a Restore Point**

  ![Selecting a Restore Point](/.screenshots/4.restore-select.png)
- **Confirming Restore Action**

  ![Confirming Restore Action](/.screenshots/5.restore-confirm.png)
- **Restore Completed**

  ![Restore Completed](/.screenshots/6.restore-complete.png)
- **Confirming Deletion of Backup**

  ![Confirming Deletion of Backup](/.screenshots/7.confirm-delete.png)
- **Home Screen**

  ![Home Screen](/.screenshots/home.png)
- **Search Functionality**

  ![Search Functionality](/.screenshots/search.png)

## Roadmap
Currently, the project is considered complete (pau). Future updates may focus on performance improvements and compatibility enhancements if necessary. I'm happy with where it's at here, but there are some possible improvements.
### (Possible) Upcoming Features
- **Travel Mode**: Automatically create a backup when the player's position has moved a configurable number of tiles on the world map, as determined by the last entry in the message log.
- **Elapsed Time Mode**: Generate a backup based on the number of in-game days that have passed, using the information from the message log.
- **On-Trigger Backup**: Implement backups that are triggered by specific in-game events, which will be identified through the message log entries. e.g. Falling through the ice, being attacked, etc.

## Cautions
Some UrW saves can be very large, and making an excessive number of backups could easily grow to be several GB quite quickly. Use judiciously.

## Disclosures
Microsoft Copilot (not Github, but not sure how they differ tbh?) used to generate both script and documentation, though it was stitched together and tested by a human(me). Background image generated in Microsoft Designer, modified using GIMP. Source image available in assets.
