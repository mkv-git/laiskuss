unit aMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ShellApi, Menus, Registry, StdCtrls, ComCtrls, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, structVault, ExtCtrls, IdAuthentication;

const
  NIF_INFO = $10;
  NIF_MESSAGE = 1;
  NIF_ICON = 2;
  NOTIFYICON_VERSION = 3;
  NIF_TIP = 4;
  NIM_SETVERSION = $00000004;
  NIM_SETFOCUS = $00000003;
  NIIF_INFO = $00000001;
  NIIF_WARNING = $00000002;
  NIIF_ERROR = $00000003;
  NIN_BALLOONSHOW = WM_USER + 2;
  NIN_BALLOONHIDE = WM_USER + 3;
  NIN_BALLOONTIMEOUT = WM_USER + 4;
  NIN_BALLOONUSERCLICK = WM_USER + 5;
  NIN_SELECT = WM_USER + 0;
  NINF_KEY = $1;
  NIN_KEYSELECT = NIN_SELECT or NINF_KEY;
  WM_ICONTRAY = WM_USER + $7258;


type
  PNewNotifyIconData = ^TNewNotifyIconData;
  TDummyUnion    = record
    case Integer of
      0: (uTimeout: UINT);
      1: (uVersion: UINT);
  end;

  TNewNotifyIconData = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
   //Version 5.0 is 128 chars, old ver is 64 chars
    szTip: array [0..127] of Char;
    dwState: DWORD; //Version 5.0
    dwStateMask: DWORD; //Version 5.0
    szInfo: array [0..255] of Char; //Version 5.0
    DummyUnion: TDummyUnion;
    szInfoTitle: array [0..63] of Char; //Version 5.0
    dwInfoFlags: DWORD;   //Version 5.0
  end;

type  
  SectKog = array of TSectKog;
  KonfKog = array of TKonfKog;
  MacrKog = array of TMacrKog;


{******************* DLL Functions ********************}

// Error handler
  function GetLastDllError: string; stdcall; external 'funcSet.dll';

// http päringute parsija
  function sulu_parser(sisend: string; otsing: string): string; stdcall; external 'funcSet.dll';

// sisselogitud kasutajanime päring
  function getKasutaja: string; stdcall; external 'funcSet.dll';

// serveriga autentimine
  procedure idendiKasutaja(var tulem: boolean; var siider: string; sendStat: boolean = False); stdcall; external 'funcSet.dll';

// statistika saatmine serverisse
	procedure getStatsData(sisend: TStrArr); stdcall; external 'funcSet.dll'; 
  
// kas sisend on number?
  function isInt(str: string): boolean; stdcall; external 'funcSet.dll';

// number <-> boolean 
  function IntToBool(sisend: byte): boolean; stdcall; external 'funcSet.dll';
  function BoolToInt(sisend: boolean): byte; stdcall; external 'funcSet.dll';

// faili suuruse teadasaamise funktsioon
  function findFileSize(filee: string): integer; stdcall; external 'funcSet.dll';

// string to Array
  function explode(sisend: string; delim: string): TStrArr; stdcall; external 'funcSet.dll';

// known folder location
  function getKnownPath(tyyp: ShortInt): string; stdcall; external 'funcSet.dll';

{***************** konfid ****************}
// sector handler
  function sectorLoad(kaust: string; var sectors: SectKog): boolean; stdcall; external 'funcSet.dll';
  function sectorSave(kaust: string; sectors: SectKog): boolean; stdcall; external 'funcSet.dll';

// konfi handler
  function konfLoad(kaust: string; var konfid: KonfKog): boolean; stdcall; external 'funcSet.dll';
  function konfSave(kaust: string; konfid: KonfKog): boolean; stdcall; external 'funcSet.dll';

// macrod handler
  function macroLoad(kaust: string; var macrod: MacrKog): boolean; stdcall; external 'funcSet.dll';
  function macroSave(kaust: string; macrod: MacrKog): boolean; stdcall; external 'funcSet.dll';

// unixTime functions
  function DateToUnix(aeg: TDateTime): LongWord; stdcall; external 'funcSet.dll';
  function UnixToDate(unix: LongWord): TDateTime; stdcall; external 'funcSet.dll';

// DLL Functions END


type
  TaHost = class(TForm)
    tiPM: TPopupMenu;
    pmClose: TMenuItem;
    pmTools: TMenuItem;
    pmTlOptions: TMenuItem;
    pmTlScripts: TMenuItem;
    pmTlIpTools: TMenuItem;
    pmAbout: TMenuItem;
    pmUpdates: TMenuItem;
    aHttp: TIdHTTP;
    aTcpc: TIdTCPClient;
    syncTimer: TTimer;
    N1: TMenuItem;
    Button1: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormHide(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
// TrayIcon menüü
    procedure pmCloseClick(Sender: TObject);
    procedure pmShowClick(Sender: TObject);
    procedure pmTlOptionsClick(Sender: TObject);
    procedure pmTlScriptsClick(Sender: TObject);
    procedure pmTlIpToolsClick(Sender: TObject);
    procedure pmUpdatesClick(Sender: TObject);
    procedure pmAboutClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure syncTimerTimer(Sender: TObject);
  private
    TrayData: TNewNotifyIconData;
    WM_TASKBARCREATED: DWORD;
    trayMsgIdx: SmallInt; // Tray Icon message onClick selector
    ssh_auth_data: TSshAuthData;
    returnOwner: HWND;
    procedure TMess(var Msg: TMessage); message WM_ICONTRAY;
    procedure showSysTrayMsg(sisu: string);
    procedure returnAuthData;
  public
// global Reg var
    dirPath   : string; // AppData location
    userPath  : string; // User directory
    logiPath  : string; // Logi directory
    picOrigPath
              : string; // MyPictures default location
    picSelectedPath
              : string; // Kasutaja enda poolt määratud piltide kausta asukoht
    brwPath   : string; // Default browser location
    lksVers   : string; // Laiskussi versioon
    lksPath   : string; // Laiskussi asukoht
    ussVers   : string; // Ussike versioon
    ussPath   : string; // Ussike asukoht
    accSid    : string; // logged user's objectSid

    termCol   : LongInt; // terminali värv
    termTxtCol: LongInt; // terminali teksti värv
    termFSize : LongInt; // terminali teksti suurus
    termFName : string; // terminal font

    lksDefClient
            : boolean; // is Laiskuss default telnet client
    cnfKonf : boolean; // Kinnitus konfi saatmisel
    termFB  : boolean; // Terminali tekst bold
    hkAllowed
            : boolean; // Hotkey kasutamise lubamine
    etUser	: string;
    pEtUser : PAnsiChar;
    connection_type_preference: Byte;
// end global Regvar

// global konf var
    sectors: SectKog;
    konfid: KonfKog;
    macrod: MacrKog; // array

// end global konf var

// elemendi väljalülitamine ja halliks muutmine
    procedure disGray(element: TEdit; seisund: boolean); overload;
    procedure disGray(element: TComboBox; seisund: boolean); overload;
    procedure disGray(element: TListView; seisund: boolean); overload;
// elemendi vl end
    procedure writeErrorLog(msg: string);

// Registry
    procedure loadSettings;
    procedure saveSettings;
    function isRegValid(reg: TRegistry; value: string; returnVal: string = ''): string; overload;
    function isRegValid(reg: TRegistry; value: string; returnVal: integer = 0): integer; overload;
    function isRegValid(reg: TRegistry; value: string; returnVal: boolean = False): boolean; overload;
    function isRegValid(reg: TRegistry; value: string; returnVal: TDateTime): TDateTime; overload;
    
  protected
  	procedure WMCopyData(var M: TMessage); message WM_COPYDATA;
    procedure WndProc(var Message : TMessage); override;
  end;

const
  ussVersioon   : string = '1.0.0.0';
  lksVersioon   : string = '2.0.0.0';
  ussErrorLog   : string = 'ussLogi.txt';
  LogDir        : string = 'lks_logi\';
  UserDir       : string = 'LaiskussF\';
  servAdre: string = 'http://laiskuss.elion.ee/';

var
  aHost: TaHost;
  gReg: TRegistry;
  ueFile: TextFile; // Ussike Error Logi file
  jubaKirjutatud, jubaOlemas: boolean;


implementation

uses aToolsOpt, aScriptDB, aSplashScreen, aInfoWnd;

{$R *.dfm}


procedure TaHost.FormCreate(Sender: TObject);
var
  sisseLogimine: boolean;
  iCnt: SmallInt;
begin
  idendiKasutaja(sisseLogimine, accSid);
  if (sisseLogimine = False) then
    begin
      if aSplash.Showing then
        begin
          aSplash.splashLabel.Font.Style:= aSplash.splashLabel.Font.Style + [fsBold];
          aSplash.splashLabel.Caption:= 'Access denied';
          aSplash.splashLabel.Hint:= GetLastDllError;
          iCnt:= 0;
          repeat
            aSplash.splashButton.Visible:= True;
            aSplash.splashButton.Caption:= 'Closing in ' + (IntToStr((100 - iCnt) div 10)) + '...';
            Application.ProcessMessages;
            inc(iCnt);
            sleep(100);
          until (iCnt > 90) OR (aSplash.splKinni);
        end
      else
        begin
          if (aSplash.olek = False) then
            Application.MessageBox('Access denied', 'Laiskuss annab teada', MB_ICONSTOP);
        end;
      PostQuitMessage(0);
    end;

  //firstRun:= True; // esmasel käivitamisel tuleb ette seadistusakn

  WM_TASKBARCREATED:= RegisterWindowMessage('TaskbarCreated');

  // Tray ikooni loomine
  TrayData.cbSize:= SizeOf(TrayData);
  TrayData.Wnd:= Handle;
  TrayData.uID:= 0;
  TrayData.uFlags:= NIF_MESSAGE + NIF_TIP + NIF_ICON;
  TrayData.uCallbackMessage:= WM_ICONTRAY;
  TrayData.hIcon:= Application.Icon.Handle;
  TrayData.szTip:= 'Laiskussi Agent';
  Shell_NotifyIcon(NIM_ADD, @TrayData);
  trayMsgIdx:= 0;
  LoadSettings;


// Logi dir kontroll
  if NOT DirectoryExists(userPath + LogDir) then
    try
      CreateDir(PAnsiChar(userPath + LogDir));
    except
      Application.MessageBox('Error on creating Log Folder ', 'Ussike annab teada', MB_ICONERROR);
    end;

// Error logi faili sätted
  jubaOlemas:= False; // kui Errorit ei ole veel kirjeldatud siis lisame faili headeri

// CRLF lisamine
  if (findFileSize(ussErrorLog) = -1) then
    jubaKirjutatud:= False
  else
    jubaKirjutatud:= True;

  AssignFile(ueFile, userPath + LogDir + UssErrorLog);
  if FileExists(userPath + LogDir + UssErrorLog) then
    Append(ueFile)
  else
    ReWrite(ueFile);
  aHttp.HandleRedirects:= True;
  SaveSettings;
  syncTimer.Interval:=  1 * (60 * 60)  * 1000; // x tundi ((60 minutit * 60 sekundit) ms)
  etUser:= getKasutaja;
  
  with ssh_auth_data do
    begin
      sshUsername:= '';
      sshPassword:= '';
      sshFailedLogin:= True;
    end;
end;

procedure TaHost.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_SHOW);
end;

procedure TaHost.FormHide(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TaHost.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    saveSettings;
  except
  end;
end;

procedure TaHost.FormDestroy(Sender: TObject);
begin
  try
    Shell_NotifyIcon(NIM_DELETE, @TrayData);
    CloseFile(ueFile);
  except
  end;
end;

// iga x (väärtus seatud formCreate's) tunni tagant kontrollitakse, kas on uus versioon saadaval, õigused,
// SKM sünkimine
procedure TaHost.syncTimerTimer(Sender: TObject);
var
  sisseLogimine, uus_vers: boolean;
begin
	try
  	idendiKasutaja(sisseLogimine, accSid, True);
    trayMsgIdx:= 0;
    uus_vers:= aInformant.checkVers(False);
    Sleep(500);
    aScrKog.syngiFailid(1);
    Sleep(300);
    aScrKog.syngiFailid(2);
    Sleep(300);
    aScrKog.syngiFailid(3);
    Sleep(500);
    if uus_vers then
      begin
        showSysTrayMsg('New version is available...');
        trayMsgIdx:= 1;
      end;
  except on E:Exception do
  	WriteErrorLog('Exception @ syncData: ' + E.Message);
  end;
end;

{*******************************************
              REGISTER PROCEDURES
*******************************************}

function TaHost.isRegValid(reg: TRegistry; value: string; returnVal: string = ''): string;
begin
  try
    if reg.ValueExists(value) then
      returnVal:= reg.ReadString(value);
  except on E:Exception do
    writeErrorLog('Error on reading "' + value + '" (str): ' + E.Message);
  end;
  Result:= returnVal;
end;

function TaHost.isRegValid(reg: TRegistry; value: string; returnVal: integer = 0): integer;
begin
  try
    if reg.ValueExists(value) then
      returnVal:= reg.ReadInteger(value);
  except on E:Exception do
    writeErrorLog('Error on reading "' + value + '" (int): ' + E.Message);
  end;
  Result:= returnVal;
end;

function TaHost.isRegValid(reg: TRegistry; value: string; returnVal: boolean = False): boolean;
begin
  try
    if reg.ValueExists(value) then
      returnVal:= reg.ReadBool(value);
  except on E:Exception do
    writeErrorLog('Error on reading "' + value + '" (bool): ' + E.Message);
  end;
  Result:= returnVal;
end;

function TaHost.isRegValid(reg: TRegistry; value: string; returnVal: TDateTime): TDateTime;
begin
  try
    if reg.ValueExists(value) then
      returnVal:= reg.ReadDateTime(value);
  except on E:Exception do
    writeErrorLog('Error on reading "' + value + '" (bool): ' + E.Message);
  end;
  Result:= returnVal;
end;

// Uss settings
procedure TaHost.loadSettings;
const
  IEPath: string = 'C:\Program Files\Internet Explorer\iexplore.exe';
var
  vastus: string;
begin
  gReg:= TRegistry.Create;
  dirPath:= '';
  userPath:= '';
  logiPath:= '';
  picOrigPath:= '';
  lksPath:='';
  vastus := '';
  lksDefClient:= False;
  cnfKonf:= False;
  connection_type_preference:= 0;
  
  try
    gReg.RootKey:= HKEY_CURRENT_USER;
    try
      dirPath:= getKnownPath(0); // appData
      userPath:= dirPath + '\' + UserDir;

      if NOT DirectoryExists(userPath) then
        try
          CreateDir(PAnsiChar(userPath));
        except
          Application.MessageBox('Error on creating User Folder', 'Ussike annab teada', MB_ICONERROR);
        end;

      picOrigPath:= getKnownPath(1); // MyPictures


// Laiskussi registri andmed
      if gReg.OpenKey('SOFTWARE\Laiskuss2', True) then
        begin
          if gReg.ValueExists('picLocation') then
            begin
              picSelectedPath:= gReg.ReadString('picLocation');
              if (Length(picSelectedPath) < 1) then
                picSelectedPath:= picOrigPath;
            end
          else
            picSelectedPath:= picOrigPath;

          if gReg.ValueExists('defBrowser') then
            begin
              brwPath:= gReg.ReadString('defBrowser');
              if (Length(brwpath) < 1) then
                brwPath:= IEPath;
            end
          else
            brwPath:= IEPath;

          // Laiskussi location
          lksPath:= ExtractFilePath(Application.ExeName);

          // Laiskussi versioon
          lksVers:= isRegValid(gReg, 'lksVers', lksVersioon);

          // pop-up confirmation on sending script
          cnfKonf:= isRegValid(gReg, 'confirmKonf', True);

          // is hotKeys allowed
          hkAllowed:= isRegValid(gReg, 'allowHotkeys', False);

          connection_type_preference:= isRegValid(gReg, 'default_connection_type', 0);
        end;
      gReg.CloseKey;
// End Laiskussi registri andmed

// Terminali andmed
      gReg.OpenKey('SOFTWARE\Laiskuss2\Term', True);
        // uTerm background color
        termCol:= isRegValid(gReg, 'termCol', 0);

        // uTerm text color
        termTxtCol:= isRegValid(gReg, 'termTxtCol', 12632256);

        // uTerm font name
        termFName:= isRegValid(gReg, 'termFName', 'Terminal');

        // uTerm font size
          termFSize:= isRegValid(gReg, 'termFSize', 10);

        // uTerm font bold or normal
          termFB:= isRegValid(gReg, 'termBold', False);

      gReg.CloseKey;
// End Terminali andmed

// Ussike registri andmed
      gReg.OpenKey('SOFTWARE\Laiskuss2\Ussike', True);
      ussVers:= isRegValid(gReg, 'ussVers', ussVersioon);
      ussPath:= isRegValid(gReg, 'ussPath', ExtractFilePath(Application.ExeName));
      gReg.CloseKey;
// End Ussike registri andmed

// Check if Laiskuss is default telnet client
      if gReg.OpenKey('Software\Classes\telnet\shell\open\command', False) then
        begin
          vastus:= gReg.ReadString('');
          if (vastus = (ussPath + 'Laiskuss.exe %1')) then
            begin
              lksDefClient:= True;
            end;
        end;
      gReg.CloseKey;
// End default checking

      ussPath:= ExtractFilePath(Application.ExeName);
      try
        gReg.OpenKey('SOFTWARE\Laiskuss2\Ussike', True);
        gReg.WriteString('ussVers', ussVersioon);
        gReg.WriteString('ussPath', ussPath);
        gReg.CloseKey;
      except on E:Exception do
        WriteErrorLog('Ussike registry: ' + E.Message);
      end;

    except on E:Exception do
      Application.MessageBox(PAnsiChar('Error @ loadReg'+#13#10 + E.Message), 'Ussike annab teada', MB_ICONERROR);
    end;
  finally
    gReg.Free;
  end;
end;
// end of loadSettings

procedure TaHost.saveSettings;
begin
  gReg:= TRegistry.Create;
  try
    gReg.RootKey:= HKEY_CURRENT_USER;
    try
    
      try
        gReg.OpenKey('SOFTWARE\Laiskuss2', True);
        gReg.WriteString('picLocation', picSelectedPath);
        gReg.WriteString('defBrowser', brwPath);
        gReg.WriteString('lksPath', lksPath);
        gReg.WriteBool('confirmKonf', cnfKonf);
        gReg.WriteBool('allowHotkeys', hkAllowed);
        gReg.WriteInteger('default_connection_type', connection_type_preference);
        gReg.CloseKey;
      except on E:Exception do
        WriteErrorLog('Laiskuss2 registry: ' + E.Message);
      end;

      try
        gReg.OpenKey('SOFTWARE\Laiskuss2\Term', True);
        gReg.WriteInteger('termCol', termCol);
        gReg.WriteInteger('termTxtCol', termTxtCol);
        gReg.WriteString('termFName', termFName);
        gReg.WriteInteger('termFSize', termFSize);
        gReg.WriteBool('termBold', termFB);
        gReg.CloseKey;
      except on E:Exception do
        WriteErrorLog('L2\Term registry: ' + E.Message);
      end;

    except
      Application.MessageBox('Error @ saveReg', 'Ussike annab teada', MB_ICONERROR);
    end;
  finally
    gReg.Free;
  end;
end;

procedure TaHost.disGray(element: TEdit; seisund: boolean);
begin
  if seisund then
    begin
      element.Enabled:= True;
      element.Color:= clWindow;
    end
  else
    begin
      element.Enabled:= False;
      element.Color:= clBtnFace;
    end;
end;

procedure TaHost.disGray(element: TComboBox; seisund: boolean);
begin
  if seisund then
    begin
      element.Enabled:= True;
      element.Color:= clWindow;
    end
  else
    begin
      element.Enabled:= False;
      element.Color:= clBtnFace;
    end;
end;

procedure TaHost.disGray(element: TListView; seisund: boolean);
begin
  if seisund then
    begin
      element.Enabled:= True;
      element.Color:= clWindow;
    end
  else
    begin
      element.Enabled:= False;
      element.Color:= clBtnFace;
    end;
end;

procedure TaHost.writeErrorLog(msg: string);
var
  td: TDateTime;
begin
  try
    td:= Now;
    if jubaOlemas = False then
      begin
        if jubaKirjutatud then
          WriteLn(ueFile, '');
        WriteLn(ueFile, '################## Error log for "Ussike" @ ' + DateTimeToStr(td) +
          ' ##################'+#13#10);
        WriteLn(ueFile, msg);
        jubaOlemas:= True;
        jubaKirjutatud:= False;
      end
    else
      WriteLn(ueFile, msg);
  except
    Application.MessageBox('Error on writing error', 'Ussike annab teada', MB_ICONERROR);
  end;
end;


{*****
   TrayIcon menüü
*****}

procedure TaHost.WndProc(var Message: TMessage);
begin
  if (Message.Msg = WM_TASKBARCREATED) then
    begin
      Shell_NotifyIcon(NIM_DELETE, @TrayData);
      Shell_NotifyIcon(NIM_ADD, @TrayData);
    end;
  inherited WndProc(Message);
end;

procedure TaHost.TMess(var Msg: TMessage);
var
  pt: TPoint;
begin
  case Msg.LParam of
    WM_LBUTTONDOWN:
      begin
      SetForegroundWindow(Handle);
      end;
    WM_LBUTTONDBLCLK:
      begin
        if NOT aScrKog.Showing then
          aScrKog.Show;
      end;
    WM_RBUTTONDOWN:
      begin
        SetForegroundWindow(Handle);
        GetCursorPos(pt);
        tiPM.Popup(pt.X, pt.Y);
        PostMessage (Handle, WM_NULL, 0, 0);   {!2.1.0.3}
      end;
    NIN_BALLOONUSERCLICK:
      begin
        if (trayMsgIdx = 1) then
          aInformant.updateSetup(True);
      end;
  end;
end;


procedure TaHost.showSysTrayMsg(sisu: string);
var
  tipInfo: string;
begin
  TrayData.cbSize:= SizeOf(TrayData);
  TrayData.uFlags:= NIF_INFO;
  tipInfo:= sisu;
  strPLCopy(TrayData.szInfo, tipInfo, SizeOf(TrayData.szInfo)-1);
  TrayData.DummyUnion.uTimeout:= 5000;
  TrayData.dwInfoFlags:= NIIF_INFO;
  Shell_NotifyIcon(NIM_MODIFY, @TrayData);
end;

{***************************************
  VERSIOONI VAHETUSED
***************************************}




{

 Tools aken :

 pmTlOptions - default valikud, hotkeyd, registry, GUI settings
 pmTlScripts - Sektorite, Skriptide ja Makrode seadistamise koht
 pmTlIpTools - ping, traceroute võimalused

}

procedure TaHost.pmTlOptionsClick(Sender: TObject);
begin
  if NOT aOptions.Showing then
    aOptions.Show;
end;

procedure TaHost.pmTlScriptsClick(Sender: TObject);
begin
  if NOT aScrKog.Showing then
    aScrKog.Show;
end;

procedure TaHost.pmTlIpToolsClick(Sender: TObject);
begin
//
end;


procedure TaHost.pmUpdatesClick(Sender: TObject);
begin
  //checkVers(True);
  aInformant.updateSetup;
end;

procedure TaHost.pmAboutClick(Sender: TObject);
begin
  aInformant.showAbout;
//  aHost.show;
end;

{*******************************************************************************
                                    MAX Speed
********************************************************************************}                                                                                              



procedure TaHost.WMCopyData(var M: TMessage);
var
	pAuthData: TSshAuthData;
begin
  try
    pAuthData:= PSshAuthData(PCopyDataStruct(M.LParam)^.lpData)^;
    returnOwner:= M.WParam;

    if (pAuthData.sshRequestData) then
      begin
        ssh_auth_data.sshRequestData:= False;
        returnAuthData;
      end
    else
      ssh_auth_data:= pAuthData;
  except
  end;

end;

procedure TaHost.returnAuthData;
var
  copyStruct: TCopyDataStruct;
begin
  try
    if ssh_auth_data.sshUsername = '' then
      ssh_auth_data.sshUsername:= etUser;
  except
  end;

  with copyStruct do
    begin
      dwData:= 0;
      cbData:= SizeOf(TSshAuthData);
      lpData:= @ssh_auth_data;
    end;
  SendMessage(returnOwner, WM_COPYDATA, Application.MainForm.Handle, LongInt(@copyStruct));
end;


                                   
{*******************************************************************************
                                    ///// TO DELETE !!!
********************************************************************************}                                                                                              

procedure TaHost.pmShowClick(Sender: TObject);
begin
  if NOT aHost.Showing then
      aHost.Show;
end;

procedure TaHost.pmCloseClick(Sender: TObject);
begin
  PostQuitMessage(0);
end;

end.
