# Windows 10 scripting collection

## Overview

This is a collection of batch scripts intended for automating clean up of Windows, typically right after a fresh installation. They were developed and tested on Windows 10 Pro 64bit (1703).

Feel free to contribute where you see room for improvements or fixes!

## Contents

### Disable *Cortana*

    > cortana_disable.bat
	
Disables the (preinstalled) *Cortana*. First, *Cortana* is disabled for searching by a registry setting. Second, it is forced to shutdown with its installation folder being immediately moved to a backup folder which prevents it from restarting effectively.

### Remove *OneDrive*

	> onedrive_remove.bat

Disables and removes the (preinstalled) *OneDrive*. First, *OneDrive* is deactivated for file storage by a group policy setting. Second, it is uninstalled with all related files and folders removed for the current user.

Depends on the *LGPO* tool for the group policy setting. [It is part of the *Microsoft Security Compliance Toolkit*](https://www.microsoft.com/en-us/download/details.aspx?id=55319)

### List packages

    > pckg_list.bat
	
Lists installed or provisioned Windows (modern app) packages.

    > pckg_list.bat name
	
Lists installed or provisioned Windows (modern app) packages having 'name' in their package name (case-insensitive search).

### Remove packages

    > pckg_remove.bat name
	
Removes all packages having 'name' in their package name (case-insensitive search). Multiple name arguments are allowed.

1. Matching packages will be unprovisioned: They will not be installed anymore for newly created user accounts.
2. Additionally, a script is created for uninstalling matching packages in the 'Startup' folder of the start menu for each user who has the respective package installed. The automatically created script deletes itself after the first run which is triggered at login time. The script is created with a timestamp, thus `pckg_remove.bat` can be run multiple times, resulting in multiple startup scripts for the respective users.

### Clean up *This PC* folders

    remove_This_PC_folders_64bit.reg
	
A registry file, when applied, removes all folder shortcuts listed under *This PC* in Windows explorer.

## License

[MIT License](license.txt)