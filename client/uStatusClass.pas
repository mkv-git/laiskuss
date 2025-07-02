unit uStatusClass;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, StdCtrls, Buttons,
  ComCtrls, Forms, ShellApi, Dialogs, structVault, ExtCtrls, StrUtils;


type
  TuStatusTS = class(TObject)
    public
    // global variables
      isEthConnection: boolean; // kas tegemist on DSL või ETH ühendusega
      connectionIntf: string;
      st_refreshB: TSpeedButton;//TBitBtn;
      ipArr: array of TIpAddress;
      st_loadBar: TProgressBar;
      refresh_timer_label: TLabel;

    // "Device Status"
      router_type: string;
      soft_version: string;
      isSoftOld: boolean;
      ds_label: array[0..15] of TLabel; // Device status labels

    // "Line Quality"
      lq_label: array[0..11] of TLabel;
      lq_edit: array[0..7] of TEdit;
      vend_type: Byte;

    // sector selector
//    	sector_radiogroup: TRadioGroup;
      sector_checkbox: array[0..3] of TCheckBox;

    // procedures
      constructor Create;
      destructor Destroy; override;
      procedure clearObjects(par: Byte = 4);
      procedure statusUpdate(state: boolean);
      procedure countRefreshTimer(st_time: Word);

// Public data parsers
      // andmete saatmine telneti, koos päringu lõpplausega, returnState false
      //korral andmed ikka jäävad puhvri, mitte uTermi 
      procedure sendRequest(cmd: string; returnState: boolean = True);
      procedure Get_Blocks(sisend: string); // explode function
      procedure get_router_type;
      procedure get_software_version;
      procedure getDevice; // ruuteri põhiandmete peilimine
      procedure getConType; // korjame ühenduse intf nime ja uurime, kas on ETH või DSL
      procedure getIpAdre; // korjame kliendi IP aadresse
      procedure sendLogData; // data uHost2.logText jaoks (router log)
      function timeAgo(aeg: string): string;
    private
      st_gb_arr: array[0..3] of TGroupBox; // Status groupbox

    // "WLAN"
      wl_button: array[0..4] of TButton;
      wl_label: array[0..6] of TLabel;
      wl_edit: array[0..1] of TEdit;
      wl_combobox: array[0..2] of TComboBox;
      wl_checkbox: array[0..4] of TCheckBox;
      wl_sec_type: byte;

    // "Line quality"
    	lq_image: array[0..1] of TImage;
    
    // "ETH"
      eth_label: array[0..4] of TLabel;
      eth_edit: array[0..9] of TEdit;
      eth_button: array[0..4] of TBitBtn;
    // Expanded eth view
      eth_panel: TPanel; // kui mac aadresse on rohkem kui üks per ethport
                                            // siis on võimalik neid kõiki vaaada sellel paneelil (avatav)
      eth_navi_panel: TScrollBox; // mac aadressite Listimine
      eth_panel_info_label: TLabel; // eth_panel header ("ethport x")
      eth_panel_button: TButton; // eth panel killer
      eth_panel_dev_label: array of TLabel; // eth_panel listimine

      eth_duplex_combobox: TComboBox;
      eth_duplex_button: array[0..1] of TButton;

////// END var for elements
      blocks: array[0..10] of string;
      mac_cnt: array[1..5] of array of TMacs;

    procedure elementideSeis(seisund: boolean); // Status TAB'i komponentide olek
    procedure updateStatus(Sender: TObject); // st_refreshB button handler;
    procedure getMiscData; // ruuteri uptime
    procedure collectMaxSpeed;
    procedure getSpeedData; // reaalsed kiirused
    procedure getEthData; // eth pordi andmed
    procedure getMacData; // maclisti loomine
    function testForDummy(sisend: string; kus: string): boolean; // kontrollib, kas mac aadressiks on amino,
                                                   // või mtorola ja kas on see default või muul vlan'l
    procedure tootleMacList; // mac aadressite assignimine ethportidele
    procedure getAtmData; // atm andmed
    procedure getXdslData; // dsl'i kiirused, katkemised, vead jne

    procedure getWlanData; // wifi parameetrid
    procedure getWlanKeyData; //wireless secutiry andmed
// Device handlers
    procedure launchDevice(Sender: TObject);

// WLAN handlers
    procedure wlanState(Sender: TObject);
    procedure changeWlan(Sender: TObject);
    procedure showWlanClients(Sender: TObject);
    procedure scanWlan(Sender: TObject);
    procedure changeWlanPar(kumb: byte);
    function isWepValid(sisend: string): boolean; // kas WEP võti vastav nõuetele (10 v 26 numbrit või 5 v 13 ASCII)

// ETH group handlers
    procedure enterLabel(Sender: TObject); // label: mouse enter
    procedure exitLabel(Sender: TObject); // label: mouse exit
    procedure ethMacSet(ethif: TEdit; open: boolean); // label: avab/suleb eth_panel
    procedure looPanelList(vanemaID: Smallint); //eth_panel_dev_label loomise protseduur
    procedure killETH(Sender: TObject); // ETH pordi sulemine/avamine
    procedure ethAdvancedMode(Sender: TObject); // aktiveerib ETH lisamenüüd
    procedure duplexSet(Sender: TObject);

  end;

  TSpeedThreader = class(TThread)
    private
      dsEdit: TEdit;
      usEdit: TEdit;
      downMaxSpeed: string;
      upMaxSpeed  : string;
      function extractSpeed(needle, haystack: string): string;
      procedure setSpeedEdit(downSpeedEdit, upSpeedEdit: TEdit);
      procedure updateEditValue;
    protected
      procedure Execute; override;
  end;

var
  uStatusTS: TuStatusTS;      

implementation
uses
  uMain;

procedure TSpeedThreader.setSpeedEdit(downSpeedEdit, upSpeedEdit: TEdit);
begin
  dsEdit:= downSpeedEdit;
  usEdit:= upSpeedEdit;
end;

function TSpeedThreader.extractSpeed(needle, haystack: string): string;
type
  TNumber = set of '0'..'9';
var
  startPos, endPos, i: SmallInt;
  response, tempStr: string;
  numberSet: TNumber;
begin
  numberSet:= ['0'..'9'];
  response:= '';
  startPos:= AnsiPos(needle, haystack) + Length(needle);
  endPos:= PosEx(',', haystack, startPos);
  tempStr:= Copy(haystack, startPos, endPos - startPos);

  for i:= 0 to Length(tempStr) do
    if (tempStr[i] in numberSet) or (tempStr[i] = '.') then
      response := response + tempStr[i];
  Result:= response;
end;

procedure TSpeedThreader.updateEditValue;
begin
  dsEdit.Text:= downMaxSpeed;
  usEdit.Text:= upMaxSpeed;
end;

procedure TSpeedThreader.Execute;
var
  response: string;
begin
  response     := uHost2.getHttpData('http://stat.kmi.estpak.ee/port/json/' + uHost2.sp_id);
  if (AnsiPos('xdslOperData', response) > 0) then
    begin
      downMaxSpeed := extractSpeed('maxtxrateds', response);
      upMaxSpeed   := extractSpeed('maxtxrateus', response);
    end
  else if (AnsiPos('line_operstate', response) > 0) then
    begin
      downMaxSpeed := extractSpeed('line_maxrate_down', response);
      upMaxSpeed   := extractSpeed('line_maxrate_up', response);   
    end;
  Synchronize(updateEditValue);
end;

const
// WLAN combobox var
  wl_security: array[0..3] of string = (
    'OFF', 'WEP', 'WPA', 'WPA+WPA2');
  wl_interop: array[0..4] of string = (
    '802.11b', '802.11b(legacy)/g', '802.11b/g', '802.11g', '802.11b/g/n');


constructor TuStatusTS.Create;
const
// status groupbox width
  stgbW: array[0..4] of SmallInt = (0, 150, 210, 185, 320);
// status groupbox caption
  stgbN: array[0..3] of string = ('Device status', 'WLAN', 'Line Quality', 'ETH');
// "device status" label caption
  dsLabN: array[0..15] of string = (
    'Device:', '',
    'S/N:', '',
    'M.A.C:', '',
    'Software:', '',
    'Uptime:', '',
    'Dsl Up:', '',
    'Resets:',  '',
    'PIN:', '');

// "WLAN" label caption
  wl_labelN: array[0..6] of string = ('State:', 'SSID:', 'KEY:', 'Channel:', 'Security:', 'Interop:', '');
  wl_buttonN: array[0..4] of string = ('ON', 'OFF', 'Change', 'Show wireless clients', 'Scan WLAN');
  wl_buttonW: array[0..4] of SmallInt = (30, 30, 75, 115, 75);
  wl_buttonL: array[0..4] of SmallInt = (50, 85, 127, 5, 128);

// "Line quality" label caption
  lq_labelN: array[0..11] of string = (
    'Standard:', '', 'Dslam:', '', 'PVC:', '', 'ATM:', '',
    'Margin:', 'Attenuation:', 'Speed:', 'Max Speed:');

// eth duplex combobox items
  duplex: array[0..4] of string = (
    'auto', '10BaseTHD', '10BaseTFD', '100BaseTHD', '100BaseTFD');

// sector radioButton caption
	sectorRB_caption: array[0..4] of string = (
  	'Router', 'WLAN', 'XDSL', 'ETH', 'All data');

var
  i, j, compCnt, miscInt, ethNr1, ethNr2, ethWidth: SmallInt;
begin
// default settings
  router_type:= '';
  soft_version:= '';
{
st_gb_arr = TGroupBox:
  0 - Device
  1 - Wireless
  2 - Line quality
  3 - ETH
}
  for i:= 0 to 3 do
    begin
      st_gb_arr[i]:= TGroupBox.Create(nil);
      st_gb_arr[i].Parent:= uHost2.statusTab;
      st_gb_arr[i].Caption:= stgbN[i];
      st_gb_arr[i].Height:= uHost2.statusTab.Height;
      st_gb_arr[i].Width:= stgbW[i+1];
      st_gb_arr[i].Top:= 0;
      if (i > 0) then
        st_gb_arr[i].Left:= st_gb_arr[i-1].Left + st_gb_arr[i-1].Width
      else
        st_gb_arr[i].Left:= 0;
    end;
  st_gb_arr[3].Height:= uHost2.statusTab.Height - 27;

// st_loadBar = TProgressBar - näitab päringute valmisolekut
  st_loadBar:= TProgressBar.Create(nil);
  st_loadBar.Parent:= uHost2.statusTab;
  st_loadBar.Width:= 16;
  st_loadBar.Height:= uHost2.statusTab.Height - 5;
  st_loadBar.Top:= 5;
  st_loadBar.Left:= st_gb_arr[3].Left + st_gb_arr[3].Width + 1;
  st_loadBar.Position:= 0;
  st_loadBar.Orientation:= pbVertical;
  st_loadBar.Min:= 0;
  st_loadBar.Max:= 110;

// st_refreshB = TBitBtn: värskendab Status TAB'i andmeid
  st_refreshB:= TSpeedButton.Create(nil);
  st_refreshB.Parent:= uHost2.statusTab;
  st_refreshB.Height:= 25;
  st_refreshB.Width:= 75;
  st_refreshB.Glyph.LoadFromFile(ExtractFilePath(Application.ExeName) + 'dat\refreshB.bmp');
  st_refreshB.Caption:= 'Refresh';
  st_refreshB.Top:= uHost2.statusTab.Height - 26;
  st_refreshB.Left:= st_loadBar.Left - st_refreshB.Width - 2;
  st_refreshB.OnClick:= updateStatus;

// label kui palju aega on kulunud andmete värskendamiseks
  refresh_timer_label:= TLabel.Create(nil);
  with refresh_timer_label do
    begin
      Parent:= st_gb_arr[3];
      Height:= 21;
      Width:= 85;
      Top:= st_gb_arr[3].Height - Height - 5;
      Left:= st_gb_arr[3].Width - Width - 7;
      AutoSize:= False;
      Layout:= tlCenter;
      Alignment:= taRightJustify;
    end;

{
ds_label= TLabel:
  0, 1 - Device
  2, 3 - S/N
  4, 5 - Modem Access Code
  6, 7 - Software
  8, 9 - Uptime
  10, 11 - Dsl Uptime
  12, 13 - Resets
}
  compCnt:= 0;
  for i:= 0 to 7 do
    for j:= 0 to 1 do
      begin
        ds_label[compCnt]:= TLabel.Create(nil);
        ds_label[compCnt].Parent:= st_gb_arr[0];
        ds_label[compCnt].Caption:= dsLabN[compCnt];
        ds_label[compCnt].AutoSize:= False;
        ds_label[compCnt].Layout:= tlCenter;
        ds_label[compCnt].Top:= i * 21 + 13;
        ds_label[compCnt].Left:= j * 53 + 5;
        ds_label[compCnt].Height:= 20;
        ds_label[compCnt].Width:= j * 40 + 50;
        inc(compCnt);
      end;

  ds_label[9].OnMouseEnter:= enterLabel;
  ds_label[9].OnMouseLeave:= exitLabel;
  ds_label[11].OnMouseEnter:= enterLabel;
  ds_label[11].OnMouseLeave:= exitLabel;

////////////////////// WLAN

{
wl_label = TLabel:
  0 - state
  1 - ssid
  2 - key
  3 - channel
  4 - security
  5 - interoperability
  6 - channel mode
}
  for i:= 0 to 6 do
    begin
      wl_label[i]:= TLabel.Create(nil);
      wl_label[i].Parent:= st_gb_arr[1];
      wl_label[i].AutoSize:= False;
      wl_label[i].Layout:= tlCenter;
      wl_label[i].Caption:= wl_labelN[i];
      wl_label[i].Top:= (i * 24) + 13;
      wl_label[i].Left:= 5;
      wl_label[i].Width:= 45;
      wl_label[i].Height:= 21;
    end;

{
wl_button = TButton:
  0 - On
  1 - Off
  2 - Change
  3 - Show wireless clients
  4 - scan wlan
}
  for i:= 0 to 4 do
    begin
      wl_button[i]:= TButton.Create(nil);
      wl_button[i].Parent:= st_gb_arr[1];
      wl_button[i].Caption:= wl_buttonN[i];
      wl_button[i].Top:= 13;
      wl_button[i].Left:= wl_buttonL[i];
      wl_button[i].Height:= 21;
      wl_button[i].Width:= wl_buttonW[i];
      wl_button[i].Tag:= i;
    end;
  for i:= 0 to 2 do
    wl_button[i].Enabled:= False;

  wl_button[0].OnClick:= wlanState;
  wl_button[1].OnClick:= wlanState;
  wl_button[2].OnClick:= changeWlan;
  wl_button[3].OnClick:= showWlanClients;
  wl_button[4].OnClick:= scanWlan;


  wl_button[3].Top:= st_gb_arr[1].Height - 25;
  wl_button[4].Top:= st_gb_arr[1].Height - 25;

{
wl_edit = TEdit
  0 - SSID
  1 - KEY
}
  for i:= 0 to 1 do
    begin
      wl_edit[i]:= TEdit.Create(nil);
      wl_edit[i].Parent:= st_gb_arr[1];
      wl_edit[i].Top:= wl_label[i+1].Top;
      wl_edit[i].Left:= 50;
      wl_edit[i].Width:= 135;
      wl_edit[i].ShowHint:= True;
    end;
  wl_edit[1].Font.Style:= wl_edit[1].Font.Style + [fsBold];

{
wl_combobox = TCombobox
  0 - channel
  1 - security
  2 - interoperability
}
  for i:= 0 to 2 do
    begin
      wl_combobox[i]:= TCombobox.Create(nil);
      wl_combobox[i].Parent:= st_gb_arr[1];
      wl_combobox[i].Top:= wl_label[i+3].Top;
      wl_combobox[i].Left:= 50;
      wl_combobox[i].Width:= (abs(i + 1) div 2) * 60 + 75;
      if (i > 0) then
        wl_combobox[i].Style:= csDropDownList;
    end;
  wl_combobox[0].Items.Add('auto');
  for i:= 1 to 13 do
    wl_combobox[0].Items.Add(IntToStr(i));

  for i:= 0 to Length(wl_security)-1 do
    wl_combobox[1].Items.Add(wl_security[i]);

  for i:= 0 to Length(wl_interop)-1 do
    wl_combobox[2].Items.Add(wl_interop[i]);

  for i:= 0 to 2 do
    wl_combobox[i].ItemIndex:= 0;

  wl_label[6].Left := wl_combobox[0].Left + wl_combobox[0].Width + 5;
  wl_label[6].Top:= wl_combobox[0].Top;

{
wl_checkbox = TCheckbox:
  0 - ssid
  1 - key
  2 - channel
  3 - security
  4 - interoperability
}
  for i:= 0 to 4 do
    begin
      wl_checkbox[i]:= TCheckBox.Create(nil);
      wl_checkbox[i].Parent:= st_gb_arr[1];
      wl_checkbox[i].Top:= wl_label[i+1].Top;
      wl_checkbox[i].Left:= st_gb_arr[1].Width - 20;
      wl_checkbox[i].Height:= 22;
      wl_checkbox[i].Width:= 17;
    end;


/////////////////////// Line Quality
{
lq_label = TLabel:
  0, 1 - Standard
  2, 3 - dslam
  4, 5 - atm
  6, 7 - pvc
  8 - margin
  9 - attenuation
  10 - speed
  11 - max speed
}
  for i:= 0 to 11 do
    begin
      lq_label[i]:= TLabel.Create(nil);
      lq_label[i].Parent:= st_gb_arr[2];
      lq_label[i].AutoSize:= False;
      lq_label[i].Layout:= tlCenter;
      lq_label[i].Height:= 21;
      lq_label[i].Width:= 60;
      lq_label[i].Caption:= lq_labelN[i];
      lq_label[i].Left:= 3;
    end;
    
  for i:= 0 to 7 do
    begin
      lq_label[i].Top:= (i div 2) * 21 + 13;
      lq_label[i].Left:= (i mod 2) * 60 + 5;
      lq_label[i].Width:= (i mod 2) * 60 + 50;
    end;

  for i:= 8 to High(lq_label) do
    lq_label[i].Top:= (i - 4)* 21 + 13;

{
lq_edit = TEdit:
  0, 1 - margin
  2, 3 - attenuation
  4, 5 - speed
  6, 7 - max speed
}
  for i:= 0 to 7 do
    begin
      lq_edit[i]:= TEdit.Create(nil);
      lq_edit[i].Parent:= st_gb_arr[2];
      lq_edit[i].AutoSize:= False;
      lq_edit[i].Top:= lq_label[(i div 2)+8].Top + 1;
      lq_edit[i].Left:= (i mod 2) * 47 + (i mod 2) * 12 + 65;
      lq_edit[i].Width:= 47;
      lq_edit[i].Height:= 20;
    end;

  for i:= 0 to 1 do
  	begin
    	lq_image[i]:= TImage.Create(nil);
      with lq_image[i] do
      	begin
        	Parent:= st_gb_arr[2];
          Top:= lq_edit[i].Top;
          Left:= lq_edit[i].Left + lq_edit[i].Width + 1;
          Transparent:= True;
          try
	          Picture.LoadFromFile(ExtractFilePath(Application.ExeName) + 'dat\lqData'+IntToStr(i)+'.bmp');
          except on E:Exception do
          	uHost2.writeErrorLog('Error on loading lqData: ' + E.Message);
          end;
        end;
    end;
    
////////////////////// ETH
  for i:= 0 to 4 do
    begin
      eth_label[i]:= TLabel.Create(nil);
      eth_label[i].Parent:= st_gb_arr[3];
      eth_label[i].AutoSize:= False;
      eth_label[i].Layout:= tlCenter;
      eth_label[i].Width:= 16;
      eth_label[i].Height:= 20;
      eth_label[i].Left:= 2;
      eth_label[i].Top:= i * 23 + 13;
      eth_label[i].Caption:= IntToStr(i+1);
      eth_label[i].Alignment:= taCenter;
      eth_label[i].Font.Style:= eth_label[i].Font.Style + [fsBold];
      eth_label[i].Color:= $000BDFD5;
    end;
{
eth_edit = TEdit:
  0, 1 - eth1 (duplex & device)
  2, 3 - eth2 (duplex & device)
  4, 5 - eth3 (duplex & device)
  6, 7 - eth4 (duplex & device)
  8, 9 - eth5 (duplex & device)
}

  compCnt:= 0;
  for i:= 0 to 4 do
    for j:= 0 to 1 do
      begin
        eth_edit[compCnt]:= TEdit.Create(nil);
        eth_edit[compCnt].Parent:= st_gb_arr[3];
        eth_edit[compCnt].ReadOnly:= True;
        eth_edit[compCnt].Top:= eth_label[i].Top;
        eth_edit[compCnt].Left:= (j * 50) + eth_label[i].Width + 3;
        eth_edit[compCnt].Width:= (j * 168) + 50;
        eth_edit[compCnt].ShowHint:= True;
        eth_edit[compCnt].OnDblClick:= ethAdvancedMode;
        eth_edit[compCnt].Tag:= compCnt;
        eth_edit[compCnt].Cursor:= crArrow;
        inc(compCnt);
      end;

  for i:= 0 to 4 do
    begin
      eth_button[i]:= TBitBtn.Create(nil);
      eth_button[i].Parent:= st_gb_arr[3];
      eth_button[i].Top:= eth_label[i].Top;
      eth_button[i].Left:= st_gb_arr[3].Width - 28;
      eth_button[i].Width:= 25;
      eth_button[i].Height:= 22;
      eth_button[i].Caption:= '';
      eth_button[i].Tag:= i+1;
      eth_button[i].OnClick:= killETH;
    end;
  eth_button[4].Visible:= False; // eth_WAN'le ei ole vaja killimise nuppu

// expanded eth view panel, label & button
  eth_panel:= TPanel.Create(nil);
  with eth_panel do
    begin
      Parent:= st_gb_arr[3];
      Height:= 23;
      Caption:= '';
      BevelInner:= bvLowered;
      BevelOuter:= bvRaised;
      Color:= $00E2D7CF;
      Top:= 13;
      Left:= 2;
      Height:= st_gb_arr[3].Height - 14; //eth_edit[9].Top + eth_edit[9].Height + 40;
      Width:= st_gb_arr[3].Width - 3;
    end;

  eth_panel_info_label:= TLabel.Create(nil);
  with eth_panel_info_label do
    begin
      Parent:= eth_panel;
      AutoSize:= False;
      Layout:= tlCenter;
      Align:= alTop;
      Alignment:= taCenter;
      Height:= 22;
      Color:= $00D1C0AB;
      Font.Style:= Font.Style + [fsBold];
    end;

  eth_panel_button:= TButton.Create(nil);
  with eth_panel_button do
    begin
      Parent:= eth_panel;
      Top:= 3;
      Left:= eth_panel.Width - 28;
      Height:= 20;
      Width:= 25;
      Caption:= 'X';
      onClick:= ethAdvancedMode;
      Font.Style:= Font.Style + [fsBold];
    end;

  eth_navi_panel:= TScrollBox.Create(nil);
  with eth_navi_panel do
    begin
      Parent:= eth_panel;
      Align:= alClient;
      VertScrollBar.Visible:= True;
      HorzScrollBar.Visible:= False;
      BorderStyle:= bsNone;
    end;

// duplex objects

  eth_duplex_combobox:= TCombobox.Create(nil);

  with eth_duplex_combobox do
    begin
      Parent:= st_gb_arr[3];
      Width:= 100;
      Style:= csDropDownList;
      for i:= 0 to Length(duplex)-1 do
        Items.Add(duplex[i]);
      Left:= eth_edit[0].Left;
      ItemIndex:= 0;
      Visible:= False;
    end;

  for i:= 0 to 1 do
    begin
      eth_duplex_button[i]:= TButton.Create(nil);
      eth_duplex_button[i].Parent:= st_gb_arr[3];
      eth_duplex_button[i].Height:= 22;
      eth_duplex_button[i].Width:= 55;      
      eth_duplex_button[i].Top:= eth_edit[8].Top + eth_edit[8].Height + 2;
      eth_duplex_button[i].Left:= i * (eth_duplex_button[i].Width + 2) + eth_edit[8].Left;  
      eth_duplex_button[i].Visible:= False;
      eth_duplex_button[i].Tag:= i;
      eth_duplex_button[i].OnClick:= duplexSet;
    end;
  eth_duplex_button[0].Caption:= 'Change';
  eth_duplex_button[1].Caption:= 'Cancel';

	for i:= 0 to High(sector_checkbox) do
  	begin
    	sector_checkbox[i]:= TCheckBox.Create(nil);
      with sector_checkbox[i] do
      	begin
        	Parent:= uHost2.statusTab;
          Height:= 20;
          Width:= 60-i+2;
          Top:= st_refreshB.Top + 5;
          Left:= (Width * i) + 5 + st_gb_arr[3].Left;
          Caption:= sectorRB_caption[i];
          Tag:= i;
          Checked:= True;
        end;
    end;

  isEthConnection:= False;
  eth_panel.Visible:= False;
  elementideSeis(False);
  statusUpdate(False);
end;

// end of constructor

destructor TuStatusTS.Destroy;
begin
// device status
  uHost2.vabadus(ds_label);

// wlan
  uHost2.vabadus(wl_label);
  uHost2.vabadus(wl_button);
  uHost2.vabadus(wl_edit);
  uHost2.vabadus(wl_combobox);
  uHost2.vabadus(wl_checkbox);

// line quality
  uHost2.vabadus(lq_label);
  uHost2.vabadus(lq_edit);

// eth extra
  uHost2.vabadus(eth_panel_info_label);
  uHost2.vabadus(eth_panel_button);
  uHost2.vabadus(eth_panel_dev_label);
  uHost2.vabadus(eth_navi_panel);
  uHost2.vabadus(eth_panel);
  uHost2.vabadus(eth_duplex_combobox);
  uHost2.vabadus(eth_duplex_button);
  
// eth
  uHost2.vabadus(eth_label);
  uHost2.vabadus(eth_edit);
  uHost2.vabadus(eth_button);

// extra struff
	uHost2.vabadus(sector_checkbox);
  uHost2.vabadus(refresh_timer_label);
  try
    st_refreshB.Free;
  except on E:Exception do
    MessageBox(GetDesktopWindow, PAnsiChar('Error on freeing st_refreshB' + E.Message), 'Laiskuss annab teada', MB_ICONERROR);
  end;
  try
    st_loadBar.Free;
  except on E:Exception do
    MessageBox(GetDesktopWindow, PAnsiChar('Error on freeing st_loadBar' + E.Message), 'Laiskuss annab teada', MB_ICONERROR);
  end;

// Status TAB groupbox
  uHost2.vabadus(st_gb_arr);
end;


procedure TuStatusTS.statusUpdate(state: boolean);
var
  i: SmallInt;
begin
  for i:= Low(st_gb_arr) to High(st_gb_arr) do
    st_gb_arr[i].Enabled:= state;
end;

procedure TuStatusTS.countRefreshTimer(st_time: Word);
var
  stop_counter: Word;
begin
  stop_counter:= GetTickCount;
  try
  if (stop_counter > st_time) then
    refresh_timer_label.Caption:= Format('Total: %2.3f sec', [((stop_counter - st_time) / 1000)]);
  except on E:Exception do
    uHost2.writeErrorLog('Exception @ cntRefresh: ' + E.Message);
  end;
end;

procedure TuStatusTS.elementideSeis(seisund: boolean);
var
  i: SmallInt;
begin
// WLAN
  for i:= 0 to 4 do
    wl_button[i].Enabled:= seisund;

  for i:= 0 to 1 do
    uHost2.disGray(wl_edit[i], seisund);

  for i:= 0 to 2 do
    uHost2.disGray(wl_combobox[i], seisund);
  for i:= 0 to 4 do
    wl_checkbox[i].Enabled:= seisund;

// ETH
  for i:= 0 to 3 do
    eth_button[i].Enabled:= seisund;
end;

procedure TuStatusTS.clearObjects(par: Byte = 4);
var
  i: SmallInt;
begin
// device status label
  if (par = 0) OR (par = 4) then
    try
    	for i:= 1 to 5 do
      	ds_label[((i-1)*2)+1].Caption:= '';

      ds_label[High(ds_label)].Caption:= '';
    except on E: Exception do
      uHost2.writeErrorLog('Error @ clearObjects[1]: ' + E.Message);
    end;

// WLAN edit, checkbox and combobox
  if (par = 1) OR (par = 4) then
    try
      begin
        for i:= 0 to 2 do
          wl_button[i].Enabled:= False;

        for i:= 0 to 1 do
          begin
            wl_edit[i].Clear;
            wl_edit[i].Color:= clWindow;
            wl_edit[i].Hint:= '';
          end;


        for i:= 0 to 4 do
          wl_checkbox[i].Checked:= False;

        for i:= 0 to 2 do
          wl_combobox[i].ItemIndex:= 0;

        wl_label[6].Caption:= '';
      end;
    except on E:Exception do
      uHost2.writeErrorLog('Error @ clearObjects[2]: ' + E.Message);
    end;

// LQ label, edit
  if (par = 2) OR (par = 4) then
    try
      i:= 1;
      while (i <> 9) do
        begin
          lq_label[i].Caption:= '';
          inc(i, 2);
        end;
      for i:= 0 to 7 do
        lq_edit[i].Clear;

      ds_label[11].Caption:= '';
      ds_label[13].Caption:= '';

//  Adv LQ TAB memo
      uHost2.alqTs.alq_memo[1].Clear;
    except on E:Exception do
      uHost2.writeErrorLog('Error @ clearObjects[3]: ' + E.Message);
    end;

// eth label, edit
  if (par = 3) OR (par = 4) then
    try
      for i:= 1 to 5 do
        begin
          SetLength(mac_cnt[i], 0);
          eth_edit[(i-1)*2+1].Width:= 218;
          eth_edit[(i-1)*2+1].Left:= eth_label[i-1].Width + 53;
        end;
      for i:= 0 to 4 do
        begin
          eth_label[i].Color:= $000BF2E7;
          eth_button[i].Kind:= bkHelp;
          eth_button[i].Caption:= '';
        end;
      for i:= 0 to 9 do
        begin
          eth_edit[i].Clear;
          eth_edit[i].Hint:= '';
          eth_edit[i].Color:= clWindow;
        end;
    except on E:Exception do
      uHost2.writeErrorLog('Error @ clearObjects[4]: ' + E.Message);
    end;

//  Wifi paneel
  st_gb_arr[1].Enabled:= False;

// clear global variables
  router_type:= '';
  soft_version:= '';
  connectionIntf:= '';
  isEthConnection:= False;
end;






{***************************** *****************************
  DATA PARSER
***************************** ***************************** }

// Refresh Button
procedure TuStatusTS.updateStatus(Sender: TObject);
var
	cb_set: Set of 0..3;
	i: SmallInt;
  start_counter: Word;
begin
  if (Sender is TSpeedButton) then
    if uHost2.is_connection_alive then
      try
        refresh_timer_label.Caption:= '';
        start_counter:= GetTickCount; // set start time
        uhost2.timer1_cnt:= 0;
        LongTimeFormat:= 'hh:nn:ss:zzz';
        uHost2.haltOnRefresh(False);
        cb_set:= []; // selected checkbox array
        for i:= 0 to High(sector_checkbox) do
        	if (sector_checkbox[i].Checked) then
          	begin
	          	include(cb_set, i);
        			clearObjects(i);
            end;
{
Korjame ruuteri põhiandmeid:
  * Ruuteri tüüp
  * Seerianumber
  * Modem Access Code
  * Softi versioon
}
        countRefreshTimer(start_counter);
				if (0 in cb_set) then
        	begin
            st_loadBar.Position:= 0;
            uHost2.st_loadInfo.Caption:= ' Sending request...';
            getDevice;
            st_gb_arr[0].Enabled:= True;
            countRefreshTimer(start_counter);
// Korjame ruuteri Uptime'i
            st_loadBar.Position:= 10;
            uHost2.st_loadInfo.Caption:= ' Router''s status...';
            getMiscData;
            countRefreshTimer(start_counter);
            getIpAdre;
            countRefreshTimer(start_counter);
          end;

// Korjame Etherneti andmeid, mis seadmed ja mis pesas asuvad
				if (3 in cb_set) then
        	begin
            st_loadBar.Position:= 20;
            uHost2.st_loadInfo.Caption:= ' Ethernet status...';
            getEthData;
            countRefreshTimer(start_counter);

// Mac aadressite korjamine + eth väljade kirjledamine + stb kontroll
            st_loadBar.Position:= 30;
            uHost2.st_loadInfo.Caption:= ' Creating maclist...';
            getMacData;
            st_gb_arr[3].Enabled:= True;
            countRefreshTimer(start_counter);
					end;

// xDSL müra, sumbuvus, errorid, dsl kustumised ja dsl uptime
				if (2 in cb_set) then
        	begin
            getConType;
            countRefreshTimer(start_counter);
            st_loadBar.Position:= 40;
            uHost2.st_loadInfo.Caption:= ' Line Quality...';
            getXdslData;
            countRefreshTimer(start_counter);

// xDSL kiirused
            st_loadBar.Position:= 50;
            uHost2.st_loadInfo.Caption:= ' Speedstream...';
            collectMaxSpeed;
            countRefreshTimer(start_counter);
            getSpeedData;
            countRefreshTimer(start_counter);

            st_loadBar.Position:= 70;
            uHost2.st_loadInfo.Caption:= ' Max Speed...';


// ATM ridade arv
            st_loadBar.Position:= 80;
            uHost2.st_loadInfo.Caption:= ' ATM info...';
            getAtmData;
            countRefreshTimer(start_counter);
        end;

// WLAN info ja turva sätted
				if (1 in cb_set) then
        	begin
            if (router_type <> 'ST546') then
              begin
                elementideSeis(True);
                st_loadBar.Position:= 90;
                uHost2.st_loadInfo.Caption:= ' Wireless info...';
                getWlanData;
                countRefreshTimer(start_counter);

                st_loadBar.Position:= 100;
                uHost2.st_loadInfo.Caption:= ' Security settings info...';
                getWlanKeyData;
                countRefreshTimer(start_counter);
              end
            else
              elementideSeis(False);
          end; // in set

        st_loadBar.Position:= 110;
        countRefreshTimer(start_counter);
        uHost2.haltOnRefresh(True);
        uHost2.st_loadInfo.Caption:= ' Status data updated...';
      except on E:Exception do
        uHost2.writeErrorLog('error @ updateStatus: ' + E.Message);
      end
    else
      MessageBox(uHost2.Handle, 'Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

// saadame telneti käskluse andmete kättesaamiseks
procedure TuStatusTS.sendRequest(cmd: string; returnState: boolean = True);
begin
  uHost2.is_query_finished:= False;
  uHost2.writeLn_to_terminal(cmd, 2);
  Sleep(100);
  uHost2.WaitForData(returnState);
  Sleep(100);
end;

// kui ühest reast vaja rohkem eraldi andmid siis parseldame need andmed
// blokkideks (array of string = blocks)
procedure TuStatusTS.Get_Blocks(sisend: string);
var
  iPos, bCnt: SmallInt;
begin
  try
    sisend:= sisend + ' ';
    for bCnt:= 0 to Length(blocks)-1 do
      begin
        blocks[bCnt]:= '';
        iPos:= AnsiPos(' ', sisend);
        blocks[bCnt]:= Copy(sisend, 1, iPos-1);
        Delete(sisend, 1, iPos);
        sisend:= TrimLeft(sisend);
      end;
  except on E:Exception do
    uHost2.writeErrorLog('error @ get_blocks: ' + E.Message);
  end;
end;

procedure TuStatusTS.sendLogData;
var
  i: SmallInt;
begin
  uHost2.logText.SelStart:= 0;
  SendMessage(uHost2.logText.Handle, EM_SCROLLCARET, 0, 0);
  uHost2.logText.Lines.Add('Router : ' + ds_label[1].Caption + ' ' + ds_label[7].Caption);
  uHost2.logText.Lines.Add('Router S/N: ' + ds_label[3].Caption);
  uHost2.logText.Lines.Add('Uptime: ' + ds_label[9].Caption);
  uHost2.logText.Lines.Add('DSL standard: ' + lq_label[1].Caption);
  uHost2.logText.Lines.Add('DSL Uptime: ' + ds_label[11].Caption);
  uHost2.logText.Lines.Add('DSL Resets: ' + ds_label[13].Caption);
  uHost2.logText.Lines.Add('Margin: ' + lq_edit[0].Text + ' dB/ ' + lq_edit[1].Text + ' dB');
  uHost2.logText.Lines.Add('Attenuation: ' + lq_edit[2].Text + ' dB/ ' + lq_edit[3].Text + ' dB');
  uHost2.logText.Lines.Add('Conf. speed: ' + lq_edit[4].Text + ' kbps/ ' + lq_edit[5].Text + ' kbps');
  uHost2.logText.Lines.Add('Max speed: ' + lq_edit[6].Text + ' kbps/ ' + lq_edit[7].Text + ' kbps' + #13#10);
  uHost2.logText.Lines.Add('Errors: ');
  for i:= 0 to uHost2.alqTs.alq_memo[1].Lines.Count-1 do
    uHost2.logText.Lines.Add('  ' + uHost2.alqTs.alq_memo[1].Lines[i]);
  uHost2.logText.Lines.Add(#13#10 + 'GAP: ');
  for i:= 0 to uHost2.alqTs.alq_memo[0].Lines.Count-1 do
    uHost2.logText.Lines.Add('  ' + uHost2.alqTs.alq_memo[0].Lines[i]);
end;

// kui on vaja välja selgitada, mis ajal (kp + kell) toimus x tegevus,
// sisendiks on aeg kujul "xx days, hh:mm:ss"

function TuStatusTS.timeAgo(aeg: string): string;
var
  iPos: SmallInt;
  hetkel, tulem, d, h, m, s: LongWord;
  blokkid: TStrArr;
  temp, vastus: string;
  occured: TDate;
begin
//13 days, 17:15:42
  LongTimeFormat:= 'hh:nn:ss';
  temp:= '';
  blokkid:= nil;
  occured:= Now;
  try
    if (Length(aeg) > 0) then
      begin
        iPos:= AnsiPos('day', aeg);
        if (iPos > 0) then
          begin
            temp:= Trim(Copy(aeg, 1, iPos-1));
            Delete(aeg, 1, iPos+4);
            blokkid:= explode(Trim(aeg), ':');

            // päevad * 86400 sek (24*60*60)
            try
              d:= 86400 * StrToInt(temp);
            except
              d:= 0;
            end;

            // tunnid * 3600 sek (60*60)
            try
              h:= 3600 * StrToInt(blokkid[0]);
            except
              h:= 0;
            end;

            // minutid * 60 sek
            try
              m:= 60 * StrToInt(blokkid[1]);
            except
              m:= 0;
            end;

            // sekundid
            try
              s:= StrToInt(blokkid[2]);
            except
              s:= 0;
            end;

            hetkel:= DateToUnix(Now); // praegune kuupäev + kell
            tulem:= d + h + m + s;

            try
              occured:= UnixToDate(hetkel - tulem);
            except
            end;
            vastus:= DateTimeToStr(occured);
          end; // iPos
      end; // Length

  except on E:Exception do
    uHost2.writeErrorLog('Exception @ timeAgo: ' + E.Message);
  end; // try
  LongTimeFormat:= 'hh:nn:ss:zzz';
  Result:= vastus;
end;







{*******************************
     Pärime seadmete andmeid

*******************************}

procedure TuStatusTS.get_router_type;
const
  deviceName: array[0..1] of string = ('VARIANT_FRIENDLY_NAME=', 'PROD_NUMBER=');
var
  i, j: SmallInt;
  query: string;
begin
  for i:= 0 to 1 do
    begin
      query:= 'env get var _' + deviceName[i];
      sendRequest(query);
      for j:= 0 to uHost2.dataBuffer.Count - 1 do
        if uHost2.dataBuffer.Strings[j] = query then
          begin
            router_type:= Trim(uHost2.dataBuffer.Strings[j+1]);
            Exit;
          end;
    end
end;

procedure TuStatusTS.get_software_version;
const
  softVersion   = 'BUILD';
var
  i: SmallInt;
  query: string;
begin
  query:= 'env get var _' + softVersion;
  sendRequest(query);
  for i:= 0 to uHost2.dataBuffer.Count - 1 do
    if uHost2.dataBuffer.Strings[i] = query then
      begin
        soft_version:= uHost2.dataBuffer.Strings[i+1];
        Exit;
      end;
end;

procedure TuStatusTS.getDevice;
const
  softVersion   = '_BUILD=';
  deviceName1   = 'VARIANT_FRIENDLY_NAME=';
  deviceName2   = 'PROD_NUMBER=';
  serialNumber  = '_PROD_SERIAL_NBR=';
  accessCode1   = 'MODEM_ACCESS_CODE';
  accessCode2   = 'MODEM_ACCESS_CODE';
  wirelessPin		= '_WL0_PIN_SERIAL';
var
  i: SmallInt;
  temp, dummy: string;
  found: boolean;
begin
//90.191.163.88
  try
    sendRequest(':env list', False);
    Found:= False;
    isSoftOld:= True;
    for i:= 0 to uHost2.dataBuffer.Count-1 do
      begin
        temp:= uHost2.dataBuffer.Strings[i];
// Otsime mudeli nime
        if (AnsiPos(deviceName1, temp) > 0) then
          ds_label[1].Caption:= uHost2.VordusMark(temp)
        else if (AnsiPos(deviceName2, temp) > 0) then
          ds_label[1].Caption:= uHost2.VordusMark(temp);
        router_type:= ds_label[1].Caption;

// seerianumbri
        if (AnsiPos(serialNumber, temp) > 0) then
          begin
            ds_label[3].Caption:= uHost2.VordusMark(temp);
            ds_label[3].Font.Style:= ds_label[3].Font.Style + [fsUnderline];
            ds_label[3].Cursor:= crHandPoint;
            ds_label[3].OnClick:= launchDevice;
            Found:= True;
          end;

        if (NOT Found) then
          begin
            ds_label[3].Caption:= 'N/A';
            ds_label[3].Font.Style:= ds_label[3].Font.Style - [fsUnderline];
            ds_label[3].Cursor:= crDefault;
            ds_label[3].OnClick:= nil;
          end;

// otsime Modem Access Code'i
        if (AnsiPos(accessCode1, temp) > 0) then
          ds_label[5].Caption:= uHost2.VordusMark(temp);

// Otsime tarkvara versiooni numbri
        if (AnsiPos(softVersion, temp) > 0) then
          begin
            ds_label[7].Caption:= uHost2.VordusMark(temp);
            soft_version:= ds_label[7].Caption;

            if soft_version[1] <> '6' then
              begin
                isSoftOld:= False;
              end
            else
              try
                dummy:= Copy(soft_version, 1, 3);
                DecimalSeparator:= '.';
                if (StrToFloat(dummy) > 6.2) then
                  isSoftOld:= False;
              except on E:Exception do
                begin
                  isSoftOld:= True;
                  uHost2.writeErrorLog('Error @ getDevice(soft): ' + E.Message);
                end; // except
              end; // try
          end; // AnsiPos

// Otsime Wireless PIN'i
        if (AnsiPos(wirelessPin, temp) > 0) then
        	begin
          	ds_label[15].Caption:= uHost2.VordusMark(temp);          
          end; // AnsiPos
          
      end; // for i loop
  except on E:Exception do
    uHost2.writeErrorLog('Error @ getDevice: ' + E.Message);
  end;
end;



procedure TuStatusTS.getMiscData;
var
  i: SmallInt;
  temp, aeg: string;
begin
  if uHost2.is_connection_alive then
    begin
      try
        sendRequest(':system settime', False);
        for i:= 0 to uHost2.dataBuffer.Count-1 do
          begin
      // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
            if (i > uHost2.dataBuffer.Count) then
              begin
                break;
              end;
            temp:= uHost2.dataBuffer.Strings[i];
            ds_label[9].ShowHint:= True;
            if (AnsiPos('uptime', temp) > 0) then
              begin
                aeg:= uHost2.VordusMark(temp);
                ds_label[9].Caption:= aeg;
                ds_label[9].Hint:= timeAgo(aeg);
              end; // AnsiPos
          end;  // for i loop (system settime)
      except on E:Exception do
        uHost2.writeErrorLog('Error @ getMiscData: ' + E.Message);
      end;
  end; // tcpc.connected
end;

procedure TuStatusTS.getConType;
var
  i: SmallInt;
  temp: string;
  blokkid: TStrArr;
begin
  blokkid:= nil;
  if (uHost2.is_connection_alive) then
    begin
      try
        isEthConnection:= False;
        sendRequest(':ip iplist', False);
        for i:= 0 to uHost2.dataBuffer.Count-1 do
          begin
            temp:= uHost2.dataBuffer.Strings[i];
            if (AnsiPos(uHost2.hostAddress, temp) > 0) then
              begin
                blokkid:= uMain.explode(temp, ' ');
                connectionIntf:= Trim(blokkid[1]);
                // kui interface'i lõppus on '.' siis kustutame ära
                if (AnsiPos('.', blokkid[1]) > 0) then
                  Delete(connectionIntf, AnsiPos('.', blokkid[1]), MaxInt);
                if (connectionIntf = 'ipKmInet') then
                  isEthConnection:= True;
              end;
          end; // for i loop (ip iplist)

      except on E:Exception do
        uHost2.writeErrorLog('Error @ getConType: ' + E.Message);
      end;
  end; // tcpc.connected
end;

procedure TuStatusTS.getIpAdre;
var
  i: SmallInt;
  temp: string;
  blokkid: TStrArr;
  arrCnt: SmallInt;
begin
  blokkid:= nil;
  arrCnt:= 0;
  SetLength(ipArr, arrCnt);
  if (uHost2.is_connection_alive) then
    begin
      try
        sendRequest(':ip arplist', False);
        for i:= 0 to uHost2.dataBuffer.Count-1 do
          begin
            temp:= uHost2.dataBuffer.Strings[i];
            if (AnsiPos('192.168', temp) > 0) then
              begin
                blokkid:= explode(temp, ' ');
                if (Length(blokkid) > 0) then
                  begin
                    arrCnt:= Length(ipArr);
                    SetLength(ipArr, arrCnt+1);
                    ipArr[arrCnt].ip_adre:= blokkid[2];
                    ipArr[arrCnt].ip_mac:= blokkid[3];
                  end;
              end; // AnsiPos
          end; // for i loop
      except on E:Exception do
        uHost2.writeErrorLog('Error @ getIpAdre: ' + E.Message);
      end;
  end; // tcpc.connected
end;

procedure TuStatusTS.getEthData;
var
  i, e, eth_nr, iPos: SmallInt;
  eth_status_ID: Byte;
  eth_duplex_ID: Byte;
  temp, uus_block: string;
begin
  if uHost2.is_connection_alive then
    try
      if router_type = '' then
        get_router_type;
      if soft_version = '' then
        get_software_version;

      sendRequest(':eth device iflist', False);
      for i:= 2 to uHost2.dataBuffer.Count-3 do
      begin
        temp:= uHost2.dataBuffer.Strings[i];
        if (router_type = 'TG789vn') OR (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9') then
          begin
            eth_status_ID:= 4;
            eth_duplex_ID:= 5;
            for e:= 1 to 5 do
              begin
              eth_nr:= (e-1)*2; // (e-1)*2 = eth 0, 2, 4, 6
              if (AnsiPos('ethif' + IntToStr(e), temp) > 0) then
                begin
                  Get_Blocks(temp);
              // ETH status
                  if ((blocks[eth_status_ID] = 'enabled') OR (blocks[eth_status_ID] = 'connected')) then
                    eth_button[e-1].Kind:= bkOK
                  else if (blocks[eth_status_ID] = 'disabled') then
                    eth_button[e-1].Kind:= bkCancel
                  else
                    eth_button[e-1].Kind:= bkHelp;
                  eth_button[e-1].Caption:= '';

              // ETH state
                  if (blocks[eth_status_ID] = 'connected') then
                    eth_label[e-1].Color:= clGreen
                  else
                    eth_label[e-1].Color:= $000BF2E7;

              // ETH duplex
                  iPos:= AnsiPos('Base', blocks[eth_duplex_ID]);
                  if (iPos > 0) AND (blocks[2] = 'enabled') then
                    eth_edit[eth_nr].Hint:= blocks[eth_duplex_ID]
                  else
                    eth_edit[eth_nr].Hint:= 'auto';

                  if (iPos > 0) then
                    eth_edit[eth_nr].Text:= Copy(blocks[eth_duplex_ID], 1, iPos-1) + ' ' +
                      Copy(blocks[eth_duplex_ID], iPos+4, MaxInt)
                  else
                    eth_edit[eth_nr].Text:= '---';
                end; // AnsiPos(ethif)
              end; // for e loop
          end
        else
        begin
          for e:= 1 to 5 do
          begin
            eth_nr:= (e-1)*2; // (e-1)*2 = eth 0, 2, 4, 6
            if (AnsiPos('ethif'+IntToStr(e), temp) > 0) then
              begin
                Get_Blocks(temp);
                eth_edit[eth_nr].Hint:= blocks[1];
                if blocks[2] = 'Not' then
                  begin
                    eth_edit[eth_nr].Text:= '---';
                    uus_block:= blocks[4]
                  end
                else
                  begin
                    Delete(blocks[2], AnsiPos('Base', blocks[2]), 4);
                    eth_edit[eth_nr].Text:= blocks[2]; // (e-1)*2 = eth 0, 2, 4, 6
                    uus_block:= blocks[3];
                  end;
                if (uus_block = 'UP') then
                  eth_button[e-1].Kind:= bkOK
                else if (uus_block = 'DOWN') then
                  eth_button[e-1].Kind:= bkCancel
                else
                  eth_button[e-1].Kind:= bkHelp;
                eth_button[e-1].Caption:= '';
              end; // end ansipos(ethif)
            end; // end for e loop
        end; // end else
      end; // end for loop
    except on E:Exception do
      uHost2.writeErrorLog('Error @ gathering Eth data: ' + E.Message);
    end;
end;



procedure TuStatusTS.getMacData;
var
  i, m, mCnt: SmallInt;
  temp, tempMac, tulem, search_string: string;
  leitud, is_valid_ethport: boolean;
begin
  if uHost2.is_connection_alive then
    try
      sendRequest(':eth bridge maclist', False);
      for i:= 0 to uHost2.dataBuffer.Count-1 do
        begin
          temp:= uHost2.dataBuffer.Strings[i];
          for m:= 1 to Length(mac_cnt)-1 do
            begin
              if (router_type = 'TG789vn') OR (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9') then
                begin
                  search_string:= Format('ethport%d(%d)', [m, m]);
                  is_valid_ethport:= (AnsiPos(search_string, temp) > 0) AND (AnsiPos('dynamic', temp) > 0);
                end
              else
                begin
                  search_string:= Format('ethport%d', [m]);
                  is_valid_ethport:= (AnsiPos(search_string, temp) > 0);
                end;

              if is_valid_ethport then
                begin
                // kui array on juba olemas ja esimene element on "dummy" siis kirjutame üle selle elemendi
                  if ((Length(mac_cnt[m]) > 0) AND (mac_cnt[m][0].nimi = 'dummy')) then
                    mCnt:= 0
                  else
                    mCnt:= Length(mac_cnt[m]);

                  tempMac:= Copy(temp, 1, AnsiPos(' ', temp));
                  tulem:= tempMac;
                  leitud:= uHost2.searchForMac(tempMac, tulem);
                  if testForDummy(tulem, temp) OR (router_type = 'TG789vn') OR
                    (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9')then
                    begin
                      SetLength(mac_cnt[m], mCnt+1);
                      mac_cnt[m][mCnt].nimi:= tulem;
                      if leitud then
                        mac_cnt[m][mCnt].macAadress:= tempMac
                      else
                        mac_cnt[m][mCnt].macAadress:= '';
                    end;
                end
              // kui ei leitud ühtegi maclist selle ethpordiga siis teeme "dummy" elemendi
              else if (Length(mac_cnt[m]) = 0) then
                begin
                  SetLength(mac_cnt[m], 1);
                  mac_cnt[m][0].nimi:= 'dummy';
                end;
            end; // for M loop end
        end; // for I loop end

// populate MAC adresses to ETH ports
      tootleMacList;
    except on E:Exception do
      uHost2.writeErrorLog('Error @ gathering Mac data: ' + E.Message);
    end;
end;

// function not to be used with TG789 and TG784 (v 8.C.D.5) routers
function TuStatusTS.testForDummy(sisend: string; kus: string): boolean;
var
  tulemus: boolean;
begin
  if (sisend = 'Amino') OR (sisend = 'Motorola') OR (sisend = 'COMTREND') or (AnsiPos('Ruckus', sisend) > 0) then
    begin
      if (AnsiPos('default', kus) > 0) then
        tulemus:= False
      else
        tulemus:= True;
    end
  else
    tulemus:= True;
  Result:= tulemus;
end;

procedure TuStatusTS.tootleMacList;
var
  i, j, mCnt, ethNr: SmallInt;
  ethHint, rawHint: string;
begin
  try
    for i:= 1 to Length(mac_cnt)-1 do
      begin
        ethNr:= ((i-1)*2)+1; // ((e-1)*2)+1 = eth 1, 3, 5, 7
        mCnt:= Length(mac_cnt[i]);
        if (mCnt > 1) then
          begin
            eth_edit[ethNr].Color:= $0000A400;
            eth_edit[ethNr].Text:= mac_cnt[i][0].nimi;
            ethHint:= '';
            rawHint:= '';
            for j:= 0 to mCnt-1 do
              begin
                if (mac_cnt[i][j].nimi <> '') then
                  rawHint:= mac_cnt[i][j].nimi + ' - ' + mac_cnt[i][j].macAadress
                else
                  rawHint:= mac_cnt[i][j].macAadress;
                if (j <> mCnt-1) then
                  ethHint:= ethHint + rawHint + #13#10
                else
                  ethHint:= ethHint + rawHint;
              end; // end for j loop
            eth_edit[ethNr].Hint:= ethHint;
          end
        else if (mCnt = 1) AND (mac_cnt[i][0].nimi <> 'dummy') then
          begin
            eth_edit[ethNr].Text:= mac_cnt[i][0].nimi;
            if (mac_cnt[i][0].nimi <> '') then
              eth_edit[ethNr].Hint:= mac_cnt[i][0].nimi + ' - ' + mac_cnt[i][0].macAadress
            else
              eth_edit[ethNr].Hint:= mac_cnt[i][0].macAadress;
          end;

      end; // end i for loop
  except on E:Exception do
    uHost2.writeErrorLog('Error @ tootelMacList: ' + E.Message);
  end;
end;


procedure TuStatusTS.collectMaxSpeed;
var
  speedThreader: TSpeedThreader;
begin
  try
    speedThreader:= TSpeedThreader.Create(True);
    speedThreader.setSpeedEdit(lq_edit[6], lq_edit[7]);
    speedThreader.Resume;
  except on E:Exception do
    uHost2.writeErrorLog('Error @ gathering collectMaxSpeed: ' + E.Message);
  end;
end;

procedure TuStatusTS.getSpeedData;
const
  dsl_speed  = 'Bandwidth';
var
  i, bPos: SmallInt;
  temp, s: string;
begin
  if uHost2.is_connection_alive then
    try
      if router_type = '' then
        get_router_type;
      if soft_version = '' then
        get_software_version;
            
      if (router_type = 'TG789vn') OR (router_type = 'TG787v') OR (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9') then
        sendRequest(':xdsl info', False)
      else
        sendRequest(':adsl info', False);
      for i:= 0 to uHost2.dataBuffer.Count-1 do
        begin
          temp:= uHost2.dataBuffer.Strings[i];
          if (AnsiPos(dsl_speed, temp) > 0) then
            begin
              s:= uHost2.Koolon(temp);
              bPos:= AnsiPos('/', s);
              lq_edit[4].Text:= Trim(Copy(s, 1, bPos-1));
              lq_edit[5].Text:= Trim(Copy(s, bPos+1, MaxInt));
            end;
        end;
    except on E:Exception do
      uHost2.writeErrorLog('Error @ gathering Misc data: ' + E.Message);
    end;
end;

procedure TuStatusTS.getXdslData;
const
// kõik ruuterid v.a. TG789vn
  error_const: array[0..5] of string = (
    'Received FEC', 'Received CRC', 'Received HEC',
    'Transmitted FEC', 'Transmitted CRC', 'Transmitted HEC');
  v_tHec= 'Tranmsitted HEC'; // tg585 valesti kirjeldatud



// TG789vn const'd
  tgCRC  = 'Code Violation (CV):';
  tgFEC = 'FEC:';
  tgHEC = 'HEC violation count (HEC):';
var
  i: SmallInt;
  temp, vend, spec: string;
  error_arr: array[0..5] of string;
  aeg: string;
  vendSpec: TStrArr;
begin
	vendSpec:= nil;
  if uHost2.is_connection_alive then
    try
      if router_type = '' then
        get_router_type;
      if soft_version = '' then
        get_software_version;

      if (router_type = 'TG789vn') OR (router_type = 'TG787v') OR (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9') then
        sendRequest(':xdsl info expand enabled', False)
      else
        sendRequest(':adsl info expand enabled', False);
      for i:= 0 to uHost2.dataBuffer.Count-1 do
        begin

          temp:= uHost2.dataBuffer.Strings[i];
// Otsime xDSL standardi
          if (AnsiPos('xDSL Standard', temp) > 0) then
            lq_label[1].Caption:= uHost2.Koolon(temp);

// Otsime DSLAMi
          if (AnsiPos('Chipset', temp) > 0) then
            begin
              vend:= Trim(uHost2.Koolon(uHost2.dataBuffer.Strings[i+2]));
              spec:= Trim(uHost2.Koolon(uHost2.dataBuffer.Strings[i+3]));
              vendSpec:= Explode(spec, ' ');
              get_Blocks(vend);
              if (blocks[1] = 'BDCM') OR (blocks[1] = 'IKNS') then
              	begin
	                lq_label[3].Caption:= 'Alcatel';
                  vend_type:= 3;
                end
              else if (blocks[1] = 'GSPN') then
              	begin
                	if (vendSpec[1] = '0010') then
                  	begin
			                lq_label[3].Caption:= 'Nokia D500';
                      vend_type:= 2;
                    end
                  else
                  	begin
			                lq_label[3].Caption:= 'Nokia D50';
                      vend_type:= 1;
                    end;
                end
              else if (blocks[1] = 'ALCB') then
              	begin
	              	lq_label[3].Caption:= 'Nokia D50';
                	vend_type:= 1;
                end
              else
                lq_label[3].Caption:= 'N/A';
            end;
// end DSLAMi otsimine

// Fill PVC
			lq_label[5].Caption:= uHost2.pvcStr;

// DSL uptime ja resets
          if (router_type = 'TG789vn') OR (router_type = 'TG787v') OR (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9') then
            begin

            ds_label[11].ShowHint:= True;
            if (AnsiPos('Up time', temp) > 0) then
              begin
                aeg:= uHost2.Koolon(temp);
                ds_label[11].Caption:= aeg;
                ds_label[11].Hint:= timeAgo(aeg);
              end; // AnsiPos

              if (AnsiPos('Number of reset:', temp) > 0) then
                ds_label[13].Caption:= uHost2.Koolon(temp);
            end
          else
            begin
            ds_label[11].ShowHint:= True;
            if (AnsiPos('Uptime', temp) > 0) then
              begin
                aeg:= uHost2.Koolon(temp);
                ds_label[11].Caption:= aeg;
                ds_label[11].Hint:= timeAgo(aeg);
              end; // AnsiPos
              if (AnsiPos('resets', temp) > 0) then
                ds_label[13].Caption:= uHost2.Koolon(temp);
            end;

// Margin & attenuation
          if (AnsiPos('Margin', temp) > 0) then
            begin
              Get_Blocks(uHost2.Koolon(temp));
              lq_edit[0].Text:= blocks[0];
              lq_edit[1].Text:= blocks[1];
            end;
          if (AnsiPos('Attenuation', temp) > 0) then
            begin
              Get_Blocks(uHost2.Koolon(temp));
              lq_edit[2].Text:= blocks[0];
              lq_edit[3].Text:= blocks[1];
            end;

// Errors
          if (router_type = 'TG789vn') OR (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9') then
            begin

              if ((AnsiPos(tgCRC, temp)> 0) AND (Length(error_arr[1]) = 0)) then
                begin
                  Get_Blocks(uHost2.Koolon(temp));
                  error_arr[1]:= blocks[0];
                  error_arr[4]:= blocks[1];
                  uHost2.alqTs.errors_list[1]:= blocks[0];
                  uHost2.alqTs.errors_list[4]:= blocks[1];
                end;

              if ((AnsiPos(tgFEC, temp)> 0) AND (Length(error_arr[0]) = 0)) then
                begin
                  Get_Blocks(uHost2.Koolon(temp));
                  error_arr[0]:= blocks[0];
                  error_arr[3]:= blocks[1];
                  uHost2.alqTs.errors_list[0]:= blocks[0];
                  uHost2.alqTs.errors_list[3]:= blocks[1];
                end;

              if ((AnsiPos(tgHEC, temp)> 0) AND (Length(error_arr[2]) = 0)) then
                begin
                  Get_Blocks(uHost2.Koolon(temp));
                  error_arr[2]:= blocks[0];
                  error_arr[5]:= blocks[1];
                  uHost2.alqTs.errors_list[2]:= blocks[0];
                  uHost2.alqTs.errors_list[5]:= blocks[1];
                end;
            end // router_type = tg789vn
          else
            begin
              if (AnsiPos(error_const[0], temp) > 0) then
                begin
                  uHost2.alqTs.alq_memo[1].Lines.Add(error_const[0]+ ' : ' + uHost2.Koolon(temp));
                  uHost2.alqTs.errors_list[0]:= uHost2.Koolon(temp);
                end;

              if (AnsiPos(error_const[1], temp) > 0) then
                begin
                  uHost2.alqTs.alq_memo[1].Lines.Add(error_const[1]+ ' : ' + uHost2.Koolon(temp));
                  uHost2.alqTs.errors_list[1]:= uHost2.Koolon(temp);
                end;

              if (AnsiPos(error_const[2], temp) > 0) then
                begin
                  uHost2.alqTs.alq_memo[1].Lines.Add(error_const[2]+ ' : ' + uHost2.Koolon(temp));
                  uHost2.alqTs.errors_list[2]:= uHost2.Koolon(temp);
                end;

              if (AnsiPos(error_const[3], temp) > 0) then
                begin
                  uHost2.alqTs.alq_memo[1].Lines.Add(error_const[3]+ ' : ' + uHost2.Koolon(temp));
                  uHost2.alqTs.errors_list[3]:= uHost2.Koolon(temp);
                end;

              if (AnsiPos(error_const[4], temp) > 0) then
                begin
                  uHost2.alqTs.alq_memo[1].Lines.Add(error_const[4]+ ' : ' + uHost2.Koolon(temp));
                  uHost2.alqTs.errors_list[4]:= uHost2.Koolon(temp);
                end;

              if (AnsiPos(error_const[5], temp) > 0) then
                begin
                  uHost2.alqTs.alq_memo[1].Lines.Add(error_const[5]+ ' : ' + uHost2.Koolon(temp));
                  uHost2.alqTs.errors_list[5]:= uHost2.Koolon(temp);
                end
              else if (AnsiPos(v_tHEC, temp) > 0) then
                begin
                  uHost2.alqTs.alq_memo[1].Lines.Add(error_const[5]+ ' : ' + uHost2.Koolon(temp));
                  uHost2.alqTs.errors_list[5]:= uHost2.Koolon(temp);
                end;
            end; // router_type = else
        end; // enf for i loop

        if (router_type = 'TG789vn') OR (soft_version = '8.C.D.5') OR (soft_version = '8.C.D.9') then
          for i:= 0 to 5 do
            uHost2.alqTs.alq_memo[1].Lines.Add(error_const[i]+ ' : ' + error_arr[i]);



// kui andmete kirjutamisel on memo ees siis kaob esimene rida ära
// forcime memo'le scrollimise 1 index'i peale,
          uHost2.alqTs.alq_memo[1].SelStart:= 0;
          SendMessage(uHost2.alqTs.alq_memo[1].Handle, EM_SCROLLCARET, 0, 0);

    except on E:Exception do
      uHost2.writeErrorLog('Error @ gathering Xdsl data: ' + E.Message);
    end;
end;


procedure TuStatusTS.getAtmData;
var
  i, atmCnt: SmallInt;
begin
  if uHost2.is_connection_alive then
    try
      atmCnt:= 0;
      if (router_type <> 'TG787v') then
        begin
          sendRequest(':atm iflist', False);
          for i:= 0 to uHost2.dataBuffer.Count-1 do
            begin
              if (AnsiPos('dest', uHost2.dataBuffer.Strings[i]) > 0) then
                inc(atmCnt);
            end;
          lq_label[7].Caption:= IntToStr(atmCnt);
        end
      else
        lq_label[7].Caption:= 'N/A';
    except on E:Exception do
      uHost2.writeErrorLog('Error @ gathering Xdsl data: ' + E.Message);
    end;
end;

//////////////// WLAN
procedure TuStatusTS.getWlanData;
var
  i, wl: SmallInt;
  temp, olek: string;
  interop, is_channel_found: boolean;
begin
  is_channel_found:= False;
  if uHost2.is_connection_alive then
    try
      if router_type = '' then
        get_router_type;
      if soft_version = '' then
        get_software_version;

      st_gb_arr[1].Enabled:= True;
      interop:= False;
      sendRequest(':wireless ifconfig', False);
      for i:= 0 to uHost2.dataBuffer.Count-1 do
        begin
          temp:= uHost2.dataBuffer.Strings[i];

// Wireless state
          if (router_type = 'TG789vn') then
            begin
              if (AnsiPos('Oper State', temp) > 0) then
                olek:= uHost2.Koolon(temp);
            end // tg789 only
          else
            begin
              if (AnsiPos('State', temp) > 0) then
                olek:= uHost2.Koolon(temp);
            end; // other routers

          if (Length(olek) > 0) then
            begin
              if (olek = 'enabled') then
                begin
                  wl_button[0].Enabled:= False;
                  wl_button[1].Enabled:= True;
                  wl_button[2].Enabled:= True;
                end // enabled
              else
                begin
                  wl_button[0].Enabled:= True;
                  wl_button[1].Enabled:= False;
                  wl_button[2].Enabled:= False;
                end; // disabled
            end; // Length(olek)

// Wireless SSID
          if (AnsiPos('Network name', temp) > 0) then
            wl_edit[0].Text:= uHost2.Koolon(temp);

// Wireless channel
          // TG789 on nii mölakas, et channel järgi otsida ei saa, on ka teisi parameetre
          // seetõttu otsime välja Channelwidth ja võtame sellest Pos'st järgmise rea
          if Not is_channel_found then
            if (router_type = 'TG789vn') then
              begin
                if (AnsiPos('Channelwidth', temp) > 0) then
                  begin
                    Get_Blocks(uHost2.Koolon(uHost2.dataBuffer.Strings[i+1]));
                    wl_combobox[0].Text:= blocks[0];
                    wl_label[6].Caption:= blocks[1];
                    is_channel_found:= True;
                  end;
              end
            else // kõik teised ruuterid
              if (AnsiPos('Channel', temp) > 0) then
                begin
                  Get_Blocks(uHost2.Koolon(temp));
                  wl_combobox[0].Text:= blocks[0];
                  wl_label[6].Caption:= blocks[1];
                  is_channel_found:= True;
                end;

// Wirelesss interoperability
          if (AnsiPos('Interoperability', temp) > 0) then
            begin
              for wl:= 0 to Length(wl_interop)-1 do
                if (uHost2.Koolon(temp) = wl_combobox[2].Items[wl]) then
                  begin
                    wl_combobox[2].ItemIndex:= wl;
                    interop:= True;
                    break;
                  end;
            end;

        end; // end for i loop
    if NOT interop then
      uHost2.disGray(wl_combobox[2], False);
    except on E:Exception do
      uHost2.writeErrorLog('Error @ gathering Wlan data: ' + E.Message);
    end;
end;

procedure TuStatusTS.getWlanKeyData;
var
  i, sec_type: SmallInt;
  temp: string;
begin
  if uHost2.is_connection_alive then
    try
      for i:= 0 to 1 do
        uHost2.disGray(wl_edit[i], True);
      sendRequest(':wireless secmode config', False);
      wl_edit[1].Clear;
      wl_edit[1].Hint:= '';
      sec_type:= 0;
      wl_sec_type:= 0;
      for i:= 0 to uHost2.dataBuffer.Count-1 do
        begin
          temp:= uHost2.dataBuffer.Strings[i];
// Type of security
          if (AnsiPos('Security level', temp) > 0) then
            if (AnsiPos('WPA', temp) > 0) then
              begin
                sec_type:= 1;
                wl_edit[1].Color:= $0000A400;//$0000C600;
              end
            else if (AnsiPos('WEP', temp) > 0) then
              begin
                sec_type:= 2;
                wl_edit[1].Color:= $004080FF;
              end;
// end of security

// Key
          if (sec_type = 1) then // wpa
            begin
              if (AnsiPos('preshared', temp) > 0) or
                (AnsiPos('passphrase', temp) > 0 ) then
                wl_edit[1].Text:= uHost2.Koolon(temp);

// Encryption type
              if (AnsiPos('encryption', temp) > 0) then
                wl_edit[1].Hint:= '(' + uHost2.Koolon(temp) + ')';
// end of encryption type

// Encryption version
              if (AnsiPos('version', temp) > 0) then
                if (Trim(uHost2.Koolon(temp)) = 'WPA') then
                  begin
                    wl_sec_type:= 2;
                    wl_combobox[1].ItemIndex:= 2;
                    wl_edit[1].Hint:= 'WPA ' + wl_edit[1].Hint;
                  end
                else
                  begin
                    wl_sec_type:= 3;
                    wl_combobox[1].ItemIndex:= 3;
                    wl_edit[1].Hint:= 'WPA+WPA2 ' + wl_edit[1].Hint;
                  end;
// end of version


            end // end of sec_type 1
          else if (sec_type = 2) then // wep
            begin
// Key
              if (AnsiPos('encryption', temp) > 0) then
                wl_edit[1].Text:= uHost2.Koolon(temp);

              wl_edit[1].Color:= $004080FF;
              wl_edit[1].Hint:= 'WEP';
              wl_sec_type:= 1;
              wl_combobox[1].ItemIndex:= 1;
            end; // end of sec_type 2
        end; // end for i loop
    except on E:Exception do
      uHost2.writeErrorLog('Error @ gathering secutiry data: ' + E.Message);
    end;
end;


{**************************** Control Panel handlers **********************}
/////////////////////////// Device

procedure TuStatusTS.launchDevice(Sender: TObject);
begin
  if Sender is TLabel then
    ShellExecute(uHost2.Handle, 'open', PChar(uHost2.brwPath),
      PChar('http://marvin.elion.ee/device/?SERIAL=' + TLabel(Sender).Caption), nil, SW_SHOWNOACTIVATE);
end;

// END of Device handler

////////////////////////// WLAN

procedure TuStatusTS.wlanState(Sender: TObject);
var
  wTag: SmallInt;
begin
  if (Sender is TButton) then
    if uHost2.is_connection_alive then
      begin
        wTag:= TButton(Sender).Tag;
        if (wTag = 0) then
          begin
            if (router_type = 'TG789vn') then
              begin
                uHost2.writeLn_to_terminal(':wireless ifconfig any enabled');
                uHost2.writeLn_to_terminal(':wireless ifconfig state enabled');
              end
            else
              uHost2.writeLn_to_terminal(':wireless ifconfig state enabled');
              
            uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
            sendRequest(':saveall');
            uHost2.st_loadInfo.Caption:= ' WLAN enabled';
            wl_button[0].Enabled:= False;
            wl_button[1].Enabled:= True;
            wl_button[2].Enabled:= True;
          end
        else
          begin
            uHost2.writeLn_to_terminal(':wireless ifconfig state disabled');
            uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
            sendRequest(':saveall');
            uHost2.st_loadInfo.Caption:= ' WLAN disabled';
            wl_button[0].Enabled:= True;
            wl_button[1].Enabled:= False;
            wl_button[2].Enabled:= False;
          end; // end of wTag
      end // end of is_connection_alive
    else
      Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

procedure TuStatusTS.changeWlan(Sender: TObject);
var
  i, wCnt: SmallInt;
begin
  if Sender is TButton then
    try
      if uHost2.is_connection_alive then
        begin
          if (wl_checkbox[4].Checked) AND (router_type <> 'TG789vn') then
            if (wl_combobox[2].ItemIndex = 4) then
              begin
                Application.MessageBox(PAnsiChar(wl_combobox[2].Items[4] + ' not supported'),
                  'Laiskuss annab teada', MB_ICONWARNING);
                wl_checkbox[4].Checked:= False;
              end;

          wCnt:= 0;
          st_refreshB.Enabled:= False;
          for i:= 0 to Length(wl_checkbox)-1 do
            if wl_checkbox[i].Checked then
              begin
                changeWlanPar(i);
                inc(wCnt);
              end;

          if (wCnt > 0) then
            begin
              uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
              sendRequest(':saveall');
              uHost2.st_loadInfo.Caption:= ' WLAN info updated';
            end
          else
            uHost2.st_loadInfo.Caption:= ' No changes made...';
          st_refreshB.Enabled:= True;
        end // end of tcpc.connected
      else
        Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
    except on E:Exception do
      uHost2.writeErrorLog('Error @ changing WLAN: ' + E.Message);
    end;
end;

procedure TuStatusTS.changeWlanPar(kumb: byte);
var
  i, wl, sec_type: SmallInt;
  temp, sec_valik: string;
  interop, muudetud: boolean;
begin
  wl_checkbox[kumb].Checked:= False;
  uHost2.whereDoYouGo:= 2;
  case kumb of
    0: // SSID
      begin
        uHost2.st_loadInfo.Caption:= ' Updating SSID...';
        uHost2.writeLn_to_terminal(':wireless ifconfig ssid=" ' + wl_edit[0].Text + '"');
        wl_edit[0].Clear;
        sendRequest(':wireless ifconfig');
        for i:= 0 to uHost2.dataBuffer.Count-1 do
          begin
    // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
            if (i > uHost2.dataBuffer.Count) then
              break;

            temp:= uHost2.dataBuffer.Strings[i];
            if (AnsiPos('Network name', temp) > 0) then
              wl_edit[0].Text:= uHost2.Koolon(temp);
          end; // end for i loop

      end; // end case 0

    1: // Encryption Key
      begin
        uHost2.st_loadInfo.Caption:= ' Updating encryption key...';
        muudetud:= False;

// kui encryption type on muutmisel siis muudame vastavalt uuele seadistusele,
// vastasel juhul muudame vastavalt päritud encryption tüübile
        if wl_checkbox[3].Checked  then
          sec_type:= wl_combobox[1].ItemIndex
        else
          sec_type:= wl_sec_type;

        if (sec_type = 1) then
          if (isWepValid(wl_edit[1].Text)) then
            begin
              muudetud:= True;
              uHost2.writeLn_to_terminal(':wireless secmode config mode disable');
              uHost2.writeLn_to_terminal(':wireless secmode wep encryptionkey ' + wl_edit[1].Text);
              uHost2.writeLn_to_terminal(':wireless secmode config mode wep');
            end  // end of isWepValid
          else
            Application.MessageBox(PAnsiChar('Invalid WEP key:' + #13#10 +
              'expected format 5 or 13 ASCII characters, or 10 or 26 HEX digits.'),
              'Laiskuss annab teada', MB_ICONWARNING);
        // end if sec_type 1

        if (sec_type > 1) then
          if (Length(wl_edit[1].Text) >= 8) then
            begin
              if sec_type = 2 then
                sec_valik:= 'wpa'
              else if sec_type = 3 then
                sec_valik:= 'wpa+wpa2';
              muudetud:= True;
              uHost2.writeLn_to_terminal(':wireless secmode config mode disable');
              uHost2.writeLn_to_terminal(':wireless secmode wpa-psk presharedkey ' + wl_edit[1].Text);
              uHost2.writeLn_to_terminal(':wireless secmode wpa-psk version=' + sec_valik);
              uHost2.writeLn_to_terminal(':wireless secmode config mode wpa-psk');
            end // end of WPA Length
          else
            Application.MessageBox(PAnsiChar('Invalid WPA key - WPA key length must be 8-63 characters'),
              'Laiskuss annab teada', MB_ICONWARNING);
         // end if sec_type 2, 3

        if (muudetud) then
          begin
            wl_edit[1].Clear;
            sendRequest(':wireless secmode config');
            for i:= 0 to uHost2.dataBuffer.Count-1 do
              begin
      // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
                if (i > uHost2.dataBuffer.Count) then
                  break;

                temp:= uHost2.dataBuffer.Strings[i];
                if (sec_type = 1) then // wep
                  begin
                    if (AnsiPos('encryption', temp) > 0) then
                      wl_edit[1].Text:= uHost2.Koolon(temp);
                  end
                else if (sec_type > 1) then // wpa
                  begin
                    if (AnsiPos('preshared', temp) > 0) then
                      wl_edit[1].Text:= uHost2.Koolon(temp);
                  end;
            end; // for i loop
          end; // end of if muudetud
      end; // end case 1

    2: // Channel
      begin
        uHost2.st_loadInfo.Caption:= ' Updating channel...';
        uHost2.writeLn_to_terminal(':wireless ifconfig channel ' + wl_combobox[0].Text);
        sendRequest(':wireless ifconfig');
        for i:= 0 to uHost2.dataBuffer.Count-1 do
          begin
    // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
            if (i > uHost2.dataBuffer.Count) then
              break;

            temp:= uHost2.dataBuffer.Strings[i];
          // TG789 on nii mölakas, et channel järgi otsida ei saa, on ka teisi parameetre
          // seetõttu otsime välja Channelwidth ja võtame sellest Pos'st järgmise rea
          if (router_type = 'TG789vn') then
            begin
              if (AnsiPos('Channelwidth', temp) > 0) then
                begin
                  Get_Blocks(uHost2.Koolon(uHost2.dataBuffer.Strings[i+1]));
                  wl_combobox[0].Text:= blocks[0];
                  wl_label[6].Caption:= blocks[1];
                end;
            end
          else // kõik teised ruuterid
            if (AnsiPos('Channel', temp) > 0) then
              begin
                Get_Blocks(uHost2.Koolon(temp));
                wl_combobox[0].Text:= blocks[0];
                wl_label[6].Caption:= blocks[1];
              end;

          end; // end for i loop
      end; // end case 2

    3: // Encryption type
      begin
        uHost2.st_loadInfo.Caption:= ' Updating encryption...';
        case wl_combobox[1].ItemIndex of
          0:
            begin
              uHost2.writeLn_to_terminal(':wireless secmode config mode disable');
            end; // end of case 0 (wl_combobox[1]
          1:
            begin
              uHost2.writeLn_to_terminal(':wireless secmode config mode wep');
            end; // end of case 1 (wl_combobox[1]
          2:
            begin
              uHost2.writeLn_to_terminal(':wireless secmode config mode disable');
              uHost2.writeLn_to_terminal(':wireless secmode wpa-psk version=wpa');
              uHost2.writeLn_to_terminal(':wireless secmode config mode wpa-psk');
            end; // end of case 2 (wl_combobox[1]
          3:
            begin
              uHost2.writeLn_to_terminal(':wireless secmode config mode disable');
              uHost2.writeLn_to_terminal(':wireless secmode wpa-psk version=wpa+wpa2');
              uHost2.writeLn_to_terminal(':wireless secmode config mode wpa-psk');
            end; // end of case 3 (wl_combobox[1]
        end; // end of wl_combobox[1] case

        getWlanKeyData;
      end; // end case 3

    4: // interoperability
      begin
        interop:= False;
        uHost2.st_loadInfo.Caption:= ' Updating interoperability status...';
        uHost2.writeLn_to_terminal(':wireless ifconfig interop ' +
          wl_combobox[2].Items[wl_combobox[2].itemIndex]);
        sendRequest(':wireless ifconfig');

        for i:= 0 to uHost2.dataBuffer.Count-1 do
          begin
    // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
            if (i > uHost2.dataBuffer.Count) then
              break;

            temp:= uHost2.dataBuffer.Strings[i];
            if (AnsiPos('Interoperability', temp) > 0) then
              begin
                for wl:= 0 to Length(wl_interop)-1 do
                  if (uHost2.Koolon(temp) = wl_combobox[2].Items[wl]) then
                    begin
                      wl_combobox[2].ItemIndex:= wl;
                      interop:= True;
                      break;
                    end; // end of comparison
              end; // end of ansiPos
          end; // end for i loop
        if NOT interop then
        uHost2.disGray(wl_combobox[2], False);
      end; // end case 4
      
  end; // end of case 
end;

function TuStatusTS.isWepValid(sisend: string): boolean;
var
  lub: set of 'A'..'z';
  i, j, uus_len: integer;
begin
  Result:= False;
  lub:= ['A'..'z'];
  j:= 0;
  uus_len:= Length(sisend);
  for i:= 0 to uus_len do
    if (sisend[i] in lub) then inc(j);
  if (j > 0) then
    begin
    if (uus_len = 5) or (uus_len =  13) then
      Result:= True;
    end
  else if (j = 0) then
    begin
      if (uus_len = 10) or (uus_len = 26) then
        Result:= True;
    end
  else
    Result:= False;
end;

procedure TuStatusTS.showWlanClients(Sender: TObject);
begin
  if Sender is TButton then
    if uHost2.is_connection_alive then
      uHost2.writeLn_to_terminal(':wireless stations list')
    else
      Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

procedure TuStatusTS.scanWlan(Sender: TObject);
begin
  if Sender is TButton then
    if uHost2.is_connection_alive then
      begin
        if (MessageDlg('All wlan connections will be disconnected, proceed?',
          mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
            uHost2.writeLn_to_terminal(':wireless wds scanresults rescan enabled');
      end // end of tcpc.connected
    else
      Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;



// END of WLAN handler

///////////////////////// ETH


// marvin label handlers
procedure TuStatusTS.enterLabel(Sender: TObject);
begin
  if (Sender is TLabel) then
    begin
      if (TLabel(Sender) = ds_label[9]) OR (TLabel(Sender) = ds_label[11]) then
        begin
          TLabel(Sender).Color:= $00E2D7CF;
        end
      else // Device status labels
        begin
          if (TLabel(Sender).Tag > 100) then
            TLabel(Sender).Font.Style:= TLabel(Sender).Font.Style + [fsUnderline];
          TLabel(Sender).Color:= $00D6C6B1;
          TLabel(Sender).Cursor:= crHandPoint;
        end; // all other
    end;
end;

procedure TuStatusTS.exitLabel(Sender: TObject);
begin
  if (Sender is TLabel) then
    begin
      if (TLabel(Sender) = ds_label[9]) OR (TLabel(Sender) = ds_label[11]) then
        begin
          TLabel(Sender).Color:= $00E4E4E4;
        end
      else // Device status labels
        begin
          if (TLabel(Sender).Tag > 100) then
            TLabel(Sender).Font.Style:= TLabel(Sender).Font.Style - [fsUnderline];
          TLabel(Sender).Color:= $00E0D5C7;
        end; // all other
    end;
end;

procedure TuStatusTS.ethMacSet(ethif: TEdit; open: boolean);
var
  lTag: SmallInt;
begin
// kontrollime, et avatud oleks ikka õige asi
  lTag:= -1;
  try
    if (ethif <> nil) then
      lTag:= ethif.Tag;
  except
    lTag:= -1;
  end;

  try
    if (open) then
      begin
        AnimateWindow(eth_panel.Handle, 100, AW_ACTIVATE OR AW_CENTER);
      // animateWindow vastane häkk, vastasel juhul nupp & scrollBox ei ole nähtav
        ShowWindow(eth_navi_panel.Handle, SW_SHOW);
        ShowWindow(eth_panel_button.Handle, SW_SHOW);
        eth_panel_info_label.Caption:= 'Ethernet port ' + inttostr((lTag div 2) + 1);
        if (lTag > -1) then
          looPanelList((lTag div 2) + 1);
      end
    else if (NOT open) then
      begin
        uHost2.vabadus(eth_panel_dev_label);
        SetLength(eth_panel_dev_label, 0);
        AnimateWindow(eth_panel.Handle, 100, AW_HIDE OR AW_CENTER);
      end;

  except on E:Exception do
    uHost2.writeErrorLog('Exception @ ethMacSet (' + IntToStr(lTag) + '): ' + E.Message);
  end;

end;

// end of eth_panel & marvin label handlers

procedure TuStatusTS.looPanelList(vanemaID: Smallint);
var
  i, laius, macArv: SmallInt;
begin
  macArv:= Length(mac_cnt[vanemaID]);
  try
    if (macArv > 4) then
      laius:= 17
    else
      laius:= 0;
  except
    laius:= 0;
  end;

  try
    if (mac_cnt[vanemaID][0].nimi <> 'dummy') then
      for i:= 0 to macArv-1 do
        begin
          SetLength(eth_panel_dev_label, i+1);
          eth_panel_dev_label[i]:= TLabel.Create(nil);
          eth_panel_dev_label[i].Parent:= eth_navi_panel;
          eth_panel_dev_label[i].AutoSize:= False;
          eth_panel_dev_label[i].Layout:= tlCenter;
          eth_panel_dev_label[i].Top:= (i*24) + 2;
          eth_panel_dev_label[i].Left:= 2;
          eth_panel_dev_label[i].Width:= eth_panel.Width - 7 - laius;
          eth_panel_dev_label[i].Height:= 22;
          eth_panel_dev_label[i].ShowHint:= True;
          eth_panel_dev_label[i].Caption:= mac_cnt[vanemaID][i].nimi;
          eth_panel_dev_label[i].Color:= $00F0E4E4;
        end;
  except on E:Exception do
    uHost2.writeErrorLog('Exception @ looPanelList: ' + E.Message);
  end;
end;

procedure TuStatusTS.killETH(Sender: TObject);
var
  state, stateStr: string;
begin
  if Sender is TBitBtn then
    begin
      state:= '';
      if TBitBtn(Sender).Kind = bkOk then
        begin
          state:= 'disabled';
          stateStr:= 'Disable';
        end
      else if TBitBtn(Sender).Kind= bkCancel then
        begin
          state:= 'enabled';
          stateStr:= 'Enable';
        end;

      if (uHost2.is_connection_alive AND (state <> '')) then
        begin
          if (MessageDlg((stateStr + ' ETH port ' + IntToStr(TBitBtn(Sender).Tag) + '?'),
            mtWarning, [mbOK, mbCancel], 0) = mrOK) then
            begin
              //uHost2.writeLn_to_terminal
              sendRequest('eth device ifconfig intf ethif' + IntToStr(TBitBtn(Sender).Tag) +
                ' state ' + state + ' type auto');
              getEthData;
              uHost2.st_loadInfo.Caption:= ' ETH port ' + IntToStr(TBitBtn(Sender).Tag) +
                ' = ' + state + '...';
            end; // end of MessageDlg
        end // end if tcpc.connected
      else
        Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
    end;
end;


// ETH lisavõimalused (duplex mode muutmine, mac aadress expandor) - dblClick handler
procedure TuStatusTS.ethAdvancedMode(Sender: TObject);
const
  duplex: array[0..4] of string = (
    'auto', '10BaseTHD', '10BaseTFD', '100BaseTHD', '100BaseTFD');
var
  ethNr, i, leitud: SmallInt;
begin
  if (Sender is TEdit) then
    begin
      ethNr:= TEdit(Sender).Tag;
    // kui mod 2 = 0 siis on valitud 0,2,4,6,8 väljad (duplex)
    // sel juhul aktiveerime duplex mode changer'i
      if ((ethNr mod 2) = 0) AND (ethNr <> 8) then
        begin
          for i:= 0 to 3 do
            begin
              eth_edit[i*2].Visible:= True;
              eth_edit[i*2+1].Left:= eth_edit[i*2].Left + eth_edit[i*2].Width;
              eth_edit[i*2+1].Width:= 218;
            end;
          for i:= 0 to 1 do
            eth_duplex_button[i].Visible:= True;

          eth_edit[ethNr].Visible:= False;
          eth_edit[ethNr+1].Left:= eth_duplex_combobox.Left + eth_duplex_combobox.Width;
          eth_edit[ethNr+1].Width:= eth_edit[ethNr+1].Width - eth_duplex_combobox.Width + eth_edit[ethNr].Width;
          eth_duplex_combobox.Top:= eth_edit[ethNr].Top;
          eth_duplex_combobox.Visible:= True;
          eth_duplex_combobox.Tag:= ethNr div 2;

          leitud:= -1;
          for i:= 0 to Length(duplex)-1 do
            if (duplex[i] = eth_edit[ethNr].Hint) then
              begin
                leitud:= i;
                break;
              end;
          if (leitud > 0) then
            eth_duplex_combobox.ItemIndex:= leitud
          else
            eth_duplex_combobox.ItemIndex:= 0;
        end
    // kui mod 2 <> 0 siis on valitud 1,3,5,7,9 väljad (mac)
    // sel juhul aktiveerime eth advanced panel'i
      else if ((ethNr mod 2) <> 0) AND (ethNr <> 9) then
        begin
          ethMacSet(TEdit(Sender), True);
        end;
    end // end if Sender Edit
  else if (Sender is TButton) then
    ethMacSet(nil, False);
end;

// ETH duplex muutmine
procedure TuStatusTS.duplexSet(Sender: TObject);
var
  i, cbTag: SmallInt;
  sending: string;
begin
  if Sender is TButton then
    begin
      cbTag:= eth_duplex_combobox.Tag;
      sending:= eth_duplex_combobox.Items[eth_duplex_combobox.ItemIndex];

      if (TButton(Sender).Tag = 0) then // Change button
      begin
        if MessageDlg('Change ethif' + IntToStr(cbTag + 1) +' type to "' + sending + '" ?'
          , mtWarning, mbOkCancel, 0) = mrOk then
          begin
            if uHost2.is_connection_alive then
              begin
                for i:= 0 to 1 do
                  eth_duplex_button[i].Visible:= False;
                eth_duplex_combobox.Visible:= False;
                eth_edit[cbTag*2].Visible:= True;
                eth_edit[cbTag*2+1].Left:= eth_edit[cbTag*2].Left + eth_edit[cbTag*2].Width;
                eth_edit[cbTag*2+1].Width:= 218;
                
                st_refreshB.Enabled:= False;
                uHost2.st_loadInfo.Caption:= ' Updating ETH duplex mode, please wait...';
                uHost2.whereDoYouGo:= 2;

                uHost2.writeLn_to_terminal(':eth device ifconfig intf ethif' +
                  IntToStr(cbTag + 1) + ' type ' + sending + ' state disabled');
                uHost2.writeLn_to_terminal(':eth device ifconfig intf ethif' + IntToStr(cbTag + 1) +
                ' state enabled');

                uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
                sendRequest(':saveall');
                getEthData;
                uHost2.st_loadInfo.Caption:= ' ETH duplex mode updated...';
                st_refreshB.Enabled:= True;
              end // end tcpc.connected
            else
              Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
          end; // end if mrOK
      end // end of Tag = 0
      else if (TButton(Sender).Tag = 1) then   // Cancel button
        begin
          for i:= 0 to 1 do
            eth_duplex_button[i].Visible:= False;
          eth_duplex_combobox.Visible:= False;
          eth_edit[cbTag*2].Visible:= True;
          eth_edit[cbTag*2+1].Left:= eth_edit[cbTag*2].Left + eth_edit[cbTag*2].Width;
          eth_edit[cbTag*2+1].Width:= 218;
        end; // end of Tag = 1
    end; // end of Sender
end;


end.

