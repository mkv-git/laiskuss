unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OoMisc, ADTrmEmu, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdTelnet, StdCtrls, ExtCtrls, Menus, Registry, Buttons, WinInet,
  IdAntiFreezeBase, IdAntiFreeze, structVault, ShellApi, ComCtrls, uStatusClass,
  uAlqClass, uScriptClass, uMiscClass, StrUtils, AppEvnts, ClipBrd, ImgList, AdPort,
  tlntsend, ssl_openssl, ssl_openssl_lib, ssl_cryptlib, uLoginForm, aSplashScreen;


type
  SectKog = array of TSectKog;
  KonfKog = array of TKonfKog;
  MacrKog = array of TMacrKog;
  siteMgr = array of TSiteManager;
  smData  = array of TSmData;
  PingKog = array of TPingKog;
  TLiveLinkArray = record
    llAasta: string[10];
    llAdre : string[200];
  end;

{******************* DLL Functions ********************}

// Error handler
  function GetLastDllError: string; stdcall; external 'funcSet.dll';

// http päringute parsija
  function sulu_parser(sisend: string; otsing: string): string; stdcall; external 'funcSet.dll';

// serveriga autentimine
  procedure idendiKasutaja(var tulem: boolean; var siider: string); stdcall; external 'funcSet.dll';

// kas sisend on numnber?
  function isInt(str: string): boolean; stdcall; external 'funcSet.dll';

// number <-> boolean
  function IntToBool(sisend: byte): boolean; stdcall; external 'funcSet.dll';
  function BoolToInt(sisend: boolean): byte; stdcall; external 'funcSet.dll';

// stringi maskeerimine & demaskeerimine

  function encStr(inpt: string): string; stdcall; external 'funcSet.dll';
  function decStr(inpt: string): string; stdcall; external 'funcSet.dll';

// faili suuruse teadasaamise funktsioon
  function findFileSize(filee: string): integer; stdcall; external 'funcSet.dll';

// string to Array
  function explode(sisend: string; delim: string): TStrArr; stdcall; external 'funcSet.dll';

// known folder location
  function getKnownPath(tyyp: ShortInt): string; stdcall; external 'funcSet.dll';

{***************** konfid ****************}
// sector handler
  function sectorLoad(kaust: string; var sectors: SectKog): boolean; stdcall; external 'funcSet.dll';

// konfi handler
  function konfLoad(kaust: string; var konfid: KonfKog): boolean; stdcall; external 'funcSet.dll';

// macrod handler
  function macroLoad(kaust: string; var macrod: MacrKog): boolean; stdcall; external 'funcSet.dll';

// unixTime functions
  function DateToUnix(aeg: TDateTime): LongWord; stdcall; external 'funcSet.dll';
  function UnixToDate(unix: LongWord): TDateTime; stdcall; external 'funcSet.dll';



{*************** IP tools function **************}
// Error handler
  function GetLastIpError: string; stdcall; external 'ipTools.dll';

// DNS hostname resolver
  function dnsLookup(sisse: string; var vastus: string): boolean; stdcall; external 'ipTools.dll';

// pinger handler (uAlqClass)
  function pingLoad(kaust: string; var pingerid: PingKog): boolean; stdcall; external 'ipTools.dll';
  function pingSave(kaust: string; pingerid: PingKog): boolean; stdcall; external 'ipTools.dll';


// DLL Functions END


type
  TuHost2 = class(TForm)
    uTerm: TAdTerminal;
    VT100_Emul: TAdVT100Emulator;
    uHostLabel: TLabel;
    uPortLabel: TLabel;
    uLoginLabel: TLabel;
    uPortEdit: TEdit;
    uUserEdit: TEdit;
    uPassEdit: TEdit;
    uCtrl1: TBevel;
    uCtrl2: TBevel;
    uCon: TButton;
    autoCB: TCheckBox;
    cp_panel: TButton;
    macroPanel: TScrollBox;
    ppTerm: TPopupMenu;
    termCopyB: TMenuItem;
    termPasteB: TMenuItem;
    N1: TMenuItem;
    termMSB: TMenuItem;
    termPingerB: TMenuItem;
    IdAntiFreeze1: TIdAntiFreeze;
    uHostEdit: TEdit;
    quickConnectB: TBitBtn;
    ppQuickConnect: TPopupMenu;
    Clearhistory1: TMenuItem;
    N2: TMenuItem;
    siteManagerPM: TPopupMenu;
    tcpc2: TIdTCPClient;
    siteManagerB: TBitBtn;
    sitePresetB: TBitBtn;
    ExitB: TBitBtn;
    cpTpg: TPageControl;
    statusTab: TTabSheet;
    alqTab: TTabSheet;
    miscTab: TTabSheet;
    scriptTab: TTabSheet;
    ariTab: TTabSheet;
    cpPanel: TPanel;
    st_loadInfo: TStaticText;
    cpe_log: TButton;
    scr_editor: TButton;
    siteManagerTV: TTreeView;
    newSiteB: TButton;
    newGroupB: TButton;
    renameSiteB: TButton;
    deleteSiteB: TButton;
    Bevel1: TBevel;
    siteConB: TButton;
    siteCloseB: TButton;
    siteManagerP: TPanel;
    conInfoP: TPanel;
    conTypeLabel: TLabel;
    telnetRB: TRadioButton;
    serialRB: TRadioButton;
    smDescMemo: TMemo;
    smComDescLabel: TLabel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    smDescCnt: TLabel;
    smImageList: TImageList;
    siteSaveB: TButton;
    comPort: TApdComPort;
    selectTelnet: TRadioButton;
    selectSerial: TRadioButton;
    logPanel: TPanel;
    logText: TMemo;
    logCloseB: TButton;
    logCopyB: TButton;
    logRefreshB: TButton;
    select_connection_type_label: TLabel;
    livelinkLabel: TLabel;
    livelinkImage: TImage;
    multiPanel: TPanel;
    miButton: TButton;
    Bevel4: TBevel;
    uTelnet: TIdTelnet;
    ussiEvent: TApplicationEvents;
    estpak_tunnel_selector: TCheckBox;
    Button1: TButton;
    macroNaviUp: TSpeedButton;
    macroNaviDown: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure uConClick(Sender: TObject);
    procedure cp_panelClick(Sender: TObject);
    procedure uTermKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure uHostEditKeyPress(Sender: TObject; var Key: Char);
    procedure termCopyBClick(Sender: TObject);
    procedure termPasteBClick(Sender: TObject);
    procedure termMSBClick(Sender: TObject);
    procedure termPingerBClick(Sender: TObject);
    procedure Clearhistory1Click(Sender: TObject);
    procedure quickConnectBClick(Sender: TObject);
    procedure siteManagerBClick(Sender: TObject);
    procedure ExitBClick(Sender: TObject);
    procedure statusTabShow(Sender: TObject);
    procedure alqTabShow(Sender: TObject);
    procedure miscTabShow(Sender: TObject);
    procedure scriptTabShow(Sender: TObject);
    procedure ariTabShow(Sender: TObject);
    procedure ussiEventIdle(Sender: TObject; var Done: Boolean);
    procedure macroPanelMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure uTermMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure scr_editorClick(Sender: TObject);
    procedure one20TabShow(Sender: TObject);
    procedure uTermMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure uTermMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ppTermPopup(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure newSiteBClick(Sender: TObject);
    procedure newGroupBClick(Sender: TObject);
    procedure renameSiteBClick(Sender: TObject);
    procedure deleteSiteBClick(Sender: TObject);
    procedure siteConBClick(Sender: TObject);
    procedure siteCloseBClick(Sender: TObject);
    procedure siteManagerTVClick(Sender: TObject);
    procedure telnetRBClick(Sender: TObject);
    procedure serialRBClick(Sender: TObject);
    procedure smDescMemoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure siteSaveBClick(Sender: TObject);
    procedure siteManagerTVAddition(Sender: TObject; Node: TTreeNode);
    procedure siteManagerTVEdited(Sender: TObject; Node: TTreeNode;
      var S: String);
    procedure siteManagerTVEditing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure sitePresetBClick(Sender: TObject);
    procedure cpe_logClick(Sender: TObject);
    procedure logCloseBClick(Sender: TObject);
    procedure logCopyBClick(Sender: TObject);
    procedure logRefreshBClick(Sender: TObject);
    procedure siteManagerTVDblClick(Sender: TObject);
    procedure macroNaviUpClick(Sender: TObject);
    procedure macroNaviDownClick(Sender: TObject);
    procedure uTermDblClick(Sender: TObject);
    procedure macroNaviUpMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure macroNaviDownMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure uTermMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure livelinkLabelClick(Sender: TObject);
    procedure livelinkLabelMouseEnter(Sender: TObject);
    procedure livelinkLabelMouseLeave(Sender: TObject);
    procedure miButtonClick(Sender: TObject);
    procedure uTelnetDataAvailable(Sender: TIdTelnet;
      const Buffer: String);
    procedure on_tcp_ssh_connected(Sender: TObject);
    procedure uTelnetDisconnected(Sender: TObject);
    procedure selectSerialClick(Sender: TObject);
    procedure selectTelnetClick(Sender: TObject);
    procedure estpak_tunnel_selectorClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
// local Reg var
    gReg: TRegistry;
    lksVers   : string; // Laiskussi versioon
//    autoC     : boolean; // Laiskuss autoconnect
    checkCon  : boolean; // kontrollib kas tcp ühendus on aktiivne

    termCol   : LongInt; // terminali värv
    termTxtCol: LongInt; // terminali teksti värv
    termFName : string;  // terminali font
    termFSize : LongInt; // terminali teksti suurus
    terminal_character_height: integer;

    winLeft   : LongInt; // Laiskussi vasak
    winTop    : LongInt; // Laiskussi top
    winHeight : LongInt; // Laiskussi kõrgus
    autent		: TAuthSettings; // kasutaja õiguste record
    userLevel	: Word; // kasutaja lisaõiguste tase
    //accSid    : string; // logged user's objectSid
// end local Regvar

// general vars
    isTelnetOverSshOpen: boolean;
    is_com_port_open: boolean;
    isCpOpen: boolean; // kontrol paneeli olek
    isSmOpen: boolean; // Site manageri olek
    isLogOpen: boolean; // router log paneeli olek
    lhFile: file of TLoginHistory; // file for login quickhistory
    loginHistory: array of TLoginHistory; // dataset for login quickhistory
    // sisselogimise handler
    is_user_found: boolean;
    is_pswd_found: boolean;
    is_estpak_forwarded: boolean;
    loginType: byte;
    lisaIpList: array of TLabel;
    lisaIpImg: array of TImage;
// end general vars

// telnet/serial connection (Upper level) procedures
    tsLabel: array[0..5] of TLabel;  // created @ valmistaSites
    tsCombobox: array[0..5] of TCombobox; // created @ valmistaSites

// end telnet/serial procedures

// terminal vars
    globX   : array[0..1] of integer; // term selectori x coords
    globX2  : array[0..1] of integer;
    globY   : integer; // term selectori y coords
    valitud : string; // dblClick selected text result
    valitud2: string; // mouseSelect selected text result
    globVal : string;

// end of terminal vars

// macroPanel vars
    mcr_button: array of TButton;
    macroPanelExpanded: boolean;

// end macroPanel vars

// hotKeys vars
    hotkeys: array of THotKeys;
    hotKeyList: File of THotKeys; // Hotkeys's fail
    findHotKey: string; // onKeyUp Hotkey handler
    hkSisend: array[0..2] of string; // hotkey mappimine
// end hotKeys vars

// siteManager vars
    siteManager: siteMgr;
    siteFile  : File of TSiteManager;

    siteData: smData;
    siteDataFile: File of TSmData;

    smLabel: array[0..10] of TLabel;
    smEdit: array[0..3] of TEdit;
    smComboBox: array[0..6] of TComboBox;
    smActiveNode: SmallInt;
// end siteManager vars

// liveLink local vars
    liveLinkPanel: TPanel;
    liveLinkLabelArray: array[0..3] of TLabel;
// end of liveLing vars

// MISC vars
    benchmark_list: TStringList;
    benchmark_start: Cardinal;
    benchmark_last: Cardinal;

    procedure setup_default_visual_settings;
    function isRegValid(reg: TRegistry; value: string; returnVal: string = ''): string; overload;
    function isRegValid(reg: TRegistry; value: string; returnVal: integer = 0): integer; overload;
    function isRegValid(reg: TRegistry; value: string; returnVal: boolean = False): boolean; overload;
    procedure loadSettings; // load data from register
    procedure saveSettings; // sada data to register
    procedure recalculateHeights; // recalculate uterm height
    function VKtoChar(Key: Word): string; // Virtual key to Ascii
    function getVK_ID(VK_IDENT: Word): string; // Virtual key to Ascii v2
    procedure checkForAutoConnect;
    function generateObjId: integer;

// telnet/serial connection (Upper level) procedures
    procedure vahetaConnector(telnet_state: boolean = True);
    function validateIpAdre(var veaTeade: string): boolean;
    procedure write_inner_buffer(const Buffer: string);

// end telnet/serial procedures


// Login History
    procedure saveLoginHistory; // eelnevata logimise ajaloo salvestamine
    procedure populateLogin(loadFile: boolean = True); // populate popup menu
    procedure loadQCData(Sender: TObject); // popup menu click

// terminal handler
    procedure logiSisse(sisend: string = 'Waiting for trigger...');
    procedure forward_estpak_to_telnet(sisend: string = '');
    procedure tcp_ssh_connect;
    procedure tcp_ssh_disconnect;

    procedure tcp_connect;
    procedure tcp_disconnect;
    procedure ssh_connect;
    procedure ssh_disconnect;
    procedure disconnect_message(in_msg: string);

// MacroPanel procedures
    procedure drawMacros;
    procedure launchMacro(Sender: TObject);
    procedure checkNavi;

// Hotkeys procedures
    procedure loadHotkeys;
    function findCon(setVK_ID: string; var retContID: SmallInt): boolean; // find hotKey ID
    procedure activateHK(hkID: SmallInt);

// siteManager procedures
    procedure valmistaSites; // elementide loomine conInfoP paneeli jaoks
    procedure resetSiteManager;
    procedure loadSites;
    procedure loadSitesFromTV(clear: boolean = False);
    procedure telnetOrSerial(telnet: boolean);
    procedure smLoginType(Sender: TObject);
    procedure smLoginHandler(tyyp: SmallInt);
    procedure lockSiteElements(seisund: boolean);
    procedure onExitSmElement(Sender: TObject);
    procedure smConnect(Sender: TObject);
    function findMenuItem(vanem: TMenuItem; otsi: string): TMenuItem;
    procedure activSaveB(Sender: TObject);

// livelinkPanel procedures
    procedure llLabelMouseEnter(Sender: TObject);
    procedure llLabelMouseExit(Sender: TObject);
    procedure llLabelMouseClick(Sender: TObject);

// MISC procedures
    procedure mark_benchmark(in_time: Cardinal; func_address: string);
    procedure display_benchmark_result;
  public
// global Reg var
    dirPath   : string; // AppData location
    lksPath   : string; // Laiskussi asukoht
    userPath  : string; // User directory
    logiPath  : string; // Logi directory
    picOrigPath
              : string; // MyPictures default location
    picSelectedPath
              : string; // Kasutaja enda poolt määratud piltide kausta asukoht
    brwPath   : string; // Default browser location
    cnfKonf : boolean; // Kinnitus konfi saatmisel
    termFB  : boolean; // Terminali tekst bold
    hkAllowed
            : boolean; // Hotkey kasutamise lubamine
    default_connection_type: Byte;
// end global Regvar

// global var
    ssh_auth_data: TSshAuthData;
    connection_type: CONNECTION_TYPES;
    sectors: SectKog;
    konfid: KonfKog;
    macrod: MacrKog;
    pingerid: PingKog;
    clp: TClipBoard;
    timer1_cnt: SmallInt;
    acceptImg: string;
    cancelImg: string;
    rawLiveLinkAdre: string;
    liveLinkAdre: string;
    liveLinkArray: array of TLiveLinkArray;
    livelinkExists: boolean;
    is_query_finished: boolean;

// end global var

// TABID
    statusTs: TuStatusTS; // Status TAB class
    alqTs: TuAlqTS;       // Adv. LQ TAB class
    scrTs: TuScriptTS;    // Scripts TAB class
    miscTs: TuMiscTS;     // Misc TAB class
// end of TABID

    strArr: TStrArr; // array of string for explode funtcion

    hostAddress: string;
    dataBuffer: TStringList; // uTeln data kogumik - andmete parseldamiseks
    whereDoYouGo: Byte; // kas tcpc andmed lähevad uTerm'i või TStringList'i parseldamiseks
                        // 1 - uTerm (default), 2 - dataBuffer (TStringList)
    isDataGatheringOver: boolean; // kui andmeid parseldatakse siis andmed ei ole nähtaval uTerm's,
                                  // ilmuvad uuesti kui isDataGatheringOver = True
                                  // tingimus on tõene, kui püütakse kinni "#lks_lopp" string
    macFile: TextFile;
// status TAB'i global objects
    pNumber: string;
    pvcStr: string;
    profile: string;
    sp_id: string[10];
    isMacListed: boolean; // TSiteData's kontrollitakse eth bridge maclist käsklust

// elementide vabastamine
    procedure writeErrorLog(msg: string);
    procedure vabadus(elemendid: array of TPanel); overload;
    procedure vabadus(elemendid: array of TButton); overload;
    procedure vabadus(elemendid: array of TGroupBox); overload;
    procedure vabadus(elemendid: array of TLabel); overload;
    procedure vabadus(elemendid: array of TEdit); overload;
    procedure vabadus(elemendid: array of TCheckBox); overload;
    procedure vabadus(elemendid: array of TComboBox); overload;
    procedure vabadus(elemendid: array of TBitBtn); overload;
    procedure vabadus(elemendid: array of TMemo); overload;
    procedure vabadus(elemendid: array of TScrollBox); overload;
    procedure vabadus(elemendid: array of TRadioButton); overload;
    procedure vabadus(elemendid: array of TImage); overload;

// elemendi väljalülitamine ja halliks muutmine
    procedure disGray(element: TEdit; seisund: boolean); overload;
    procedure disGray(element: TComboBox; seisund: boolean); overload;
    procedure disGray(element: TListView; seisund: boolean); overload;
    procedure disGray(element: TMemo; seisund: boolean); overload;
// elemendi vl end
    function ExtrAddr(const telnet: string): string;
    procedure mainCaption(sisend: string = 'Waiting for trigger...');
    procedure haltOnRefresh(olek: boolean); // elementide disablemine data parsimise ajaks

// DATA parsijad
    procedure WaitForData(going: boolean);
    function VordusMark(sisend: string): string;
    function Koolon(sisend: string): string;
    procedure Explode2(sisend: string; delim: string; var blokk: TStrArr);
    function isMacValid(sisend: string; var vastus: string): boolean;
    function searchForMac(sisend: string; var vastus: string): boolean;
    function isIPValid(sisend: string; var addr: string): boolean;
    function getHttpData(aUrl: string): string;
    procedure getDataFromServer;
    function fetchIpFromSnr(sisend: string; var addr: string): boolean;
// multiPanel object handlers
    procedure launchLaiskuss(Sender: TObject);
    procedure miLabelMouseEnter(Sender: TObject);
    procedure miLabelMouseExit(Sender: TObject);

// MAX Speed spy
		procedure RequestLoginData;

// Telnet/SSH procedure
    function is_connection_alive(test_for_ssh_only: boolean = False): boolean;
    procedure write_to_terminal(in_val: string; receiver_id: byte = 1);
    procedure writeLn_to_terminal(in_val: string; receiver_id: byte = 1);
	protected
  	procedure WMCopyData(var M: TMessage); message WM_COPYDATA;
  end;

  TuLiveLink = class(TThread)
    private
    public
      constructor Create(CreateSuspended: boolean);
    protected
      procedure Execute; override;
  end;

  TSshIoHandler = class(TThread)
    public
      constructor Create(CreateSuspended: boolean);
    private
      Msg: string;
      procedure HandleMessages;
      procedure Stop;
    protected
      procedure Execute; override;
  end;

var
  uHost2: TuHost2;
  uLiveLink: TuLiveLink;
  ssh_client: TTelnetSend;
  sshIoHandler: TSshIoHandler;
  leFile: TextFile; // Laiskuss Error Log file
  laFile: TextFile; // Laiskuss Action Log file
  jubaKirjutatud, jubaOlemas: boolean; // ErrorLog handlers
  laIsWritten, laIsExist: boolean; // ActionLog handlers

const
  lksVersioon   : string = '2.2.1.2'; // Laiskussi versioon
  lksErrorLog   : string = 'laiskussLogi.txt'; // Laiskuss Error Log file
  lksActionLog  : string = 'actionLog.txt'; // Laiskuss Action Log file
  LogDir        : string = 'lks_logi\'; // Logi folder
  UserDir       : string = 'LaiskussF\'; // AppData's Laiskuss folder
  loginFile     : string = 'lHistory.l2f'; // loginHistory file
  hkFile        : string = 'hkList.l2f'; // hotKey file
  smFile        : string = 'smList.l2f'; // siteManager file
  smDFile       : string = 'smData.l2f'; // siteManager data file
  TELNET_ESTPAK : string = '80.235.8.166';
  SSH_PORT      : string = '22';

// objects caption
  FC = ' - Laiskuss ';
  STATUS = 'Waiting for trigger...';
  CN = '&Connect';
  CNING = 'Cancel';
  DN = '&Disconnect';

implementation

uses uScrEditor, uInfoWnd;

{$R *.dfm}

constructor TuLiveLink.Create(CreateSuspended: boolean);
begin
  FreeOnTerminate := True;
  inherited Create(CreateSuspended);
end;

procedure TuLiveLink.Execute;
begin
  uHost2.livelinkExists  := uHost2.alqTS.checkForLivelink;
end;

constructor TSshIoHandler.Create(CreateSuspended: boolean);
begin
  FreeOnTerminate := True;
  inherited Create(CreateSuspended);
end;

procedure TSshIoHandler.Stop;
begin
  Suspend;
  Msg:= '';
end;

procedure TSshIoHandler.Execute;
begin
  while Not Suspended do
    begin
      if ssh_client.Sock.CanRead(10) or (ssh_client.Sock.WaitingData > 0) then
        begin
          Msg:= ssh_client.Sock.RecvPacket(10);
          uHost2.write_inner_buffer(Msg);
          Synchronize(HandleMessages);
        end;
    end;
end;

procedure TSshIoHandler.HandleMessages;
begin
  if uHost2.whereDoYouGo = 1 then
    uHost2.uTerm.WriteString(Msg);
end;

procedure TuHost2.mark_benchmark(in_time: Cardinal; func_address: string);
begin
  benchmark_last:= GetTickCount;
  benchmark_list.Add(func_address + ': ' + IntToStr(benchmark_last - in_time));
end;

procedure TuHost2.display_benchmark_result;
begin
  if not uScriptEditor.Showing then
    uScriptEditor.Show;

  uScriptEditor.scrText.Text:= benchmark_list.Text;
  uScriptEditor.scrText.Lines.Add(IntToStr(benchmark_last - benchmark_start));
end;

procedure TuHost2.FormCreate(Sender: TObject);
var
  ussike: HWND;
  ussi_olek: array[0..1024] of char;
  sisseLogimine: boolean;
  iCnt: SmallInt;
begin
  benchmark_list:= TStringList.Create;
  benchmark_start:= GetTickCount;
  mark_benchmark(benchmark_start, 'formCreate start');

  sisseLogimine:= False;
  ussike:= FindWindow('TaHost', 'valmis');
  if (ussike <> 0) then
    begin
      SendMessage(ussike, WM_GETTEXT, sizeof(ussi_olek), integer(@ussi_olek));
      if (strPas(ussi_olek) = 'valmis') then
        begin
          sisseLogimine:= True;
        end;
    end;

  if (sisseLogimine = False) then
    begin
      if aSplash.Showing then
        begin
          aSplash.splashLabel.Font.Style:= aSplash.splashLabel.Font.Style + [fsBold];
          aSplash.splashLabel.Caption:= 'Accesss denied';
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
        Application.MessageBox('Access denied', 'Laiskuss annab teada', MB_ICONSTOP);
      PostQuitMessage(0);
    end;
  mark_benchmark(benchmark_start, 'authenication ended');

  // Authenication data for SSH connection
  ssh_auth_data.sshUsername:= '';
  ssh_auth_data.sshPassword:= '';
  ssh_auth_data.sshFailedLogin:= True;
  ssh_auth_data.sshRequestData:= True;

// INIT SSH
  ssh_client:= TTelnetSend.Create;
  connection_type:= CONNECTION_TYPES(default_connection_type);

  mark_benchmark(benchmark_start, 'init ssh');
// Load register
  loadSettings;
    mark_benchmark(benchmark_start, 'load_settings');

// Fail loader
  sectorLoad(userPath, sectors);
  konfLoad(userPath, konfid);
  macroLoad(userPath, macrod);
  pingLoad(userPath, pingerid);
  mark_benchmark(benchmark_start, 'file loader');

  mainCaption(STATUS);
  uHost2.Constraints.MaxWidth:= 902;
  uHost2.Constraints.MinWidth:= 902;
  uHost2.Constraints.MaxHeight:= Screen.Height -50;
  uHost2.Constraints.MinHeight:= 700;
  KeyPreview:= True;
  uCon.Caption:= CN;
  uHost2.Top:= winTop;
  uHost2.Left:= winLeft;
  uHost2.Height:= winHeight;
  mark_benchmark(benchmark_start, 'pre_default settings');

  dataBuffer:= TStringList.Create;
  is_com_port_open:= False;
  isCpOpen:= False;
  isSmOpen:= False;
  isLogOpen:= False;
  isMacListed:= False;

  jubaOlemas:= False;
  is_user_found:= False;
  is_pswd_found:= False;
  is_estpak_forwarded:= False;
  whereDoYouGo:= 1; // tcpc data to uTerm
  loginType:= 0;
  isDataGatheringOver:= True;

  globX[0]:= -2;
  globX[1]:= -2;
  globY:= -2;

  if NOT DirectoryExists(userPath + LogDir) then
    try
      CreateDir(PAnsiChar(userPath + LogDir));
    except
      Application.MessageBox('Error on creating Log Folder ', 'Ussike annab teada', MB_ICONERROR);
    end;

  mark_benchmark(benchmark_start, 'pos_default settings');

// Error logi faili sätted
  jubaOlemas:= False; // kui Errorit ei ole veel kirjeldatud siis lisame faili headeri

// eL CRLF lisamine
  if (findFileSize(userPath + LogDir + lksErrorLog) = -1) then
    jubaKirjutatud:= False
  else
    jubaKirjutatud:= True;

// Action logi faili sätted
  laIsExist:= False; // kui Errorit ei ole veel kirjeldatud siis lisame faili headeri

// aL CRLF lisamine
  if (findFileSize(userPath + LogDir + lksActionLog) = -1) then
    laIsWritten:= False
  else
    laIsWritten:= True;

  mark_benchmark(benchmark_start, 'pre_control_panel init');
  statusTs:= TuStatusTS.Create;
  alqTs:= TuAlqTS.Create;
  scrTs:= TuScriptTS.Create;
  miscTs:= TuMiscTS.Create;
  mark_benchmark(benchmark_start, 'post_control_panel init');

  clp:= TClipBoard.Create;
  valmistaSites; // siteManager elementide valmistamine
  saveSettings;
  mark_benchmark(benchmark_start, 'savesettings');

  try
	  acceptImg:= ExtractFilePath(Application.ExeName) + 'dat\acceptB.ico';
  	cancelImg:= ExtractFilePath(Application.ExeName) + 'dat\cancelB.ico';
  except on E:Exception do
  end;
	//SetForegroundWindow(Handle);
  mark_benchmark(benchmark_start, 'form_create end');
end;

// Laiskuss startUp
procedure TuHost2.FormShow(Sender: TObject);
var
  i: SmallInt;
begin
  mark_benchmark(benchmark_start, 'formShow start');
  setup_default_visual_settings;

// Login history data
  populateLogin;

// hotKey data
  loadHotkeys;

// siteManager data
  loadSites;
  loadSitesFromTv;

  mark_benchmark(benchmark_start, 'loadSites finished');
// MAC aadressite kogumik
  if (FileExists(ExtractFilePath(Application.ExeName) + 'dat\macDB.ldbf')) then
    begin
      AssignFile(macFile, ExtractFilePath(Application.ExeName) + 'dat\macDB.ldbf');
      Reset(macFile);
    end
  else
    Application.MessageBox('Error: macDB.ldbf file not found!',
      'Laiskuss annab teada', MB_ICONERROR);
  mark_benchmark(benchmark_start, 'macList load finished');
  siteManagerP.Top:= uTerm.Top;
  siteManagerP.Visible:= False;
  conInfoP.Visible:= False;
  logPanel.Top:= uTerm.Top;
  logPanel.Left:= uHost2.ClientWidth - logPanel.Width;
  logPanel.Visible:= False;

  multiPanel.Top:= uTerm.Top;
  mark_benchmark(benchmark_start, 'cp_panel load started');
  cp_panel.Click;
  mark_benchmark(benchmark_start, 'cp_panel load finished');
  case default_connection_type of
    0: selectTelnet.Checked:= True;
    1:
      begin
        selectTelnet.Checked:= True;
        estpak_tunnel_selector.Checked:= True;
      end;
    2:
      begin
        selectSerial.Checked:= True;
      end;
    end;

  mark_benchmark(benchmark_start, 'requestLoginData start');
  RequestLoginData;
  mark_benchmark(benchmark_start, 'requestLoginData end');
  if (ParamCount > 0) then
    begin
      uHostEdit.Text:= ExtrAddr(ParamStr(1));
      checkForAutoConnect;
    end;
  macroPanel.Height:= 26;
  checkNavi;

// liveLink panel preparations
  try
    livelinkPanel:= TPanel.Create(Self);
    with livelinkPanel do
      begin
        Parent:= uHost2;
        Top:= liveLinkLabel.Top + liveLinkLabel.Height + 7;
        Left:= liveLinkLabel.Left - 2;
        Height:= 0;
        Width:= 75;
        Color:= $00E6DAD0;
        Visible:= False;
      end;

    for i:= 0 to High(liveLinkLabelArray) do
      begin
        liveLinkLabelArray[i]:= TLabel.Create(Self);
        with liveLinkLabelArray[i] do
          begin
            Parent:= liveLinkPanel;
            AutoSize:= False;
            Layout:= tlCenter;
            Alignment:= taCenter;
            ShowHint:= True;
            Height:= 21;
            Width:= 65;
            Top:= (Height + 2) * i + 3;
            Left:= 5;
            Color:= $00E4E4E4;
            Visible:= False;
            OnMouseEnter:= llLabelMouseEnter;
            OnMouseLeave:= llLabelMouseExit;
            OnClick:= llLabelMouseClick;
          end;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Exception @ livelinkPanel creation: ' + E.Message);
  end;
  mark_benchmark(benchmark_start, 'formShow end');
end;

procedure TuHost2.setup_default_visual_settings;
begin
  VT100_Emul.ANSIMode:= True;
  VT100_Emul.AppKeyMode:= True;
  uTerm.Color:= termCol;
  uTerm.Emulator.Buffer.ColCount:= 108;
  uTerm.Emulator.Buffer.DefBackColor:= termCol;
  uTerm.Emulator.Buffer.BackColor:= termCol;
  uTerm.Emulator.Buffer.DefForeColor:= termTxtCol;
  uTerm.Emulator.Buffer.ForeColor:= termTxtCol;
  try
    uTerm.Font.Name:= termFName;
  except
      uTerm.Font.Name:= 'Terminal';
  end;
  uTerm.Font.Size:= termFSize;
  uTerm.Width:= uHost2.ClientWidth;

  if (termFB) then
    uTerm.Font.Style:= uTerm.Font.Style + [fsBold];

  macroPanel.Width:= uHost2.Width - 50;
  cpPanel.Width:= uHost2.ClientWidth;
  st_loadInfo.Left:= cpTpg.Width - st_loadInfo.Width + 1;

// macroPanel seadistus
  macroPanel.VertScrollBar.Visible:= False;
  macroPanel.HorzScrollBar.Visible:= False;
  drawMacros;  
end;

procedure TuHost2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  saveSettings;
  try
    if is_connection_alive then
      tcp_ssh_disconnect;
  except
    PostQuitMessage(0);
  end;

  if (multiPanel.Visible) then
  	miButton.Click;
end;

procedure TuHost2.FormDestroy(Sender: TObject);
begin
  try
    vabadus(tsLabel);
    vabadus(tsCombobox);
    vabadus(smLabel);
    vabadus(smEdit);
    vabadus(smComboBox);
    clp.Free;
    vabadus(mcr_button);
    CloseFile(macFile);
    dataBuffer.Free;
    statusTs.Destroy;
    alqTs.Destroy;
    scrTs.Destroy;
    miscTs.Destroy;
    benchmark_list.Free;
  except
  end;
end;

procedure TuHost2.FormResize(Sender: TObject);
begin
  if uHost2.Showing then
    recalculateHeights;
end;

{
 Hotkey handler, klahvi vajutamisel paigaldatakse ID record'i
 ja siis võrreldakse määratud funktsioonide ID'ga (onKeyUp)

}
procedure TuHost2.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  iKey: string;
  i   : LongInt;
begin
  if hkAllowed then
    begin
      findHotKey:= '';
      for i:= 0 to 2 do
        hkSisend[i]:= '';
      iKey:= getVK_ID(key); // Translate keycode to Ascii

    // hkSisend[0] = Ctrl või Shift, Ctrl on primaarne
    // hkSisend[1] = Shift või Alt, Shift on primaarne
    // hkSisend[2] = kõik muud sisendid v.a. Ctrl, Shift ja Alt

      if ssCtrl in Shift then
        begin
          if (Length(hkSisend[0]) = 0) then
            hkSisend[0]:= 'Ctrl'
          else
            begin
              if (hkSisend[0] = 'Shift') then
                begin
                  hkSisend[1]:= 'Shift';
                  hkSisend[0]:= 'Ctrl';
                end
              else if (hkSisend[0] = 'Alt') then
                begin
                  hkSisend[1]:= 'Alt';
                  hkSisend[0]:= 'Ctrl';
                end;
            end;
        end;
      if ssShift in Shift then
        begin
          if (Length(hkSisend[0]) = 0) then
            hkSisend[0]:= 'Shift'
          else
            begin
              if (hkSisend[0] = 'Ctrl') then
                begin
                    hkSisend[1]:= 'Shift';
                  hkSisend[0]:= 'Ctrl';
                end
              else if (hkSisend[1] = 'Alt') then
                begin
                  hkSisend[1]:= 'Alt';
                  hkSisend[0]:= 'Shift';
                end;
            end;
        end;
      if ssAlt in Shift then
        begin
          if (Length(hkSisend[1]) = 0) then
            hkSisend[1]:= 'Alt'
          else
            begin
              if (hkSisend[1] = 'Shift') then
                hkSisend[0]:= 'Shift';
                hkSisend[1]:= 'Alt';
            end;
        end;

      if (iKey <> 'Ctrl') AND (iKey <> 'Shift') AND (iKey <> 'Alt') then
        hkSisend[2]:= iKey;

      for i:= 0 to 2 do
        begin
          if (Length(hkSisend[i]) > 0) then
            begin
              if (Length(findHotKey) = 0) then
                findHotKey:= hkSisend[i]
              else
                findHotKey:= findHotKey + ' + ' + hkSisend[i];
            end; // Length > 0
        end; // for i loop
  end;
end;

procedure TuHost2.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i, tulem: SmallInt;
begin
  if (hkAllowed) then
    begin
    // Kui hkSisend[2] ehk ükskõik mis sümbol, v.a. Ctrl, Shift ja Alt on olemas
    // siis hotkey aktiveeritakse
      tulem:= -1;
      if (hkSisend[2] <> '') then
        if findCon(findHotKey, tulem) then
          activateHK(tulem);
    end;

// Alt ja F10 FIX "form change" vastu
  if (Key = 18) OR (Key = 121) then Key:= 0;

// tühjendame puhvri (alt + tab vajutamine tekitab konflikti {korduv hotkey'i sisestamine} !!!)
  for i:= 0 to Length(hkSisend)-1 do
    hkSisend[i]:= '';
  findHotKey:= '';
end;

procedure TuHost2.ExitBClick(Sender: TObject);
begin
  if is_connection_alive then
    try
      tcp_ssh_disconnect;
    except on E:Exception do
      begin
        Application.ProcessMessages;
        WriteErrorLog('Error on exit: ' + E.Message);
      end;
    end;
  Application.ProcessMessages;
  Close;
  Application.ProcessMessages;
end;

procedure TuHost2.ussiEventIdle(Sender: TObject; var Done: Boolean);
var
  ctrl: TWinControl;
begin
  if ((NOT uScriptEditor.Showing) AND (NOT uScriptEditor.Active)) AND (uHost2.Active) then
    if (NOT isSmOpen) AND (NOT isLogOpen) then
    begin
      ctrl:= FindVCLWindow(Mouse.CursorPos);
      if (ctrl <> nil) then
        begin
          if (ctrl.ClassType = TScrollBox) then
            begin
              if ctrl.CanFocus AND (NOT ctrl.Focused) then
                try
                  ctrl.SetFocus;
                except on E:Exception do
                  writeErrorLog('Error @ focusing ctrl: ' + E.Message);
                end;
            end // TScrollBox
          else if (ctrl.ClassType = TBitBtn) then
            begin
              if ctrl.CanFocus AND (NOT ctrl.Focused) then
                try
                  ctrl.SetFocus;
                except on E:Exception do
                  writeErrorLog('Error @ focusing TBitBtn: ' + E.Message);
                end;
            end // TBitBtn
          else if (ctrl.ClassType = TGroupBox) then
            begin
              if (ctrl.Controls[0].ClassType = TScrollBox) then
                try
                  if (TWinControl(ctrl.Controls[0]).CanFocus) then
                    TWinControl(ctrl.Controls[0]).SetFocus; // scripts Tab'i jaoks
                except on E:Exception do
                  writeErrorLog('Error @ focusing TWinControl(ctrl.Controls[0]): ' + E.Message);
                end;
            end // TGroupBox
          else if (ctrl.ClassType = TAdTerminal) then
            try
              if is_connection_alive AND ctrl.CanFocus AND (NOT ctrl.Focused) then
                try
                  if TAdTerminal(ctrl).Active then
                  	if is_connection_alive then
	                    ctrl.SetFocus;
                except
                end;
            except on E:Exception do
              writeErrorLog('Error @ focusing uTerm: ' + E.Message);
            end;
        end; // ctrl <> nil
    end;
end;

// end form main procedures


// Laiskussi exceptionite salvestamisne
// kirja pannakse, aeg, versioon, ruuter (mudel + soft) ja ip aadress:port
procedure TuHost2.writeErrorLog(msg: string);
var
  td: TDateTime;
  seade: string;
begin
  try
    AssignFile(leFile, userPath + LogDir  + lksErrorLog);
    if FileExists(userPath + LogDir + lksErrorLog) then
      Append(leFile)
    else
      ReWrite(leFile);
    td:= Now;
    if jubaOlemas = False then
      begin
        if jubaKirjutatud then
          WriteLn(leFile, '');
        WriteLn(leFile, '################## Error log for Laiskuss v'+ lksVersioon +
          ' @ ' + DateTimeToStr(td) + ' ##################');
        if (statusTs.router_type <> '') then
          seade:= #13#10 + 'Router type: ' + statusTs.router_type
        else
          seade:= ' Router type: N/A';

        if (statusTs.soft_version <> '') then
          seade:= seade + ', soft vers: ' + statusTs.soft_version;

        WriteLn(leFile, 'host address: ' + uHostEdit.Text + ':' + uPortEdit.Text + seade);
        WriteLn(leFile, msg);
        jubaOlemas:= True;
        jubaKirjutatud:= False;
      end
    else
      WriteLn(leFile, msg);
    CloseFile(leFile);
  except
    Application.MessageBox('Error on writing error', 'Ussike annab teada', MB_ICONERROR);
  end;
end;

procedure TuHost2.vabadus(elemendid: array of TPanel);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing panels: ' + E.Message);
  end;
//  messagebox(getdesktopwindow, 'freeing Panel', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TButton);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing buttons: ' + E.Message);
  end;
//  messagebox(getdesktopwindow, 'freeing Button', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TGroupBox);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing groupbox: ' + E.Message);
  end;
//messagebox(getdesktopwindow, 'freeing groupbox', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TLabel);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing labels: ' + E.Message);
  end;
  //messagebox(getdesktopwindow, 'freeing labels', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TEdit);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing edits: ' + E.Message);
  end;
  //messagebox(getdesktopwindow, 'freeing edits', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TCheckBox);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing checkbox: ' + E.Message);
  end;
  //messagebox(getdesktopwindow, 'freeing edits', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TComboBox);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing ComboBox: ' + E.Message);
  end;
  //messagebox(getdesktopwindow, 'freeing edits', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TBitBtn);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing bitbnt: ' + E.Message);
  end;
  //messagebox(getdesktopwindow, 'freeing edits', '', 0);
end;

procedure TuHost2.vabadus(elemendid: array of TMemo);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing Memo: ' + E.Message);
  end;
//  messagebox(getdesktopwindow, 'freeing TMemo', '', 0);
end;

procedure Tuhost2.vabadus(elemendid: array of TScrollBox);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing ScrollBox: ' + E.Message);
  end;
//  messagebox(getdesktopwindow, 'freeing ScrollBox', '', 0);
end;


procedure Tuhost2.vabadus(elemendid: array of TRadioButton);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
        elemendid[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing RadioButton: ' + E.Message);
  end;
end;


procedure TuHost2.vabadus(elemendid: array of TImage);
var
  i: SmallInt;
begin
  try
    for i:= Low(elemendid) to High(elemendid) do
      begin
        elemendid[i].Free;
      	elemendid[i]:= nil;           
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing Image: ' + E.Message);
  end;
end;

/////////////// END OF VABADUS ELEMENTIDELE



procedure TuHost2.disGray(element: TEdit; seisund: boolean);
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

procedure TuHost2.disGray(element: TComboBox; seisund: boolean);
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

procedure TuHost2.disGray(element: TListView; seisund: boolean);
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

procedure TuHost2.disGray(element: TMemo; seisund: boolean);
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

// telneti aadressi puhastamine - jäetakse ainult numbrid ja '.'
function TuHost2.ExtrAddr(const telnet: string): string;
var
  aadress: string;
  temp: string;
begin
  temp:= AnsiReplaceStr(telnet, '/', '');
  aadress:= Copy(temp, AnsiPos('telnet:', temp) + 7, MaxInt);
  Result:= aadress;
end;

procedure TuHost2.mainCaption(sisend: string = 'Waiting for trigger...');
begin
  uHost2.Caption:= sisend + FC + lksVersioon;
end;

procedure TuHost2.haltOnRefresh(olek: boolean);
begin
  uTerm.Active:= olek;
  uTerm.Enabled:= olek;
  macroPanel.Enabled:= olek;
  statusTS.statusUpdate(olek);
  alqTS.alqUpdate(olek);
  miscTS.miscUpdate(olek);
  scriptTab.Enabled:= olek;
  ariTab.Enabled:= olek;
end;

{*******************************************************************************
                                    LIVELINK
********************************************************************************}

procedure TuHost2.livelinkLabelClick(Sender: TObject);
var
  llCnt, i: SmallInt;
begin
  if (livelinkLabel.Caption = 'Connect to Livelink') then
    begin
      try
        uLiveLink.Resume;
      except on E:Exception do
        WriteErrorLog('Exception @ connecting to Livelink: ' + E.Message);
      end;
    end
  else
    try
      llCnt:= Length(liveLinkArray);
      if (llCnt = 1) then
        ShellExecute(0, PAnsiChar('open'), PAnsiChar(livelinkAdre), nil, nil, SW_SHOWNORMAL)
      else if (llCnt > 1) then
        begin
          if (liveLinkPanel.Showing) then
            liveLinkPanel.Visible:= False
          else
            begin
              liveLinkPanel.Visible:= True;
              liveLinkPanel.Height:= llCnt * 25 + 1;
              for i:= 0 to llCnt-1 do
                begin
                  liveLinkLabelArray[i].Caption:= liveLinkArray[i].llAasta;
                  liveLinkLabelArray[i].Hint:= liveLinkArray[i].llAdre;
                  liveLinkLabelArray[i].Visible:= True;
                end;
            end;
        end;
    except on E:Exception do
      WriteErrorLog('Exception @ opening livelink (label): ' + E.Message);
    end;
end;

procedure TuHost2.livelinkLabelMouseEnter(Sender: TObject);
begin
	Cursor:= crHandPoint;
  livelinkLabel.Font.Style:= livelinkLabel.Font.Style + [fsUnderline];
end;

procedure TuHost2.livelinkLabelMouseLeave(Sender: TObject);
begin
	Cursor:= crDefault;
  livelinkLabel.Font.Style:= livelinkLabel.Font.Style - [fsUnderline];
end;

// livelinkLabel array mouse handler
procedure TuHost2.llLabelMouseEnter(Sender: TObject);
begin
	TLabel(Sender).Cursor:= crHandPoint;
  TLabel(Sender).Font.Style:= TLabel(Sender).Font.Style + [fsUnderline];
end;

procedure TuHost2.llLabelMouseExit(Sender: TObject);
begin
	TLabel(Sender).Cursor:= crDefault;
  TLabel(Sender).Font.Style:= TLabel(Sender).Font.Style - [fsUnderline];
end;

procedure TuHost2.llLabelMouseClick(Sender: TObject);
var
  llAdre: string;
begin
  llAdre:= TLabel(Sender).Hint;
  ShellExecute(0, PAnsiChar('open'), PAnsiChar(llAdre), nil, nil, SW_SHOWNORMAL)
end;

{************************** REGISTER *******************************}

function TuHost2.isRegValid(reg: TRegistry; value: string; returnVal: string = ''): string;
begin
  try
    if reg.ValueExists(value) then
      returnVal:= reg.ReadString(value);
  except on E:Exception do
    writeErrorLog('Error on reading "' + value + '" (str): ' + E.Message);
  end;
  Result:= returnVal;
end;

function TuHost2.isRegValid(reg: TRegistry; value: string; returnVal: integer = 0): integer;
begin
  try
    if reg.ValueExists(value) then
      returnVal:= reg.ReadInteger(value);
  except on E:Exception do
    writeErrorLog('Error on reading "' + value + '" (int): ' + E.Message);
  end;
  Result:= returnVal;
end;

function TuHost2.isRegValid(reg: TRegistry; value: string; returnVal: boolean = False): boolean;
begin
  try
    if reg.ValueExists(value) then
      returnVal:= reg.ReadBool(value);
  except on E:Exception do
    writeErrorLog('Error on reading "' + value + '" (bool): ' + E.Message);
  end;
  Result:= returnVal;
end;

procedure TuHost2.loadSettings;
const
  IEPath: string = 'C:\Program Files\Internet Explorer\iexplore.exe';
var
  vastus: string;
begin
  gReg:= TRegistry.Create;
  userPath:= '';
  logiPath:= '';
  lksPath:='';
  vastus := '';

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

          lksVers:= isRegValid(gReg, 'lksVers', lksVersioon); // Laiskussi versioon
          lksPath:= isRegValid(gReg, 'lksPath', ExtractFilePath(Application.ExeName)); // Laiskussi asukoht
          autoCB.Checked:= isRegValid(gReg, 'autoConnect', True); // loo ühendust käivitamisel
          cnfKonf:= isRegValid(gReg, 'confirmKonf', True); // küsi kinnitust konfi saatmisel
          hkAllowed:= isRegValid(gReg, 'allowHotkeys', False); // hotkey'de lubamine
          checkCon:= isRegValid(gReg, 'checkConnection', False);
          macroPanelExpanded:= isRegValid(gReg, 'mpExpanded', True);
          default_connection_type:= isRegValid(gReg, 'default_connection_type', 0);

        	if gReg.ValueExists('authData') then
          	begin
            	gReg.ReadBinaryData('authData', autent, SizeOf(autent));
              userLevel:= autent.asLevel;
            end;                                    
        end;
      gReg.CloseKey;
// End Laiskussi registri andmed

// Terminali andmed
      gReg.OpenKey('SOFTWARE\Laiskuss2\Term', True);

        termCol:= isRegValid(gReg, 'termCol', 0); // terminali värvu
        termTxtCol:= isRegValid(gReg, 'termTxtCol', 12632256); // terminali teksi värv
        termFSize:= isRegValid(gReg, 'termFSize', 10); // terminali teksti suurus
        termFB:= isRegValid(gReg, 'termBold', False); // terminali tekst paksus

        winTop:= isRegValid(gReg, 'winTop', 25); // Laiskussi y koordinaat
        winLeft:= isRegValid(gReg, 'winLeft', Trunc(Screen.Width/16)); // Laiskussi x koordinaat
        winHeight:= isRegValid(gReg, 'winHeight', 694); // Laiskussi laius

      gReg.CloseKey;
// End Terminali andmed

// End default checking
    except on E:Exception do
      Application.MessageBox(PAnsiChar('Error @ loadReg'+#13#10 + E.Message), 'Ussike annab teada', MB_ICONERROR);
    end;

// Laiskussi registri andmed
  finally
    gReg.Free;
  end;

end;

procedure TuHost2.saveSettings;
var
  trueHeight: SmallInt;
begin
  gReg:= TRegistry.Create;
  try
    gReg.RootKey:= HKEY_CURRENT_USER;
    try
      gReg.OpenKey('SOFTWARE\Laiskuss2\', True);
      gReg.WriteBool('autoConnect', autoCB.Checked);
      gReg.WriteString('lksVers', lksVersioon);
      gReg.WriteString('lksPath', ExtractFilePath(Application.ExeName));
      gReg.WriteBool('mpExpanded', macroPanelExpanded);
      gReg.CloseKey;
    except on E:Exception do
      WriteErrorLog('Error @ saveSettings1: ' + E.Message);
    end;

    try
      gReg.OpenKey('SOFTWARE\Laiskuss2\Term', True);
      gReg.WriteInteger('winTop', uHost2.Top);
      gReg.WriteInteger('winLeft', uHost2.Left);
      if isCpOpen then
        trueHeight:= uHost2.Height - 200
      else
        trueheight:= uHost2.Height;
      gReg.WriteInteger('winHeight', trueHeight);
      gReg.CloseKey;
    except on E:Exception do
      WriteErrorLog('Error @ saveSettings2: ' + E.Message);
    end;
  finally
    gReg.Free;
  end;
end;

// terminali kõrguse sättimine, võetakse arvesse toolbari (x2), kontrolpaneeli ja macropaneeli kõrgused
// arvutatakse akna suuuruse muutmisel ja/või kontrolpaneeli avamisel/sulgemisel
procedure TuHost2.recalculateHeights;
var
  cpPanH: SmallInt;
begin
  if cpPanel.Visible then
    cpPanH:= cpPanel.Height
  else
    cpPanH:= 0;

  cpPanel.Top:= uHost2.ClientHeight - cpPanel.Height;
  if isCpOpen then
	  macroPanel.Top:= cpPanel.Top - macroPanel.Height
  else
  	macroPanel.Top:= uHost2.ClientHeight - macroPanel.Height;

  macroNaviUp.Top:= macroPanel.Top;
  macroNaviDown.Top:= macroNaviUp.Top + macroNaviUp.Height;
  uTerm.Height:= uHost2.ClientHeight - (uCtrl1.Height + uCtrl2.Height) -
    macroPanel.Height - cpPanH - 2;

  // getTotalCharHeight should be gathered after first uTerm resize is done
  // although it will work correctly even if it will be gathered at start
  // but debugger then will start annoying with EAccessViolation error
  // (which is strangely quite harmless).... go figure...  
  if terminal_character_height = 0 then
    terminal_character_height:= 12
  else
    terminal_character_height:= uTerm.GetTotalCharHeight;
  uTerm.Rows:= Trunc(uTerm.ClientHeight / terminal_character_height);
end;

function TuHost2.VKtoChar(Key: Word): string;
var
  keyboardState: TKeyboardState;
  asciiResult: integer;
begin
  GetKeyboardState(keyboardState);
  SetLength(Result, 2) ;
  asciiResult := ToAscii(key, MapVirtualKey(key, 0), keyboardState, @Result[1], 0);
  case asciiResult of
    0: Result := '';
    1: SetLength(Result, 1);
    2:;
    else
      Result := '';
  end;
end;

function TuHost2.getVK_ID(VK_IDENT: Word): string;
var
  arr: array [0..1024] of char;
  scanCode: uInt;
begin
  scanCode := MapVirtualKey(VK_IDENT, 0) shl 16;
  GetKeyNameText(scanCode, arr, sizeof(arr));
  Result:= strPas(arr);
end;

procedure TuHost2.checkForAutoConnect;
begin
  if autoCB.Checked then
    begin
      uCon.Click;
    end;
end;


// objekti ID genereerimine
function TuHost2.generateObjId: integer;
begin
  Randomize;
  Result:= StrToInt(Format('%d%d%d%d', [(10 + Random(89)),
    (10 + Random(89)), (10 + Random(89)), (10+ Random(89))]));
end;



{************************** Telnet/SSH/Serial connection ***************}

procedure TuHost2.selectTelnetClick(Sender: TObject);
begin
  connection_type:= TELNET;
  vahetaConnector;
  estpak_tunnel_selector.Enabled:= True;
end;

procedure TuHost2.estpak_tunnel_selectorClick(Sender: TObject);
begin
  if estpak_tunnel_selector.Checked then
    connection_type:= SSH
  else
    connection_type:= TELNET;
end;

procedure TuHost2.selectSerialClick(Sender: TObject);
begin
  connection_type:= SERIAL;
  vahetaConnector(False);
  estpak_tunnel_selector.Enabled:= False;
end;

procedure TuHost2.vahetaConnector(telnet_state: boolean = True);
var
  i: SmallInt;
begin
  uHostEdit.Visible:= telnet_state;
  uHostLabel.Visible:= telnet_state;
  uPortEdit.Visible:= telnet_state;
  uPortLabel.Visible:= telnet_state;
  for i:= 0 to Length(tsCombobox)-1 do
    begin
      tsLabel[i].Visible:= NOT telnet_state;
      tsCombobox[i].Visible:= NOT telnet_state;
    end;

  if (telnet_state = False) then
    begin
      tsCombobox[0].ItemIndex:= 0;
      tsCombobox[1].ItemIndex:= 5;
      tsCombobox[2].ItemIndex:= tsCombobox[2].Items.Count-1;
      tsCombobox[3].ItemIndex:= 2;
      tsCombobox[4].ItemIndex:= 0;
      tsCombobox[5].ItemIndex:= 1;
    end;
end;

function TuHost2.validateIpAdre(var veaTeade: string): boolean;
var
  tulemus: boolean;
  tyyp: string;
  raw_adre: string;
  otsing: string;
begin
  tulemus:= False;
  tyyp:= '';
  raw_adre:= Trim(uHostEdit.Text);
  try
    if (isIpValid(raw_adre, hostAddress)) then
      begin
        tulemus:= True;
        uHostEdit.Text:= hostAddress;
      end // validate IP
    else if (fetchIpFromSnr(raw_adre, otsing)) then
      begin
        if (isIpValid(otsing, hostAddress)) then
          begin
            tulemus:= True;
            uHostEdit.Text:= hostAddress;
          end;
      end // get IP from P number
    else if (dnsLookup(raw_adre, otsing)) then
      begin
        if (isIpValid(otsing, hostAddress)) then
          begin
            tulemus:= True;
            uHostEdit.Text:= hostAddress;
          end;
      end; // DNS lookup
    veaTeade:= 'Couldn''t resolve ' + raw_adre;
  except on E:Exception do
    WriteErrorLog('Exception @ validating ' + tyyp + ' : ' + E.Message);
  end;
  Result:= tulemus;
end;

{************************** TERMINAL HANDLE ************************}

procedure TuHost2.uTelnetDataAvailable(Sender: TIdTelnet;
  const Buffer: String);
const
    CR = #13;
    LF = #10;
var
    Start, Stop: Integer;
    s: string;
    lastLine: string;
begin
  lastLine:= '';
  case whereDoYouGo of
    1:
	    uTerm.WriteString(Buffer);
    2:
    	begin
        if dataBuffer.Count = 0 then dataBuffer.Add('');
        Start := 1;
        Stop  := Pos(CR, Buffer);
        if Stop = 0 then
            Stop := Length(Buffer) + 1;
        while Start <= Length(Buffer) do
          begin
            dataBuffer.Strings[dataBuffer.Count - 1] :=
                dataBuffer.Strings[dataBuffer.Count - 1] +
                Copy(Buffer, Start, Stop - Start);
                s:= Copy(Buffer, Start, Stop - Start);
            if Buffer[Stop] = CR then
              begin
                dataBuffer.Add('');
              end;
            Start := Stop + 1;
            if Start > Length(Buffer) then
                Break;
            if Buffer[Start] = LF then
               Start := Start + 1;
            Stop := Start;
            while (Buffer[Stop] <> CR) and (Stop <= Length(Buffer)) do
                Stop := Stop + 1;
          end;
      end;
  end;

  if dataBuffer.Count > 0 then
    lastLine:= dataBuffer.Strings[dataBuffer.Count - 1];

  if Trim(lastLine) = '{helpdesk}=>' then
    is_query_finished:= True;

  if NOT (is_user_found AND is_pswd_found) then
    uHost2.logiSisse(Buffer);
end;


// sisselogimise protseduur
procedure TuHost2.logiSisse(sisend: string);
begin
// insert username
  if (loginType < 3) then
    begin
      if (AnsiPos('Username :', sisend) > 0) or (AnsiPos('Username:', sisend) > 0) then
      	begin
      	writeLn_to_terminal(uUserEdit.Text);
      	is_user_found:= True;
      	end;
    end;

// insert password
  if (loginType < 2) then
    begin
      if (AnsiPos('Password :', sisend) > 0) or (AnsiPos('Password:', sisend) > 0) then
        begin
          writeLn_to_terminal(uPassEdit.Text);
          is_pswd_found:= True;
        end;
    end;

  if is_user_found AND is_pswd_found then
    begin
      if connection_type = SSH then
        begin
          is_estpak_forwarded:= True;
          isTelnetOverSshOpen:= True;
        end;
      MainCaption(uHost2.pNumber + ' @ ' + uHost2.uHostEdit.Text);
      Application.Title:= uHost2.pNumber + ' @ ' + uHost2.uHostEdit.Text + ' - Laiskuss 2';
    end;
end;

procedure TuHost2.forward_estpak_to_telnet(sisend: string = '');
begin
  if AnsiPos((ssh_auth_data.sshUsername + ':~$'), sisend) > 0 then
    begin
      writeLn_to_terminal('telnet ' + hostAddress);
      is_estpak_forwarded:= True;
      isTelnetOverSshOpen:= True;
    end;
end;

procedure TuHost2.uConClick(Sender: TObject);
const
  pars: array[0..4] of TParity = (
    pEven, pMark, pNone, pOdd, pSpace);
  flow: array[0..3] of TSWFlowOptions = (
    swfBoth, swfNone, swfReceive, swfTransmit);
var
  errMsg: string;
begin
  pNumber:= '';
  pvcStr:= '';
  profile:= '';
  sp_id:= '';

  // connectimisel või disconnectimisel tühjendada livelink sätted
  livelinkAdre:= '';
  rawLivelinkAdre:= '';
  liveLinkArray:= nil;

  //if (selectTelnet.Checked) then
  if (connection_type = TELNET) or (connection_type = SSH) then
    begin
      mark_benchmark(benchmark_start, 'connection init');
      if (uCon.Caption = CN) then
        begin
          if validateIpAdre(errMsg) then
            tcp_ssh_connect
          else
            Application.MessageBox(PAnsiChar(errMsg),
              'Laiskuss annab teada', MB_ICONWARNING);
        end
      else if (uCon.Caption = CNING) then
        begin
          tcp_ssh_disconnect;
          disconnect_message('Canceled by user...');
        end
      else if (uCon.Caption = DN) then
        begin
          tcp_ssh_disconnect;
          disconnect_message('Disconnected by user...');
        end;
      mark_benchmark(benchmark_start, 'connection end');        
    end
  else if connection_type = SERIAL then
    begin
      if (uCon.Caption= CN) then
        begin
          uTerm.Clear;
          comPort.ComNumber:= StrToint(tsCombobox[0].Items[tsCombobox[0].itemIndex]);
          comPort.Baud:= StrToint(tsCombobox[1].Items[tsCombobox[1].itemIndex]);
          comPort.DataBits:= StrToint(tsCombobox[2].Items[tsCombobox[2].itemIndex]);
          comPort.Parity:= pars[tsCombobox[3].ItemIndex];
          comPort.StopBits:= StrToInt(tsCombobox[4].Items[tsCombobox[4].itemIndex]);
          comport.SWFlowOptions:= flow[tsCombobox[5].ItemIndex];
          comPort.Open:= True;
          comPort.PutChar(#10);
          uCon.Caption:= DN;
          selectTelnet.Enabled:= False;
          estpak_tunnel_selector.Enabled:= False;
          is_com_port_open:= True;

          if isCpOpen = True then
            cp_panel.Click;
        end
      else if (uCon.Caption= DN) then
        begin
          comPort.Open:= False;
          selectTelnet.Enabled:= True;
          estpak_tunnel_selector.Enabled:= True;
          selectSerial.Enabled:= True;
          uCon.Caption:= CN;
          is_com_port_open:= False;
        end;
    end; // end if selectSerial
end;

procedure TuHost2.tcp_ssh_connect;
begin
  if connection_type = SSH then
    begin
      ssh_connect;
    end
  else if connection_type = TELNET then
    tcp_connect;
end;

procedure TuHost2.ssh_connect;
var
  login_status: SmallInt;
  is_logged_in: boolean;
begin
  try
    if ssh_auth_data.sshFailedLogin then
      begin
      LoginForm.Position:= poMainFormCenter;
      login_status:= LoginForm.ShowModal;

      if login_status <> mrOK then
        begin
          tcp_ssh_disconnect;
          Exit;
        end;
      end;

    is_user_found:= False;
    is_pswd_found:= False;
    is_estpak_forwarded:= False;
    with ssh_client do
      begin
        TargetHost:= TELNET_ESTPAK;
        TargetPort:= SSH_PORT;
        UserName:= ssh_auth_data.sshUsername;
        Password:= ssh_auth_data.sshPassword;
      end;

    uCon.Caption:= DN;
    getDataFromServer; // get sp_id, snr, profilve, pvc
    mainCaption('Connecting to ' + uHostEdit.Text);
    is_logged_in:= ssh_client.SSHLogin;
    if NOT is_logged_in then
      begin
        tcp_ssh_disconnect;
        if ssh_client.Sock.LastError = 10091 then
          begin
            ssh_auth_data.sshFailedLogin:= True;
            RequestLoginData;
            ssh_connect;
          end
        else
          MessageDlg(ssh_client.Sock.LastErrorDesc, mtError, [mbOK], 0);
        Exit;
      end;

    ssh_auth_data.sshFailedLogin:= False;
    RequestLoginData;

    if NOT Assigned(sshIoHandler) then
      sshIoHandler:= TSshIoHandler.Create(False)
    else if sshIoHandler.Suspended then
      try
        sshIoHandler.Resume;
      except
        if Not sshIoHandler.Terminated then
          sshIoHandler.Terminate;
        sshIoHandler:= TSshIoHandler.Create(False);
      end;
    on_tcp_ssh_connected(Self);

  except
    uCon.Caption:= CN;
  end;
end;

procedure TuHost2.tcp_connect;
begin
  try
    is_user_found:= False;
    is_pswd_found:= False;
    with uTelnet do
      begin
        host:= hostAddress;
        port:= StrToInt(uPortEdit.Text);
        uCon.Caption:= CNING;
        getDataFromServer; // get sp_id, snr, profilve, pvc
        mainCaption('Connecting to ' + uHostEdit.Text);
        connect;
      end;
  except
    uCon.Caption:= CN;
  end;

end;

procedure TuHost2.tcp_ssh_disconnect;
begin
  try
    is_query_finished:= True;
    is_user_found:= False;
    is_pswd_found:= False;
    is_estpak_forwarded:= False;
    uCon.Caption:= CN;
    whereDoYouGo:= 2;
    livelinkLabel.Visible:= False;
    livelinkImage.Visible:= False;
    livelinkImage.Picture:= nil;
    alqTS.alq_button[2].Enabled:= False;
    scrTs.Set_rbState(False);
    mainCaption(STATUS);
    selectTelnet.Enabled:= True;
    estpak_tunnel_selector.Enabled:= True;
    selectSerial.Enabled:= True;
    loginType:= 0;
    Application.Title:= 'Laiskuss 2';
    livelinkLabel.Caption:= 'Connect to Livelink';
    livelinkLabel.Hint:= '';
  except on E:Exception do
    writeErrorLog('Error on tcp_ssh_disconnect'+#13#10 + E.Message);
  end;

  case connection_type of
    TELNET: tcp_disconnect;
    SSH: ssh_disconnect;
  end;

//  if liveLinkPanel.Showing then
//    liveLinkPanel.Hide;
end;

procedure TuHost2.ssh_disconnect;
begin
  try
    ssh_client.Logout;
    if Assigned(sshIoHandler) AND Not sshIoHandler.Suspended then
      sshIoHandler.Stop;
    ssh_client.Sock.Purge;
  except
    // we might expect an exception here,
    // no need to mark it
  end;
end;

procedure TuHost2.tcp_disconnect;
begin
  try
		if is_connection_alive then
    	uTelnet.Disconnect;
  except on E: Exception do
    WriteErrorLog('Error on tcp_disconnect'+#13#10 + E.Message);
  end;
end;

procedure TuHost2.on_tcp_ssh_connected(Sender: TObject);
begin
  try
    if is_connection_alive(True) then {!r19}
      begin
        st_loadInfo.Caption:= ' ...';
        saveLoginHistory;
      	livelinkAdre:= '';
        rawLiveLinkAdre:= '';
        liveLinkExists:= False;
        estpak_tunnel_selector.Enabled:= False;
        selectSerial.Enabled:= False;
        statusTs.clearObjects;
        alqTs.resetGapCanvas;
        scrTs.Set_rbState(True);
        miscTS.setToDefault;
        uCon.Caption:= DN;
        whereDoYouGo:= 1;
        uTerm.ClearAll;
        if (isCpOpen = False) then
          cp_panel.Click;
        uTerm.SetFocus;
        if (userLevel = 1) then
        	begin
	          alqTS.alq_button[2].Visible:= True;
            if (pNumber <> '') then
              begin
            		alqTS.alq_button[2].Enabled:= True;
                livelinkLabel.Visible:= True;
                livelinkImage.Visible:= True;
                rawLiveLinkAdre:= '\\edhs.elion.ee\edhsdav\enterprise\Tehnoloogia\JUURDEPÄÄSUVÕRK\Dokumendid\';
                livelinkLabel.ShowHint:= True;
                uLiveLink:= TuLiveLink.Create(True);
                livelinkLabel.Hint:= liveLinkAdre;
              end; // pNumber exists
          end; // userLevel
    end;
  except on E:Exception do
    WriteErrorLog('Error @ uTelnet.Connected' + E.Message);
  end;       
end;

procedure TuHost2.uTelnetDisconnected(Sender: TObject);
begin
  try
    pNumber:= '';
    pvcStr:= '';
    profile:= '';
    sp_id:= '';
    livelinkAdre:= '';
    liveLinkExists:= False;
  except
  end;
end;

procedure TuHost2.disconnect_message(in_msg: string);
begin
  st_loadInfo.Caption:= ' ' + in_msg;
end;

//procedure TuHost2

procedure TuHost2.uTermKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  try
  if is_connection_alive(True) then
    begin
      case Key of
        VK_UP:      write_to_terminal(#27#79#65);
        VK_DOWN:    write_to_terminal(#27#79#66);
        VK_RIGHT:   write_to_terminal(#27#79#67);
        VK_LEFT:    write_to_terminal(#27#79#68);
        vk_DELETE:  write_to_terminal(#127);
      else
        write_to_terminal(vkToChar(key));
      end;
    end;
  except
  end;
end;

////////// uTerm popUp
procedure TuHost2.ppTermPopup(Sender: TObject);
var
  dummy: string;
begin
// kontrollime, kas on mida pasteerida
  if (clp.HasFormat(CF_TEXT)) AND is_connection_alive then
    termPasteB.Enabled:= True
  else
    termPasteB.Enabled:= False;
// kontrollime, kas selectitud on MAC aadress
  if isMacValid(valitud, dummy) then
    begin
      termMSB.Enabled:= True;
      globVal:= valitud;
    end
  else if isMacValid(valitud2, dummy) then
    begin
      termMSB.Enabled:= True;
      globVal:= valitud2;
    end
  else
    termMSB.Enabled:= False;

// kontrollime, kas selectitud on IP aadress
  if (isIpValid(valitud, dummy)) then
    begin
      termPingerB.Enabled:= True;
      globVal:= valitud;
    end
  else if (isIpValid(valitud2, dummy)) then
    begin
      termPingerB.Enabled:= True;
      globVal:= valitud2;
    end
  else
    termPingerB.Enabled:= False;
end;


procedure TuHost2.termCopyBClick(Sender: TObject);
begin
  if (valitud <> '') then
    clp.AsText:= valitud
  else if (valitud2 <> '') then
    clp.AsText:= valitud2
  else
    uTerm.CopyToClipboard;
    
  valitud:= '';
  valitud2:= '';
end;

procedure TuHost2.termPasteBClick(Sender: TObject);
begin
  if is_connection_alive then
    write_to_terminal(clp.AsText)
  else
    Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

procedure TuHost2.termMSBClick(Sender: TObject);
var
  vastus: string;
begin
  if searchForMac(globVal, vastus) then
    Application.MessageBox(PAnsiChar(globVal + ' = ' + vastus), 'MAC address lookup')
  else
    Application.MessageBox(PAnsiChar('Unknown address (' + globVal + ')'), 'MAC address lookup', MB_ICONWARNING);
  globVal:= '';
  valitud:= '';
  valitud2:= '';
end;

procedure TuHost2.termPingerBClick(Sender: TObject);
begin
  if is_connection_alive then
    begin
      writeLn_to_terminal('ping proto ip addr ' + globVal + ' count 10');
    end
  else
    Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
  globVal:= '';
  valitud:= '';
  valitud2:= '';
end;

procedure TuHost2.uTermMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
//
end;

// double click handler
// for select mac & IP Address
procedure TuHost2.uTermMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  getRow  : integer;
  getCol  : integer;
  i       : SmallInt;
  rida    : PAnsiChar;
begin
try
  if (globY > -1) then
    begin
      for i:= globX[0]+1 to globX[1] do
        begin
          uTerm.ForeColor[globY, i]:= termTxtCol;
          uTerm.BackColor[globY, i]:= termCol;
        end;
      globX[0]:= -2;
      globX[1]:= -2;
      globY:= -2;
    end;

  if (ssDouble in Shift) then
    begin
      getRow:= y div uTerm.GetTotalCharHeight + uTerm.ClientOriginRow;
      getCol:= x div uTerm.GetTotalCharWidth + uTerm.ClientOriginCol;
      rida:= uTerm.Emulator.Buffer.GetLineCharPtr(getRow);

  // esimese tühiku otsimine
      for i:= getCol downto 0 do
        if (rida[i] = ' ') then
          begin
            globX[0]:= i;
            break;
          end;
      if (globX[0] = 0) then
        globX[0]:= -1;

  // teise tühiku otsimine
      for i:= getCol-1 to uTerm.Emulator.Buffer.ColCount-1 do
        if (rida[i] in [' ', ',']) then
          begin
            globX[1]:= i;
            break;
          end;

  // selecti värvimine ja valitud stringi char'de sisestamine
  // globX[0]+2 to globX[1] = esimesest viimase vahemikuni 
      valitud:= '';

      for i:= globX[0]+2 to globX[1] do
        begin
          uTerm.ForeColor[getRow, i]:= termCol;
          uTerm.BackColor[getRow, i]:= termTxtCol;
          valitud:= valitud + rida[i-1];
        end;
      globY:= getRow;
      valitud:= Trim(valitud);
      //clp.AsText:= valitud;
    end // end of if ssDouble
  else
    begin
      globX2[0]:= X;
    end;
except on E:Exception do
  writeErrorLog('Exception @ uTermMouseDown: ' + E.Message);
end;
end;

procedure TuHost2.uTermMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  getRow  : integer;
  i       : SmallInt;
  rida    : PAnsiChar;
begin
  if (Button = mbLeft) then
    begin
      valitud2:= '';
      globx2[1]:= X;
      getRow:= y div uTerm.GetTotalCharHeight + uTerm.ClientOriginRow;
      rida:= uTerm.Emulator.Buffer.GetLineCharPtr(getRow);

      for i:= (globX2[0] div uTerm.GetTotalCharWidth) to (globX2[1] div uTerm.GetTotalCharWidth) do
        valitud2:= valitud2 + rida[i];
    end;
end;

procedure TuHost2.uTermDblClick(Sender: TObject);
begin
//
end;

// uTerm mousewheel handler
procedure TuHost2.uTermMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if (WheelDelta > 0) then
    uTerm.Perform(WM_VSCROLL, SB_LINEUP, 0)
  else
    uTerm.Perform(WM_VSCROLL, SB_LINEDOWN, 0)
end;

// end terminal handle



{************************ Control Panel *********************}

procedure TuHost2.cp_panelClick(Sender: TObject);
begin
  if isCpOpen then
    begin
      isCpOpen:= False;
      cpPanel.Visible:= False;
      uHost2.Height:= uHost2.Height - cpPanel.Height;
    end
  else
    begin
      isCpOpen:= True;
      cpPanel.Visible:= True;
      uHost2.Height:= uHost2.Height + cpPanel.Height;
      cpTpg.ActivePageIndex:= 0;
    end;
  recalculateHeights;
end;


procedure TuHost2.uHostEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    uCon.Click;
end;

{************************* Login History ***********************}

procedure TuHost2.quickConnectBClick(Sender: TObject);
var
  pt: TPoint;
begin
  try
    pt.X:= uCon.Left + uCon.Width;
    pt.Y:= uCon.Top + uCon.Height;
    pt:= ClientToScreen(pt);
    ppQuickConnect.Popup(pt.X, pt.Y);
  except on E:Exception do
    WriteErrorLog('Error @quickConnectB: ' + E.Message);
  end;
end;

procedure TuHost2.Clearhistory1Click(Sender: TObject);
var
  i: SmallInt;
begin
  if FileExists(userPath + loginFile) then
    begin
      AssignFile(lhFile, userPath + loginFile);
      DeleteFile(userPath + loginFile);
    end;
    
  Setlength(loginHistory, 0);
  loginHistory:= nil;
  for i:= ppQuickConnect.Items.Count-1 downto 2 do
    ppQuickConnect.Items.Delete(i);
end;

procedure TuHost2.populateLogin(loadFile: boolean = True);
var
  i: SmallInt;
  nimi, connection_type_string: string;
  mItem: TMenuItem;
begin
  for i:= ppQuickConnect.Items.Count-1 downto 2 do
    ppQuickConnect.Items.Delete(i);
// load login history
  if loadFile then
    begin
      AssignFile(lhFile, userPath + loginFile);
      if FileExists(userPath + loginFile) then
        Reset(lhFile)
      else
        ReWrite(lhFile);

      for i:= 0 to FileSize(lhFile)-1 do
        begin
          SetLength(loginHistory, i+1);
          Read(lhFile, loginHistory[i]);
        end;
      CloseFile(lhFile);
    end;

  try
    for i:= 0 to Length(loginHistory)-1 do
      begin
        case loginHistory[i].hType of
          TELNET: connection_type_string:= 'Telnet';
          SSH: connection_type_string:= 'Telnet@estpak';
          SERIAL: connection_type_string:= 'Serial';
        end;

        nimi:= loginHistory[i].hUser;
        if (Length(nimi) > 0) then
          nimi:= Format('%s@%s:%d [%s]', [
              nimi,
              loginHistory[i].hHost,
              loginHistory[i].hPort,
              connection_type_string]
          )
        else
          nimi:= Format('%s:%d [%s]', [
              loginHistory[i].hHost,
              loginHistory[i].hPort,
              connection_type_string]
          );

        mItem:= TMenuItem.Create(Self);
        mItem.Caption:= nimi;
        mItem.Tag:= i;
        mItem.OnClick:= loadQCData;
        ppQuickConnect.Items.Add(mItem);
      end;
  except on E:Exception do
    ShowMessage(e.Message);
  end;
end;

procedure TuHost2.saveLoginHistory;
var
  i, j, lhfCnt, lhCnt, found: SmallInt;
  temp1: TLoginHistory;
begin
  found:= -1;
  lhCnt:= 0;
  try
    SetLength(loginHistory, 0);
    AssignFile(lhFile, userPath + loginFile);
    if FileExists(userPath + loginFile) then
      begin
        Reset(lhFile);
        lhfCnt:= FileSize(lhFile);
        if (lhfCnt > 0) then
          for i:= 0 to lhfCnt-1 do
            begin
              Setlength(loginHistory, lhCnt+1);
              Read(lhFile, loginHistory[lhCnt]);
              inc(lhCnt);
            end;
      end
    else
      ReWrite(lhFile);
      lhCnt:= Length(loginHistory);

    temp1.hHost:= uHostEdit.Text;
    temp1.hPort:= StrToInt(uPortEdit.Text);
    temp1.hUser:= uUserEdit.Text;
    temp1.hType:= connection_type;
    if (Length(uPassEdit.Text) > 0) then
      temp1.hPass:= encStr(uPassEdit.Text)
    else
      temp1.hPass:= '';
    temp1.hLogin:= loginType;

    if (Length(loginHistory) > 0) then
      for i:= 0 to Length(loginHistory)-1 do
        if ((temp1.hHost = loginHistory[i].hHost) AND (temp1.hUser = loginHistory[i].hUser)) then
          begin
            found:= i;
            break;
          end;

    ReWrite(lhFile);
    if (found >= 0) then
      begin
        for i:= found downto 1 do
          begin
            loginHistory[i]:= loginHistory[i-1];
          end;
        loginHistory[0]:= temp1;
      end
    else
      begin
        SetLength(loginHistory, lhCnt+1);
        for j:= lhCnt downto 1 do
          loginHistory[j]:= loginHistory[j-1];
        inc(lhCnt);
        loginHistory[0]:= temp1;
      end;

// login history recordite maksimaalne arv on 10
    if lhCnt > 10 then
      lhCnt := 10;
    for i:= 0 to lhCnt-1 do
      Write(lhFile, loginHistory[i]);

    CloseFile(lhFile);
    populateLogin(False);
  except on E:Exception do
    ShowMessage(E.Message);
  end;
end;

// Load QuickConnect data
procedure TuHost2.loadQCData(Sender: TObject);
var
  mTag: SmallInt;
  connection_type_string: string;
begin
  if Sender is TMenuItem then
    begin
      mTag:= TMenuItem(Sender).Tag;
      if is_connection_alive then
        begin
          case connection_type of
            TELNET: connection_type_string:= 'Telnet';
            SSH: connection_type_string:= 'Telnet@estpak';
            SERIAL: connection_type_string:= 'Serial';
          end;

          if (MessageDlg(connection_type_string + ' connection is active, disconnect?',
            mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
              tcp_ssh_disconnect
          else
            Exit;
        end;

      with loginHistory[mTag] do
        begin
          uHostEdit.Text:= hHost;
          uPortEdit.Text:= IntToStr(hPort);
          uUserEdit.Text:= hUser;
          uPassEdit.Text:= decStr(hPass);
          connection_type:= hType;
        end;

      // NO Serial quick connect
      selectTelnet.Checked:= True;
      estpak_tunnel_selector.Checked:= (connection_type = SSH);

      Sleep(100);
      try
        // we use Click instead of tcp_ssh_disconnect
        // becuase it has an address validation
        if (autoCB.Checked) then
          uCon.Click;
      except on E:Exception do
        ShowMessage((Format('%d - %s', [mTag, connection_type_string])));
      end;

    end;
end;

{******************************* Toolbar2 ************************* }


procedure TuHost2.siteManagerBClick(Sender: TObject);
var
  Flags: DWORD;
  Handle: HWND;
begin
  Handle:= siteManagerP.Handle;
  if isSmOpen then
    begin
      Flags:= AW_HIDE OR AW_VER_NEGATIVE;
      loadSitesFromTv(True);
    end
  else
    begin
      Flags:= AW_ACTIVATE OR AW_VER_POSITIVE;
      siteManagerTV.Items.Clear;
      loadSites;
      siteSaveB.Enabled:= False;
    end;

  isSmOpen:= NOT isSmOpen;
  Flags:= Flags OR AW_SLIDE;
  AnimateWindow(Handle, 100, Flags);

  conInfoP.Invalidate;
end;



{******************************* TPageControl **********************}

procedure TuHost2.statusTabShow(Sender: TObject);
begin
//
end;

procedure TuHost2.alqTabShow(Sender: TObject);
begin
//
end;

procedure TuHost2.miscTabShow(Sender: TObject);
begin
//
end;

procedure TuHost2.scriptTabShow(Sender: TObject);
begin
//
//
end;

procedure TuHost2.ariTabShow(Sender: TObject);
begin
//
end;

procedure TuHost2.one20TabShow(Sender: TObject);
begin
//
end;

{******************************* DATA Parser **********************}

procedure TuHost2.WaitForData(going: boolean);
begin
  while NOT is_query_finished do
    Application.ProcessMessages;
end;

function TuHost2.VordusMark(sisend: string): string;
var
  i: integer;
begin
  i:= pos('=', sisend);
  result:= Trim(Copy(sisend, i+1, Length(sisend) - i));
end;

function TuHost2.koolon(sisend: string): string;
var
  i: integer;
begin
  sisend:= Trim(sisend);
  i:= pos(': ', sisend);
  Result:= Trim(Copy(sisend, i+1, Length(sisend)-1));
end;

procedure TuHost2.Explode2(sisend: string; delim: string; var blokk: TStrArr);
var
  iPos    : SmallInt; // delim asukoht
  bCnt    : SmallInt; // blokki suurus
  piiraja : SmallInt; // fail-safe counter
  sSize   : SmallInt; // sisendi suurus
begin
  try
    piiraja:= 0;
    sSize:= Length(sisend);

// kui sisendil puudub eraldaja, lisame
    if (sisend[sSize] <> delim) then
      sisend:= sisend + delim;
    SetLength(blokk, 0);
   repeat
      sisend:= TrimLeft(sisend);
      bCnt:= Length(blokk);
      SetLength(blokk, bCnt+1);
      iPos:= AnsiPos(delim, sisend);
      blokk[bCnt]:= Copy(sisend, 1, iPos-1);
      Delete(sisend, 1, iPos);
      inc(piiraja);
    until (Length(sisend) = 0) OR (piiraja = sSize);
  except on E:Exception do
    writeErrorLog('error @ get_blocks: ' + E.Message);
  end;
end;


{
  kontrollime kas mac aadress ikka vastab otsingu tingimustele:
  sisend peab sisaldama ainult hex'i sümboleid (0-9 ja a-f);
  lubatud on xxxxxx, xxxxxxxxxxxx, xx:xx:xx, xx:xx:xxxx:xx:xx, xx-xx-xx, xx-xx-xxxx-xx-xx kujul
}
function TuHost2.isMacValid(sisend: string; var vastus: string): boolean;
var
  delim: string;
  i, hexCnt: SmallInt;
  tulemus: boolean;
begin
  tulemus:= False;
  sisend:= Trim(AnsiUpperCase(sisend));
  vastus:= 'dd';
  delim:= '';
  hexCnt:= 0;
  if (Length(sisend) >= 5) AND (Length(sisend) < 18) then
    begin
    // ":" ja "-" eemaldamine
      if (AnsiPos(':', sisend) > 0) then
        sisend:= AnsiReplaceStr(sisend, ':', '')
      else if (AnsiPos('-', sisend) > 0) then
        sisend:= AnsiReplaceStr(sisend, '-', '');

    // HEX kontroll
      for i:= 0 to Length(sisend) do
        if ((sisend[i] in ['0'..'9', 'A'..'F'])) then
          inc(hexCnt);

      if (Length(sisend) >= 6) AND (hexCnt = Length(sisend)) then
          begin
            vastus:= Copy(sisend, 1, 6);
            tulemus:= True;
          end;
    end; // end length
  Result:= tulemus;
end;

function TuHost2.searchForMac(sisend: string; var vastus: string): boolean;
const
  predefined_mac_list: array[0..2] of TMacs = (
    (nimi: 'Samsung SmartTV'; macAadress: 'C4731E'),
    (nimi: 'Motorola'; macAadress: '00029B'),
    (nimi: 'Amino'; macAadress: '000202')
  );
var
  s, tagasi: string;
  tulemus: boolean;
  i: SmallInt;
begin
  tulemus:= False;
  if (isMacValid(sisend, tagasi)) then
    begin
      for i:= 0 to Length(predefined_mac_list) - 1 do
        if predefined_mac_list[i].macAadress = tagasi then
          begin
            vastus:= predefined_mac_list[i].nimi;
            Result:= True;
            Exit;
          end;

      Reset(macFile);
      repeat
          ReadLn(macFile, s);
          if (AnsiPos(tagasi, s) > 0) then
            begin
              vastus:= Trim(Copy(s, AnsiPos(' ', s), MaxInt));
              tulemus:= True;
              break;
            end;
      until EOF(macFile);
    end;
  Result:= tulemus;
end;


function TuHost2.isIPValid(sisend: string; var addr: string): boolean;
var
  set_nr: set of '0'..'9';
  i,j, pcnt: integer;
  aadress: string;
  tulemus: boolean;
begin
  set_nr:= ['0'..'9'];
  i:= Length(sisend);
  aadress:= '';
  if (i > 0) then
  begin
    for j:= 0 to i do
      begin
        if ((sisend[j] in set_nr) or (sisend[j] = '.')) then
          aadress:= aadress + sisend[j];
      end;
  end;
  pcnt := 0;
  if (Length(aadress) > 7) then
    for i:= 0 to Length(aadress)-1 do
      if (aadress[i] = '.') then inc(pcnt);
  if (pcnt = 3) then
    tulemus := True
  else
    tulemus := False;
  addr:= aadress;
  result:= tulemus;
end;

function TuHost2.getHttpData(aUrl: string): string;
var
  hSession, hService: HINTERNET;
  cuBuffer: array[0..1024+1] of char;
  cuBytesRead: DWORD;
  vastus: string;
begin
  vastus:= '';
  hSession:= InternetOpen('Laiskuss', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  try
    if assigned(hSession) then
      begin
        hService:= InternetOpenUrl(hSession, PChar(aUrl), nil, 0, INTERNET_FLAG_RELOAD,0);
        if assigned(hService) then
          try
            while True do
              begin
                cuBytesRead:= 1024;
                InternetReadFile(hService, @cuBuffer, 1024, cuBytesRead);
                if cuBytesRead = 0 then break;
                cuBuffer[cuBytesRead]:= #0;
                vastus:= vastus + cuBuffer;
              end;
              Result:= vastus;
          finally
            InternetCloseHandle(hService);
          end;
      end;
  finally
    InternetCloseHandle(hSession);
  end;
end;

procedure TuHost2.getDataFromServer;
var
  vastus: string;
begin
  try
    vastus:= getHttpData('http://laiskuss.elion.ee/uss_remote2/get_port.php?ipAddr=' + hostAddress);
    pNumber:= sulu_parser(vastus, 'P_NR');
    pvcStr:= sulu_parser(vastus, 'PVC');
    profile:= sulu_parser(vastus, 'PROFILE');
    sp_id:= sulu_parser(vastus, 'SP_ID');
  except on E:Exception do
    WriteErrorLog('Except @ getDataFromServer: ' + E.Message);
  end;
end;

function TuHost2.fetchIpFromSnr(sisend: string; var addr: string): boolean;
var
  tulemus: boolean;
  vastus: string;
  lisad: string;
  i, lisadeArv: SmallInt;
begin
  tulemus:= False;
  lisad:= '';
  try
	  SetLength(lisaIpList, 0);
  	SetLength(lisaIpImg, 0);
    vastus:= getHttpData('http://laiskuss.elion.ee/uss_remote2/fetch_ip.php?pNr='+sisend);
    if (AnsiCompareStr(sulu_parser(vastus, 'response'), '400') = 0) then
      begin
        addr:= sulu_parser(vastus, 'pNumber');
        lisad:= sulu_parser(vastus, 'lisadeArv');
        if (isInt(lisad)) then
        	begin
          	lisadeArv:= StrToInt(lisad);
            if (lisadeArv > 0) then
            	multiPanel.Visible:= True;
              multiPanel.Height:= 30 * lisadeArv + 35;
              for i:= 0 to lisadeArv-1 do
              	begin
                	SetLength(lisaIpList, i+1);
                  lisaIpList[i]:= TLabel.Create(nil);
                  with lisaIpList[i] do
                  	begin
                    	Parent:= multiPanel;
                      AutoSize:= False;
                      Layout:= tlCenter;
                      Width:= 100;
                      Left:= 5;
                      Height:= 17;
                      Top:= i * 20 + 5;
                      Font.Style:= Font.Style + [fsBold];
                      Font.Style:= Font.Style + [fsUnderline];                      
                      OnClick:= launchLaiskuss;
                      Caption:= sulu_parser(vastus, 'lisaIp' + IntToStr(i+1));
                      Visible:= True;    
                      OnMouseEnter:= miLabelMouseEnter;
                      OnMouseLeave:= miLabelMouseExit;                
                    end; // with 

                  
                  SetLength(lisaIpImg, i+1);
                  lisaIpImg[i]:= TImage.Create(nil);
                  with lisaIpImg[i] do
                  	begin
                    	Parent:= multiPanel;
                      Left:= lisaIpList[i].Left + lisaIpList[i].Width + 10;
                      Top:= lisaIplist[i].Top
                    end; // with 
                  
                end; // for i loop
          end;
        tulemus:= True;
      end;
  except on E:Exception do
    WriteErrorLog('Exception @ fetching IP: ' + E.Message);
  end;
  Result:= tulemus;
end;

{*******************************************************************************
                                    LISA IP AADRESSID on P number
********************************************************************************}

procedure TuHost2.miButtonClick(Sender: TObject);
begin
	try
  	vabadus(lisaIpList);
    vabadus(lisaIpImg);
    multiPanel.Visible:= False;
  except on E:Exception do
  	WriteErrorLog('Exception @ freeing lisaIpList: ' + E.Message);
  end;
end;

procedure TuHost2.launchLaiskuss(Sender: TObject);
begin
	if (Sender is TLabel) then
  	begin
    	ShellExecute(0, PAnsiChar('open'), PAnsiChar('telnet://' + TLabel(Sender).Caption), 
      nil, nil, SW_SHOWNORMAL);
    end;
end;

procedure TuHost2.miLabelMouseEnter(Sender: TObject);
begin
	TLabel(Sender).Cursor:= crHandPoint;
  TLabel(Sender).Font.Color:= clBlue;
end;

procedure TuHost2.miLabelMouseExit(Sender: TObject);
begin
	TLabel(Sender).Cursor:= crDefault;
  TLabel(Sender).Font.Color:= clBlack;
end;

{*******************************************************************
                            MACRO PANEL
********************************************************************}

procedure TuHost2.drawMacros;
var
  i: SmallInt;
begin
  try
    for i:= 0 to Length(macrod)-1 do
      begin
        SetLength(mcr_button, i+1);
        mcr_button[i]:= TButton.Create(nil);
        mcr_button[i].Parent:= macroPanel;
        mcr_button[i].Top:= (i div 11) * 25; // reas on 11 nuppu
        mcr_button[i].Left:= (i mod 11) * 77 + 2; // reas on 11 nuppu
        mcr_button[i].Width:= 75;
        mcr_button[i].Height:= 22;
        mcr_button[i].Caption:= macrod[i].macr_nimi;
        mcr_button[i].ShowHint:= True;
        mcr_button[i].Hint:= macrod[i].macr_hint;
        mcr_button[i].Tag:= i;
        mcr_button[i].OnClick:= launchMacro;
      end;

    macroNaviUp.Top:= macroPanel.Top;
    macroNaviUp.Glyph.LoadFromFile(ExtractFilePath(Application.ExeName) + 'dat\bUp2.bmp');
    macroNaviUp.Width:= 37;
    macroNaviUp.Left:= macroPanel.Left + macroPanel.Width + 2;
    macroNaviUp.Height:= 13;

    macroNaviDown.Top:= macroNaviUp.Top + macroNaviUp.Height + 1;
    macroNaviDown.Left:= macroNaviUp.Left;
    macroNaviDown.Glyph.LoadFromFile(ExtractFilePath(Application.ExeName) + 'dat\bDown2.bmp');
    macroNaviDown.Height:= macroNaviUp.Height;
    macroNaviDown.Width:= macroNaviUp.Width;

  except on E:Exception do
    writeErrorLog('Error @ drawMacros: ' + E.Message);
  end;
end;


procedure TuHost2.macroPanelMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  firstElement: SmallInt; // ScrollBox'i esimene nupp - Left pos jaoks
  lastElement : SmallInt; // ScrollBox'i viimane nupp - Rioht jaoks
  elementCnt  : SmallInt; // ScrollBox'i nuppude arv
begin
  Handled:= True;
  if (Sender is TScrollBox) then
    begin
      elementCnt:= TScrollBox(Sender).ControlCount;
      if (elementCnt > 0) then
        begin
          firstElement:= TScrollBox(Sender).Controls[0].Top;
          lastElement:= TScrollBox(Sender).Controls[elementCnt-1].Top + 25;

          if WheelDelta < 0 then
            begin
              if (lastElement > TScrollBox(Sender).Height) then
                TScrollBox(Sender).ScrollBy(0, -25);
            end // end of wheel down
          else if WheelDelta > 0 then
            begin
              if (firstElement < 0) then
                TScrollBox(Sender).ScrollBy(0, 25);
            end; // end of wheel up
      end; // end of elementCnt
    end; // end of if Sender
  checkNavi;
end;

procedure TuHost2.launchMacro(Sender: TObject);
var
  bTag: SmallInt; // macro nuppu tag ID
  macroText: string;
begin
//  if (Sender is TButton) then
    if is_connection_alive then
      begin
        bTag:= TButton(Sender).Tag;
        macroText:= scrTS.koolonKontroll(macrod[bTag].macr_text);
        if (macrod[bTag].macr_cnf) then
          begin
            if (MessageDlg(PAnsiChar('Are you sure?'), mtConfirmation, [mbOk, mbCancel], 0) = mrOk) then
              writeLn_to_terminal(macroText)
          end
        else
          writeLn_to_terminal(macroText);
      end
    else
      Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

//  macroNavi state
procedure TuHost2.checkNavi;
begin
  try
    if macroPanelExpanded then
      begin
        macroPanel.Height:= 52;
        macroNaviUp.Height:= 26;
        macroNaviDown.Height:= 26;
      end
    else
      begin
        macroPanel.Height:= 26;
        macroNaviUp.Height:= 13;
        macroNaviDown.Height:= 13;
      end;
  except on E:Exception do
    writeErrorLog('Exception @ checkNavi: ' + E.Message);
  end;
end;

procedure TuHost2.scr_editorClick(Sender: TObject);
begin
  if uScriptEditor.Showing then
    uScriptEditor.BringToFront
  else
    begin
      uScriptEditor.Top:= uHost2.Top + uTerm.Top + 35;
      uScriptEditor.Left:= uHost2.Left + uHost2.ClientWidth - uScriptEditor.ClientWidth - 25;
      uScriptEditor.Show;
    end;
end;


procedure TuHost2.macroNaviUpClick(Sender: TObject);
var
  firstElement: SmallInt; // ScrollBox'i esimene nupp - Left pos jaoks
  elementCnt  : SmallInt; // ScrollBox'i nuppude arv
begin
  elementCnt:= macroPanel.ControlCount;
  if (elementCnt > 0) then
    begin
      firstElement:= macroPanel.Controls[0].Top;
      if (firstElement < 0) then
        macroPanel.ScrollBy(0, 25);
    end; // end of elementCnt
  checkNavi;
end;

procedure TuHost2.macroNaviDownClick(Sender: TObject);
var
  lastElement : SmallInt; // ScrollBox'i viimane nupp - Right jaoks
  elementCnt  : SmallInt; // ScrollBox'i nuppude arv
begin
  elementCnt:= macroPanel.ControlCount;
  if (elementCnt > 0) then
    begin
      lastElement:= macroPanel.Controls[elementCnt-1].Top + 25;
      if (lastElement > macroPanel.Height) then
        macroPanel.ScrollBy(0, -25);
    end; // end of elementCnt
  checkNavi;
end;

procedure TuHost2.macroNaviUpMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    begin
    	macroPanelExpanded:= NOT macroPanelExpanded;
      checkNavi;
      recalculateHeights;        
    end;
end;

procedure TuHost2.macroNaviDownMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    begin
			macroPanelExpanded:= NOT macroPanelExpanded;
      checkNavi;
      recalculateHeights;
    end;
end;

{******************************************************
HOTKEYS
******************************************************}

procedure TuHost2.loadHotkeys;
var
  i, j: SmallInt;
begin
  if FileExists(userPath + hkFile) then
    begin
      AssignFile(hotKeyList, userPath + hkFile);
      Reset(hotKeyList);
      j:= FileSize(hotKeyList);
      if j > 0 then
        begin
          try
            SetLength(hotKeys, j);
            for i:= 0 to j-1 do
              Read(hotkeyList, hotKeys[i]);
            except on E:Exception do
              WriteErrorLog('Error on loading hotkey list: ' + E.Message);
            end;
        end;
      CloseFile(hotkeyList);
    end;
end;

// setVK_ID = hotkey kombinatsioon, kui hotkey kombinatsioon leitud siis tulemus = True ja
// retContID tagastab funktsiooni ID numbri
function TuHost2.findCon(setVK_ID: string; var retContID: SmallInt): boolean;
var
  i: integer;
begin
  Result:= False;
  for i:= 0 to Length(hotKeys) -1 do
  // võrdleme etteantud kombinatsiooni recordiga
    if (AnsiMatchStr(hotKeys[i].shortcut, setVK_ID)) then
      begin
        Result:= True;
        retContID:= hotKeys[i].action;
        break;
      end;
end;

procedure TuHost2.activateHK(hkID: SmallInt);
var
	i: SmallInt;
begin
	if (hkID >= 200) AND (hkID < 300) then
	  for i:= 0 to High(statusTS.sector_checkbox) do
  	  	statusTS.sector_checkbox[i].Checked:= True;
  case hkID of
// Andmete värskendamine
// status tab
    200: cpTpg.ActivePageIndex:= 0; // Show Status
    201: statusTs.st_refreshB.Click; // Refresh Status
    202: 
        begin
          cpTpg.ActivePageIndex:= 0;
          statusTs.st_refreshB.Click;
        end;
    203: 
      begin
        for i:= 1 to High(statusTS.sector_checkbox) do
            statusTS.sector_checkbox[i].Checked:= False;
        statusTs.st_refreshB.Click;
      end;
    204: 
      begin
        for i:= 0 to High(statusTS.sector_checkbox) do
          if (i <> 1) then
            statusTS.sector_checkbox[i].Checked:= False
          else
            statusTS.sector_checkbox[i].Checked:= True;
          statusTs.st_refreshB.Click;
      end;
    205: 
      begin
        for i:= 0 to High(statusTS.sector_checkbox) do
          if (i <> 2) then
            statusTS.sector_checkbox[i].Checked:= False
          else
            statusTS.sector_checkbox[i].Checked:= True;
          statusTs.st_refreshB.Click;
      end;
    206: 
      begin
        for i:= 0 to High(statusTS.sector_checkbox)-1 do
          statusTS.sector_checkbox[i].Checked:= False;
        statusTs.st_refreshB.Click;
      end;

// Adv. LQ tab
    300: cpTpg.ActivePageIndex:= 1; // Show Adv. LQ
    301: alqTs.alq_button[0].Click;
    302: 
        begin
          cpTpg.ActivePageIndex:= 1;
          alqTs.alq_button[0].Click;
        end;       
// Misc tab
    400: cpTpg.ActivePageIndex:= 2; // Show Misc
    401: miscTS.updateMiscTab;
    402:
        begin
          cpTpg.ActivePageIndex:= 2;
          miscTS.updateMiscTab;
        end;
    403: miscTS.pf_button[2].Click;
    404: miscTS.voip_update.Click;
    405: miscTS.vm_button[1].Click;

// Other shortcuts
    500:
      begin
        statusTs.st_refreshB.Click;
        alqTs.alq_button[0].Click;
        miscTS.updateMiscTab;
      end;
    501: 
      begin
        statusTs.sendLogData;
        logText.SelectAll;
        logText.CopyToClipboard;
      end;
  end;
end;


{****************************************************
                  CONNECTION MANAGER
****************************************************}

procedure TuHost2.sitePresetBClick(Sender: TObject);
var
  pt: TPoint;
begin
  try
    pt.X:= siteManagerB.Left;
    pt.Y:= siteManagerB.Top + siteManagerB.Height;
    pt:= ClientToScreen(pt);
    siteManagerPM.Popup(pt.X, pt.Y);
  except on E:Exception do
    WriteErrorLog('Error @quickConnectB: ' + E.Message);
  end;
end;


procedure TuHost2.valmistaSites;
const
  smComboLogin: array[0..3] of string = (
      'Helpdesk account', 'Normal account',
      'Ask for password', 'Interactive'
  );

  smLabelNimi: array[0..10] of string = (
    'Logon type:', 'Username:', 'Password:',
    'Host address:', 'Port:', 'COM:', 'b/sec:',
    'Data:', 'Parity:', 'Stop:',
    'Flow:'
  );

  tsLabelNimi: array[0..5] of string = (
    'COM ', 'bps ', 'Data ', 'Parity ', 'Stop ', 'Flow ');

  tsComboWidth: array[0..6] of SmallInt = (
    0, 40, 62, 40, 57, 40, 80);

  smLabelHint: array[0..10] of string = (
    'Authenication type', 'Username', 'Password',
    'IP address or host name', '', 'COM line', 'Bits per second',
    'Data bits', 'Parity', 'Stop bits',
    'Flow control'
  );
  smComboParity: array[0..4] of string = (
    'Even', 'Odd', 'None', 'Mark', 'Space'
  );

  smComboFlow: array[0..3] of string = (
    'XON/XOFF', 'None', 'RTS/CTS', 'DTR/DSR'
  );
var
  i, j: SmallInt;
  kordaja: LongWord;
begin
{ smLabel = TLabel:
  0: logontype
  1: username
  2: password
  3: host
  4: port
  5: COM
  6: Bits per second
  7: Data bits
  8: Parity
  9: stop bits
  10: flow control
}
  try
    j:= 0;
    for i:= 0 to Length(smLabel)-1 do
      begin
        smLabel[i]:= TLabel.Create(nil);
        smLabel[i].Parent:= conInfoP;
        smLabel[i].AutoSize:= False;
        smLabel[i].Layout:= tlCenter;
        if (i > 2) then
          begin
            j:= 10;
            smLabel[i].ShowHint:= True;
          end;
        smLabel[i].Left:= 5;
        smLabel[i].Top:= (i * 23) + 35 + j;
        smLabel[i].Height:= 20;
        smLabel[i].Width:= 65;
        smLabel[i].Caption:= smLabelNimi[i];
        smLabel[i].Visible:= True;
        smLabel[i].Hint:= smLabelHint[i];
      end;
  except on E:Exception do
    WriteErrorLog('Exception @ valimistaSites 1: ' + E.Message);
  end;

// telnet/serial connector
  try
    for i:= 0 to Length(tsLabel)-1 do
      begin
        tsLabel[i]:= TLabel.Create(nil);
        tsLabel[i].Parent:= uHost2;
        if (i = 0) then
          j:= (selectSerial.Left + selectSerial.Width + 5)
        else
          j:= tsLabel[i-1].Left + tsLabel[i-1].Width + tsComboWidth[i] + 5;
        tsLabel[i].Left:= j;
        tsLabel[i].Top:= 6;
        tsLabel[i].Height:= 20;
        tsLabel[i].Caption:= tsLabelNimi[i];
        tsLabel[i].Visible:= False;
        tsLabel[i].ShowHint:= True;
        tsLabel[i].Hint:= smLabelHint[i+5];
        tsLabel[i].Font.Style:= tsLabel[i].Font.Style + [fsBold];
      end;
  except on E:Exception do
    WriteErrorLog('Exception @ valmistaSites 1.2: ' + E.Message);
  end;


  try
    for i:= 0 to Length(tsCombobox)-1 do
      begin
        tsCombobox[i]:= TCombobox.Create(nil);
        tsCombobox[i].Parent:= uHost2;
        tsCombobox[i].Top:= 2;
        tsCombobox[i].Left:= tsLabel[i].Left + tsLabel[i].Width;
        tsCombobox[i].Width:= tsComboWidth[i+1];
        tsCombobox[i].Style:= csDropDownList;
        tsCombobox[i].Visible:= False;
        tsCombobox[i].ShowHint:= True;
        tsCombobox[i].Hint:= smLabelHint[i+5];
        tsCombobox[i].TabOrder:= i + 2;
      end;
    tsCombobox[1].DropDownCount:= 15;
  except on E:Exception do
    WriteErrorLog('Exception @ valmistaSites 1.2: ' + E.Message);
  end;

// end of telnet/serial connector

{
smEdit = TEdit:
  0: Username
  1: Password
  2: Host address
  3: Password
}

  try
    for i:= 0 to Length(smEdit)-1 do
      begin
        smEdit[i]:= TEdit.Create(nil);
        smEdit[i].Parent:= conInfoP;
        smEdit[i].Left:= 75;
        smEdit[i].Height:= 20;
        smEdit[i].Width:= 175;
        smEdit[i].Visible:= True;
        smEdit[i].Tag:= i;
        smEdit[i].OnExit:= onExitSmElement;
      end;
    smEdit[1].PasswordChar:= '*';
  except on E:Exception do
    WriteErrorLog('Exception @ valmistaSites 2: ' + E.Message);
  end;

{
smCombobox = TCombobox:
  0: logon type
  1: COM tüüp
  2: Bits per second
  3: Data bits
  4: Parity
  5: Stop bits
  6: Flow control
}

  try
    for i:= 0 to Length(smCombobox)-1 do
      begin
        smCombobox[i]:= TComboBox.Create(nil);
        smCombobox[i].Parent:= conInfoP;
        smCombobox[i].Left:= 75;
        smCombobox[i].Width:= 175;
        smCombobox[i].Style:= csDropDownList;
        smCombobox[i].Visible:= False;
        smCombobox[i].Tag:= i;
        smCombobox[i].OnExit:= onExitSmElement;
        smCombobox[i].OnChange:= activSaveB;
      end;
  except on E:Exception do
    WriteErrorLog('Exception @ valmistaSites 3: ' + E.Message);
  end;


  try
    smComboBox[0].Visible:= True; // Logontype
    smCombobox[0].Top:= smLabel[0].Top;
    smEdit[0].Top:= smLabel[1].Top; // Username
    smEdit[1].Top:= smLabel[2].Top; // Password
//    smEdit[1].PasswordChar:= '*';

// Host
    smEdit[2].Top:= smLabel[3].Top;
    smEdit[2].Width:= 100;

// Port
    smLabel[4].Top:= smLabel[3].Top;
    smLabel[4].Width:= 25;
    smLabel[4].Left:= smEdit[2].Width + smEdit[2].Left + 5;
    smEdit[3].Top:= smLabel[3].Top;
    smEdit[3].Width:= 45;
    smEdit[3].Left:= smLabel[4].Width + smLabel[4].Left;
  except on E:Exception do
    WriteErrorLog('Exception @ settings valus for smElements 1: ' + E.Message);
  end;

// Serial
  try
    for i:= 5 to 10 do
      begin
        smLabel[i].Width:= 30;
        smLabel[i].Left:= ((i-1) mod 2) * (smLabel[i].Width + 95) + 5;
        smLabel[i].Top:= ((i+1) div 2) * 23 + 45;
        smLabel[i].Visible:= False;
        smCombobox[i-4].Top:= smLabel[i].Top;
        smCombobox[i-4].Left:= smLabel[i].Width + smLabel[i].Left + 5;
        smCombobox[i-4].Width:= 85;
        smCombobox[i-4].Visible:= False;
      end;
  except on E:Exception do
    WriteErrorLog('Exception @ settings valus for smElements 2: ' + E.Message);
  end;

  for i:= 0 to Length(smComboLogin)-1 do
    smCombobox[0].Items.Add(smComboLogin[i]);

  smCombobox[1].Items.Add('COM1');
  tsCombobox[0].Items.Add('1');
  smCombobox[1].Items.Add('COM3');
  tsCombobox[0].Items.Add('3');

  smCombobox[2].Items.Add('111');
  tsCombobox[1].Items.Add('111');
  smCombobox[2].Items.Add('300');
  tsCombobox[1].Items.Add('300');

  kordaja:= 1200;
  for i:= 0 to 5 do
    begin
      smCombobox[2].Items.Add(IntToStr(kordaja));
      tsCombobox[1].Items.Add(IntToStr(kordaja));
      kordaja:= kordaja * 2;
    end;
  kordaja:= 57600;
  for i:= 0 to 4 do
    begin
      smCombobox[2].Items.Add(IntToStr(kordaja));
      tsCombobox[1].Items.Add(IntToStr(kordaja));
      kordaja:= kordaja * 2;
    end;

  for i:= 5 to 8 do
    begin
      smCombobox[3].Items.Add(IntToStr(i));
      tsCombobox[2].Items.Add(IntToStr(i));
    end;

  for i:= 0 to 4 do
    begin
      smCombobox[4].Items.Add(smComboParity[i]);
      tsCombobox[3].Items.Add(smComboParity[i]);
    end;

  for i:= 1 to 2 do
    begin
      smCombobox[5].Items.Add(IntToStr(i));
      tsCombobox[4].Items.Add(IntToStr(i));
    end;

  for i:= 0 to 3 do
    begin
      smCombobox[6].Items.Add(smComboFlow[i]);
      tsCombobox[5].Items.Add(smComboFlow[i]);
    end;

  resetSiteManager;
  smCombobox[0].OnChange:= smLoginType;
  smDescMemo.OnExit:= onExitSmElement;

  siteManagerB.Glyph:= nil;
  quickConnectB.Glyph:= nil;
  sitePresetB.Glyph:= nil;

  smImageList.GetBitmap(2, siteManagerB.Glyph);
  smImageList.GetBitmap(3, quickConnectB.Glyph);
  smImageList.GetBitmap(3, sitePresetB.Glyph);
  sitePresetB.Layout:= blGlyphBottom;
  quickConnectB.Layout:= blGlyphBottom;
end;

// END OF valmistaSites

// Set to default siteManager objects
procedure TuHost2.resetSiteManager;
begin
  telnetRB.Checked:= True;
  smEdit[0].Text:= 'helpdesk';
  smEdit[1].Text:= 'helpdesk';
  smEdit[2].Clear;
  smEdit[3].Text:= '23';
  smCombobox[0].ItemIndex:= 0;
  smCombobox[1].ItemIndex:= 0;
  smCombobox[2].ItemIndex:= 5;
  smCombobox[3].ItemIndex:= smCombobox[3].Items.Count-1;
  smCombobox[4].ItemIndex:= 2;
  smCombobox[5].ItemIndex:= 0;
  smCombobox[6].ItemIndex:= 1;
  smDescMemo.Clear;
end;

procedure TuHost2.smLoginType(Sender: TObject);
begin
  if (Sender is TCombobox) then
    begin
      smEdit[0].Clear;
      smEdit[1].Clear;
      disGray(smEdit[0], True);
      disGray(smEdit[1], True);
      smLoginHandler(TCombobox(Sender).ItemIndex);
    end;
end;

procedure TuHost2.smLoginHandler(tyyp: SmallInt);
begin
  case tyyp of
    0:
      begin
        smEdit[0].Enabled:= False;
        smEdit[1].Enabled:= False;
        smEdit[0].Text:= 'helpdesk';
        smEdit[1].Text:= 'helpdesk';
      end;
    1:
      begin
        disGray(smEdit[0], True);
        disGray(smEdit[1], True);
      end;
    2:
      begin
        smEdit[0].Enabled:= True;
        disGray(smEdit[1], False);
      end;
    3:
      begin
        disGray(smEdit[0], False);
        disGray(smEdit[1], False);
      end;
  end;
end;

procedure TuHost2.smDescMemoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  smDescCnt.Caption:= '255/' + IntToStr(255 - smDescMemo.GetTextLen);
end;

// kas aktiveerime telneti või seriali komponente?
procedure TuHost2.telnetOrSerial(telnet: boolean);
var
  i, peitus: SmallInt;
begin
  if telnet then
    peitus:= 5
  else
    peitus:= 0;

  for i:= 3 to 4 do
    begin
      smLabel[i].Visible:= telnet;
      ShowWindow(smEdit[i-1].Handle, peitus);
    end;

  for i:= 1 to 6 do
    begin
      smLabel[i+4].Visible:= NOT telnet;
      ShowWindow(smCombobox[i].Handle, 5 - peitus);
    end;

end;

procedure TuHost2.telnetRBClick(Sender: TObject);
begin
  try
    telnetOrSerial(True);
  except on E:Exception do
    WriteErrorLog('Exception @ telnetRB: ' + E.Message);
  end;
end;

procedure TuHost2.serialRBClick(Sender: TObject);
begin
  try
    telnetOrSerial(False);
  except on E:Exception do
    WriteErrorLog('Exception @ telnetRB: ' + E.Message);
  end;
end;

procedure TuHost2.loadSites;
var
  i: SmallInt;
  smLaps  : SmallInt; // is Node group or host
  smGrpId : SmallInt; // objekti ID ehk mis gruppi alla ta kuulub
  fNode   : TTreeNode; // first Node
  tNode   : TTreeNode; // loadup Node's
begin
  siteManagerTV.Items.Clear;
  deleteSiteB.Enabled:= False;
  renameSiteB.Enabled:= False;
  
  fNode:= siteManagerTV.Items.AddFirst(nil, 'My connections');
  fNode.SelectedIndex:= 0;
  fNode.ImageIndex:= 0;
  fNode.Selected:= True;
  lockSiteElements(False);
  SetLength(siteManager, 0); // nullime siteManager list, seejärel laeme nimekiri failist

  AssignFile(siteFile, userPath + smFile);
  try
    if (FileExists(userPath + smFile)) then
      begin
        Reset(siteFile);
        for i:= 0 to FileSize(siteFile)-1 do
          begin
            SetLength(siteManager, i+1);
            Read(siteFile, siteManager[i]);

            // juhul kui smGrpId ei ole number siis viskame ta root gruppi alla
            try
              smGrpId:= siteManager[i].smGrpId;
            except
              smGrpId:= 0;
            end;

            fNode:= siteManagerTV.Items[smgrpid];
            smLaps:= siteManager[i].smChild;
            tNode:= siteManagerTV.Items.AddChild(fNode, siteManager[i].smName);
            tNode.Data:= Pointer(siteManager[i].smID);
            fNode.Expanded:= True;
            tNode.Expanded:= True;
            tNode.ImageIndex:= smLaps;
            tNode.SelectedIndex:= smLaps;
          end;
      end
    else
      ReWrite(siteFile);
  finally
    CloseFile(siteFile);
  end;

// siteManager data listing
  SetLength(siteData, 0); // nullime siteManager data list, seejärel laeme nimekiri failist
  AssignFile(siteDataFile, userPath + smDFile);
  try
    if (FileExists(userPath + smDFile)) then
      begin
        Reset(siteDataFile);
        for i:= 0 to FileSize(siteDataFile)-1 do
          begin
            SetLength(siteData, i+1);
            Read(siteDataFile, siteData[i]);
          end;
      end
    else
      ReWrite(siteDataFile);
  finally
    CloseFile(siteDataFile);
  end;
end;

procedure TuHost2.loadSitesFromTV(clear: boolean = False);
var
  smCnt   : SmallInt; // SiteManager counter
  i       : SmallInt;
  tNode   : TTreeNode;
  smItem  : TMenuItem; // PopupMenu object
  subItem : TMenuItem; // PopupMenu submenu object
begin
  try
  // siteManagerPM tühjendamine
    for i:= siteManagerPM.Items.Count-1 downto 0 do
      siteManagerPM.Items.Delete(i);

    SetLength(siteManager, 0);
    for i:= 1 to siteManagerTV.Items.Count-1 do
      begin
        tNode:= siteManagerTV.Items[i];
        smCnt:= Length(siteManager);
        Setlength(siteManager, smCnt+1);
        with siteManager[smCnt] do
          begin
            smName:= tNode.Text;
            smGrpId:= tNode.Parent.AbsoluteIndex;
            smLevelId:= tNode.Level;
            smID:= integer(tNode.Data);
            smChild:= tNode.ImageIndex;
          end;
      // end of siteManagerTV population

        smItem:= TMenuItem.Create(Self);
        smItem.Caption:= tNode.Text;
        smItem.Tag:= integer(tNode.Data);

        if (tNode.ImageIndex = 0) then // kas tegemist on grupp või site'ga
          smItem.ImageIndex:= tNode.ImageIndex
        else if (tNode.ImageIndex = 1) then
          smItem.OnClick:= smConnect;

        if (tNode.Parent.Level = 0) then // kui on 0 siis tegemist on esimese leveli objektiga
          siteManagerPM.Items.Add(smItem)
        else // vastasel juhul tee submenu ja lisa objekt sinna
          begin
            subItem:= findMenuItem(siteManagerPM.Items, tNode.Parent.Text);
            if (subItem <> nil) then
              subItem.Add(smItem);
          end;
      end;
  except on E:Exception do
    WriteErrorLog('Exception @ newSites: + ' + E.Message);
  end;
end;

procedure TuHost2.siteManagerTVClick(Sender: TObject);
var
  tNode: ttreenode;
  i: SmallInt;
begin
  resetSiteManager;
  tNode:= siteManagerTV.Selected;
  smActiveNode:= -1;
  for i:= 0 to Length(siteData)-1 do
    if (integer(tNode.Data) = siteData[i].smID) then
      begin
        smActiveNode:= i;
        break;
      end;

  if (Assigned(tNode)) then
    begin
      if tNode.ImageIndex = 0 then
        lockSiteElements(False)
      else
        begin
          lockSiteElements(True);
          if (siteData[smActiveNode].smType = 1) then
            begin
              telnetRB.Checked:= True;
              serialRB.Checked:= False;
            end;
          if (siteData[smActiveNode].smType = 2) then
            begin
              telnetRB.Checked:= False;
              serialRB.Checked:= True;
            end;

          smDescMemo.Text:= siteData[smActiveNode].smDesc;
          smCombobox[0].ItemIndex:= siteData[smActiveNode].smLogin;
          smLoginHandler(siteData[smActiveNode].smLogin);
          smEdit[0].Text:= siteData[smActiveNode].smUser;
          try
            smEdit[1].Text:= decStr(siteData[smActiveNode].smPswd)
          except
            smEdit[1].Text:= '';
          end;
          smEdit[2].Text:= siteData[smActiveNode].smHost;
          smEdit[3].Text:= IntToStr(siteData[smActiveNode].smPort);
          smCombobox[1].ItemIndex:= siteData[smActiveNode].smCom;
          smCombobox[2].ItemIndex:= siteData[smActiveNode].smBps;
          smCombobox[3].ItemIndex:= siteData[smActiveNode].smData;
          smCombobox[4].ItemIndex:= siteData[smActiveNode].smPar;
          smCombobox[5].ItemIndex:= siteData[smActiveNode].smStop;
          smCombobox[6].ItemIndex:= siteData[smActiveNode].smFlow;
        end; // Index <> 0
    end; // Assigned
//    
// root elementi ei tohi kustutada ega ümber nimetada
  deleteSiteB.Enabled:= tNode <> siteManagerTV.Items[0];
  renameSiteB.Enabled:= tNode <> siteManagerTV.Items[0];
end;

procedure TuHost2.siteManagerTVDblClick(Sender: TObject);
begin
  if siteConB.Enabled then
    siteConB.Click;
end;

{******* siteManager add *********}


procedure TuHost2.newSiteBClick(Sender: TObject);
var
  tNode, vanemNode: TTreeNode;
  smith: integer;
  sdCnt: SmallInt;
begin
  if (siteManagerTV.Selected <> nil) then
    begin
      resetSiteManager;
      lockSiteElements(True);
      if siteManagerTV.Selected.ImageIndex = 0 then
        vanemNode:= siteManagerTV.Selected
      else
        vanemNode:= siteManagerTV.Selected.Parent;

      tNode:= siteManagerTV.Items.AddChild(vanemNode, 'New host' + inttostr(sitemanagertv.Items.Count));

      tNode.ImageIndex:= 1;
      tNode.SelectedIndex:= 1;
      smith:= generateObjId;
      tNode.Data:= Pointer(smith);

      sdCnt:= Length(siteData);
      SetLength(siteData, sdCnt+1);
      with siteData[sdCnt] do
        begin
          smID:= smith;
          smLogin:= smCombobox[0].ItemIndex;
          smType:= 1;
          smDesc:= smDescMemo.Text;
          smUser:= smEdit[0].Text;
          smPswd:= encStr(smEdit[1].Text);
          smHost:= smEdit[2].Text;
          smPort:= StrToInt(smEdit[3].Text);
          smCom:= smCombobox[1].ItemIndex;
          smBps:= smCombobox[2].ItemIndex;
          smData:= smCombobox[3].ItemIndex;
          smPar:= smCombobox[4].ItemIndex;
          smStop:= smCombobox[5].ItemIndex;
          smFlow:= smCombobox[6].ItemIndex;
        end;

      smActiveNode:= sdCnt;
      siteManagerTV.Selected.Expanded:= True;
      tNode.EditText;
      tNode.Selected:= True;
      loadSitesFromTV;
      siteSaveB.Enabled:= True;
    end
  else
    Application.MessageBox('Select group', 'Laiskuss annab teada', MB_ICONINFORMATION);
end;

procedure TuHost2.newGroupBClick(Sender: TObject);
var
  tNode, vanemNode: TTreeNode;
begin
  if (siteManagerTV.Selected <> nil) then
    begin
      resetSiteManager;
      lockSiteElements(False);
      if siteManagerTV.Selected.ImageIndex = 0 then
        vanemNode:= siteManagerTV.Selected
      else
        vanemNode:= siteManagerTV.Selected.Parent;

      tNode:= siteManagerTV.Items.AddChildFirst(vanemNode, 'New group' + inttostr(sitemanagertv.Items.Count));
      tNode.ImageIndex:= 0;
      tNode.SelectedIndex:= 0;
      tNode.Data:= Pointer(-1);
      siteManagerTV.Selected.Expanded:= True;

      tNode.EditText;
      tNode.Selected:= True;
      loadSitesFromTV;
      siteSaveB.Enabled:= True;
    end
  else
    Application.MessageBox('Select group', 'Laiskuss annab teada', MB_ICONINFORMATION);
end;

procedure TuHost2.siteManagerTVAddition(Sender: TObject; Node: TTreeNode);
begin
end;

{******* siteManager change *********}

procedure TuHost2.renameSiteBClick(Sender: TObject);
begin
  siteManagerTV.Selected.EditText;
  siteSaveB.Enabled:= True;
end;

procedure TuHost2.siteManagerTVEditing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
  AllowEdit:= Node <> siteManagerTV.Items[0];
end;

procedure TuHost2.siteManagerTVEdited(Sender: TObject; Node: TTreeNode;
  var S: String);
begin
  try
    siteManager[Node.AbsoluteIndex-1].smName:= S;
  except on E:Exception do
    WriteErrorLog('Exception @ sm Item edit: ' + E.Message);
  end;
end;


{******* siteManager delete *********}

procedure TuHost2.deleteSiteBClick(Sender: TObject);
var
  i, j: SmallInt;
  dummyData: TSmData;
  foundID: integer;
  smdCnt: SmallInt; // siteManager data record counter
begin
  Exit;
  try
    siteManagerTV.Selected.Delete;
    loadSitesFromTV(True);
    siteSaveB.Enabled:= True;
  except on E:Exception do
    WriteErrorLog('Exception @ deleteSite: ' + E.Message);
  end;

// Renew siteManager data record
  try
    AssignFile(siteDataFile, userPath + smDFile);
    SetLength(siteData, 0);
    try
      if (FileExists(userPath + smDFile)) then
        begin
          Reset(siteDataFile);
          for i:= 0 to FileSize(siteDataFile)-1 do
            begin
              foundID:= 0;
              Read(siteDataFile, dummyData);
              for j:= 0 to Length(siteManager)-1 do
                if (dummyData.smID = siteManager[j].smID) then
                  begin
                    foundID:= siteManager[j].smID;
                    break;
                  end;
              if (foundID <> 0) then
                begin
                  smdCnt:= Length(siteData);
                  SetLength(siteData, smdCnt+1);
                  siteData[smdCnt]:= dummyData;
                end; // end of smID equal
            end; // end for i loop
        end // end if filexists
      else
        ReWrite(siteDataFile);
    finally
      CloseFile(siteDataFile);
    end; // end try finally block
  except on E:Exception do
    WriteErrorLog('Exception @ deleteSite data: ' + E.Message);
  end; // end try except block
end;

procedure TuHost2.siteConBClick(Sender: TObject);
var
  conType: string;
  i: SmallInt;
begin
  Exit;
  loginType:= 0;

  loginType:= smCombobox[0].ItemIndex;

  uUserEdit.Text:= smEdit[0].Text;
  uPassEdit.Text:= smEdit[1].Text;
  if (telnetRB.Checked) then
    begin
      if (autoCB.Checked) then
        begin
          if (conType <> '') then
            begin
              if (MessageDlg(conType + ' connection is active, disconnect?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
                  uCon.Click
              else
                Exit;
            end;// end of conType
          uHostEdit.Text:= smEdit[2].Text;
          uPortEdit.Text:= smEdit[3].Text;
          selectTelnet.Checked:= True;
          siteManagerB.Click;
          Sleep(50);
          uCon.Click;
        end // end if autoCB
      else
        begin
          uHostEdit.Text:= smEdit[2].Text;
          uPortEdit.Text:= smEdit[3].Text;
          selectTelnet.Checked:= True;
          siteManagerB.Click;
        end;
    end // end if telnetRb checked
  else if serialRB.Checked then
    begin
      if (autoCB.Checked) then
        begin
          if (conType <> '') then
            begin
              if (MessageDlg(conType + ' connection is active, disconnect?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
                uCon.Click
              else
                Exit;
            end;// end of conType

          for i:= 0 to 5 do
            tsCombobox[i].ItemIndex:= smCombobox[i+1].ItemIndex;
          selectSerial.Checked:= True;
          siteManagerB.Click;
          Sleep(50);
          uCon.Click;
        end // end if autoCB
      else
        begin
          for i:= 0 to 5 do
            tsCombobox[i].ItemIndex:= smCombobox[i+1].ItemIndex;
          selectSerial.Checked:= True;
          siteManagerB.Click;
        end;
    end; // end if serialRB
end;

procedure TuHost2.siteSaveBClick(Sender: TObject);
var
  i: SmallInt;
begin
  Exit;
  AssignFile(siteFile, userPath + smFile);
  try
    try
      Rewrite(siteFile);
      for i:= 0 to Length(siteManager)-1 do
        Write(siteFile, siteManager[i]);
    except on E:Exception do
      WriteErrorLog('Exception @ siteSave: ' + E.Message);
    end;
  finally
    CloseFile(siteFile);
  end;

  AssignFile(siteDataFile, userPath + smdFile);
  try
    try
    ReWrite(siteDataFile);
    for i:= 0 to Length(siteData)-1 do
      Write(siteDataFile, siteData[i]);
    except on E:Exception do
      WriteErrorLog('Exception @ siteDataSave: ' + E.Message);
    end;
  finally
    siteSaveB.Enabled:= False;
    CloseFile(siteDataFile);
  end;
end;

procedure TuHost2.siteCloseBClick(Sender: TObject);
begin
  loadSites; // laeme kõik andmed failist, selleks, et ülejäägid ejectida
  siteManagerB.Click;
end;

procedure TuHost2.lockSiteElements(seisund: boolean);
var
  i: SmallInt;
begin
  Exit;
  for i:= 0 to High(smLabel) do
    smLabel[i].Enabled:= seisund;
  for i:= 0 to High(smEdit) do
    disGray(smEdit[i], seisund);
  for i:= 0 to High(smCombobox) do
    disGray(smCombobox[i], seisund);
  disGray(smDescMemo, seisund);
  telnetRB.Enabled:= seisund;
  serialRB.Enabled:= seisund;
  siteConB.Enabled:= seisund;
end;


procedure TuHost2.onExitSmElement(Sender: TObject);
begin
  Exit;
  with siteData[smActiveNode] do
    begin
      smLogin:= smCombobox[0].ItemIndex;
      smUser:= smEdit[0].Text;
      if (Length(smEdit[1].Text) > 0) then
        smPswd:= encStr(smEdit[1].Text)
      else
        smPswd:= '';
      smDesc:= smDescMemo.Text;
    end;
  if (telnetRB.Checked) then
    begin
      with siteData[smActiveNode] do
        begin
          smType:= 1;
          smHost:= smEdit[2].Text;
          smPort:= StrToInt(smEdit[3].Text);
        end;
    end
  else
    begin
      with siteData[smActiveNode] do
        begin
          smCom:= smCombobox[1].ItemIndex;
          smBps:= smCombobox[2].ItemIndex;
          smData:= smCombobox[3].ItemIndex;
          smPar:= smCombobox[4].ItemIndex;
          smStop:= smCombobox[5].ItemIndex;
          smFlow:= smCombobox[6].ItemIndex;
        end;
    end;
  siteSaveB.Enabled:= True;
end;

procedure TuHost2.smConnect(Sender: TObject);
var
  i, siteID: SmallInt;
  conType: string;
begin
  loginType:= 0;
  Exit;
  if Sender is TMenuItem then
    begin
      siteID:= -1;
      for i:= 0 to Length(siteData)-1 do
        begin
          if (TMenuItem(Sender).Tag = siteData[i].smID) then
            begin
              siteID:= i;
              break;
            end;
        end;
      if (siteID >= 0) then
        begin
        // kontrollime, kas on aktiivseid ühednusi, kui jah siis promptime enne disconnecti
          if is_connection_alive then
            conType:= 'Telnet';

          // login andmed ei sõltu ühenduse tüübist, seega lisame koheselt
          loginType:= siteData[siteID].smLogin;
          uHostEdit.Text:= siteData[siteID].smHost;
          uPortEdit.Text:= IntToStr(siteData[siteID].smPort);

          // kui tegemist on telnetiga
          if (siteData[siteID].smType = 1) then
            begin
              selectTelnet.Checked:= True;
              uUserEdit.Text:= siteData[siteID].smUser;
              uPassEdit.Text:= decStr(siteData[siteID].smPswd);
              if (autoCB.Checked) then
                begin
                  if (conType <> '') then
                    begin
                      if (MessageDlg(conType + ' connection is active, disconnect?',
                        mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
                        uCon.Click
                      else
                        Exit;
                    end;// end of conType
                  Sleep(50);
                  uCon.Click;
                end; // end of autoCB

            end //end if smType = 1
          else if (siteData[siteID].smType = 2) then
            begin
              selectSerial.Checked:= True;
              uUserEdit.Text:= siteData[siteID].smUser;
              uPassEdit.Text:= decStr(siteData[siteID].smPswd);
              tsCombobox[0].ItemIndex:= siteData[siteID].smCom;
              tsCombobox[1].ItemIndex:= siteData[siteID].smBps;
              tsCombobox[2].ItemIndex:= siteData[siteID].smData;
              tsCombobox[3].ItemIndex:= siteData[siteID].smPar;
              tsCombobox[4].ItemIndex:= siteData[siteID].smStop;
              tsCombobox[5].ItemIndex:= siteData[siteID].smFlow;
              if (autoCB.Checked) then
                begin
                  if (conType <> '') then
                    begin
                      if (MessageDlg(conType + ' connection is active, disconnect?',
                        mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
                        uCon.Click
                      else
                        Exit;
                    end;// end of conType
                  Sleep(50);
                  uCon.Click;
                end; // end of autoCB
            end; // end of smType = 2
        end // end if siteID
      else
        Application.MessageBox('No data was found!', 'Laiskuss annab teada', MB_ICONERROR);
    end;
end;

// TPopupMenu objekti otsimine (submenu'de olemasolul) caption alusel,
// tagastatakse TMenuItem objekti
function TuHost2.findMenuItem(vanem: TMenuItem; otsi: string): TMenuItem;
var
  search: TMenuItem;
  i: smallint;
begin
  search:= nil;
  for i:= 0 to vanem.Count-1 do
    begin
      if (vanem.Items[i].Caption = otsi) then
        begin
          search:= vanem.Items[i];
          break;
        end;
      if (vanem.Items[i].Count > 0) then
        search:= findMenuItem(vanem.Items[i], otsi);
    end;
  Result:= search;
end;

procedure TuHost2.activSaveB(Sender: TObject);
begin
  if Sender is TCombobox then
    siteSaveB.Enabled:= True;
end;


{****************************************************
                  ROUTER LOG DATA
****************************************************}

procedure TuHost2.cpe_logClick(Sender: TObject);
var
  Flags: DWORD;
  Handle: HWND;
begin
  Handle:= logPanel.Handle;
  if isLogOpen then
    begin
      Flags:= AW_HIDE OR AW_VER_NEGATIVE;
    end
  else
    begin
      Flags:= AW_ACTIVATE OR AW_VER_POSITIVE;
      logText.Clear;
      statusTs.sendLogData;
    end;

  isLogOpen:= NOT isLogOpen;
  Flags:= Flags OR AW_SLIDE;
  AnimateWindow(Handle, 100, Flags);

  logPanel.Invalidate;
end;

procedure TuHost2.logRefreshBClick(Sender: TObject);
begin
  logText.Clear;
  statusTs.sendLogData;
  if (logText.CanFocus) then
    logText.SetFocus;
end;

procedure TuHost2.logCopyBClick(Sender: TObject);
begin
  logText.SelectAll;
  logText.CopyToClipboard;
end;

procedure TuHost2.logCloseBClick(Sender: TObject);
begin
  cpe_log.Click;
end;

{*******************************************************************************
                                    SSH
********************************************************************************}

procedure TuHost2.RequestLoginData;
var
	laiskuss_agent: HWND;
  copyStruct: TCopyDataStruct;
begin
  // make sure agent is running
  laiskuss_agent:= FindWindow(PAnsiChar('TaHost'), 'valmis');
  if laiskuss_agent <> 0 then
    begin
      with copyStruct do
        begin
          dwData:= 0;
          cbData:= SizeOf(ssh_auth_data);
          lpData:= @ssh_auth_data;
        end;
      SendMessage(laiskuss_agent, WM_COPYDATA, Handle, LongInt(@copyStruct));
    end;
end;

// receive data from agent
procedure TuHost2.WMCopyData(var M: TMessage);
var
	ss: TSshAuthData;
begin
	ss:= PSshAuthData(PCopyDataStruct(M.LParam)^.lpData)^;
  ssh_auth_data:= ss;
end;

function TuHost2.is_connection_alive(test_for_ssh_only: boolean = False): boolean;
var
  ret_val: boolean;
begin
  case connection_type of
    TELNET: ret_val:= uTelnet.Connected;
    SSH:
      begin
        if test_for_ssh_only then
          ret_val:= ssh_client.Sock.CanWrite(0)
        else
          ret_val:= ssh_client.Sock.CanWrite(0) AND isTelnetOverSshOpen;
      end;
    SERIAL: ret_val:= is_com_port_open;
    else
      ret_val:= False;
  end;
  Result:= ret_val;
end;

procedure TuHost2.write_to_terminal(in_val: string; receiver_id: byte = 1);
begin
  try
  if receiver_id = 1 then
    whereDoYouGo:= 1
  else if receiver_id = 2 then
    begin
      dataBuffer.Clear;
      whereDoYouGo:= 2;
    end;

  case connection_type of
    TELNET: uTelnet.IOHandler.Write(in_val);
    SSH: ssh_client.Sock.SendString(in_val);
  end;
  except on E:Exception do
    ShowMessage('writer ' + E.Message);
  end;
end;

procedure TuHost2.writeLn_to_terminal(in_val: string; receiver_id: byte = 1);
begin
  write_to_terminal(in_val + #13, receiver_id);
end;

procedure TuHost2.write_inner_buffer(const Buffer: string);
const
  CR = #13;
  LF = #10;
var
  Start, Stop: Integer;
  s: string;
  lastLine: string;
begin
  lastLine:= '';
  if dataBuffer.Count = 0 then dataBuffer.Add('');
  Start := 1;
  Stop  := Pos(CR, Buffer);
  if Stop = 0 then
      Stop := Length(Buffer) + 1;
  while Start <= Length(Buffer) do
    begin
      dataBuffer.Strings[dataBuffer.Count - 1] :=
          dataBuffer.Strings[dataBuffer.Count - 1] +
          Copy(Buffer, Start, Stop - Start);
          s:= Copy(Buffer, Start, Stop - Start);
      if Buffer[Stop] = CR then
        begin
          dataBuffer.Add('');
        end;
      Start := Stop + 1;
      if Start > Length(Buffer) then
          Break;
      if Buffer[Start] = LF then
         Start := Start + 1;
      Stop := Start;
      while (Buffer[Stop] <> CR) and (Stop <= Length(Buffer)) do
          Stop := Stop + 1;
    end;

  if dataBuffer.Count > 0 then
    lastLine:= Trim(dataBuffer.Strings[dataBuffer.Count - 1]);

  if lastLine = '{helpdesk}=>' then
    is_query_finished:= True;

  if (ssh_auth_data.sshUsername + ':~$' = lastLine) AND is_estpak_forwarded then
    begin
      disconnect_message('Connection closed by foreign host...');    
      isTelnetOverSshOpen:= False;
      tcp_ssh_disconnect;
      Exit;
    end;

  if NOT (is_user_found AND is_pswd_found) then
    uHost2.logiSisse(Buffer);

  if NOT is_estpak_forwarded then
    forward_estpak_to_telnet(Buffer);
end;

procedure TuHost2.Button1Click(Sender: TObject);
begin
  display_benchmark_result;
end;

end.
