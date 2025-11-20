; Sonarr-Seedr Integration Installer Script
; Generated for Inno Setup 6.x

#define MyAppName "Seedr"
#define MyAppVersion "Sonarr-SeedrIntegration-AutomatedtorrentdownloadingviaSeedrcloudservice"
#define MyAppPublisher "Joseph"
#define MyAppURL "https://github.com/jose987654/sonarr-plugin"
#define MyAppExeName "SonarrSeedr.exe"
#define MyAppId "{{1947a849-4ee4-494f-8a6f-08d1c765d29b}}"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; Generate a new GUID here: https://www.guidgenerator.com/
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=LICENSE
OutputDir=releases\installers
OutputBaseFilename=SonarrSeedr-Setup-v{#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
SetupIconFile=logo.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes
DisableWelcomePage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startupicon"; Description: "Start {#MyAppName} on Windows startup"; GroupDescription: "Startup Options:"

[Files]
Source: "dist\SonarrSeedr\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\SonarrSeedr\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[InstallDelete]
; Clean up old marker file on reinstall
Type: files; Name: "{app}\.installed"

[UninstallDelete]
; Remove marker file on uninstall
Type: files; Name: "{app}\.installed"

[UninstallRun]
; Stop the application if running
Filename: "{cmd}"; Parameters: "/C taskkill /F /IM {#MyAppExeName} /T"; Flags: runhidden; RunOnceId: "StopApp"

[Code]
// Create marker file after installation to indicate this is an installed version
procedure CurStepChanged(CurStep: TSetupStep);
var
  MarkerFile: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Create .installed marker file
    MarkerFile := ExpandConstant('{app}\.installed');
    SaveStringToFile(MarkerFile, 'This file indicates the application was installed via installer.' + #13#10 + 'It tells the app to use AppData for data storage instead of the exe directory.' + #13#10, False);
  end;
end;

// Check if application is running before uninstall
function InitializeUninstall(): Boolean;
var
  ErrorCode: Integer;
begin
  if CheckForMutexes('{#MyAppName}') then
  begin
    if MsgBox('The application is currently running. Do you want to close it and continue uninstalling?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      Exec('taskkill.exe', '/F /IM {#MyAppExeName} /T', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
      Result := True;
    end
    else
      Result := False;
  end
  else
    Result := True;
end;

