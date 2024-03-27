# Set the source and base destination paths
$backupsLocation = $PSScriptRoot
$urwLoc = "C:\Program Files (x86)\Steam\steamapps\common\UnRealWorld\"
# Load the settings.ini file
$iniPath = ".\settings.ini"


function create-new-ini {
    # Set default values
    $defaultValues = @"
[Settings]
defaultCharacterName=name
urwLoc=C:\Program Files (x86)\Steam\steamapps\common\UnRealWorld\
backupLocation=$PSScriptRoot
"@

    # Replace the placeholder with the actual script path
    $defaultValues = $defaultValues -replace '\$PSScriptRoot', $PSScriptRoot

    # Create a new INI file with default values
    $defaultValues | Out-File -FilePath $iniPath
}

# Check if the INI file exists
if (-not (Test-Path $iniPath)) {
    # Call the function to create a new INI file
    create-new-ini
}
$iniContent = Get-Content -Path $iniPath

# Loop through each non-commented line in the ini file
$iniContent | Where-Object { $_ -notmatch '^(;|#)' } | ForEach-Object {
    # Split the line into key and value
    $key, $value = $_.Split('=').Trim()
    # Remove any potential quotes around the value
    $value = $value -replace '^"|"$'
    # Create a variable with the name of the key and assign the value to it
    New-Variable -Name $key -Value $value
}

# Example usage: Accessing the variable
#Write-Host $defaultCharacterName



# Create a function to copy files
function Copy-Files {
    param (
        [string]$source,
        [string]$baseDestination,
		[string]$characterName,
		[string]$backupReason
    )
    $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
	$backupDetails = $characterName + "_" + $timestamp + "_" + $backupReason
    $destinationPath = Join-Path -Path $baseDestination -ChildPath ("$backupDetails")

    # Create the target directory if it doesn't exist
    if (-not (Test-Path -Path $destinationPath)) {
        New-Item -ItemType Directory -Force -Path $destinationPath
    }

    Get-ChildItem -Path $source -Recurse | ForEach-Object {
        $targetPath = $_.FullName.Replace($source, $destinationPath)
        Copy-Item -Path $_.FullName -Destination $targetPath -Force
    }
	return $backupDetails
}

[void] [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Backup Utility'
$form.Size = New-Object System.Drawing.Size(496,404)
$form.AutoScaleMode = 'None'
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
# Set a light pastel blue background that matches the serene sky blue button
$form.BackColor = [System.Drawing.Color]::FromArgb(189, 212, 214)

# Create the picture box
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = 'Fill'
# Define the full path to the image
$imagePath = Join-Path $PSScriptRoot ".\.assets\main-background.png"

# Use the full path in the FromFile method
$pictureBox.BackgroundImage = [System.Drawing.Image]::FromFile($imagePath)
$pictureBox.BackgroundImageLayout = 'None'

# Set the transparency
$pictureBox.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($pictureBox)



$defaultFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)



# Create the label for the character name text box
$characterNameLabel = New-Object System.Windows.Forms.Label
$characterNameLabel.Location = New-Object System.Drawing.Point(10,80)
$characterNameLabel.Size = New-Object System.Drawing.Size(125,20)
$characterNameLabel.Text = 'Character Name:'
$characterNameLabel.Font = $defaultFont
$characterNameLabel.BackColor = [System.Drawing.Color]::Transparent

$form.Controls.Add($characterNameLabel)


# Create the text box for the character name input
$characterNameTextBox = New-Object System.Windows.Forms.TextBox
$characterNameTextBox.Location = New-Object System.Drawing.Point(137,75)
$characterNameTextBox.Size = New-Object System.Drawing.Size(140,40)
$form.Controls.Add($characterNameTextBox)
$characterNameTextBox.font = $defaultFont
$characterNameTextBox.text = $defaultCharacterName
# Set the character name text box to a light orange, echoing the deep sunset orange button
$characterNameTextBox.BackColor = [System.Drawing.Color]::FromArgb(255, 229, 204)


$filterSearchLabel = New-Object System.Windows.Forms.Label
$filterSearchLabel.Location = New-Object System.Drawing.Point(292,80) # Position to the right of the text box
$filterSearchLabel.Size = New-Object System.Drawing.Size(100,20) # Half the width and height of the character name label
$filterSearchLabel.Text = "(also filter search)"
$filterSearchLabel.Font = New-Object System.Drawing.Font($defaultFont.FontFamily.Name, ($defaultFont.Size / 1.5), $defaultFont.Style)
$characterNameLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($filterSearchLabel)



# Create a timer
$idleTimer = New-Object System.Windows.Forms.Timer
$idleTimer.Interval = 1000 # Set the interval to 1 second

# Timer Tick event that runs when the user stops typing
$idleTimer.Add_Tick({
    $idleTimer.Stop() # Stop the timer to prevent it from ticking again
    $rootNode.Nodes.Clear() # Clear the existing nodes
	#Write-Host $backupsLocation $rootNode $characterName
    Populate-TreeView -rootPath $backupsLocation -node $rootNode
    $rootNode.Expand()
	$rootNode.EnsureVisible()
})

# TextChanged event for the character name text box
$characterNameTextBox.Add_TextChanged({
    $idleTimer.Stop() # Stop the timer if it's already running
    $idleTimer.Start() # Start the timer which will tick after 1 second of inactivity
})

# Don't forget to dispose of the timer when closing the form
$form.Add_FormClosing({ $idleTimer.Dispose() })

# Handle the FormClosing event
$form.Add_FormClosing({
    # Path to the settings.ini file
    $iniPath = ".\settings.ini"
    
    # Read the existing content of the ini file
    $iniContent = Get-Content -Path $iniPath
    
    # Find the line containing the default character name
    $characterNameLine = $iniContent | Where-Object { $_ -match "^defaultCharacterName\s*=" }
    
    # If the line exists, replace it with the new value
    if ($characterNameLine) {
        $newValue = "defaultCharacterName = " + $characterNameTextBox.Text
        $iniContent = $iniContent -replace [regex]::Escape($characterNameLine), $newValue
    } else {
        # If the line does not exist, add it to the ini file
        $iniContent += "defaultCharacterName = " + $characterNameTextBox.Text
    }
    
    # Save the updated content back to the settings.ini file
    $iniContent | Set-Content -Path $iniPath
})


# Create the label
$originalText = "Hail, traveler, to the unreal UnReal World.`n  Secure your legacy; let not the frost claim your tales.                  github.com/wdpk/urwbackup"

$outputBanner = New-Object System.Windows.Forms.Label
$outputBanner.AutoSize = $true
$outputBanner.Text = $originalText

# Assuming $outputBanner is your label and $originalText is the original text
$bannerTimer = New-Object System.Windows.Forms.Timer
$bannerTimer.Interval = 15000 # Set the interval to 15 seconds (15000 milliseconds)

# Define the action to take when the timer elapses
$bannerTimer.Add_Tick({
    $outputBanner.Text = $originalText
    $outputBanner.BackColor = $form.BackColor

    $bannerTimer.Stop() # Stop the timer after resetting the text
})

# Function to start the timer, call this function whenever you change the text of the outputBanner
function Start-ResetTimer {
    $bannerTimer.Start()
}


$form.Add_FormClosing({ $bannerTimer.Dispose() })

# Position the label at the bottom left of the form
$outputBanner.Location = New-Object System.Drawing.Point(10, 329)

# Add the label to the form
$form.Controls.Add($outputBanner)

# Rest of your form code...





# Create the TreeView control
$treeView = New-Object System.Windows.Forms.TreeView
$treeView.Location = New-Object System.Drawing.Point(120, 120)
$treeView.Size = New-Object System.Drawing.Size(363, 200)
$treeView.Font = New-Object System.Drawing.Font("Arial", 10)


# Set the TreeView to a light green, complementing the fresh leaf green button
$treeView.BackColor = $form.BackColor
# Make the TreeView border transparent
$treeView.BorderStyle = 'None'


# Function to populate the TreeView with directories
function Populate-TreeView($rootPath, $node) {
	$filterName = $characterNameTextBox.Text.ToUpper() # Get the character name and convert to uppercase
    try {
        # Get directories that match the filter and add them as child nodes
        $directories = Get-ChildItem -Path $rootPath -Directory | Where-Object { $_.Name -like "*$filterName*" -and $_.Name -notlike ".*" }
        foreach ($directory in $directories) {
            $subNode = New-Object System.Windows.Forms.TreeNode($directory.Name)
            $subNode.Tag = $directory.FullName
			#Write-Host "Found the thing which is $subNode"
            $empty = $node.Nodes.Add($subNode)
            # Optionally, recursively populate the tree if needed
            #Populate-TreeView -rootPath $directory.FullName -node $subNode -filterName $filterName
        }
    } catch {
        Write-Host "Error accessing ${rootPath}: $_"
    }
    foreach ($node in $treeView.Nodes) {
    if ($node.Tag -eq (Get-Date).ToString('yyyyMMdd')) {
        $node.NodeFont = New-Object System.Drawing.Font($treeView.Font, [System.Drawing.FontStyle]::Bold)
    }
}

}



# Initial population of the TreeView
$rootNode = New-Object System.Windows.Forms.TreeNode($backupsLocation)
$rootNode.Tag = $backupsLocation
$treeView.Nodes.Add($rootNode)
Populate-TreeView -rootPath $backupsLocation -node $rootNode
$rootNode.Expand()

# Add the TreeView to the form
$form.Controls.Add($treeView)



$makeBackupButton = New-Object System.Windows.Forms.Button
$makeBackupButton.Location = New-Object System.Drawing.Point(10,170)
$makeBackupButton.Size = New-Object System.Drawing.Size(100,46)
# Set the button text to display on two lines
$makeBackupButton.Text = "Make`nBackup"

# Increase the font size of the button text
$makeBackupButton.Font = $defaultFont
# A fresh leaf green, evoking the vibrant, renewing energy of spring foliage.
$makeBackupButton.BackColor = [System.Drawing.Color]::FromArgb(60, 179, 113)


$makeBackupButton.Add_Click({
    $characterName = $characterNameTextBox.Text.Trim()
    if (-not [string]::IsNullOrWhiteSpace($characterName)) {
        # Proceed with backup logic here
$backupForm = New-Object System.Windows.Forms.Form
$backupForm.Text = 'Backup Reason'
$backupForm.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 0) # Autumn Orange
$backupForm.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Bold)
$backupForm.StartPosition = 'CenterScreen'
$backupForm.Size = New-Object System.Drawing.Size(350, 200)
$backupForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

# Create a label
$backupForm = New-Object System.Windows.Forms.Form
$backupForm.Text = 'Backup Reason'
$backupForm.BackColor = [System.Drawing.Color]::FromArgb(200, 229, 204) # Pastel Green
$backupForm.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Bold)
$backupForm.StartPosition = 'CenterScreen'
$backupForm.Size = New-Object System.Drawing.Size(350, 200)
$backupForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(330, 70)
$label.Text = "Enter the reason for the backup:`r`e.g. pre-battle, journey, season, scheduled, etc."
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$backupForm.Controls.Add($label)

# Create a text box
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(45, 80)
$textBox.Size = New-Object System.Drawing.Size(260, 30)
$textBox.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 10)
$textBox.Text = "Reason..."
$backupForm.Controls.Add($textBox)

# Create an OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(125, 120)
$okButton.Size = New-Object System.Drawing.Size(100, 35)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$backupForm.AcceptButton = $okButton
$backupForm.Controls.Add($okButton)

# Show the form as a dialog box and capture the result
$result = $backupForm.ShowDialog()


# Output the text box value if the user clicked OK
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $backupReason = $textBox.Text -replace '[\\\/:*?"<>|\s]+', '-'
    # Now you can use $backupReason as needed
}

# Clean up the form
$backupForm.Dispose()

if ($backupReason -eq '') {
    $backupReason = 'routine'
}
		# Retrieve the character name from the text box and convert it to upper case
		$characterName = $characterNameTextBox.Text.ToUpper()
		$saveSourcePath = "C:\Program Files (x86)\Steam\steamapps\common\UnRealWorld\" + $characterName
        $savedToPlace = Copy-Files -source $saveSourcePath -baseDestination $backupsLocation -characterName $characterName -backupReason $backupReason
		$outputBanner.Text = "Saved as `n$savedToPlace"
        
        Start-ResetTimer # Starts the countdown to reset the text

		$rootNode.Nodes.Clear()
		Populate-TreeView -rootPath $backupsLocation -node $rootNode
    
} else {
        $outputBanner.Text = "Error: Character name cannot be blank to start backup."
            $outputBanner.BackColor = [System.Drawing.Color]::FromArgb(255, 229, 204)

        Start-ResetTimer
    }
})

$form.Controls.Add($makeBackupButton)

$restoreBackupButton = New-Object System.Windows.Forms.Button
$restoreBackupButton.Location = New-Object System.Drawing.Point(10,220)
$restoreBackupButton.Size = New-Object System.Drawing.Size(100,46)
$restoreBackupButton.Text = "Restore`nBackup"
# Increase the font size of the button text
$restoreBackupButton.Font = $defaultFont
# A deep sunset orange, capturing the warm, soothing hues of a late evening sky.
$restoreBackupButton.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 0)



$restoreBackupButton.Add_Click({
    if ($treeView.SelectedNode -ne $null) {
        $selectedFolder = $treeView.SelectedNode.Tag
        if ($selectedFolder) {
            # Extract the folder name without the timestamp
            $index_of_underscore = $selectedFolder.IndexOf("_")
            if ($index_of_underscore -ne -1) {
                $folderNameFull = $selectedFolder.Substring(0, $index_of_underscore)
            } else {
                $folderNameFull = $selectedFolder
            }
            $folderName = Split-Path -Path $folderNameFull -Leaf

            $unrealWorldPath = "C:\Program Files (x86)\Steam\steamapps\common\UnRealWorld\"
            $destinationPath = Join-Path -Path $unrealWorldPath -ChildPath $folderName

            if (Test-Path -Path $destinationPath) {
                # Confirmation form for overriding existing game
                #
                $confirmOverrideForm = New-Object System.Windows.Forms.Form
$confirmOverrideForm.Text = "Existing Character Conflict"
$confirmOverrideForm.BackColor = [System.Drawing.Color]::DarkOrange
$confirmOverrideForm.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Bold)
$confirmOverrideForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$confirmOverrideForm.Size = New-Object System.Drawing.Size(350, 200)
$confirmOverrideForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

$label = New-Object System.Windows.Forms.Label
$label.Text = "Are you sure you want to `nreplace the existing character:`n" + $folderName + "?"
$label.Size = New-Object System.Drawing.Size(330, 70)
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.Location = New-Object System.Drawing.Point(10, 20)
$confirmOverrideForm.Controls.Add($label)

$yesButton = New-Object System.Windows.Forms.Button
$yesButton.Text = "Yes"
$yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
$yesButton.Size = New-Object System.Drawing.Size(120, 35)
$yesButton.Location = New-Object System.Drawing.Point(50, 120)
$confirmOverrideForm.Controls.Add($yesButton)
$confirmOverrideForm.AcceptButton = $yesButton

$noButton = New-Object System.Windows.Forms.Button
$noButton.Text = "No"
$noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
$noButton.Size = New-Object System.Drawing.Size(120, 35)
$noButton.Location = New-Object System.Drawing.Point(180, 120)
$confirmOverrideForm.Controls.Add($noButton)
$confirmOverrideForm.CancelButton = $noButton
$confirmOverrideForm.ActiveControl = $noButton

$confirmOverrideForm.ShowDialog()


                if ($confirmOverrideForm.DialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Remove-Item -Path $destinationPath -Recurse -Force
                    Copy-Item -Path $selectedFolder -Destination $destinationPath -Recurse -Force
                    $outputBanner.Text = "Restore performed from: `n`t" + $selectedFolder
                }

                $confirmOverrideForm.Dispose()
            } else {
                Copy-Item -Path $selectedFolder -Destination $destinationPath -Recurse -Force
                $outputBanner.Text = "Restore performed from: `n`t" + $selectedFolder
            }
            Start-ResetTimer # Starts the countdown to reset the text
        }
    }
})

$form.Controls.Add($restoreBackupButton)

$browseBackupButton = New-Object System.Windows.Forms.Button
$browseBackupButton.Location = New-Object System.Drawing.Point(10,120)
$browseBackupButton.Size = New-Object System.Drawing.Size(100,46)

$browseBackupButton.Text = "Browse`nBackups"
# Increase the font size of the button text
$browseBackupButton.Font = $defaultFont
# A soft lavender, suggestive of a gentle field of blooming lavender swaying in a light breeze.
$browseBackupButton.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 250)

$browseBackupButton.Add_Click({
    # Assuming $backupsLocation contains the path of the root node
    Start-Process "explorer.exe" -ArgumentList $backupsLocation
})

$form.Controls.Add($browseBackupButton)

$removeBackupButton = New-Object System.Windows.Forms.Button
$removeBackupButton.Location = New-Object System.Drawing.Point(10,270) # Adjust the Y-coordinate to position below the browse button
$removeBackupButton.Size = New-Object System.Drawing.Size(100,46)
$removeBackupButton.Text = "Remove`nBackup"
# Increase the font size of the button text
$removeBackupButton.Font = $defaultFont
# A bold crimson red, reflecting the passionate, dynamic spirit of a rose in full bloom.
$removeBackupButton.BackColor = [System.Drawing.Color]::FromArgb(220, 20, 60)

$removeBackupButton.Add_Click({
    # Get the selected node from the TreeView
    $selectedNode = $treeView.SelectedNode
    if ($selectedNode -ne $null) {
        # Confirm before removing
# Create a new form for delete confirmation
$deleteConfirmForm = New-Object System.Windows.Forms.Form
$deleteConfirmForm.Text = "Confirm Removal"
$deleteConfirmForm.BackColor = [System.Drawing.Color]::LightCoral
$deleteConfirmForm.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Bold)
$deleteConfirmForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$deleteConfirmForm.Size = New-Object System.Drawing.Size(350, 200)
$deleteConfirmForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

$label = New-Object System.Windows.Forms.Label
$label.Text = "Are you sure you want to remove the backup:`n$($selectedNode.Text)?"
$label.Size = New-Object System.Drawing.Size(330, 70)
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.Location = New-Object System.Drawing.Point(10, 20)
$deleteConfirmForm.Controls.Add($label)

$yesButton = New-Object System.Windows.Forms.Button
$yesButton.Text = "Yes"
$yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
$yesButton.Size = New-Object System.Drawing.Size(120, 35)
$yesButton.Location = New-Object System.Drawing.Point(50, 120)
$deleteConfirmForm.Controls.Add($yesButton)
$deleteConfirmForm.AcceptButton = $yesButton

$noButton = New-Object System.Windows.Forms.Button
$noButton.Text = "No"
$noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
$noButton.Size = New-Object System.Drawing.Size(120, 35)
$noButton.Location = New-Object System.Drawing.Point(180, 120)
$deleteConfirmForm.Controls.Add($noButton)
$deleteConfirmForm.CancelButton = $noButton
$deleteConfirmForm.ActiveControl = $noButton

$deleteConfirmForm.ShowDialog()


# Check the result
if ($deleteConfirmForm.DialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
    # User confirmed deletion
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.NameSpace(0xA)
    $itemPath = $selectedNode.Tag # Assuming the full path is stored in the Tag property
    $item = $shell.NameSpace($itemPath).Self
    $recycleBin.MoveHere($item)
    $treeView.Nodes.Remove($selectedNode)
} else {
    # User cancelled deletion
    $confirmation = $false
}

# Clean up
$deleteConfirmForm.Dispose()

    } else {
        $outputBanner.Text = "Error: No backup selected to remove."
        $outputBanner.BackColor = [System.Drawing.Color]::FromArgb(255, 129, 104)

        Start-ResetTimer
    }
})
$form.Controls.Add($removeBackupButton)

# Set the z-order for the controls to ensure they are on top of the background image
$form.Controls.SetChildIndex($characterNameLabel, 0)
$form.Controls.SetChildIndex($characterNameTextBox, 1)
$form.Controls.SetChildIndex($filterSearchLabel, 2)
$form.Controls.SetChildIndex($outputBanner, 4)
$form.Controls.SetChildIndex($treeView, 5)
$form.Controls.SetChildIndex($makeBackupButton, 6)
$form.Controls.SetChildIndex($restoreBackupButton, 7)
$form.Controls.SetChildIndex($browseBackupButton, 8)
$form.Controls.SetChildIndex($removeBackupButton, 9)
$form.Controls.SetChildIndex($pictureBox, 10)
# Note: The SetChildIndex method should be called after all controls have been added to the form.


$form.Add_Shown({$form.Activate()})
$form.ShowDialog()