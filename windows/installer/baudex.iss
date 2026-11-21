; Instalador de Baudex para Windows (Inno Setup 6).
; Lo usa .github/workflows/windows-instalador.yml. Se instala por usuario
; (no pide administrador). Los datos del negocio viven en Documentos, no en
; la carpeta del programa, así que reinstalar o actualizar no los borra.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

[Setup]
; AppId fijo: cada versión nueva reemplaza a la anterior.
AppId={{8C1F4E2A-6B3D-4A57-9E21-BA0DE5D35C11}
AppName=Baudex
AppVersion={#AppVersion}
AppPublisher=Baudity
DefaultDirName={localappdata}\Programs\Baudex
DefaultGroupName=Baudex
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=Baudex-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\Baudex.exe
CloseApplications=yes

[Languages]
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Baudex"; Filename: "{app}\Baudex.exe"
Name: "{autodesktop}\Baudex"; Filename: "{app}\Baudex.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Baudex.exe"; Description: "Abrir Baudex"; Flags: nowait postinstall skipifsilent
