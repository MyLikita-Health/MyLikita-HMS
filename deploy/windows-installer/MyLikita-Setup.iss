; ==============================================================================
;  MyLikita — Self-Contained Windows Offline Installer (Inno Setup 6)
; ------------------------------------------------------------------------------
;  Everything (Node.js, MySQL, NSSM, backend code, prebuilt node_modules,
;  frontend build, database dump) is embedded in the single setup .exe.
;
;  HOW TO COMPILE:
;    Run deploy\windows-installer\build-installer.bat on a Windows machine
;    with Inno Setup 6 installed. It assembles the bundle into dist\ and
;    invokes ISCC.exe on this script.
; ==============================================================================

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppName "MyLikita"
#define MyAppPublisher "MyLikita"
#define MyAppId "{{9F1B7C4A-2E5D-4C8B-9A3F-6D0E1B2A7C44}}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName} Hospital System
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName=C:\MyLikita
UsePreviousAppDir=yes
DisableProgramGroupPage=yes
DisableReadyPage=no
DisableFinishedPage=no
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=output
OutputBaseFilename=MyLikita-Setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
UninstallDisplayName={#MyAppName} Hospital System
Uninstallable=yes
CloseApplications=no
RestartApplications=no
; 46990 is the default app port the firewall rule opens; the post-install
; script may pick another port if 46990 is taken, and it opens its own rule.
AppComments=MyLikita hospital management system - offline deployment
SetupIconFile=mylikita.ico
; Branded wizard images - the small logo appears on every page (incl. the
; finished page where the CREDENTIALS.txt staff URLs are shown) and the
; banner on the Welcome/Finished pages. Copied into the bundle by
; build-installer.bat alongside mylikita.ico.
WizardImageFile=wizard-side.bmp
WizardSmallImageFile=wizard-small.bmp
UninstallDisplayIcon={app}\frontend\dist\icons\favicon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Icons]
; Desktop shortcut - opens MyLikita in a standalone app-style window
; (Edge/Chrome --app= mode) via the launcher, falling back to the default
; browser. Users never have to type or memorize http://localhost:46990/.
Name: "{autodesktop}\MyLikita Hospital System"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\scripts\launch-app.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\frontend\dist\icons\favicon.ico"; Comment: "Open MyLikita"

; Start Menu shortcuts
Name: "{autoprograms}\MyLikita Hospital System\MyLikita Hospital System"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\scripts\launch-app.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\frontend\dist\icons\favicon.ico"; Comment: "Open MyLikita in an app window"
Name: "{autoprograms}\MyLikita Hospital System\Open in Browser"; Filename: "http://localhost:46990/"; IconFilename: "{app}\frontend\dist\icons\favicon.ico"; Comment: "Open MyLikita in your default browser"
Name: "{autoprograms}\MyLikita Hospital System\Uninstall MyLikita"; Filename: "{uninstallexe}"; IconFilename: "{app}\frontend\dist\icons\favicon.ico"

[Files]
; Backend (includes prebuilt node_modules). Excluded: uploads (runtime data),
; logs, git metadata, and any .env the client may already have created.
Source: "backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".git,uploads,log,.env*,*.log"

; Pre-built React frontend (built with a server-IP placeholder that the
; post-install script replaces with the machine's LAN IP).
Source: "frontend\dist\*"; DestDir: "{app}\frontend\dist"; Flags: ignoreversion recursesubdirs createallsubdirs

; Embedded runtimes: Node.js, MySQL ZIP build, NSSM.
Source: "runtime\*"; DestDir: "{app}\runtime"; Flags: ignoreversion recursesubdirs createallsubdirs

; Installer helper scripts.
Source: "scripts\*"; DestDir: "{app}\scripts"; Flags: ignoreversion

; Database baseline dump.
Source: "database\prime-db.sql"; DestDir: "{app}\database"; Flags: ignoreversion

[Code]
{ ---------------------------------------------------------------------------- }
{  Runs the heavy post-install configuration (MySQL, DB import, services)      }
{  right after file extraction, hidden, with a status message on the wizard.   }
{  Fails visibly and points to the install log so support can diagnose.        }
{ ---------------------------------------------------------------------------- }

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  AppDir: String;
begin
  { Stop the MyLikita app and MySQL services BEFORE files are overwritten.
    On a reinstall (same version over an existing install) the app service
    holds backend\app.js / node_modules / .env open; overwriting them fails
    with a sharing violation and, in silent mode, the Abort-Retry-Ignore
    prompt auto-aborts the whole install (exit code 5). Stopping first makes
    reinstalls idempotent. MySQL keeps its data dir untouched - only the
    service is stopped, and postinstall restarts it. Best-effort: on a fresh
    install the services do not exist yet and the errors are ignored. }
  if CurStep = ssInstall then
  begin
    Exec(ExpandConstant('{cmd}'),
      '/c sc stop MyLikitaPrintAgent & sc stop MyLikita & sc stop MyLikitaMySQL & ping -n 4 127.0.0.1 >nul',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;

  if CurStep = ssPostInstall then
  begin
    AppDir := ExpandConstant('{app}');

    WizardForm.StatusLabel.Caption :=
      'Configuring MyLikita (MySQL, database, Windows services)...' + #13#10 +
      'This can take 5 to 15 minutes. Please do not close the installer.';

    if Exec(ExpandConstant('{cmd}'),
            '/c ""' + AppDir + '\scripts\postinstall.cmd" install"',
            AppDir, SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if ResultCode <> 0 then
      begin
        SuppressibleMsgBox(
          'MyLikita configuration finished with errors (exit code ' +
          IntToStr(ResultCode) + ').' + #13#10 + #13#10 +
          'The application files were installed, but MySQL / the database / ' +
          'the Windows service could not be fully set up.' + #13#10 + #13#10 +
          'Please open this log file and send it to support:' + #13#10 +
          AppDir + '\logs\install.log' + #13#10 + #13#10 +
          'You can retry later by running:' + #13#10 +
          AppDir + '\scripts\reconfigure.cmd  (as Administrator)',
          mbError, MB_OK, IDOK);
      end;
    end
    else
    begin
      SuppressibleMsgBox('Could not start the MyLikita configuration script.',
        mbError, MB_OK, IDOK);
    end;
  end;
end;

{ ---------------------------------------------------------------------------- }
{  Show a friendly summary on the final page, reading credentials written by   }
{  the post-install script.                                                    }
{ ---------------------------------------------------------------------------- }

procedure InitializeWizard;
begin
  WizardForm.FinishedLabel.AutoSize := False;
  WizardForm.FinishedLabel.WordWrap := True;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  AppDir, CredFile, Summary: String;
  F: TStrings;
  i: Integer;
begin
  if CurPageID = wpFinished then
  begin
    AppDir := ExpandConstant('{app}');
    CredFile := AppDir + '\CREDENTIALS.txt';
    if FileExists(CredFile) then
    begin
      Summary := 'MyLikita has been installed and configured.' + #13#10 + #13#10;
      F := TStringList.Create;
      try
        F.LoadFromFile(CredFile);
        for i := 0 to F.Count - 1 do
          Summary := Summary + F[i] + #13#10;
      finally
        F.Free;
      end;
      WizardForm.FinishedLabel.Caption := Summary;
    end;
  end;
end;

[UninstallRun]
Filename: "{cmd}"; Parameters: "/c ""{app}\scripts\uninstall.cmd"""; WorkingDir: "{app}"; Flags: runhidden waituntilterminated; StatusMsg: "Removing MyLikita services..."
