unit aScriptDB;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ShellApi, structVault, Registry, StrUtils;

type
  TaScrKog = class(TForm)
    main_tpg: TPageControl;
    sect_pg: TTabSheet;
    konf_pg: TTabSheet;
    macr_pg: TTabSheet;
    mscr: TScrollBox;
    test_field: TEdit;
    sectGB: TGroupBox;
    sec_list: TListBox;
    sec_name: TEdit;
    sec_width: TEdit;
    sec_addB: TButton;
    sec_setB: TButton;
    sec_delB: TButton;
    syncGB: TGroupBox;
    bgPan1: TPanel;
    sec_stat: TLabel;
    bgPan2: TPanel;
    syncLog: TMemo;
    memo1: TRichEdit;
    test_field2: TEdit;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure mscrMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure macr_pgShow(Sender: TObject);
    procedure sect_pgShow(Sender: TObject);
    procedure konf_pgShow(Sender: TObject);
    procedure sec_listMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sec_listDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure sec_listDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure sec_addBClick(Sender: TObject);
    procedure sec_setBClick(Sender: TObject);
    procedure sec_delBClick(Sender: TObject);
    procedure sec_widthKeyPress(Sender: TObject; var Key: Char);
    procedure sec_listClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
  // trashCan var
    trash: array of TSkmTrash;
    trashCnt: SmallInt;
    trashFile: File of TSkmTrash;

  // sync var
    snc_label: array[0..3] of TLabel;
    snc_button: array[0..7] of TButton;

  // sector var
    sectCnt: SmallInt; // sektorite arv
    startPoint: TPoint;
    oldSecWidth: ShortInt; // sektori suurus

  // konfi var
    konfCnt: SmallInt; // konfide arv
    knf_text: TMemo; // konfitekst
    knf_label: array[0..3] of TLabel; // location ja name labels
    knf_button: array[0..2] of TButton; // new, change, delete nuppud
    knf_edit: array[0..1] of TEdit; // name ja hint field
    knf_combobox: array[0..1] of TComboBox; // sector ja name lists
    knf_checkbox: array[0..1] of TCheckBox; // script assistant ja hint checkbox

  // macro var
    macrCnt: SmallInt; // macrode arv
    new_mcr_panel: TPanel; // macro lisamise paneel
    mcr_panels: array of TPanel; // macrode nimekiri
    mcr_edit: array[0..2] of TEdit; // nimi, konf, hint edit field
    mcr_button: array[0..1] of TButton; // add/change ja cancel/delete nuppud
    mcr_label: array[0..6] of TLabel;
    mcr_checkbox: array[0..1] of TCheckBox; // confirm ja Allow hint checkbox
    mcr_combobox: TComboBox; // macrode nimekiri
    leitud_panel: SmallInt; // valitud paneeli TAG
    leitud_panel_nimi: string; // valitud paneeli nimi
    mcr_uueke: boolean; // kas on valitud uus või "kasutatud" macro paneel
    mcr_panel_avatud: boolean; // ListView ja Combobox'i scroll konflikti välistamiseks


/////////////////////////////////// General procedures
    procedure StartUp;
    function SetSKM_ID(skmNimi: string): string;
    procedure countIncome(source: string; edLabel: TLabel);
    function UrlEncode(sisend: string): string;


///////////// end general procedures
  // trashCan procedures
    procedure loadTrash;
    procedure saveTrash;
    procedure syncTrash;

  // sync procedures
    procedure valmistaSync;
    procedure resetFiles(Sender: TObject);
    procedure resyncFiles(Sender: TObject);
    function responseHandler(sisend: string): boolean;
    function tootleSector(sisend: string): boolean;
    function tootleKonfid(sisend: string): boolean;
    function tootleMacrod(sisend: string): boolean;

  // sector procedures
    procedure valmistaSectorid;
    function secWidthKontroll(extWidth: ShortInt = -1): boolean;
    procedure puhastaSectors;

  // konf procedure
    procedure valmista_konfiAbi;
    procedure activHint(Sender: TObject);
    procedure puhastaKonfid(sel_konf: boolean = False);
    procedure selectKonf(Sender: TObject); // Combobox handler
    procedure newB(Sender: TObject); // New/Cancel button handler
    procedure addB(Sender: TObject); // Add/Change button handler
    procedure delB(Sender: TObject); // Delete/Cancel button handler
    procedure countKeys(Sender: TObject; var Key: Word; Shift: TShiftState); // nime ja hinti pikkuse kalkuleerimine
    procedure lisaKonf;
    procedure muudaKonf;
    procedure kustutaKonf;

  // Macro procedures
    procedure valmistaMacroAbi;
    procedure draw_macros;
    procedure ava_macro(Sender: TObject);
    procedure macro_in(Sender: TObject);
    procedure macro_out(Sender: TObject);
    procedure abivahendid(vanem: TWinControl);
    procedure select_macro(mcr_id: SmallInt);
    procedure clear_macr_selection;
    procedure liikumine(Sender: TObject; Shift: TShiftState; X, Y: Integer);

    procedure macroB1(Sender: TObject); // add/change button
    procedure macroB2(Sender: TObject); // cancel/delete button

    procedure lisa_macro;
    procedure muuda_macro;
    procedure kustuta_macro;

  public
    procedure vabadus(elemendid: array of TPanel); overload;
    procedure vabadus(elemendid: array of TButton); overload;
    procedure vabadus(elemendid: array of TGroupBox); overload;

  // sync
    procedure syngiFailid(tyyp: byte; reset: boolean=False);
  end;

const
  servAdre: string = 'http://laiskuss.elion.ee/uss_remote2/';
  f_sect = 'lks_sekt_u.l2f'; // Sektorikogumiku failinimi
  f_konf = 'lks_konf.l2f'; // Konfikogumiku failinimi
  f_macr = 'lks_macr_u.l2f'; // Makrokogumiku failinimi
  f_trash = 'lks_trash.l2f'; // skm prügikasti failinimi

var
  aScrKog: TaScrKog;

implementation

uses aMain;

{$R *.dfm}

procedure TaScrKog.FormCreate(Sender: TObject);
begin
  KeyPreview:= True;
  StartUp;
  trashCnt:= 0;
end;

procedure TaScrKog.FormShow(Sender: TObject);
begin
  if NOT aHost.Showing then
    ShowWindow(Application.Handle, SW_HIDE);
//
end;

procedure TaScrKog.FormHide(Sender: TObject);
begin
//
end;

procedure TaScrKog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//
end;

procedure TaScrKog.FormDestroy(Sender: TObject);
begin
  if (Length(mcr_panels) > 0) then
    vabadus(mcr_panels);
    
  if (Assigned(new_mcr_panel)) then
    try
      FreeAndNil(new_mcr_panel);
    except on E:Exception do
      aHost.writeErrorLog('Error @ freeing new mcr_panel on exit: ' + E.Message);
    end;
end;

procedure TaScrKog.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
    Close;
end;

procedure TaScrKog.vabadus(elemendid: array of TPanel);
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
    aHost.writeErrorLog('Error on freeing panels: ' + E.Message);
  end;
end;

procedure TaScrKog.vabadus(elemendid: array of TButton);
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
    aHost.writeErrorLog('Error on freeing buttons: ' + E.Message);
  end;
end;

procedure TaScrKog.vabadus(elemendid: array of TGroupBox);
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
    aHost.writeErrorLog('Error on freeing groupbox: ' + E.Message);
  end;
end;

{
 sektori, konfi ja makro ID genereerimine
 ID koosneb: nimest 2 esimest sümbolit + random xx numbrit +
  nimest 2 viimast sümbolit + nime pikkus + random xx numbrit
 tühikute asemele "_"
}
function TaScrKog.SetSKM_ID(skmNimi: string): string;
var
  s: string;
begin
  Randomize;
  s:= Format('%s%d%s%d%d', [Copy(skmNimi, 1, 2), (10 + Random(89)),
    (Copy(skmNimi, Length(skmNimi)-1, 2)), Length(skmNimi), (10+ Random(89))]);
  Result:= StringReplace(s, ' ', '_', [rfReplaceAll]);
end;


procedure TaScrKog.countIncome(source: string; edLabel: TLabel);
var
  algV: string;
  mainCnt: SmallInt;
begin
  algV:= Copy(edLabel.Caption, 1, AnsiPos('/', edLabel.Caption)-1);
  mainCnt:= StrToInt(algv) - Length(source);
  edLabel.Caption:= algv + '/' + IntToStr(mainCnt);
end;

function TaScrKog.UrlEncode(sisend: string): string;
var
  vastus: string;
begin
  vastus:= '';
  try
    vastus:= AnsiReplaceStr(sisend, '&', '%26');
  except on E:Exception do
    vastus:= sisend;
  end;
  Result:= vastus;
end;


///////////////// END GENERAL PROCEDURES ////////////////////


// Script DB init
procedure TaScrKog.StartUp;
var
  i: SmallInt;
  f_arr: array[1..3] of string;
begin
  main_tpg.Brush.Color:= $00E4E4E4;

  loadTrash;
  syncTrash;

  f_arr[1]:= aHost.userPath + f_sect;
  f_arr[2]:= aHost.userPath + f_konf;
  f_arr[3]:= aHost.userPath + f_macr;
  for i:= 1 to 3 do
    begin
      if (NOT FileExists(f_arr[i])) then
        syngiFailid(i);
    end;

// Sectorite loomine
  aMain.sectorLoad(aHost.userPath, aHost.sectors);
  sectCnt:= Length(aHost.sectors);
  valmistaSectorid;
  valmistaSync;

// Konfide loomine
  aMain.konfLoad(aHost.userPath, aHost.konfid);
  konfCnt:= Length(aHost.konfid);
  valmista_konfiAbi;

// Macrode loomine
  aMain.macroLoad(aHost.userPath, aHost.macrod);
  macrCnt:= Length(aHost.macrod);
  valmistaMacroAbi;
  draw_macros;
  leitud_panel:= -2;
  leitud_panel_nimi:= '';

  aHost.Caption:= 'valmis';
end;

{*************************************************************************
  TRASH CAN - sektori, konfi ja makro kustutamisel lisatakse ID prügikasti,
  enne sünkimist saadetakse serverisse info data kohta, mida on kustutatud
**************************************************************************}

procedure TaScrKog.loadTrash;
var
  i: SmallInt;
begin
  try
    if (FileExists(aHost.userPath + f_trash)) then
      begin
        AssignFile(trashFile, aHost.userPath + f_trash);
        Reset(trashFile);
        for i:= 0 to FileSize(trashFile)-1 do
          begin
            trashCnt:= Length(trash);
            SetLength(trash, trashCnt+1);
            Read(trashFile, trash[i]);
          end; // for i loop
        CloseFile(trashFile);
      end; // FileExists
  except on E:Exception do
    aHost.writeErrorLog('Exception @ loading Trash: ' + E.Message);
  end; // try
end;

procedure TaScrKog.saveTrash;
var
  i: SmallInt;
begin
  try
    AssignFile(trashFile, aHost.userPath + f_trash);
    ReWrite(trashFile);
    for i:= 0 to Length(trash)-1 do
      Write(trashFile, trash[i]);
    CloseFile(trashFile);
  except on E:Exception do
    aHost.writeErrorLog('Exception @ saving Trash: ' + E.Message);
  end; // try
end;

procedure TaScrKog.syncTrash;
var
  i: Smallint;
  trList: TStringList;
  vastus: string;
begin
  trList:= TStringList.Create;
  try
    try
      for i:= 0 to Length(trash)-1 do
        begin
          trList.Add('trash[' + IntToStr(i) + '][type]=' + IntToStr(trash[i].skm_type));
          trList.Add('trash[' + IntToStr(i) + '][id]=' + trash[i].skm_id);
        end;

      vastus:= aHost.aHttp.Post(servAdre + 'sync_trash.php?sid=' + aHost.accSid, trList);
      memo1.Text:= vastus;
      if (AnsiCompareStr(sulu_parser(vastus, 'response'), '555') = 0) then
        if (FileExists(aHost.userPath + f_trash)) then
          if DeleteFile(aHost.userPath + f_trash) = False then
            memo1.Lines.add(IntToStr(GetLastError));

      SetLength(trash, 0);
      trash:= nil;

    except on E:Exception do
      aHost.writeErrorLog('Exception @ posting Trash: ' + E.Message);
    end; // try except
  finally
    trList.Free;
  end; // try finally
end;


{*************************************************************************
sectorite, konfide ja macrode sünkroniseerimine
esmalt võrreldakse serveri ja host'i aegu, kõige viimase ajaga päring võidab
**************************************************************************}

procedure TaScrKog.valmistaSync;
const
  sbCaption: array[0..7] of string = (
    'Resync sectors', 'Resync scripts', 'Resync macros', 'Resync all files',
    'Reset sectors', 'Reset scripts',  'Reset macros', 'Reset all files'
  );

var
  i, j, cnt: SmallInt;
begin
  for i:= 0 to 3 do
    begin
      snc_label[i]:= TLabel.Create(Self);
      snc_label[i].Parent:= syncGB;
      snc_label[i].AutoSize:= False;
      snc_label[i].Alignment:= taCenter;
      snc_label[i].Layout:= tlCenter;
      snc_label[i].Top:= 10;
      snc_label[i].Left:= (i*150) + 15;
      snc_label[i].Width:= 125;
      snc_label[i].Height:= 21;
    end;
  snc_label[0].Caption:= 'Sectors';
  snc_label[1].Caption:= 'Scripts';
  snc_label[2].Caption:= 'Macros';
  snc_label[3].Caption:= 'All';
  snc_label[3].Left:= syncGB.Width - snc_label[3].Width - 30;

{
  0, 4: Sectors - resync, default
  1, 5: Konfid - resync, default
  2, 6: Macrod - resync, default
  3, 7: All - resync, default
}
  cnt:= 0;
  for i:= 0 to 1 do
    for j:= 0 to 3 do
      begin
        snc_button[cnt]:= TButton.Create(Self);
        snc_button[cnt].Parent:= syncGB;
        snc_button[cnt].Top:= (i*30) + 32;
        snc_button[cnt].Left:= snc_label[j].Left; // (j*140) + 15;
        snc_button[cnt].Width:= 125;
        snc_button[cnt].Tag:= 200 + cnt;
        snc_button[cnt].Caption:= sbCaption[cnt];
        if (i = 0) then
          snc_button[cnt].OnClick:= resyncFiles
        else if (i = 1) then
          snc_button[cnt].OnClick:= resetFiles;
        inc(cnt);
      end;
end;

// Reset button handlers
procedure TaScrKog.resetFiles(Sender: TObject);
var
  bTag: SmallInt;
begin
  if Sender is TButton then
    begin
      bTag:= TButton(Sender).Tag - 200;
      case bTag of
        4:
          begin
            syngiFailid(1, True);
          end;
        5:
          begin
            syngiFailid(2, True);
          end;
        6:
          begin
            try
              syngiFailid(3, True);
            except on E:Exception do
              aHost.writeErrorLog('reset macro: '+E.Message);
            end;
          end;
        7:
          begin
            //syncLog.Text:= 'all';
          end;
      end;
    end;
end;

// Resync button handlers
procedure TaScrKog.resyncFiles(Sender: TObject);
var
  bTag: SmallInt;
begin
  if Sender is TButton then
    begin
      bTag:= TButton(Sender).Tag - 200;
      case bTag of
        0:
          begin
            try
              syngiFailid(1);
            except on E:Exception do
              aHost.writeErrorLog('sector sync: ' + E.Message);
            end;
          end;
        1:
          begin
            try
              syngiFailid(2);
            except on E:Exception do
              aHost.writeErrorLog('konfi sync: ' + E.Message);
            end;
          end;
        2:
          try
            syngiFailid(3);
          except on E:Exception do
            aHost.writeErrorLog('macro sync: ' + E.Message);
          end;
        3:
          begin
            //syncLog.Text:= 'sync all';
          end;
      end;
    end;
end;

///////////////// SÜNKIMISE PROTSEDUURID

{
  response codes:
  -1  : incorrect query
  0   : mysql returnes 0 results
  1   : invalid action
  5   : "objectSid" var is missing
  6   : user not found
  7   : Date receiveing failed
  400 : succesful request
}

function TaScrKog.responseHandler(sisend: string): boolean;
var
  tulemus: boolean;
begin
  tulemus:= False;
  if (AnsiCompareStr(sisend, '400') = 0) then
    tulemus:= True
  else if (AnsiCompareStr(sisend, '0') = 0) then
    syncLog.Lines.Add(DateTimeToStr(Now) + ': Sync failed - DB returned 0 results...' + #13#10)
  else if (AnsiCompareStr(sisend, '1') = 0) then
    syncLog.Lines.Add(DateTimeToStr(Now) + ': Sync failed - missing/incorrect action...' + #13#10)
  else if (AnsiCompareStr(sisend, '5') = 0) then
    syncLog.Lines.Add(DateTimeToStr(Now) + ': Sync failed - missing/incorrect sid...' + #13#10)
  else if (AnsiCompareStr(sisend, '6') = 0) then
    syncLog.Lines.Add(DateTimeToStr(Now) + ': Sync failed - user not found...' + #13#10)
  else if (AnsiCompareStr(sisend, '7') = 0) then
    syncLog.Lines.Add(DateTimeToStr(Now) + ': Sync failed - corrupted post data...' + #13#10)
  else if (AnsiCompareStr(sisend, '-1') = 0) then
    syncLog.Lines.Add(DateTimeToStr(Now) + ': Sync failed - incorrect method data...' + #13#10)
  else
    syncLog.Lines.Add(DateTimeToStr(Now) + ': Sync failed - reason unknown' + #13#10);
  Result:= tulemus;
end;


procedure TaScrKog.syngiFailid(tyyp: byte; reset: boolean = False);
const
  aegValue: array[0..2] of string =
    ('lastSyncSect', 'lastSyncKonf', 'lastSyncMacr');
var
  skm_list: TStringList;
  i, j: SmallInt;
  vastus: string;
  sReg: TRegistry;
  aeg: array[0..2] of TDateTime;
begin
  vastus:= '';
  sReg:= TRegistry.Create;
  skm_list:= TStringList.Create;
  skm_list.Add('sid='+aHost.accSid);

// SKM viimase sünkimise aeg
  try
    sReg.RootKey:= HKEY_CURRENT_USER;
    sReg.OpenKey('SOFTWARE\Laiskuss2\Ussike\', True);

    for i:= 0 to 2 do
      aeg[i]:= Now;
      //aeg[i]:= aHost.isRegValid(sReg, aegValue[i], Now);

  except on E:Exception do
    aHost.writeErrorLog('Unable to open sReg: ' + E.Message);
  end; // try sReg

  syncLog.Lines.Add(DateTimeToStr(Now) + ': Connecting to server...');
  syncTrash;
  memo1.clear;
  try
    case tyyp of
      1: // sector
        begin
          try
            if (reset) then
              begin
                vastus:= aHost.aHttp.Get(servAdre + 'sync_sect.php?action=reset&sid=' + aHost.accSid);
              end
            else
              begin
                for i:= 0 to Length(aHost.sectors)-2 do
                  begin
                    skm_list.Add('sector['+IntToStr(i)+'][nimi]='+aHost.sectors[i].sect_nimi);
                    skm_list.Add('sector['+IntToStr(i)+'][id]='+aHost.sectors[i].sect_ID);
                    skm_list.Add('sector['+IntToStr(i)+'][width]='+IntToStr(aHost.sectors[i].sect_size));
                    skm_list.Add('sector['+IntToStr(i)+'][modify]='+IntToStr(aHost.sectors[i].sect_date));
                  end;

                try
                  vastus:= aHost.aHttp.Post(servAdre + 'sync_sect.php?action=upload&sid=' + aHost.accSid, skm_list);
                except
                end;
              end; // resync

            if (aHost.aHttp.ResponseCode = 200) then
              begin
                //syncLog.Lines.Add(DateTimeToStr(Now) + ': Connection established.');
                memo1.Text:= vastus;
                tootleSector(vastus);
              end
            else
              syncLog.Lines.Add(DateTimeToStr(Now) + ': Unable to connect, error: ' + IntToStr(aHost.aHttp.ResponseCode));
          except
          end;
        end; // case of 1


      2: // konf
        begin
          try
            if (reset) then
              begin
                vastus:= aHost.aHttp.Get(servAdre + 'sync_konf.php?action=reset&sid=' + aHost.accSid);
              end
            else
              begin
                for i:= 0 to Length(aHost.konfid)-1 do
                  begin
                    skm_list.Add('konfid['+IntToStr(i)+'][id]=' + aHost.konfid[i].konf_id);
                    skm_list.Add('konfid['+IntToStr(i)+'][pl_id]=' + aHost.konfid[i].konf_pl_id);
                    skm_list.Add('konfid['+IntToStr(i)+'][nimi]=' + aHost.konfid[i].konf_nimi);
                    for j:= 0 to aHost.konfid[i].konf_text_ridu-1 do
                      skm_list.Add('konfid['+IntToStr(i)+'][text]['+IntToStr(j)+']=' + aHost.konfid[i].konf_text[j]);
                    skm_list.Add('konfid['+IntToStr(i)+'][hint]=' + UrlEncode(aHost.konfid[i].konf_hint));
                    skm_list.Add('konfid['+IntToStr(i)+'][hintAllow]=' + IntToStr(BoolToInt(aHost.konfid[i].konf_hintAllow)));
                    skm_list.Add('konfid['+IntToStr(i)+'][scrAss]=' + IntToStr(BoolToInt(aHost.konfid[i].konf_scrAssistant)));
                    skm_list.Add('konfid['+IntToStr(i)+'][modify]=' + IntToStr(aHost.konfid[i].konf_date));
                  end;
                try
                  vastus:= aHost.aHttp.Post(servAdre + 'sync_konf.php?action=upload&sid=' + aHost.accSid, skm_list);
                except
                end;

              end; // resync

            if (aHost.aHttp.ResponseCode = 200) then
              begin
                memo1.Text:= vastus;
                tootleKonfid(vastus);
              end
            else
              syncLog.Lines.Add(DateTimeToStr(Now) + ': Unable to connect, error: ' + IntToStr(aHost.aHttp.ResponseCode));
          except
          end; // try
        end; // case of 2


      3: // macro
        begin
          try
            if (reset) then
              begin
                vastus:= aHost.aHttp.Get(servAdre + 'sync_macr.php?action=reset&sid=' + aHost.accSid);
              end
            else
              begin
                for i:= 0 to Length(aHost.macrod)-1 do
                  begin
                    skm_list.Add('macrod['+IntToStr(i)+'][id]='+aHost.macrod[i].macr_id);
                    skm_list.Add('macrod['+IntToStr(i)+'][nimi]='+aHost.macrod[i].macr_nimi);
                    skm_list.Add('macrod['+IntToStr(i)+'][konf]='+aHost.macrod[i].macr_text);
                    skm_list.Add('macrod['+IntToStr(i)+'][confirm]='+IntToStr(BoolToInt(aHost.macrod[i].macr_cnf)));
                    skm_list.Add('macrod['+IntToStr(i)+'][hint]='+aHost.macrod[i].macr_hint);
                    skm_list.Add('macrod['+IntToStr(i)+'][hintAllow]='+IntToStr(BoolToInt(aHost.macrod[i].macr_hintAllow)));
                    skm_list.Add('macrod['+IntToStr(i)+'][modify]='+IntToStr(aHost.macrod[i].macr_date));
                  end; // for i loop
                try
                  vastus:= aHost.aHttp.Post(servAdre + 'sync_macr.php?action=upload&sid=' + aHost.accSid, skm_list);
                except
                end; // try
              end; // resync
          except
          end; // try

          if (aHost.aHttp.ResponseCode = 200) then
            begin
              memo1.Text:= vastus;
              tootleMacrod(vastus);
            end
          else
            syncLog.Lines.Add(DateTimeToStr(Now) + ': Unable to connect, error: ' + IntToStr(aHost.aHttp.ResponseCode));

          try
            clear_macr_selection;
            draw_macros;
          except
          end;

        end; // case of 3
    end; // case block

    for i:= 0 to 2 do
      sReg.WriteDateTime(aegValue[i], aeg[i]);

  finally
    begin
      sReg.CloseKey;
      sReg.Free;
      skm_list.Clear;
      skm_list.Free;
    end; // finally
  end; // try
end;


{******************************
 HTTP'st tulnud sectorid -> SectKog
******************************}
function TaScrKog.tootleSector(sisend: string): boolean;
var
  dummyCnt, suurus: SmallInt;
  temp: string;
  sctList: TStringList;
  tulemus: boolean;
  sctTemp: TSectKog;
  lopuVastus: string; // http päringu lõpetab response koodiga 555, kui seda kätte ei saadeta
                      // siis faili ei uuendata

// sectori data lisamine temp record'i
  function lammuta(sisse: string): boolean;
  var
    s: string;
    vastus: boolean;
  begin
    try
      if (Length(sisse) > 0) then
        begin
          s:= sulu_parser(sisse, 'ksb_sect_id');
        // väljas tulnud id'l on kasutajanimi küljes = strippime
          sctTemp.sect_ID:= Copy(s, AnsiPos('@', s)+1, MaxInt);
          sctTemp.sect_nimi:= sulu_parser(sisse, 'ksb_sect_nimi');
          sctTemp.sect_size:= StrToInt(sulu_parser(sisse, 'ksb_sect_width'));
          sctTemp.sect_date:= StrToInt(sulu_parser(sisse, 'ksb_sect_uuendatud'))+2;
          vastus:= True;
        end
      else
        vastus:= False;
    except on E:Exception do
      begin
        vastus:= False;
        aHost.writeErrorLog('sectorite lammutamine (' + sisse + '): ' + E.Message);
      end;
    end;
    Result:= vastus;
  end;

// start tootleSector
begin
  tulemus:= False;
  if (responseHandler(sulu_parser(sisend, 'response'))) then
    begin
      dummyCnt:= 0; // sectori parsija piiraja
      sctList:= TStringList.Create;
      // esmalt eraldame sectorid sissetulnud sectorite nimekirjast
      // seejärel toppime sectori andmed recordisse
      sectCnt:= 0;
      try
        lopuVastus:= sulu_parser(sisend, 'kirjutame');
        repeat
          sisend:= Trim(sisend);
          temp:= sulu_parser(sisend, 'sector');
          Delete(sisend, 1, AnsiPos('EOML', sisend)+5); // +5 = 'EOML+CRLF-1'
          Application.ProcessMessages;
          inc(dummyCnt, 1);
          suurus:= Length(sisend);
          if (lammuta(temp)) then
            begin
              SetLength(aHost.sectors, sectCnt+1);
              aHost.sectors[sectCnt]:= sctTemp;
              inc(sectCnt);
            end;
        until (suurus = 0) OR (dummyCnt = 2000);

      // Default sectori lisamine
		    try
  			  SetLength(aHost.sectors, sectCnt+1);
  	  		aHost.sectors[sectCnt].sect_nimi:= 'Default';
	  	  	aHost.sectors[sectCnt].sect_ID:= 'De29lt39';
		  	  aHost.sectors[sectCnt].sect_size:= 0;
          aHost.sectors[sectCnt].sect_date:= 0;
  		  	inc(sectCnt);
	  	  except on E:Exception do
		  	  aHost.writeErrorLog('default sector addimine: ' + E.Message);
		    end; // try - default

        valmistaSectorid;

      // faili kirjutamine, oodatakse vastust 555 - ehk kogu mysql päring on host'ni jõudnud
        if (AnsiCompareStr(lopuVastus, '555') = 0) then
          begin
            syncLog.Lines.Add(DateTimeToStr(Now) + ': Updating file...');
            if (aMain.sectorSave(aHost.userPath, aHost.sectors)) then
              syncLog.Lines.Add(DateTimeToStr(Now) + ': Sector sync complete' + #13#10)
            else
              syncLog.Lines.Add(DateTimeToStr(Now) + ': File update failed' + #13#10);
          end
        else
          syncLog.Lines.Add(DateTimeToStr(Now) + ': File update failed: corrupted data' + #13#10);

      except on E:Exception do
        aHost.writeErrorLog('sectorite parsimine: ' + E.Message);
      end; // end try block
    sctList.Free;

    end; // response
  Result:= tulemus;
end;


{******************************
 HTTP'st tulnud konfid -> KonfKog
******************************}

function TaScrKog.tootleKonfid(sisend: string): boolean;
var
  dummyCnt, suurus: SmallInt;
  temp: string;
  knfList: TStringList;
  tulemus: boolean;
  knfTemp: TKonfKog;
  lopuVastus: string; // http päringu lõpetab response koodiga 555, kui seda kätte ei saadeta
                      // siis faili ei uuendata

  function lammuta(sisse: string): boolean;
  var
    kt: SmallInt;
    s: string;
    vastus: boolean;
    textTmp: TStringList;
  begin
    try
      if (Length(sisse) > 0) then
        begin
          textTmp:= TStringList.Create;
          s:= sulu_parser(sisse, 'kkb_konf_id');
        // väljas tulnud id'l on kasutajanimi küljes = strippime
          knfTemp.konf_id := Copy(s, AnsiPos('@', s)+1, MaxInt);
          knfTemp.konf_pl_id:= sulu_parser(sisse, 'kkb_konf_locId');
          knfTemp.konf_nimi:= sulu_parser(sisse, 'kkb_konf_nimi');
          knfTemp.konf_date:= StrToInt(sulu_parser(sisse, 'kkb_konf_uuendatud'))+2;
          textTmp.Text:= sulu_parser(sisse, 'kkb_konf_text');
          for kt:= 0 to textTmp.Count-1 do
            begin
              SetLength(knfTemp.konf_text, kt+1);
              knfTemp.konf_text[kt]:= textTmp.Strings[kt];
              knfTemp.konf_text_ridu:= kt+1;
            end;
          knfTemp.konf_hintAllow:= IntToBool(StrToInt(sulu_parser(sisse, 'kkb_konf_hintAllow')));
          knfTemp.konf_hint:= sulu_parser(sisse, 'kkb_konf_hint');
          knfTemp.konf_scrAssistant:= IntToBool(StrToInt(sulu_parser(sisse, 'kkb_konf_scrAss')));
          vastus:= True;
        end
      else
        vastus:= False;
    except on E:Exception do
      begin
        vastus:= False;
        aHost.writeErrorLog('konfide lammutamine: ' + E.Message);
      end;
    end;
    Result:= vastus;
  end;

// start tootleKonfid
begin
  tulemus:= False;
  if (responseHandler(sulu_parser(sisend, 'response'))) then
    begin
      dummyCnt:= 0; // sectori parsija piiraja
      knfList:= TStringList.Create;
      // esmalt eraldame sectorid sissetulnud sectorite nimekirjast
      // seejärel toppime sectori andmed recordisse
      konfCnt:= 0;
      try
        lopuVastus:= sulu_parser(sisend, 'kirjutame');
        repeat
          sisend:= Trim(sisend);
          temp:= sulu_parser(sisend, 'konfid');
          Delete(sisend, 1, AnsiPos('EOML', sisend)+5); // +5 = 'EOML+CRLF-1'
          Application.ProcessMessages;
          inc(dummyCnt, 1);
          suurus:= Length(sisend);
          if (lammuta(temp)) then
            begin
              SetLength(aHost.konfid, konfCnt+1);
              aHost.konfid[konfCnt]:= knfTemp;
              inc(konfCnt);
            end;
        until (suurus = 0) OR (dummyCnt = 2000);

      if (AnsiCompareStr(lopuVastus, '555') = 0) then
        begin
          syncLog.Lines.Add(DateTimeToStr(Now) + ': Updating file...');
          if (aMain.konfSave(aHost.userPath, aHost.konfid)) then
            begin
              tulemus:= True;
              syncLog.Lines.Add(DateTimeToStr(Now) + ': Script sync complete' + #13#10);
            end
          else
            begin
              tulemus:= False;
              syncLog.Lines.Add(DateTimeToStr(Now) + ': File update failed' + #13#10);
            end;
        end
      else
        begin
          tulemus:= False;
          syncLog.Lines.Add(DateTimeToStr(Now) + ': File update failed: corrupted data' + #13#10);
        end;  

      except on E:Exception do
        aHost.writeErrorLog('sectorite parsimine: ' + E.Message);
      end; // end try block
    knfList.Free;

    end; // response
  Result:= tulemus;
end;



{******************************
HTTP'st tulnud macrod -> MacrKog
******************************}

function TaScrKog.tootleMacrod(sisend: string): boolean;
var
  dummyCnt, suurus: SmallInt;
  temp: string;
  mcrList: TStringList;
  tulemus: boolean;
  mcrTemp: TMacrKog;
  lopuVastus: string; // http päringu lõpetab response koodiga 555, kui seda kätte ei saadeta
                      // siis faili ei uuendata
// HTTP'st tulnud macro andmete recordi eelsisestamine
  function lammuta(sisse: string): boolean;
  var
    s: string;
    vastus: boolean;
  begin
    try
      if (Length(sisse) > 0) then
        begin
          s:= sulu_parser(sisse, 'kmb_macr_id');
        // väljas tulnud id'l on kasutajanimi küljes = strippime
          mcrTemp.macr_id:= Copy(s, AnsiPos('@', s)+1, MaxInt);
          mcrTemp.macr_nimi:= sulu_parser(sisse, 'kmb_macr_nimi');
          mcrTemp.macr_text:= sulu_parser(sisse, 'kmb_macr_text');
          mcrTemp.macr_cnf:= IntToBool(StrToInt(sulu_parser(sisse, 'kmb_macr_cnf')));
          mcrTemp.macr_hintAllow:= IntToBool(StrToInt(sulu_parser(sisse, 'kmb_macr_hintAllow')));
          mcrTemp.macr_hint:= sulu_parser(sisse, 'kmb_macr_hint');
          mcrTemp.macr_date:= StrToInt(sulu_parser(sisse, 'kmb_macr_uuendatud'))+2;
          vastus:= True;
        end
      else
        vastus:= False;
    except on E:Exception do
      begin
        vastus:= False;
        aHost.writeErrorLog('macrode lammutamine: ' + E.Message);
      end;
    end;
    Result:= vastus;
  end;

begin
  tulemus:= False;
  if (responseHandler(sulu_parser(sisend, 'response'))) then
    begin
      dummyCnt:= 0; // macrode parsija piiraja
      mcrList:= TStringList.Create;
      // esmalt eraldama macrod sissetulnud macrode nimekirjas
      // seejärel toppime macrode andmed recordisse
      macrCnt:= 0;
      try
        lopuVastus:= sulu_parser(sisend, 'kirjutame');
        repeat
          sisend:= Trim(sisend);
          temp:= sulu_parser(sisend, 'macro');
          Delete(sisend, 1, AnsiPos('EOML', sisend)+5); // +5 = 'EOML+CRLF-1'
          Application.ProcessMessages;
          inc(dummyCnt, 1);
          suurus:= Length(sisend);
          if lammuta(temp) then
            begin
              SetLength(aHost.macrod, macrCnt+1);
              aHost.macrod[macrCnt]:= mcrTemp;
              inc(macrCnt);
            end;
// katkestme, kui kõik macrod on parseldatud või vea korral lööb piiraja sisse
        until (suurus = 0) OR (dummyCnt = 2000);

        if (AnsiCompareStr(lopuVastus, '555') = 0) then
          begin
            syncLog.Lines.Add(DateTimeToStr(Now) + ': Updating file...');
            if (aMain.macroSave(aHost.userPath, aHost.macrod)) then
              syncLog.Lines.Add(DateTimeToStr(Now) + ': Macro sync complete' + #13#10)
            else
              synclog.lines.add(DateTimeToStr(Now) + ': File update failed' + #13#10);
          end
        else
          synclog.lines.add(DateTimeToStr(Now) + ': File update failed: corrupted data...' + #13#10);
      except on E:Exception do
        aHost.writeErrorLog('macrode parsimine' + E.Message);
      end; // end try block
      mcrList.Free;
  end; // Response
  Result:= tulemus;
end;






{************************ SECTORS ************************}

procedure TaScrKog.sect_pgShow(Sender: TObject);
var
  i, allCnt: SmallInt;
  f_arr: array[0..2] of string;
begin
  puhastaSectors;
  valmistaSectorid;
  f_arr[0]:= aHost.userPath + f_sect;
  f_arr[1]:= aHost.userPath + f_konf;
  f_arr[2]:= aHost.userPath + f_macr;
  allCnt:= 0;
  for i:= 0 to 2 do
    begin
      if (FileExists(f_arr[i])) then
        snc_button[i+4].Enabled:= True
      else
        begin
          snc_button[i+4].Enabled:= False;
          inc(allCnt);
        end;
    end;
  if (allCnt = 3) then
    snc_button[7].Enabled:= False
  else
    snc_button[7].Enabled:= True;
end;

procedure TaScrKog.valmistaSectorid;
var
  i, secWidth: SmallInt;
begin
  sec_list.Clear;
  secWidth:= 0;
  for i:= 0 to sectCnt-1 do
    begin
      sec_list.Items.Add(aHost.sectors[i].sect_nimi);
      if (i <> sectCnt-1) then
      secWidth:= secWidth + aHost.sectors[i].sect_size;
    end;
  sec_stat.Caption:= IntToStr(9 - secWidth -1) + ' sectors available';
end;

procedure TaScrKog.puhastaSectors;
begin
  sec_name.Clear;
  sec_width.Text:= '1';
  sec_list.ClearSelection;
  sec_setB.Enabled:= False;
  sec_delB.Enabled:= False;
  oldSecWidth:= -1;
end;

{
  kokku on võimalik lisada 8 (1 x cell) sektorit + 1 "default" sektor
  secWidthKontroll kontrollib kas uue/muudetava sektori laius on korrektne
  "extWidth" parameetri kasutatakse sektori muutmisel - valitud sektori laius
  ehk sektori laiuse mitte muutmisel ei oleks seda arvestatud
}
function TaScrKog.secWidthKontroll(extWidth: ShortInt = -1): boolean;
var
  secW, i, currWidth: ShortInt;
  tulemus: boolean;
begin
  tulemus:= False;
  currWidth:= 0;
  if (isInt(sec_width.Text)) then
    begin
      try
        secW:= StrToInt(sec_width.Text);
        for i:= 0 to sectCnt-1 do
//default sectori laiust ei arvestasta
          if (extWidth <> i) AND (i <> sectCnt-1) then
            currWidth:= currWidth + aHost.sectors[i].sect_size;

        if (secW + currWidth ) < 9 then
          tulemus:= True;
      except on E:Exception do
        aHost.writeErrorLog('secWidthKontroll: ' + E.Message);
      end;
    end
  else
    tulemus:= False;
  Result:= tulemus;
end;

procedure TaScrKog.sec_widthKeyPress(Sender: TObject; var Key: Char);
begin
  if NOT (Key in ['1'..'8', #8])then
    Key:= #0;
end;

// sektori lisamine
procedure TaScrKog.sec_addBClick(Sender: TObject);
var
  temp: TSectKog;
  idikas: string;
begin
  if ((Length(sec_name.Text) >= 3) AND (Length(sec_name.Text) <= 20)) then
    begin
      if secWidthKontroll AND (StrToInt(sec_width.Text) > 0) then
        begin
          try
            temp:= aHost.sectors[sectCnt-1];
            SetLength(aHost.sectors, sectCnt+1);
            idikas:= SetSKM_ID(sec_name.Text);
            with aHost.sectors[sectCnt-1] do
              begin
                sect_id:= Copy(idikas, 1, 8);
                sect_nimi:= sec_name.Text;
                sect_size:= StrToInt(sec_width.Text);
                sect_date:= DateToUnix(Now);
              end;

            aHost.sectors[sectCnt]:= temp;
            inc(SectCnt);
            puhastaSectors;
            valmistaSectorid;
            sectorSave(aHost.userPath, aHost.sectors);
          except on E:Exception do
            aHost.writeErrorLog('Sector add: ' + E.Message);
          end;  // end try block
        end // end width kontroll block
      else
        Application.MessageBox('Incorrect sector width', 'Ussike annab teada', MB_ICONWARNING);
    end // end sec_name block
  else
    Application.MessageBox('Name length must be 3-20 characters', 'Ussike annab teada', MB_ICONWARNING);
end;

// sektori muutmine
procedure TaScrKog.sec_setBClick(Sender: TObject);
var
  valitud: shortInt;
  laius: boolean;
begin
  valitud:= sec_list.ItemIndex;
  if (oldSecWidth = StrToInt(sec_width.Text)) then
    laius := True
  else
    laius:= secWidthKontroll(valitud);

  if ((Length(sec_name.Text) >= 3) AND (Length(sec_name.Text) <= 20)) then
    begin
      if laius then
        begin
          try
            aHost.sectors[valitud].sect_nimi:= sec_name.Text;
            aHost.sectors[valitud].sect_size:= StrToInt(sec_width.Text);
            aHost.sectors[valitud].sect_date:= DateToUnix(Now);
            puhastaSectors;
            valmistaSectorid;
            sectorSave(aHost.userPath, aHost.sectors);
          except on E:Exception do
          aHost.writeErrorLog('Sector change: ' + E.Message);
          end;  // end try block

        end // end width kontroll block
      else
        Application.MessageBox('Incorrect sector width', 'Ussike annab teada', MB_ICONWARNING);
    end // end sec_name block
  else
    Application.MessageBox('Name length must be 3-20 characters', 'Ussike annab teada', MB_ICONWARNING);
end;

// sektori kustutamine
procedure TaScrKog.sec_delBClick(Sender: TObject);
var
  i, valitud: ShortInt;
  temp: SectKog;
begin
  try
    SetLength(temp, sectCnt);
    temp:= aHost.sectors;
    sectCnt:= 0;
    valitud:= sec_list.ItemIndex;
    for i:= 0 to Length(temp)-1 do
      begin
        if (valitud <> i) then
          begin
            SetLength(aHost.sectors, sectCnt+1);
            aHost.sectors[sectCnt]:= temp[i];
            inc(sectCnt);
          end
        else if (valitud = i) then
          try
            trashCnt:= Length(trash);
            SetLength(trash, trashCnt+1);
            trash[trashCnt].skm_type:= 1;
            trash[trashCnt].skm_id:= temp[i].sect_ID;
          except on E:Exception do
            aHost.writeErrorLog('Exception @ populating Trash (sect): ' + E.Message);
          end; // try trash
      end; // for i loop

    puhastaSectors;
    valmistaSectorid;
    sectorSave(aHost.userPath, aHost.sectors);
    saveTrash;
  except on E:Exception do
    aHost.writeErrorLog('Sector delete: ' + E.Message);
  end;
end;

procedure TaScrKog.sec_listClick(Sender: TObject);
var
  selItem: ShortInt;
  laius: string;
begin
  try
    if sec_list.ItemIndex < sec_list.Items.Count then
      begin
        selItem:= sec_list.ItemIndex;
        sec_name.Text:= aHost.sectors[selItem].sect_nimi;
        oldSecWidth:= aHost.sectors[selItem].sect_size;
        sec_width.Text:= IntToStr(oldSecWidth);
        sec_setB.Enabled:= True;
        sec_delB.Enabled:= True;
      end;
    if (sec_list.ItemIndex) = (sec_list.Items.Count-1) then
      begin
        sec_setB.Enabled:= False;
        sec_delB.Enabled:= False;
        laius:= Copy(sec_stat.Caption, 1, 1);
        if (isInt(laius)) then
          sec_width.Text:= IntToStr(StrToInt(laius)+1)
        else
          sec_width.Text:= '0';
      end;
  except on E:Exception do
    aHost.writeErrorLog('sect_list: ' + E.Message);
  end;
end;

procedure TaScrKog.sec_listMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  startPoint.X:= X;
  startPoint.Y:= Y;
end;

procedure TaScrKog.sec_listDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  dropPoint: TPoint;
  startPos, dropPos, i: SmallInt;
  temp: TSectKog;
begin
  dropPoint.X:= X;
  dropPoint.Y:= Y;
  with Source as TListBox do
    begin
      startPos:= ItemAtPos(startPoint, True);
      dropPos:= ItemAtPos(dropPoint, True);
      if ((startPos <> -1) AND (startPos < (Items.Count -1)) AND (dropPos <> -1) AND (dropPos < Items.Count -1)) then
        begin
          Items.Move(startPos, dropPos);
          sleep(10);
          // sektori asukoha muutmine
          try
            if (dropPos > startPos) then
              begin
                temp:= aHost.sectors[startPos];
                for i:= startPos to dropPos do
                  aHost.sectors[i]:= aHost.sectors[i+1];
                aHost.sectors[dropPos]:= temp;
              end
            else if (dropPos < startPos) then
              begin
                temp:= aHost.sectors[startPos];
                for i:= startPos downto dropPos do
                  aHost.sectors[i]:= aHost.sectors[i-1];
                aHost.sectors[dropPos]:= temp;
              end;
            aMain.sectorSave(aHost.userPath, aHost.sectors);
          except on E:Exception do
            aHost.writeErrorLog('Sector Pos change: ' + E.Message);
          end; // end asukoha muutmine

        end;
    end;
  sec_list.ItemIndex:= dropPos;
end;

procedure TaScrKog.sec_listDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept:= Source = sec_list;
end;


{************************ KONFID ************************}

procedure TaScrKog.konf_pgShow(Sender: TObject);
var
  i: SmallInt;
begin
  puhastaKonfid;
  // reload sector list
  try
    knf_combobox[0].Clear;
    if (sectCnt > 0) then
      for i:= 0 to sectCnt-1 do
        knf_combobox[0].Items.add(aHost.sectors[i].sect_nimi);
        
    knf_combobox[0].ItemIndex:= knf_combobox[0].Items.Count-1; // select Default
  except on E:Exception do
    aHost.writeErrorLog('Error @ reloading sector on konfid: ' + E.Message);
  end;
end;

procedure TaScrKog.valmista_konfiAbi;
var
  i: SmallInt;
begin
// TMemo
  knf_text:= TMemo.Create(Self);
  knf_text.Parent:= bgPan2;
  knf_text.Top:= 55;
  knf_text.Left:= 4;
  knf_text.ScrollBars:= ssBoth;
  knf_text.Width:= bgPan2.Width - 6;
  knf_text.Height:= bgPan2.Height - 85;

{ buttons
0: new/cancel
1: add/change
2: delete
}
  for i:= 0 to 2 do
    begin
      knf_button[i]:= TButton.Create(Self);
      knf_button[i].Parent:= bgPan2;
      knf_button[i].Top:= bgPan2.Height - 27;
      knf_button[i].Left:= bgPan2.Width - 249 + (i*80);
      knf_button[i].Width:= 75;
      knf_button[i].Height:= 23;
    end;
  knf_button[0].Caption:= 'New';
  knf_button[0].OnClick:= newB;

  knf_button[1].Caption:= 'Change';
  knf_button[1].Enabled:= False;
  knf_button[1].OnClick:= addB;

  knf_button[2].Caption:= 'Delete';
  knf_button[2].Enabled:= False;
  knf_button[2].OnClick:= delB;


  for i:= 0 to 1 do
    begin
  // TEdit
  // 0: name
  // 1: hint
      knf_edit[i]:= TEdit.Create(Self);
      knf_edit[i].Parent:= bgPan2;
      knf_edit[i].Top:= i*24 + 7;
      knf_edit[i].Left:= Abs(i-1)*320 + 4;
      knf_edit[i].Height:= 21;
      knf_edit[i].Width:= i*405 + 155;
      knf_edit[i].ReadOnly:= True;
      knf_edit[i].Tag:= 100 + i;
      knf_edit[i].OnKeyUp:= countKeys;
    end;
    knf_edit[0].MaxLength:= 15;
    knf_edit[1].MaxLength:= 100;


  // ListBox
  // 0: sector
  // 1: name
  for i:= 0 to 1 do
    begin
      knf_combobox[i]:= TComboBox.Create(Self);
      knf_combobox[i].Parent:= bgPan2;
      knf_combobox[i].Top:= 7;
      knf_combobox[i].Left:= i*260 + 64;
      knf_combobox[i].Width:= Abs(i-1)*40 + 160;
      knf_combobox[i].Height:= 21;
      knf_combobox[i].Style:= csDropDownList;
    end;

  knf_combobox[1].OnChange:= selectKonf;

  // CheckBox
  // 0: hint
  // 1: script assistant
  for i:= 0 to 1 do
    begin
      knf_checkbox[i]:= TCheckBox.Create(Self);
      knf_checkbox[i].Parent:= bgPan2;
      knf_checkbox[i].Font.Style:= knf_checkbox[i].Font.Style + [fsBold];
      knf_checkbox[i].Height:= 21;
      knf_checkbox[i].Enabled:= False;
    end;
  knf_checkbox[0].Caption:= 'Hint?';
  knf_checkbox[0].Top:= knf_edit[1].Top;
  knf_checkbox[0].Left:= bgPan2.Width - 57;
  knf_checkbox[0].Width:= 51;
  knf_checkbox[0].OnClick:= activHint;

  knf_checkbox[1].Caption:= 'Script assistant?';
  knf_checkbox[1].Top:= bgPan2.Height - 25;
  knf_checkbox[1].Left:= 7;
  knf_checkbox[1].Width:= 150;


{ labels
0: location
1: name
2: name char rem
3: hint char rem
}
  for i:= 0 to 3 do
    begin
      knf_label[i]:= TLabel.Create(Self);
      knf_label[i].Parent:= bgPan2;
      knf_label[i].AutoSize:= False;
      knf_label[i].Layout:= tlCenter;
      knf_label[i].Height:= 21;
      knf_label[i].Top:= 7;
      knf_label[i].Width:= 110;
    end;
  knf_label[0].Caption:= 'Location:';
  knf_label[0].Font.style:= knf_label[0].Font.style + [fsBold];
  knf_label[0].Left:= 6;
  knf_label[0].Width:= 55;

  knf_label[1].Caption:= 'Name:';
  knf_label[1].Font.style:= knf_label[1].Font.style + [fsBold];
  knf_label[1].Left:= knf_combobox[1].Left - 38;
  knf_label[1].Width:= 38;


  knf_label[2].Caption:= '15/15';
  knf_label[2].Top:= knf_edit[0].Top;
  knf_label[2].Visible:= False;
  knf_label[2].Left:= knf_edit[0].Left + knf_edit[0].Width + 5;

  knf_label[3].Caption:= '100/100';
  knf_label[3].Top:= knf_edit[1].Top;
  knf_label[3].Visible:= False;
  knf_label[3].Left:= knf_edit[1].Left + knf_edit[1].Width + 5;

end;


procedure TaScrKog.activHint(Sender: TObject);
begin
  if Sender is TCheckBox then
    begin
      aHost.disGray(knf_edit[1], TCheckBox(Sender).Checked);
    end;
end;

procedure TaScrKog.puhastaKonfid(sel_konf: boolean = False);
var
  i: SmallInt;
begin
  knf_text.Clear;
  knf_text.ReadOnly:= True;
  knf_edit[0].Visible:= False;
  aHost.disGray(knf_edit[1], False);
  for i:= 0 to 1 do
    begin
      knf_edit[i].Clear;
      knf_edit[i].ReadOnly:= True;
      knf_button[i+1].Enabled:= False;
      knf_checkbox[i].Checked:= False;
      knf_checkbox[i].Enabled:= False;
      knf_label[i+2].Visible:= False;
    end;
  knf_button[0].Caption:= 'New';
  knf_button[1].Caption:= 'Change';
  knf_combobox[0].ItemIndex:= knf_combobox[0].Items.Count-1;
  knf_combobox[1].Visible:= True;

  if NOT sel_konf then
    begin
      knf_combobox[1].Clear;
      knf_combobox[1].Items.add('Select script...');
      for i:= 0 to konfCnt-1 do
        knf_combobox[1].Items.add(aHost.konfid[i].konf_nimi);
      knf_combobox[1].ItemIndex:= 0;
    end;
end;

procedure TaScrKog.selectKonf(Sender: TObject);
var
  i, cbAsukoht: SmallInt;
begin
  if Sender is TCombobox then
    begin
      cbAsukoht:= TCombobox(Sender).ItemIndex-1;
      puhastaKonfid(True);
      if (cbAsukoht >= 0) then
        begin
          for i:= 0 to 1 do
            knf_button[i+1].Enabled:= True;
          knf_checkbox[0].Checked:= aHost.konfid[cbAsukoht].konf_hintAllow;
          knf_edit[1].Text:= aHost.konfid[cbAsukoht].konf_hint;
          knf_checkbox[1].Checked:= aHost.konfid[cbAsukoht].konf_scrAssistant;
          for i:= 0 to sectCnt-1 do
            if (aHost.konfid[cbAsukoht].konf_pl_id = aHost.sectors[i].sect_ID) then
              begin
                knf_combobox[0].ItemIndex := i;
                break;
              end;
          for i:= 0 to aHost.konfid[cbAsukoht].konf_text_ridu-1 do
            knf_text.Lines.Add(aHost.konfid[cbAsukoht].konf_text[i]);
        end;
    end;
end;

procedure TaScrKog.newB(Sender: TObject);
var
  i: SmallInt;
begin
  if Sender is TButton then
    begin
      if (knf_button[0].Caption = 'New') then
        begin
          knf_button[0].Caption:= 'Cancel';
          knf_button[1].Caption:= 'Add';
          knf_button[1].Enabled:= True;
          knf_button[2].Enabled:= False;
          knf_combobox[0].ItemIndex:= knf_combobox[0].Items.Count-1;
          knf_combobox[1].Visible:= False;
          knf_edit[0].Visible:= True;
          knf_text.ReadOnly:= False;
          knf_text.Clear;
          for i:= 0 to 1 do
            begin
              knf_label[i+2].Visible:= True;
              knf_edit[i].ReadOnly:= False;
              knf_checkbox[i].Enabled:= True;
              knf_checkbox[i].Checked:= False;
            end;
        end
      else
        puhastaKonfid;
    end;
end;

procedure TaScrKog.addB(Sender: TObject);
var
  i: SmallInt;
begin
  if Sender is TButton then
    begin
      if (TButton(Sender).Caption = 'Add') then
        lisaKonf
      else if (TButton(Sender).Caption = 'Change') then
        begin
          knf_button[0].Enabled:= False;
          knf_button[1].Caption:= 'Save';
          knf_button[2].Caption:= 'Cancel';
          knf_text.ReadOnly:= False;
          knf_combobox[1].Visible:= False;
          knf_edit[0].Text:= knf_combobox[1].Items[knf_combobox[1].ItemIndex];
          knf_edit[0].Visible:= True;
          for i:= 0 to 1 do
            begin
              knf_checkbox[i].Enabled:= True;
              knf_edit[i].ReadOnly:= False;
            end;
        end
      else if (TButton(Sender).Caption = 'Save') then
        if (MessageDlg(('Change script "' + knf_combobox[1].Items[knf_combobox[1].itemIndex] + '"?'),
          mtConfirmation, [mbOK, mbCancel],0) = mrOk) then
            muudaKonf;
    end;
end;

procedure TaScrKog.delB(Sender: TObject);
begin
  if Sender is TButton then
    begin
      if (TButton(Sender).Caption = 'Delete') then
        begin
          if (MessageDlg(('Delete script "' + knf_combobox[1].Items[knf_combobox[1].itemIndex] + '"?'),
            mtConfirmation, [mbOK, mbCancel],0) = mrOk) then
              kustutaKonf;
        end
      else if (TButton(Sender).Caption = 'Cancel') then
        begin
          puhastaKonfid;
          knf_button[0].Enabled:= True;
        end;
    end;
end;

procedure TaScrKog.countKeys(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Sender is TEdit then
    if (TEdit(Sender).Tag = 100) then
      countIncome(TEdit(Sender).Text, knf_label[2])
    else if (TEdit(Sender).Tag = 101) then
      countIncome(TEdit(Sender).Text, knf_label[3])
end;

procedure TaScrKog.lisaKonf;
var
  strCnt, i: SmallInt;
begin
  try
    SetLength(aHost.konfid, konfCnt+1);
    with aHost.konfid[konfCnt] do
      begin
        konf_nimi := knf_edit[0].text;
        konf_hint := knf_edit[1].text;
        konf_id := Copy(SetSKM_ID(knf_edit[0].Text), 1, 8);
        konf_pl_ID := aHost.sectors[knf_combobox[0].itemIndex].sect_ID;
        konf_hintAllow := knf_checkbox[0].Checked;
        konf_scrAssistant := knf_checkbox[1].Checked;
        konf_date:= DateToUnix(Now);
      end;
    strCnt:= knf_text.Lines.Count;
    aHost.konfid[konfCnt].konf_text_ridu:= strCnt;
    SetLength(aHost.konfid[konfCnt].konf_text, strCnt+1);
    for i:= 0 to strCnt-1 do
      aHost.konfid[konfCnt].konf_text[i]:= knf_text.lines.Strings[i];
    inc(konfCnt);
    if NOT aMain.konfSave(aHost.userPath, aHost.konfid) then
      aHost.writeErrorLog('Save add konf: ' + GetLastDllError);
    puhastaKonfid;
  except on E:Exception do
    aHost.writeErrorLog('Add konf: ' + E.Message);
  end;
end;

procedure TaScrKog.muudaKonf;
var
  strCnt, i: SmallInt;
begin
  try
    with aHost.konfid[knf_combobox[1].ItemIndex-1] do
      begin
        konf_nimi := knf_edit[0].text;
        konf_hint := knf_edit[1].text;
        konf_pl_ID := aHost.sectors[knf_combobox[0].itemIndex].sect_ID;
        konf_hintAllow := knf_checkbox[0].Checked;
        konf_scrAssistant := knf_checkbox[1].Checked;
        konf_date:= DateToUnix(Now);
      end;
    strCnt:= knf_text.Lines.Count;
    aHost.konfid[knf_combobox[1].ItemIndex-1].konf_text_ridu:= strCnt;
    SetLength(aHost.konfid[knf_combobox[1].ItemIndex-1].konf_text, strCnt+1);
    for i:= 0 to strCnt-1 do
      aHost.konfid[knf_combobox[1].ItemIndex-1].konf_text[i]:= knf_text.lines.Strings[i];
    if NOT aMain.konfSave(aHost.userPath, aHost.konfid) then
      aHost.writeErrorLog('Save change konf: ' + GetLastDllError);
    puhastaKonfid;
  except on E:Exception do
    aHost.writeErrorLog('Change konf: ' + E.Message);
  end;
end;

procedure TaScrKog.kustutaKonf;
var
  temp: KonfKog;
  i: SmallInt;
begin
  try
    SetLength(temp, Length(aHost.konfid));
    temp:= aHost.konfid;
    konfCnt:= 0;
    SetLength(aHost.konfid, konfCnt);

    for i:= 0 to Length(temp)-1 do
      begin
        if (i <> (knf_combobox[1].ItemIndex-1)) then
          begin
            SetLength(aHost.konfid, konfCnt+1);
            aHost.konfid[konfCnt]:= temp[i];
            inc(konfCnt);
          end
        else if ((knf_combobox[1].ItemIndex-1) = i) then
          try
            trashCnt:= Length(trash);
            SetLength(trash, trashCnt+1);
            trash[trashCnt].skm_type:= 2;
            trash[trashCnt].skm_id:= temp[i].konf_id;
          except on E:Exception do
            aHost.writeErrorLog('Exception @ populating Trash (konf): ' + E.Message);
          end;
      end; // for i loop
        
    if NOT aMain.konfSave(aHost.userPath, aHost.konfid) then
      aHost.writeErrorLog('Save delete konf: ' + GetLastDllError);
    saveTrash;
    puhastaKonfid;
  except on E:Exception do
    aHost.writeErrorLog('Delete konf: ' + E.Message);
  end;
end;







{************************ MACROD ************************}

procedure TaScrKog.macr_pgShow(Sender: TObject);
begin
  mscr.SetFocus;
  clear_macr_selection;
  mcr_uueke:= False;
end;

{***************************
  New/Change macro handlers
****************************}

procedure TaScrKog.valmistaMacroAbi;
var
  i: SmallInt;
begin
// combobox (Macro position selector)
  mcr_combobox:= TComboBox.Create(Self);
  mcr_combobox.Top:= 7;
  mcr_combobox.Width:= 150;
  mcr_combobox.Left:= 320;
  mcr_combobox.Height:= 21;
  mcr_combobox.Style:= csOwnerDrawVariable;
  mcr_combobox.OnCloseUp:= macro_out;
  mcr_combobox.OnEnter:= macro_in;

{
  Macro nuppud
  0: Add/Change
  1: Cancel/Delete
}
  for i:= 0 to 1 do
    begin
      mcr_button[i]:= TButton.Create(Self);
      mcr_button[i].Top:= 7;
      mcr_button[i].Left:= 485+(i*90);
      mcr_button[i].Width:= 75;
      mcr_button[i].Height:= 21;
    end;
  mcr_button[0].Caption:= 'Add';
  mcr_button[0].OnClick:= macroB1;
  mcr_button[1].Caption:= 'Cancel';
  mcr_button[1].OnClick:= macroB2;


{
  Macro checkbox
  0: Macro confirm
  1: Macro allow hint
}

  for i:= 0 to 1 do
    begin
      mcr_checkbox[i]:= TCheckBox.Create(Self);
      mcr_checkbox[i].Top:= (i*25) + 37;
      mcr_checkbox[i].Left:= 575;
      mcr_checkbox[i].Height:= 21;
      mcr_checkbox[i].Width:= 70;
    end;
  mcr_checkbox[0].Caption:= 'Confirm?';
  mcr_checkbox[1].Caption:= 'Hint?';

{
  Macro edit fields
  0: nimi
  1: konf
  2: hint
}

  for i:= 0 to 2 do
    begin
      mcr_edit[i]:= TEdit.Create(Self);
      mcr_edit[i].Top:= (i*25) + 7 + (Trunc((i+1) / 2)) * 5;
      mcr_edit[i].Height:= 21;
      mcr_edit[i].Left:= 50;
      mcr_edit[i].Width:= (Trunc((i+1) / 2)) * 320 + 100;
    end;
{
  Macro labels
 0: nimi
 1: konf
 2: hint
 3: nimi counter
 4: konf counter
 5: hint counter
 6: set before (macro)
}
  for i:= 0 to 6 do
    begin
      mcr_label[i]:= TLabel.Create(Self);
      mcr_label[i].Top:= (i*25) + 7 + (Trunc((i+1) / 2)) * 5;
      mcr_label[i].Height:= 21;
      mcr_label[i].AutoSize:= False;
      mcr_label[i].Layout:= tlCenter;
      mcr_label[i].Width:= 52;
      mcr_label[i].Left:= 7;
      //mcr_label[i].Font.Style:= mcr_label[i].Font.Style + [fsBold];
    end;
  mcr_label[0].Caption:= 'Name:';
  mcr_label[1].Caption:= 'Macro:';
  mcr_label[2].Caption:= 'Hint:';

  mcr_label[3].Caption:= '15/15';
  mcr_label[3].Left:= mcr_edit[0].Left + mcr_edit[0].Width + 5;
  mcr_label[3].Top:= mcr_edit[0].Top;

  mcr_label[4].Caption:= '255/255';
  mcr_label[4].Left:= mcr_edit[1].Left + mcr_edit[1].Width + 5;
  mcr_label[4].Top:= mcr_edit[1].Top;

  mcr_label[5].Caption:= '100/100';
  mcr_label[5].Left:= mcr_edit[2].Left + mcr_edit[2].Width + 5;
  mcr_label[5].Top:= mcr_edit[2].Top;

  mcr_label[6].Caption:= 'Set before:';
  mcr_label[6].Left:= mcr_combobox.Left - 55;
  mcr_label[6].Top:= mcr_combobox.Top;
end;


{******************************************************
  macro elementide paigutamine valitud macro paneelile
*******************************************************}

procedure TaScrKog.abivahendid(vanem: TWinControl);
var
  i: SmallInt;
begin
  try
    //if (vanem <> nil) then  // toome elemendid nähtavale ja poogime vanema külge
      begin
        mcr_combobox.Parent:= vanem;
        for i:= 0 to 1 do
          begin
            mcr_button[i].Parent:= vanem;
            mcr_button[i].Visible:= (vanem <> nil);
            mcr_checkbox[i].Parent:= vanem;
            mcr_checkbox[i].Visible:= (vanem <> nil);
          end;

        for i:= 0 to 6 do
          begin
            mcr_label[i].Parent:= vanem;
            mcr_label[i].Visible:= (vanem <> nil);
          end;

        for i:= 0 to 2 do
          begin
            mcr_edit[i].Parent:= vanem;
            mcr_edit[i].Visible:= (vanem <> nil);
          end;
      end;
  except on E:Exception do
    aHost.writeErrorLog('Exception @ abivahendid: ' + E.Message);
  end;
end;

{******************************************************
  macro drawing, opening & closing
*******************************************************}

// macro paneelide joonistamine
procedure TaScrKog.draw_macros;
var
  i, j: SmallInt;
  arrCnt: SmallInt;
begin        
	if NOT (Assigned(new_mcr_panel)) then    
  try
    new_mcr_panel:= TPanel.Create(nil);
    with new_mcr_panel do
      begin
        Parent:= mscr;
        Height:= 35;
        Top:= 0;
        Align:= alTop;
        Caption:= 'New';
        OnClick:= ava_macro;
        BevelInner:= bvSpace;
        BevelOuter:= bvNone;
        Tag:= -1;
        TabOrder:= 0;
        OnMouseMove:= liikumine;
        Color:= $00D2D2D2;
      end; // with

  except on E:Exception do
    aHost.writeErrorLog('creating new macro panel: ' + E.Message);
  end; // try cresting new_mcr_panel

  if (Length(mcr_panels) > 0) then
    try
      Vabadus(mcr_panels);
      SetLength(mcr_panels, 0);
    except on E:Exception do
      aHost.writeErrorLog('Error @ mcr_panelite nullimine: ' + E.Message);
    end;
    
  if (macrCnt > 0) then
    try
      for i:= macrCnt-1 downto 0 do
        begin
          arrCnt:= Length(mcr_panels);
          SetLength(mcr_panels, arrCnt+1);
          mcr_panels[arrCnt]:= TPanel.Create(nil);
          mcr_panels[arrCnt].Parent:= mscr; // TScrollBox
          mcr_panels[arrCnt].Height:= 35;
          mcr_panels[arrCnt].Top:= macrCnt - i;
          mcr_panels[arrCnt].Align:= alTop;
          mcr_panels[arrCnt].Caption:= aHost.macrod[arrCnt].macr_nimi;
          mcr_panels[arrCnt].OnClick:= ava_macro;
          mcr_panels[arrCnt].OnEnter:= macro_in;
          mcr_panels[arrCnt].OnExit:= macro_out;
          mcr_panels[arrCnt].Tag:= arrCnt;
          mcr_panels[arrCnt].BevelInner:= bvSpace;
          mcr_panels[arrCnt].BevelOuter:= bvNone;
          mcr_panels[arrCnt].OnMouseMove:= liikumine;
          mcr_panels[arrCnt].Color:= $00D2D2D2;
          //mcr_combobox.Clear;
        end; // for i loop
    except on E:Exception do
      aHost.writeErrorLog('Error on drawing macros: ' + E.Message);
    end; // try block

// peidame abivahendi objektid
//  abivahendid(nil);
  abivahendid(new_mcr_panel);
// Combobox population
    try
      mcr_combobox.Clear;
      for j:= 0 to macrCnt-1 do
        mcr_combobox.Items.Add(aHost.macrod[j].macr_nimi);
      mcr_combobox.Items.Add('THE END');
      mcr_combobox.ItemIndex:= 0;
    except on E:Exception do
      aHost.writeErrorLog('creating new macro panel: ' + E.Message);
    end;
	abivahendid(nil);

  for i:= High(mcr_panels) downto 0 do
    mcr_panels[i].Top:= i+1;
  
end;

// macro avamine
procedure TaScrKog.ava_macro(Sender: TObject);
begin
  if ((Sender is TPanel) AND (TPanel(Sender).Tag <> leitud_panel)) then
    begin
      try
        if (leitud_panel = -1) then
          new_mcr_panel.Caption:= leitud_panel_nimi
        else if (leitud_panel > -2) then
          mcr_panels[leitud_panel].Caption:= leitud_panel_nimi;

        if (leitud_panel >= 0) then
          mcr_panels[leitud_panel].Height:= 35
        else if (leitud_panel = -1) then // New panel handler
          new_mcr_panel.Height:= 35;

        leitud_panel:= TPanel(Sender).Tag;

        abivahendid(TPanel(Sender));
        select_macro(leitud_panel);
        leitud_panel_nimi:= TPanel(Sender).Caption;
        with TPanel(Sender) do // valitud paneeli sätted
          begin
            BevelInner:= bvLowered;
            BevelOuter:= bvLowered;
            Color:= $00DFD5D2;
            Caption:= '';
            Height:= 92;
          end;
      except on E:Exception do
        aHost.writeErrorLog('mcr_panel opening: ' + E.Message);
      end;
    end; // Sender
end;

procedure TaScrKog.select_macro(mcr_id: SmallInt);
var
  i: SmallInt;
begin
 // "New" Paneli seadistus kontroll
  try
    if (mcr_id >= 0) then
      begin
        new_mcr_panel.Height:= 35;
        new_mcr_panel.BevelInner:= bvSpace;
        new_mcr_panel.BevelOuter:= bvNone;
        new_mcr_panel.color:= $00D2D2D2;
        mcr_combobox.Visible:= True;
        mcr_label[6].Visible:= True;
      end
    else
      begin
        mcr_combobox.Visible:= False;
        mcr_label[6].Visible:= False;
      end;
  except on E:Exception do
    aHost.writeErrorLog('New mcr panel: ' + E.Message);
  end;

  // set to default kõikide paneelide H ja T position
  try
    for i:= 0 to High(mcr_panels) do
      begin
        mcr_panels[i].Height:= 35;
        mcr_panels[i].BevelInner:= bvSpace;
        mcr_panels[i].BevelOuter:= bvNone;
        mcr_panels[i].color:= $00D2D2D2;
      end;


  // kirjuta andmed läbi
    if (mcr_combobox.Items.Count > 0) then
      mcr_combobox.ItemIndex:= 0;
    if (mcr_id >= 0) then
      begin
        mcr_edit[0].Text:= aHost.macrod[mcr_id].macr_nimi;
        mcr_edit[1].Text:= aHost.macrod[mcr_id].macr_text;
        mcr_edit[2].Text:= aHost.macrod[mcr_id].macr_hint;
        mcr_checkbox[0].Checked:= aHost.macrod[mcr_id].macr_cnf;
        mcr_checkbox[1].Checked:= aHost.macrod[mcr_id].macr_hintAllow;
        mcr_button[0].Caption:= 'Change';
        mcr_button[1].Caption:= 'Delete';
        mcr_uueke:= False;
      end
    else if (mcr_id = -1) then
      begin
        mcr_edit[0].Clear;
        mcr_edit[1].Clear;
        mcr_edit[2].Clear;
        mcr_checkbox[0].Checked:= False;
        mcr_checkbox[1].Checked:= False;
        mcr_button[0].Caption:= 'Add';
        mcr_button[1].Caption:= 'Cancel';
        mcr_uueke:= True;
      end;

  except on E:Exception do
    aHost.writeErrorLog('mcr_panel data write: ' + E.Message);
  end;
end;

// Macro paneelide alg dimensioonide taastamine
procedure TaScrKog.clear_macr_selection;
var
  i: SmallInt;
begin
  try
    if Assigned(new_mcr_panel) then
      begin
        new_mcr_panel.BevelInner:= bvSpace;
        new_mcr_panel.BevelOuter:= bvNone;
        new_mcr_panel.Color:= $00D2D2D2;
        new_mcr_panel.Height:= 35;
      end;
  except on E:Exception do
    aHost.writeErrorLog('clearing new_macr panel: ' + E.Message);
  end;

  if (Length(mcr_panels) > 0) then
    try
      for i:= Low(mcr_panels) to High(mcr_panels) do
        begin
          mcr_panels[i].Height:= 35;
          mcr_panels[i].BevelInner:= bvSpace;
          mcr_panels[i].BevelOuter:= bvNone;
          mcr_panels[i].color:= $00D2D2D2;
        end;
    except on E:Exception do
      aHost.writeErrorLog('clearing macro panels: ' + E.Message);
    end;

  try
    if (leitud_panel = -1) then
      new_mcr_panel.Caption:= leitud_panel_nimi
    else if (leitud_panel > -1) then
      mcr_panels[leitud_panel].Caption:= leitud_panel_nimi;
      
    leitud_panel:= -2;
    leitud_panel_nimi:= '';
    abivahendid(nil);
    if macr_pg.Showing then
      mscr.SetFocus;
  except on E:Exception do
    aHost.writeErrorLog('finishing clearing: ' + E.Message);
  end;
end;

// macro panels mouse hover action
procedure TaScrKog.liikumine(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  i: SmallInt;
begin
  if (TPanel(Sender).Tag <> leitud_panel) then
    begin
      if (new_mcr_panel.Height < 92) then
        begin
          new_mcr_panel.BevelInner:= bvSpace;
          new_mcr_panel.BevelOuter:= bvNone;
          new_mcr_panel.Color:= $00D2D2D2;
        end;

    //if (Length(mcr_panels) > 0) then
    for i:= Low(mcr_panels) to High(mcr_panels) do
      if (i <> leitud_panel) then
        begin
          mcr_panels[i].BevelInner:= bvSpace;
          mcr_panels[i].BevelOuter:= bvNone;
          mcr_panels[i].Color:= $00D2D2D2;
        end;
    TPanel(Sender).BevelInner:= bvRaised;
    TPanel(Sender).BevelOuter:= bvLowered;
    TPanel(Sender).Color:= $00E2E2E2;
  end;
end;

// maybe
procedure TaScrKog.macro_in(Sender: TObject);
begin
  mcr_panel_avatud:= True;
end;

procedure TaScrKog.macro_out(Sender: TObject);
begin
  mcr_panel_avatud:= False;
  mscr.SetFocus;
end;

procedure TaScrKog.mscrMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if NOT mcr_panel_avatud then
    mscr.VertScrollBar.Position:= mscr.VertScrollBar.Position - (Trunc(wheelDelta div 4));
end;



{******************************************************
  macro buttons handlers
*******************************************************}

procedure TaScrKog.macroB1(Sender: TObject);
begin
  if Sender is TButton then
    if mcr_uueke then
      begin
        if (Length(mcr_edit[0].Text) > 3) then
          lisa_macro
        else
          ShowMessage('boo');
      end
    else
      if (MessageBox(Application.Handle,
        PAnsiChar('Modify "' + leitud_panel_nimi + '"?'),
        'Ussike küsib', MB_OKCANCEL + MB_ICONWARNING + MB_DEFBUTTON2) = IDOK) then
        muuda_macro;
end;

procedure TaScrKog.macroB2(Sender: TObject);
begin
  if Sender is TButton then
    if mcr_uueke then
      clear_macr_selection
    else
      if (MessageBox(Application.Handle,
        PAnsiChar('Delete "' + leitud_panel_nimi + '"?'),
        'Ussike küsib', MB_OKCANCEL + MB_ICONWARNING + MB_DEFBUTTON2) = IDOK) then
        kustuta_macro;
end;

procedure TaScrKog.lisa_macro;
begin
  try
    SetLength(aHost.macrod, macrCnt+1);
    with aHost.macrod[macrCnt] do
      begin
        macr_id:= SetSKM_ID(mcr_edit[0].Text);
        macr_nimi:= mcr_edit[0].Text;
        macr_text:= mcr_edit[1].Text;
        macr_hint:= mcr_edit[2].Text;
        macr_cnf:= mcr_checkbox[0].Checked;
        macr_hintAllow:= mcr_checkbox[1].Checked;
        macr_date:= DateToUnix(Now);
      end;
    inc(macrCnt);
  except on E:Exception do
    aHost.writeErrorLog('macro lisamine: ' + E.Message);
  end;

  try
    aMain.macroSave(aHost.userPath, aHost.macrod);
    clear_macr_selection;
    draw_macros;
    mcr_uueke:= False;
    mscr.SetFocus;
  except on E:Exception do
    aHost.writeErrorLog('macro lisamise lõpetamine: ' + E.Message);
  end;
end;

procedure TaScrKog.muuda_macro;
var
  i: SmallInt;
  temp: TMacrKog;
begin
  try
    if (leitud_panel >= 0) then
      with aHost.macrod[leitud_panel] do
        begin
          macr_nimi:= mcr_edit[0].Text;
          macr_text:= mcr_edit[1].Text;
          macr_hint:= mcr_edit[2].Text;
          macr_cnf:= mcr_checkbox[0].Checked;
          macr_hintAllow:= mcr_checkbox[1].Checked;
          macr_date:= DateToUnix(Now);
        end;

  // Macro asukoha muutmine
    if (mcr_combobox.ItemIndex < leitud_panel) then
      begin
        temp:= aHost.macrod[leitud_panel];
        for i:= leitud_panel downto mcr_combobox.ItemIndex do
          aHost.macrod[i]:= aHost.macrod[i-1];
        aHost.macrod[mcr_combobox.ItemIndex]:= temp;
      end

    else if (mcr_combobox.ItemIndex > leitud_panel) then
      begin
        temp:= aHost.macrod[leitud_panel];
        for i:= leitud_panel to mcr_combobox.ItemIndex-1 do
          aHost.macrod[i]:= aHost.macrod[i+1];
        aHost.macrod[mcr_combobox.ItemIndex-1]:= temp;
      end;

  except on E:Exception do
    aHost.writeErrorLog('macro lisamine: ' + E.Message);
  end;

  try
    aMain.macroSave(aHost.userPath, aHost.macrod);
    clear_macr_selection;
    draw_macros;
    mcr_uueke:= False;
    mscr.SetFocus;
  except on E:Exception do
    aHost.writeErrorLog('macro lisamise lõpetamine: ' + E.Message);
  end;
end;

procedure TaScrKog.kustuta_macro;
var
  i: SmallInt;
  temp: MacrKog;
begin
  try
    abivahendid(nil);
    SetLength(temp, Length(aHost.macrod));
    temp:= aHost.macrod;
    macrCnt:= 0;
    SetLength(aHost.macrod, 0);

    vabadus(mcr_panels);
    SetLength(mcr_panels, 0);
  except on E:Exception do
    aHost.writeErrorLog('objektide nullimine: ' + E.Message);
  end;

  for i:= 0 to Length(temp)-1 do
    begin
      if (i <> leitud_panel) then
        begin
          SetLength(aHost.macrod, macrCnt+1);
          aHost.macrod[macrCnt]:= temp[i];
          inc(macrCnt);
        end;
    end;

  leitud_panel:= -1;
  leitud_panel_nimi:= 'New';

  try
    aMain.macroSave(aHost.userPath, aHost.macrod);
    clear_macr_selection;
    draw_macros;
    mcr_uueke:= False;
    mscr.SetFocus;
  except on E:Exception do
    aHost.writeErrorLog('macro kustutamise lõpetamine: ' + E.Message);
  end;

end;



















procedure TaScrKog.Button1Click(Sender: TObject);
begin
  syncTrash;
end;

end.
