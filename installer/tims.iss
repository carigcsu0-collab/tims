; Inno Setup script for CSU TVET IMS (Windows).
; Build with:  ISCC.exe /DAppVersion=1.0.1 installer\tims.iss
; Run from the project root after `flutter build windows --release`.

#ifndef AppVersion
  #define AppVersion "1.0.1"
#endif

#define AppName "CSU TVET IMS"
#define AppExeName "tims.exe"

[Setup]
AppId={{6F1B2C7E-3A4D-4E8F-9B21-7C5D0A9E4F10}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=CAGAYAN STATE UNIVERSITY-CARIG CAMPUS
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=..\build\installer
OutputBaseFilename=tims-setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
