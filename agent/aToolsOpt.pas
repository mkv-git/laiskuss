unit aToolsOpt;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ShellApi, ShlObj, SHFolder, CommDlg, Registry;


// hotkey registri data
type
  THotKeys = record
    action: Word;
    shortcut: string[40];
  end;

// const hotkey list nimekirja jaoks
type
  THotKeyList = record
    hkNimi: string;
    hkID: Word;
  end;

type
  TaOptions = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
  // global var
    options_tpg: TPageControl; // Options pagecontrol, mille all asub 3 lehed_tpg
    lehed_tpg: array[0..2] of TTabSheet; // settings, UI, hotkey valikud
    butPan: TPanel;
    naviBut: array[0..1] of TButton; // Apply & Close 

  // settings var
    sgb: array[0..2] of TGroupBox;
    optEdit: array[0..1] of TEdit;
    optBut: array[0..1] of TButton;
    optCB: array[0..1] of TCheckBox;
    options_label: TLabel;
    options_combobox: TComboBox;

  // UI var
    ugb: array[0..1] of TGroupBox;
    termRB: array[0..1] of TRadioButton;
    termMem: TMemo; // näidisMemo
    termGenPanel: array[0..2] of TPanel; // 3 RGB selectorit
    termColPanel: array[0..14] of TPanel; // preset värvivalikud
    termColEdit: array[0..2] of TEdit; // värvivalikud numbri abil
    termRGB: array[0..2] of TTrackBar; // värvivalikud trackBari abil
    termFontLabel: array[0..1] of TLabel;
    termFontLB: array[0..1] of TListBox; // font ja fondisuurus
    termBoldCB: TCheckBox; // to be or not to be BOLD

  // hotkeys var
    hkSetList: TListView; // nimekiri määratud hotkey'st
    hkComList: TComboBox; // funktsioonide nimekiri
    hkButtons: array[0..3] of TButton; // add, set, remove ja set to default nuppud - OnShow event
    hkLabels: array[0..1] of TLabel;
    hkEnableCB: TCheckBox;
    hkEdit: TEdit;
    hkSisend: array[0..2] of string; // hotkey mappimine
    hotkeys: array of THotKeys;
    hotKeyList: File of THotKeys;

  // General procedures
    procedure applyOptions(Sender: TObject);
    procedure closeOptions(Sender: TObject);

  // Settings procedures
    procedure show_settings(Sender: TObject); // Settings parameetrite laadimine - OnShow event
    procedure activateCB(Sender: TObject); // checkbox'i onClick naviBut[0].enabled = True
    procedure activateComboBox(Sender: TObject);

  // Kausta ja faili lokaliseerimise dialogid
    function GetFolderDialog(Handle: HWND; Pealkiri: string; var dirLocation: string): boolean;
    function GetFileDialog: string;
  // END

    procedure Browse_Alq_Folder(Sender: TObject); // Adv. LQ kausta asukoha määramine
    procedure Set_Default_Browser(Sender: TObject); // Browseri määramine - by default on IE

  // UI procedures
    procedure show_ui(Sender: TObject); // UI parameetrite laadimine
    function colorPanelValik(panNo: LongInt): TColor;  // määäratud värvide (15) valik
    procedure translateColor(varv: TColor); // termColEdit väärtuste ja termRGB position määramine
    procedure selectRButt(Sender: TObject); // termGenPanel või termLab selekteerimie Radiobutton'i kaudu
    procedure setColor(Sender: TObject); // termColPanel'i kaudu värvi muutmine
    procedure trackColor(Sender: TObject); // trackBar'i kaudu värvi muutmine
    procedure manualSetColor(Sender: TObject); // termColEdit'i kaudu värvi muutmine
    procedure correctInput(Sender: TObject; var Key: char); // lubatud ainult numbrid
    procedure setFBold(Sender: TObject);
    procedure setFFont(Sender: TObject);
    procedure setFSize(Sender: TObject);

  // Hotkey procedure
    procedure show_hotkey(Sender: TObject); // Hotkey TAB'i parameetrite laadimine - OnShow event
    procedure loadHotKeyList; // hotkey'de laadimine
    procedure addHotkey(Sender: TObject); // Add nupp - hotkey lisamine
    procedure setHotkey(Sender: TObject); // Set nupp - hotkey muutmine
    procedure delHotkey(Sender: TObject); // Remove nupp - hotkey kustutamine
    procedure hkDown(Sender: TObject; var Key: Word;
  Shift: TShiftState); // Hotkey sisestamine Edit väljasl  - onkeydown
    procedure hkUp(Sender: TObject; var Key: Word;
  Shift: TShiftState); // Hotkey sisestamine Edit väljasl  - onkeyup
    procedure allowHotkey(Sender: TObject);
    procedure selectHotkey(Sender: TObject);


  public
  // Global procedures
    function getVK_ID(VK_IDENT: Word): string;
  // Settings procedures

  // Tools
  end;

const
  hklItems: array[0..17] of THotKeyList =
  (
  // Status tab 200+
  	(hkNimi: 'Local: Show Status TAB';        hkID: 200),
    (hkNimi: 'Local: Refresh status';         hkID: 201),
    (hkNimi: 'Local: Refresh & Show Status TAB';    hkID: 202),
    (hkNimi: 'Local: Refresh device data';    hkID: 203),
    (hkNimi: 'Local: Refresh WLAN data';    hkID: 204),
    (hkNimi: 'Local: Refresh xDSL data';    hkID: 205),    
    (hkNimi: 'Local: Refresh ETH data';    hkID: 206),    
    
    
  // Adv LQ tab 300+
	  (hkNimi: 'Local: Show Adv. LQ TAB';       hkID: 300),
    (hkNimi: 'Local: Refresh Adv. LQ';        hkID: 301),
    (hkNimi: 'Local: Refresh & Show Adv. LQ TAB';   hkID: 302),

    
  // Misc tab 400+                        
  	(hkNimi: 'Local: Show Misc TAB';          hkID: 400),
    (hkNimi: 'Local: Refresh Misc Data';      hkID: 401),
    (hkNimi: 'Local: Refresh & Show Misc TAB';      hkID: 402),
    (hkNimi: 'Local: Refresh Port forward Data';      hkID: 403),
    (hkNimi: 'Local: Refresh Vlan Data';      hkID: 404),
    (hkNimi: 'Local: Refresh VoIP Data';      hkID: 405),

  // Other shortcus 500+
    (hkNimi: 'Local: Update all data';        hkID: 500),
    (hkNimi: 'Local: Copy Log';               hkID: 501)  

  );
  hkFile: string = 'hkList.l2f';

var
  aOptions: TaOptions;

implementation

uses aMain;



{$R *.dfm}

procedure TaOptions.FormCreate(Sender: TObject);
const
  nupude_nimed: array[0..3] of string = ('Add', 'Set', 'Remove', 'Restore defaults');
var
  i, j: LongInt;
begin
  KeyPreview:= True;
  Top:= Round(Screen.Height/2) - Round(aOptions.Height/2);
 // Left:= Round(Screen.Width/2) - Round(aOptions.Width/2);
 Caption:= 'Options';

  if (NOT Assigned(butPan)) then
    begin
      butPan:= TPanel.Create(Self);
      butPan.Parent:= aOptions;
      butPan.Align:= alBottom;
      butPan.Height:= 35;
      for i:= 0 to 1 do
        begin
          naviBut[i]:= TButton.Create(Self);
          naviBut[i].Parent:= butPan;
          naviBut[i].Width:= 75;
          naviBut[i].Height:= 23;
          naviBut[i].Top:= 6;
          naviBut[i].Left:= (butPan.ClientWidth - 170) + (i*85);
        end;
      naviBut[0].Caption:= 'Apply';
      naviBut[0].OnClick:= applyOptions;
      naviBut[0].Enabled:= False;
      naviBut[1].Caption:= 'OK';
      naviBut[1].OnClick:= CloseOptions;
    end;

  if (NOT Assigned(options_tpg)) then
    begin
      options_tpg:= TPageControl.Create(Self);
      options_tpg.Parent:= aOptions;
      options_tpg.Width:= aOptions.ClientWidth;
      options_tpg.Height:= aOptions.ClientHeight - 35;
      for i:= 0 to 2 do
        begin
          lehed_tpg[i]:= TTabSheet.Create(Self);
          lehed_tpg[i].PageControl:= options_tpg;
          lehed_tpg[i].Align:= alClient;
          lehed_tpg[i].Visible:= True;
        end;
      for i:= 2 downto 0 do
        options_tpg.ActivePage:= lehed_tpg[i];

// Settings TAB Init
      lehed_tpg[0].Caption:= 'Settings';
      lehed_tpg[0].OnShow:= show_settings;
      for i:= 0 to Length(sgb) - 1 do
        if (NOT Assigned(sgb[i])) then
          begin
            sgb[i]:= TGroupBox.Create(Self);
            sgb[i].Parent:= lehed_tpg[0];
            sgb[i].Width:= lehed_tpg[0].Width;
            sgb[i].Height:= 44;
            sgb[i].Top:= 44 * i;
            sgb[i].Visible:= True;
         end;
        sgb[0].Caption:= 'Adv LQ screenshot files vault';
        sgb[1].Caption:= 'Default browser';
        sgb[2].Caption:= 'Global settings';

// Browse Edit & Button
      for i:= 0 to 1 do
        begin
          optEdit[i]:= TEdit.Create(Self);
          optEdit[i].Parent:= sgb[i];
          optEdit[i].Left:= 15;
          optEdit[i].Top:= 15;
          optEdit[i].Height:= 25;
        // parenti pikkus - nuppu pikkus - 45 (elementide vahemaa 3 * 15)
          optEdit[i].Width:= sgb[i].ClientWidth - 75 - 45;

          optBut[i]:= TButton.Create(Self);
          optBut[i].Parent:= sgb[i];
          optBut[i].Left:= optEdit[i].Width + 25;
          optBut[i].Top:= 15;
          optBut[i].Width:= 75;
          optBut[i].Height:= 22;
          optBut[i].Caption:= 'Browse...';
        end;
      optBut[0].OnClick:= Browse_Alq_Folder;
      optBut[1].OnClick:= Set_Default_Browser;

      for i:= 0 to 1 do
        begin
          optCB[i]:= TCheckBox.Create(Self);
          optCB[i].Parent:= sgb[2];
          optCB[i].Checked:= False;
          optCB[i].Top:= 25*i+15;
          optCB[i].Left:= 15;
          optCB[i].Width:= sgb[2].ClientWidth-30;
          optCB[i].Height:= 25;
          optCB[i].OnClick:= activateCB;
        end;

      optCB[0].Caption:= 'Default telnet client';
      optCB[1].Caption:= 'Confirm upon sending configuration';

      options_label:= TLabel.Create(Self);
      with options_label do
        begin
          Parent:= sgb[2];
          Top:= optCB[Length(optCB)-1].Top + optCB[Length(optCB)-1].Height;
          Left:= 15;
          Height:= 21;
          AutoSize:= False;
          Width:= 115;
          Caption:= 'Default connection type:';
          Layout:= tlCenter;
        end;

      options_combobox:= TComboBox.Create(Self);
      with options_combobox do
        begin
          Parent:= sgb[2];
          Top:= options_label.Top;
          Left:= options_label.Left + options_label.Width + 5;
          Style:= csDropDownList;
          OnChange:= activateComboBox;
        end;
      options_combobox.Items.Append('Telnet');
      options_combobox.Items.Append('Telnet@Estpak');
      options_combobox.Items.Append('Serial');

      sgb[2].Height:= 25 * (Length(optCB) + 1) + 20;


// UI TAB Init
      lehed_tpg[1].Caption:= 'User Interface';
      lehed_tpg[1].OnShow:= show_ui;
      for i:= 0 to 1 do
        begin
          ugb[i]:= TGroupBox.Create(Self);
          ugb[i].Parent:= lehed_tpg[1];
          ugb[i].Top:= 0;
          ugb[i].Height:= lehed_tpg[1].Height;
        end;
      ugb[0].Caption:= 'Terminal settings';
      ugb[0].Left:= 5;
      ugb[0].Width:= 250;

      ugb[1].Caption:= 'RGB';
      ugb[1].Left:= ugb[0].Width+10;
      ugb[1].Width:= lehed_tpg[1].ClientWidth - ugb[0].width - 15;

      for i:= 0 to 14 do
        begin
          termColPanel[i]:= TPanel.Create(Self);
          termColPanel[i].Parent:= ugb[1];
          termColPanel[i].Width:= 21;
          termColPanel[i].Height:= 21;
          termColPanel[i].Color:= colorPanelValik(i);
          termColPanel[i].Top:= (i div 5) * 23 + 15;
          termColPanel[i].Left:= (i mod 5) * 23 + 18;
          termColPanel[i].BevelWidth:= 1;
          termColPanel[i].BorderStyle:= bsSingle;
          termColPanel[i].BevelOuter:= bvRaised;
          termColPanel[i].OnClick:= setColor;
          termColPanel[i].Tag:= i;
        end;

      for i:= 0 to 2 do
        begin
        // TrackBari init
          termRGB[i]:= TTrackBar.Create(Self);
          termRGB[i].Parent:= ugb[1];
          termRGB[i].TickStyle:= tsNone;
          termRGB[i].Orientation:= trVertical;
          termRGB[i].Position:= 0;
          termRGB[i].Top:= termColPanel[Length(termColPanel)-1].Top + 25;
          termRGB[i].Left:= i*35 + ugb[1].Width - 122;
          termRGB[i].Width:= 25;
          termRGB[i].Height:= 185;
          termRGB[i].Min:= 0;
          termRGB[i].Max:= 255;
          termRGB[i].OnChange:= trackColor;
          termRGB[i].Tag:= i;

        // Edit init
          termColEdit[i]:= TEdit.Create(Self);
          termColEdit[i].Parent:= ugb[1];
          termColEdit[i].Top:= termRGB[i].Top + termRGB[i].Height;
          termColEdit[i].Left:= termRGB[i].Left - 1;
          termColEdit[i].Width:= 25;
          termColEdit[i].Text:= '0';
          termColEdit[i].OnKeyPress:= correctInput;
          termColEdit[i].OnChange:= manualSetColor;
          termColEdit[i].Tag:= i;
          termColEdit[i].MaxLength:= 3;

        // Panel init
          termGenPanel[i]:= TPanel.Create(Self);
          termGenPanel[i].Parent:= ugb[1];
          termGenPanel[i].Top:= termColEdit[i].Top + termColEdit[i].Height + 2;
          termGenPanel[i].Left:= termColEdit[i].Left;
          termGenPanel[i].Width:= 25;
          termGenPanel[i].Height:= 10;
          termGenPanel[i].BevelOuter:= bvNone;
        end;
      termGenPanel[0].Color:= clRed;
      termGenPanel[1].Color:= clGreen;
      termGenPanel[2].Color:= clBlue;

// terminal settings
      for i:= 0 to 1 do
        begin
        // RadioButton
          termRB[i]:= TRadioButton.Create(Self);
          termRB[i].Parent:= ugb[0];
          termRB[i].Top:= 20;
          termRB[i].Width:= (ugb[0].Width - 20) div 2;
          termRB[i].Left:= i * termRB[i].Width + 5;
          termRB[i].Tag:= i;
          termRB[i].OnClick:= selectRButt;

        // Label
          termFontLabel[i]:= TLabel.Create(Self);
          termFontLabel[i].Parent:= ugb[0];
          termFontLabel[i].Top:= 45;
          termFontLabel[i].Left:= i*174 + 5;
          termFontLabel[i].AutoSize:= False;
          termFontLabel[i].Width:= 25;
          termFontLabel[i].Layout:= tlCenter;

        // ListBox - size & font
          termFontLB[i]:= TListBox.Create(Self);
          termFontLB[i].Parent:= ugb[0];
          termFontLB[i].Top:= 65;
          termFontLB[i].Left:= termFontLabel[i].Left;
          termFontLB[i].Height:= 90;
          termFontLB[i].Width:= (Abs(i-1) *100) + 65;
          termFontLB[i].ShowHint:= True;
          termFontLB[i].Hint:= inttostr((Abs(i-1) *100) + 60);
        end;
      termRB[0].Caption:= 'Terminal''s color';
      termRB[1].Caption:= 'Terminal''s text color';

      termFontLabel[0].Caption:= 'Font';
      termFontLabel[1].Caption:= 'Size';

      termFontLB[0].OnClick:= setFFont;
      termFontLB[0].Items.Add('Consolas');
      termFontLB[0].Items.Add('Courier');
      termFontLB[0].Items.Add('Courier New');
      termFontLB[0].Items.Add('Lucida Console');
      termFontLB[0].Items.Add('Lucida Sans Typewrite');
      termFontLB[0].Items.Add('Terminal');


      termFontLB[1].OnClick:= setFSize;
      termFontLB[1].Items.add('8');
      termFontLB[1].Items.add('10');
      termFontLB[1].Items.add('12');
      termFontLB[1].Items.add('14');

      termBoldCB:= TCheckBox.Create(Self);
      termBoldCB.Parent:= ugb[0];
      termBoldCB.Caption:= 'Bold';
      termBoldCB.Top:= termFontLabel[0].Top;
      termBoldCB.Left:= termFontLabel[0].Width + 25;
      termBoldCB.OnClick:= setFBold;

// terminali näidis
      termMem:= TMemo.Create(Self);
      termMem.Parent:= ugb[0];
      termMem.Width:= ugb[0].Width - 10;
      termMem.Height:= 150;
      termMem.Top:= ugb[0].Height - termMem.Height - 5;
      termMem.Left:= 5;
      termMem.ReadOnly:= True;
      termMem.Text:= 'Lorem ipsum dolor sit amet, ' +
        'consectetur adipiscing elit. Sed luctus volutpat lectus, ' +
        'ac tempor sapien volutpat in. Sed sit amet bibendum metus.' +
        'Phasellus facilisis elit non ante imperdiet hendrerit. ' +
        'Praesent ultricies urna ut nisl sodales posuere. ' +
        'Fusce risus dolor, vehicula quis dictum vel, posuere eget erat.' +
        'Duis sagittis facilisis augue et dignissim. Integer vel nisl mi, ' +
        'et tincidunt quam. Sed eleifend nisl et libero lacinia bibendum. ' +
        'Suspendisse sodales ligula vitae urna auctor tincidunt.';

// Hotkeys TAB Init
      lehed_tpg[2].Caption:= 'Hotkeys';
      lehed_tpg[2].OnShow:= show_hotkey;

      hkEnableCB:= TCheckBox.Create(Self);
      hkEnableCB.Parent:= lehed_tpg[2];
      hkEnableCB.Top:= 7;
      hkEnableCB.Left:= 5;
      hkEnableCB.Caption:= 'Enabled';
      hkEnableCB.OnClick:= allowHotkey;

      hkSetList:= TListView.Create(Self);
      hkSetList.Parent:= lehed_tpg[2];
      hkSetList.Left:= 5;
      hkSetList.Top:= 30;
      hkSetList.Width:= lehed_tpg[2].Width - 10;
      hkSetList.Height:= lehed_tpg[2].Height - 95;
      hkSetList.ViewStyle:= vsReport;
      hkSetList.Columns.Add.Caption:= 'Action';
      hkSetList.Column[0].Width:= 200;
      hkSetList.Columns.Add.Caption:= 'Hotkey';
      hkSetList.Column[1].Width:= 180;
      hkSetList.ReadOnly:= True;
      hkSetList.RowSelect:= True;
      hkSetList.MultiSelect:= True;
      hkSetList.OnClick:= selectHotkey;

      for i:= 0 to 1 do
        begin
          hkLabels[i]:= TLabel.Create(Self);
          hkLabels[i].Parent:= lehed_tpg[2];
          hkLabels[i].AutoSize:= False;
          hkLabels[i].Layout:= tlCenter;
          hkLabels[i].Height:= 21;
          hkLabels[i].Width:= 40;
          hkLabels[i].Top:= lehed_tpg[2].Height - (Abs(i-1) * 25) - 25;
          hkLabels[i].Left:= 5;
        end;
      hkLabels[0].Caption:= 'Action';
      hkLabels[1].Caption:= 'Hotkey';

      hkComList:= TComboBox.Create(Self);
      hkComList.Parent:= lehed_tpg[2];
      hkComList.Top:= hkLabels[0].Top;
      hkComList.Left:= hkLabels[0].Width + 5;
      hkComList.Width:= lehed_tpg[2].Width - hkLabels[0].Width - 10;
      hkComList.Style:= csDropDownList;

//******** hkComList Funktsioonide nimekiri
      try
        for i:= 0 to Length(hklItems)-1 do
          hkComList.AddItem(hklItems[i].hkNimi, TObject(hklItems[i].hkID));
      except
        Application.MessageBox('Error on filling HK_list', 'Ussike annab teada', MB_ICONERROR);
      end;


      hkEdit:= TEdit.Create(Self);
      hkEdit.Parent:= lehed_tpg[2];
      hkEdit.Left:= hkLabels[1].Width + 5;
      hkEdit.Top:= hkLabels[1].Top;
      hkEdit.Width:= lehed_tpg[2].Width - hkLabels[1].Width - 145;
      hkEdit.ReadOnly:= True;

      hkEdit.OnKeyDown:= hkDown;
      hkEdit.OnKeyUp:= hkUp;

      for i:= 0 to 3 do
        begin
          hkButtons[i]:= TButton.Create(Self);
          hkButtons[i].Parent:= lehed_tpg[2];
          hkButtons[i].Caption:= nupude_nimed[i];
          hkButtons[i].Width:= (((i+1) div 3) * 15) + 35;
          hkButtons[i].ShowHint:= True;
          hkButtons[i].Hint:= inttostr((((i+1) mod 3) * 25) + 25);
          hkButtons[i].Height:= 21;
          hkButtons[i].Left:= (lehed_tpg[2].Width - (135)) + (i*40);
          hkButtons[i].Top:= hkLabels[1].Top;
        end;
      hkButtons[3].Width:= 100;
      hkButtons[3].Top:= hkEnableCB.Top - 3;
      hkButtons[3].Left:= lehed_tpg[2].Width - hkButtons[3].Width - 5;

      hkButtons[0].OnClick:= addHotkey;
      hkButtons[1].OnClick:= setHotkey;
      hkButtons[2].OnClick:= delHotkey;

      hkButtons[1].Enabled:= False;
      hkButtons[2].Enabled:= False;
      hkButtons[3].Enabled:= False;

// HotKeyList laadimine failist
      if FileExists(aHost.userPath + hkFile) then
        begin
          AssignFile(hotKeyList, aHost.userPath + hkFile);
          Reset(hotKeyList);
          j:= FileSize(hotKeyList);
          if j > 0 then
            begin
              try
                SetLength(hotKeys, j);
                for i:= 0 to j-1 do
                  Read(hotkeyList, hotKeys[i]);
              except on E:Exception do
                aHost.WriteErrorLog('Error on loading hotkey list: ' + E.Message);
              end;
            end;
        end
      else
        begin
          AssignFile(hotKeyList, aHost.userPath + hkFile);
          ReWrite(hotKeyList);
        end;
      CloseFile(hotkeyList);
  end;
end;

procedure TaOptions.FormShow(Sender: TObject);
begin
  if Assigned(options_tpg) then
    options_tpg.ActivePage:= lehed_tpg[0];
  naviBut[0].Enabled:= False;
end;

procedure TaOptions.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//
end;

procedure TaOptions.FormDestroy(Sender: TObject);
begin
//
end;

procedure TaOptions.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then Close;
end;

procedure TaOptions.applyOptions(Sender: TObject);
var
  i: word;
  dReg: TRegistry;
begin
  if lehed_tpg[0].Showing then // Settings väärtuste salvestamine
    begin
      dReg:= TRegistry.Create;
      try
        try
          dReg.OpenKey('Software\Classes\telnet\shell\open\command', True);
          if (optCB[0].Checked) then
            dReg.WriteString('', aHost.ussPath + 'Laiskuss.exe %1')
          else
            dReg.WriteString('', 'rundll32.exe url.dll,TelnetProtocolHandler %l');
          dReg.CloseKey;
        except on E:Exception do
          aHost.WriteErrorLog('Laiskuss2 default client registry: ' + E.Message);
        end;
      finally
        dReg.Free;
      end;

      aHost.picSelectedPath:= optEdit[0].Text;
      aHost.brwPath:= optEdit[1].Text;
      aHost.cnfKonf:= optCB[1].Checked;
      aHost.connection_type_preference:= options_combobox.ItemIndex;
    end
  else if lehed_tpg[1].Showing then // UI väärtuste salvestamine
    begin
      aHost.termCol:= termMem.Color;
      aHost.termTxtCol:= termMem.Font.Color;
      aHost.termFB:= termBoldCB.Checked;
      aHost.termFName:= termFontLB[0].Items[termFontLB[0].ItemIndex];
      aHost.termFSize:= StrToInt(termFontLB[1].Items[termFontLB[1].ItemIndex]);
    end
  else if lehed_tpg[2].Showing then // Hotkey väärtuste salvestamine
    begin
      aHost.hkAllowed:= hkEnableCB.Checked;
      if hkEnableCB.Checked then
        begin
          try
            AssignFile(hotKeyList, aHost.userPath + hkFile);
            ReWrite(hotKeyList);
            if (Length(hotKeys) > 0) then
              for i:= 0 to Length(hotKeys)-1 do
                Write(hotKeyList, hotKeys[i]);
            CloseFile(hotKeyList);
          except on E:Exception do
            aHost.writeErrorLog('Error on saving hotkey list: ' + E.Message);
          end;
        end;
    end;
  aHost.saveSettings;
  naviBut[0].Enabled:= False;
end;

procedure TaOptions.closeOptions(Sender: TObject);
begin
  Close;
end;


function TaOptions.getVK_ID(VK_IDENT: Word): string;
var
  arr: array [0..1024] of char;
  scanCode: uInt;
begin
  scanCode := MapVirtualKey(VK_IDENT, 0) shl 16;
  GetKeyNameText(scanCode, arr, sizeof(arr));
  Result:= strPas(arr);
end;

{*********************************************************

Settings TAB

*********************************************************}



procedure TaOptions.show_settings(Sender: TObject);
begin
  optEdit[0].Text:= aHost.picSelectedPath;
  optEdit[1].Text:= aHost.brwPath;
  optCB[0].Checked:= aHost.lksDefClient;
  optCB[1].Checked:= aHost.cnfKonf;
  try
    options_combobox.ItemIndex:= aHost.connection_type_preference;
  except
    options_combobox.ItemIndex:= 0;
  end;
end;

function TaOptions.GetFolderDialog(Handle: HWND; pealkiri: string; var dirLocation: string): boolean;
var
  ItemIDList: PItemIDList;
  JtemIDList: PItemIDList;
  brwsInfo: TBrowseInfo;
  Path: PAnsiChar;
begin
  Result:= False;
  ZeroMemory(@brwsInfo, SizeOf(TBrowseInfo));
  Path:= StrAlloc(MAX_PATH);
  SHGetSpecialFolderLocation(Handle, CSIDL_DESKTOP, JtemIDList);
  brwsInfo.hwndOwner:= Handle;
  brwsInfo.pidlRoot:= JtemIDList;
  brwsInfo.pszDisplayName:= StrAlloc(MAX_PATH);
  brwsInfo.lpszTitle:= PAnsiChar(pealkiri);
  brwsInfo.ulFlags:= BIF_NEWDIALOGSTYLE;
  brwsInfo.lpfn:= nil;
  ItemIDList:= SHBrowseForFolder(brwsInfo);
  if (ItemIDList <> nil) then
    if SHGetPathFromIDList(ItemIDList, Path) then
      begin
        dirLocation:= Path;
        Result:= True;
      end;
end;

function TaOptions.GetFileDialog: string;
const
  FILTER = 'Select browser''s (*.exe) file' + #0 + '*.exe' + #0;
var
  ofn: OPENFILENAME;
  foundFileName: array[0..MAX_PATH] of char;
begin
  ZeroMemory(@ofn, SizeOf(OPENFILENAME));
  foundFileName:= '';
  ofn.lStructSize:= SizeOf(OPENFILENAME);
  ofn.hWndOwner:= Handle;
  ofn.lpstrFilter:= FILTER;
  ofn.lpstrFile:= foundFileName;
  ofn.lpstrInitialDir:= PAnsiChar('C:\');
  ofn.lpstrTitle:= PAnsiChar('Select a default browser for "Laiskuss"');
  ofn.nMaxFile:= MAX_PATH;
  GetOpenFileName(ofn);
  Result:= string(foundFileName);
end;

procedure TaOptions.Browse_Alq_Folder(Sender: TObject);
var
  folder_asukoht: string;
begin
  if Sender is TButton then
    if GetFolderDialog(Application.Handle, 'Adv LQ images folder', folder_asukoht) then
      begin
        optEdit[0].Text:= folder_asukoht;
        naviBut[0].Enabled:= True;
      end;
end;

procedure TaOptions.Set_Default_Browser(Sender: TObject);
var
  faili_asukoht: string;
begin
  faili_asukoht:= GetFileDialog;
  if (faili_asukoht <> '') then
    begin
      optEdit[1].Text:= faili_asukoht;
      naviBut[0].Enabled:= True; // Apply button
    end;
end;

procedure TaOptions.activateCB(Sender: TObject);
begin
  if Sender is TCheckBox then
    naviBut[0].Enabled:= True; // Apply button
end;

procedure TaOptions.activateComboBox(Sender: TObject);
begin
  if Sender is TComboBox then
    naviBut[0].Enabled:= True;
end;


{*********************************************************

UI TAB

*********************************************************}

procedure TaOptions.show_ui(Sender: TObject);
var
  i: Word;
  aktiivne: boolean;
begin
	aktiivne:= naviBut[0].Enabled;
  termMem.Color:= aHost.termCol;
  termMem.Font.Color:= aHost.termTxtCol;
  termBoldCB.Checked:= aHost.termFB;
  termRB[0].Checked:= True;
  translateColor(aHost.termCol);
  termMem.Font.Name:= aHost.termFName;
  termMem.Font.Size:= aHost.termFSize;
  termFontLB[1].ItemIndex:= 1;
// fondi nimi
  for i:= 0 to termFontLB[0].Items.count-1 do
    if (aHost.termFName = termFontLB[0].Items[i]) then
      begin
        termFontLB[0].ItemIndex:= i;
        break;
      end;

// fondi suurus
  for i:= 0 to termFontLB[1].Items.count-1 do
    if (aHost.termFSize = StrToInt(termFontLB[1].Items[i])) then
      begin
        termFontLB[1].ItemIndex:= i;
        break;
      end;
  naviBut[0].Enabled:= aktiivne;
end;

function TaOptions.colorPanelValik(panNo: LongInt): TColor;
begin
  case panNo of
  // esimene rida
    0: Result:= RGB(0,    0,    0);
    1: Result:= RGB(64,   64,   64);
    2: Result:= RGB(128,  128,  128);
    3: Result:= RGB(192,  192,  192);
    4: Result:= RGB(255,  255,  255);

  // teine rida
    5: Result:= RGB(0,    0,    64);
    6: Result:= RGB(0,    64,   128);
    7: Result:= RGB(0,    128,  192);
    8: Result:= RGB(0,    128,  128);
    9: Result:= RGB(0,    128,  0);

  // kolmas rida
    10: Result:= RGB(128, 0,    128);
    11: Result:= RGB(128, 0,    64);
    12: Result:= RGB(128, 0,    0);
    13: Result:= RGB(128, 64,   64);
    14: Result:= RGB(200, 138,  55);
  else
     Result:= clBlack;
  end;
end;

procedure TaOptions.translateColor(varv: TColor);
var
  r,g,b: Word;
begin
  r:= varv and $ff;
  g:= (varv and $ff00) shr 8;
  b:= (varv and $ff0000) shr 16;
  termRGB[0].Position:= r;
  termColEdit[0].Text:= IntToStr(r);
  termRGB[1].Position:= g;
  termColEdit[1].Text:= IntToStr(g);
  termRGB[2].Position:= b;
  termColEdit[2].Text:= IntToStr(b);
end;

procedure TaOptions.selectRButt(Sender: TObject);
begin
  if Sender is TRadioButton then
    begin
    	if (TRadioButton(Sender).Tag = 0) then
        translateColor(termMem.Color)
    	else if (TRadioButton(Sender).Tag = 1) then
        translateColor(termMem.Font.Color);
    end;
end;

procedure TaOptions.setColor(Sender: TObject);
var
  i: Word;
  varv: TColor;
begin
  for i:= Low(termColPanel) to High(termColPanel) do
    termColPanel[i].BevelOuter:= bvRaised;
  if Sender is TPanel then
    begin
      TPanel(Sender).BevelOuter:= bvLowered;
      varv:= colorPanelValik(TPanel(Sender).Tag);
      translateColor(varv);

      if termRB[0].Checked then
        begin
          termMem.Color:= varv;
        end
      else if termRB[1].Checked then
        begin
          termMem.Font.Color:= varv;
        end;

    if (naviBut[0].Enabled= False) then
      naviBut[0].Enabled:= True;
    end;
end;

procedure TaOptions.trackColor(Sender: TObject);
var
  tbPos: Word;
begin
  if Sender is TTrackBar then
    begin
      tbPos:= TTrackBar(Sender).Position;
      termColEdit[TTrackBar(Sender).Tag].Text:= IntToStr(tbPos);
      if termRB[0].Checked then
        begin
          termMem.Color:= RGB(
            termRGB[0].Position,
            termRGB[1].Position,
            termRGB[2].Position);
        end
      else if termRB[1].Checked then
        begin
          termMem.Font.Color:= RGB(
            termRGB[0].Position,
            termRGB[1].Position,
            termRGB[2].Position);
        end;
    if (naviBut[0].Enabled= False) then
      naviBut[0].Enabled:= True;
    end;
end;

procedure TaOptions.manualSetColor(Sender: TObject);
begin
  try
    if Sender is TEdit then
      begin
      	termRGB[TEdit(Sender).Tag].Position:= StrToInt(TEdit(Sender).Text);
      	TEdit(Sender).SelStart:= Length(Tedit(Sender).Text);
	  	  if (naviBut[0].Enabled= False) then
  	  	  naviBut[0].Enabled:= True;
      end;
  except on E:Exception do
    aHost.writeErrorLog('Error @ manual color selection' + #13#10 + E.Message);
  end;
end;

procedure TaOptions.correctInput(Sender: TObject; var Key: Char);
begin
  if NOT (Key in [#8, '0'..'9']) then
    Key:= #0;
end;

procedure TaOptions.setFBold(Sender: TObject);
begin
  if Sender is TCheckBox then
    begin
      if TCheckBox(Sender).Checked = True then
        termMem.Font.Style:= termMem.Font.Style + [fsBold]
      else
        termMem.Font.Style:= termMem.Font.Style - [fsBold];
	    if (naviBut[0].Enabled= False) then
  	    naviBut[0].Enabled:= True;
    end;
end;

procedure TaOptions.setFFont(Sender: TObject);
begin
  if Sender is TListBox then
  	begin
	    termMem.Font.Name:= TListBox(Sender).Items[TListBox(Sender).itemIndex];
	    if (naviBut[0].Enabled= False) then
  	    naviBut[0].Enabled:= True;
    end;
end;

procedure TaOptions.setFSize(Sender: TObject);
begin
  if Sender is TListBox then
  	begin
	    termMem.Font.Size:= StrToInt(TListBox(Sender).Items[TListBox(Sender).ItemIndex]);
      if (naviBut[0].Enabled= False) then
        naviBut[0].Enabled:= True;
    end;
end;


{*********************************************************

Hotkeys TAB

*********************************************************}

procedure TaOptions.show_hotkey(Sender: TObject);
begin
  hkEnableCB.Checked := aHost.hkAllowed;
  loadHotKeyList;
  aHost.disGray(hkSetList, hkEnableCB.Checked);
  aHost.disGray(hkComList, hkEnableCB.Checked);
  aHost.disGray(hkEdit, hkEnableCB.Checked);
  hkButtons[0].Enabled:= hkEnableCB.Checked;
end;

procedure TaOptions.loadHotKeyList;
var
  i, j: Word;
  hkNimi: string;
  lItem: TListItem;
begin
  hkEdit.Clear;
  hkSetList.Items.Clear;
  hkComList.ClearSelection;
  hkButtons[1].Enabled:= False;
  hkButtons[2].Enabled:= False;
  if (Length(hotKeys) > 0) then
    try
      for i:= 0 to Length(hotKeys)-1 do
        begin
          for j:= 0 to Length(hklItems)-1 do
              if (hotKeys[i].action = hklItems[j].hkID) then
              begin
                hkNimi:= hklItems[j].hkNimi;
                break;
              end;
          with hkSetList do
            begin
              lItem:= Items.Add;
              lItem.Caption:= hkNimi;
              lItem.SubItems.Add(hotKeys[i].shortcut);
              lItem.SubItems.Add(IntToStr(hotKeys[i].action));
            end;
        end;
    except on E:Exception do
      aHost.writeErrorLog('Error on listing hotkeys: ' + E.Message);
    end;
end;

procedure TaOptions.addHotkey(Sender: TObject);
var
  dummy, hkShortCut: string;
  hkID, hkLength: Word;
begin
  try
    if (Length(hkEdit.Text) > 0) then
        begin
          dummy:= hkComList.Items[hkComList.itemIndex]; // hotkey nimi
          hkID:= Word(hkComList.Items.Objects[hkComList.Items.IndexOf(dummy)]); // hotkey ID
          hkShortCut:= hkEdit.Text; // hotkey shortcut
          hkLength:= Length(hotKeys);
          SetLength(hotKeys, hkLength+1);
          hotKeys[hkLength].action:= hkID;
          hotKeys[hkLength].shortcut:= hkShortCut;
        end;
  except on E:Exception do
    aHost.writeErrorLog('Hotkey error @add: '+E.Message);
  end;
  naviBut[0].Enabled:= True;
  loadHotKeyList;
end;

procedure TaOptions.setHotkey(Sender: TObject);
var
  hkSelItem: Word;
begin
  try
    hkSelItem:= hkSetList.ItemIndex;
    hotKeys[hkSelItem].shortcut:= hkEdit.Text;
    loadHotKeyList;
    naviBut[0].Enabled:= True;
  except on E:Exception do
    aHost.writeErrorLog('Hotkey error @set: ' + E.Message);
  end;
end;

procedure TaOptions.delHotkey(Sender: TObject);
var
  hkSelItem, i, hkCnt: Word;
  temp: THotKeys;
begin
  try
    hkSelItem:= hKSetList.ItemIndex;
    hkCnt:= 0;
    SetLength(hotKeys, 0);
    AssignFile(hotKeyList, aHost.userPath + hkFile);
    Reset(hotKeyList);
    for i:= 0 to FileSize(hotKeyList)-1 do
      begin
        Read(hotKeyList, temp);
        if (i <> hkSelItem) then
          begin
            SetLength(hotKeys, hkCnt+1);
            hotKeys[hkCnt]:= temp;
            inc(hkCnt);
          end;
      end;
    CloseFile(hotKeyList);
    loadHotKeyList;
    naviBut[0].Enabled:= True;
  except on E:Exception do
    aHost.writeErrorLog('Hotkey error @del: ' + E.Message);
  end;
end;


procedure TaOptions.hkDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  iKey: string;
  i: LongInt;
begin
  hkEdit.Clear;
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
    if (Length(hkSisend[i]) > 0) then
      if (Length(hkEdit.Text) = 0) then
        hkEdit.Text:= hkSisend[i]
      else
        hkEdit.Text:= hkEdit.Text + ' + ' + hkSisend[i];
end;


procedure TaOptions.hkUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
// Kui hkSisend[2] ehk ükskõik mis sümbol, v.a. Ctrl, Shift ja Alt olemas
// siis hotkey sisend jäetakse nähtavale, vastasel juhul tühjendab Edit fieldi 
  if hkSisend[2] = '' then hkEdit.Clear;

// Alt ja F10 FIX "form change" vastu
  if (Key = 18) OR (Key = 121) then Key:= 0;
end;

procedure TaOptions.allowHotkey(Sender: TObject);
var
  i: Word;
begin
  if Sender is TCheckBox then
    begin
      aHost.disGray(hkSetList, TCheckBox(Sender).Checked);
      aHost.disGray(hkComList, TCheckBox(Sender).Checked);
      aHost.disGray(hkEdit, TCheckBox(Sender).Checked);
      if TCheckBox(Sender).Checked then
        hkButtons[0].Enabled:= True
      else
        begin
          for i:= 0 to 2 do
            hkButtons[i].Enabled:= False;
        end;
    end;
end;

procedure TaOptions.selectHotkey(Sender: TObject);
var
  selItem: TListItem;
  i: LongInt;
begin
  if Sender is TListView then
  try
    begin
      selItem:= TListView(Sender).Items.Item[TListView(Sender).ItemIndex];
      if Assigned(selItem) then
        begin
          if selItem.Selected then
            begin
              for i:= 0 to hkComList.Items.Count-1 do
                if (AnsiCompareText(hkComList.Items[i], selItem.Caption) = 0) then
                  begin
                    hkComList.ItemIndex:= i;
                    break;
                  end;
              hKEdit.Text:= selItem.SubItems[0];
              hkButtons[1].Enabled:= True;
              hkButtons[2].Enabled:= True;
            end
        end
      else
        begin
          hkButtons[1].Enabled:= False;
          hkButtons[2].Enabled:= False;
          hkEdit.Clear;
          hkComList.ClearSelection;
        end;
    end;
  except on E:Exception do
    aHost.writeErrorLog('Hotkey error @sel: '+E.Message);
  end;
end;

end.

