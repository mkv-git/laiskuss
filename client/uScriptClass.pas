unit uScriptClass;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, StdCtrls, Buttons,
  ComCtrls, Forms, ExtCtrls, Dialogs;


type
  TuScriptTS = class(TObject)
    public
    // global vars


    //end vars

      constructor Create;
      destructor Destroy; override;
      procedure Set_rbState(olek: boolean); // radiobutton enabled/disabled
       // kontrollid, kas stringil on koolon ees
      function koolonKontroll(sisend: string; peab: boolean = True): string;
    private
      sectCnt : SmallInt; // Sectorite (s.h. ScrollBox'de) counter
      konfCnt : SmallInt; // Konfide counter
      
      scr_gb_arr: array of TGroupBox;
      scr_scrollbox: array of TScrollBox;
      scr_button: array of TButton;
      radioPanel: TPanel;
      scr_radio: array[0..2] of TRadioButton;

    // private procedures
      function findSecLoc(parentID: string): SmallInt; // otsitakse konfi sektori ID'd (paigutamiseks)
      procedure setTopLeft(sectID: SmallInt; konfID: SmallInt); // konfide nuppude dimensioonide määramine
      procedure EnterSB(Sender: TObject); // scrollbox onEnter handler
      procedure ExitSB(Sender: TObject); // scrollbox onExit handler
      procedure mwSB(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean); // scrollbox mousewheel handler

    // konfi procedures
      procedure launchScript(Sender: TObject); // konfi saatmine telneti
      procedure suunaScript(kuhu: byte; scriptID: SmallInt); // konfi käitlemine
  end;

implementation
uses uMain, uScrEditor;

constructor TuScriptTS.Create;
const
  rb_width: array[0..3] of SmallInt = (0, 110, 210, 140);
  rb_caption: array[0..2] of string = (
    'Send data to telnet',
    'Send data to telnet with script assistant',
    'Edit data in Script Editor');
var
  i, sectLoc: SmallInt;
begin
// Radiobuttons
  try
    for i:= 0 to 2 do
      begin
        scr_radio[i]:= TRadioButton.Create(nil);
        scr_radio[i].Parent:= uHost2.scriptTab;
        scr_radio[i].Top:= uHost2.scriptTab.Height - 14;
        scr_radio[i].Width:= rb_width[i+1];
        if (i = 0) then
          scr_radio[i].Left:= 0
        else
          scr_radio[i].Left:= scr_radio[i-1].Left + scr_radio[i-1].Width + 20;
        scr_radio[i].Height:= 15;
        scr_radio[i].Caption:= rb_caption[i];
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error @ creating scr_radio: ' + E.Message);
  end;


// Sectors
  try
    sectCnt:= Length(uHost2.sectors);
    SetLength(scr_gb_arr, sectCnt+1);
    for i:= 0 to sectCnt-1 do
      begin
        scr_gb_arr[i]:= TGroupBox.Create(nil);
        scr_gb_arr[i].Parent:= uHost2.scriptTab;
        scr_gb_arr[i].Caption:= uHost2.sectors[i].sect_nimi;
        scr_gb_arr[i].Height:= uHost2.scriptTab.Height - 15;// radioPanel.Height;
        scr_gb_arr[i].Width:= uHost2.sectors[i].sect_size * 88;
        scr_gb_arr[i].Top:= 0;
        if (i = 0) then
          scr_gb_arr[i].Left:= 0
        else
          scr_gb_arr[i].Left:= scr_gb_arr[i-1].Width + scr_gb_arr[i-1].Left;
      end; // end for i loop
  except on E:Exception do
    uHost2.writeErrorLog('Error @ creating scr_gb_arr: ' + E.Message);
  end;

  try
    SetLength(scr_scrollbox, sectCnt+1);
    for i:= 0 to sectCnt-1 do
      begin
        scr_scrollbox[i]:= TScrollBox.Create(nil);
        scr_scrollbox[i].Parent:= scr_gb_arr[i];
        scr_scrollbox[i].BorderStyle:= bsNone;
        scr_scrollbox[i].Top:= 13;
        scr_scrollbox[i].Left:= 2;
        scr_scrollbox[i].Width:= scr_gb_arr[i].Width - 4;
        scr_scrollbox[i].Height:= scr_gb_arr[i].Height - 15;
        scr_scrollbox[i].HorzScrollBar.Visible:= False;
        scr_scrollbox[i].VertScrollBar.Visible:= False;
        scr_scrollbox[i].OnEnter:= EnterSB;
        scr_scrollbox[i].OnExit:= ExitSB;
        scr_scrollbox[i].OnMouseWheel:= mwSB;
      end;
  except on E: Exception do
    uHost2.writeErrorLog('Error @ creating scr_scrollbox: ' + E.Message);
  end;

// Konfide nuppud

  konfCnt:= Length(uHost2.konfid);
  try
    SetLength(scr_button, konfCnt+1);
    for i:= 0 to konfCnt-1 do
      begin
        sectLoc:= findSecLoc(uHost2.konfid[i].konf_pl_id);
        scr_button[i]:= TButton.Create(nil);
        scr_button[i].Parent:= scr_scrollbox[sectLoc];
        scr_button[i].Caption:= uHost2.konfid[i].konf_nimi;
        scr_button[i].ShowHint:= True;
        scr_button[i].Hint:= uHost2.konfid[i].konf_hint;
        scr_button[i].Height:= 23;
        scr_button[i].Width:= 82;
        scr_button[i].Tag:= i;
        scr_button[i].OnClick:= launchScript;
        setTopLeft(sectLoc, i);
      end;
    set_rbState(False);
  except on E:Exception do
    uHost2.writeErrorLog('Error @ creating scr_button: ' + E.Message);
  end;
end;

destructor TuScriptTS.Destroy;
begin
  uHost2.vabadus(scr_radio);
  uHost2.vabadus(radioPanel);
  uHost2.vabadus(scr_button);
  uHost2.vabadus(scr_scrollbox);
  uHost2.vabadus(scr_gb_arr);
end;

function TuScriptTS.findSecLoc(parentID: string): SmallInt;
var
  i: SmallInt;
begin
  Result:= Length(uHost2.sectors)-1 ;
  for i:= 0 to Length(uHost2.sectors)-1 do
    if (uHost2.sectors[i].sect_ID = parentID) then
      begin
        Result:= i;
        break;
      end;
end;

procedure TuScriptTS.setTopLeft(sectID: SmallInt; konfID: SmallInt);
var
  bTop, bLeft, contCnt, sectSize, allSectSize, i: integer;
begin
  bLeft:= 0;
  bTop:= 0;
// palju on juba nuppe sectorile määratud (-1, kuna kõnealune nupp on juba määratud sektorile)
  contCnt:= scr_scrollbox[sectID].ControlCount-1;
// sektori laius
  sectSize:= uHost2.sectors[sectID].sect_size;

// 'Default' sectori laius on 0
// tegelik laius sõltub kasutaja poolt määratud sektorite laius
  if (sectSize = 0) then
    begin
      allSectSize:= 0;
      for i:= 0 to Length(uHost2.sectors)-1 do
        allSectSize:= allSectSize + uHost2.sectors[i].sect_size;
      sectSize:= 10 - allSectSize;
    end; // end for i loop

  if (contCnt > 0) then
    begin
// nuppude arv MOD sektori laius * 88 (nupp 80px + 4 mõlemalt poolt)
     bLeft:= (contCnt mod sectSize) * 88;
// nuppude arv JAGADA sektori laius * 25 (nupp 22px + 3px )
     bTop:= (contCnt div sectSize) * 25;
    end;

// nuppude dimensioonid
  scr_button[konfID].Left:= bLeft;
  scr_button[konfID].Top:= bTop;
end;

procedure TuScriptTS.Set_rbState(olek: boolean);
begin
  scr_radio[0].Enabled:= olek;
  scr_radio[1].Enabled:= olek;
  if olek then
    scr_radio[0].Checked:= True
  else
    scr_radio[2].Checked:= True;
end;


{ ********************

Scrollbox handlers

********************* }

procedure TuScriptTS.EnterSB(Sender: TObject);
begin
  if (Sender is TScrollBox) then
    TScrollBox(Sender).Color:= $00EAE1DB;
end;

procedure TuScriptTS.ExitSB(Sender: TObject);
begin
  if (Sender is TScrollBox) then
    TScrollBox(Sender).Color:= $00E4E4E4;
end;

procedure TuScriptTS.mwSB(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  firstElement: SmallInt; // ScrollBox'i esimene nupp - Top pos jaoks
  lastElement : SmallInt; // ScrollBox'i viimane nupp - Bottom jaoks
  elementCnt  : SmallInt; // ScrollBox'i nuppude arv
begin
  if (Sender is TScrollBox) then
    begin
      Handled:= True;
      elementCnt:= TScrollBox(Sender).ControlCount;
      if (elementCnt > 0) then
        begin
          firstElement:= TScrollBox(Sender).Controls[0].Top;
          lastElement:= TScrollBox(Sender).Controls[elementCnt-1].Top + 24;

          if WheelDelta < 0 then
            begin
              if (lastElement > TScrollBox(Sender).Height) then
                TScrollBox(Sender).ScrollBy(0, -25);
            end // end of wheel UP
          else if WheelDelta > 0 then
            begin
            if (firstElement < 0) then
              TScrollBox(Sender).ScrollBy(0, 25);
            end; // end of wheel down
        end; // end of elementCnt
    end; // end of if Sender
end;

// end scrollbox handler


{*************************** SCRIPTS ***********************}
procedure TuScriptTS.launchScript(Sender: TObject);
var
  sTag    : SmallInt; // konfi nuppu tag ID
  scrNimi : string; // konfi nimi
begin
  sTag:= -1;
  if Sender is TButton then
    try
      sTag:= TButton(Sender).Tag;
      scrNimi:= uHost2.konfid[sTag].konf_nimi;
      if scr_radio[0].Checked then
        begin
          if uHost2.is_connection_alive then
            begin
              if (uHost2.cnfKonf) then
                begin
                  if (MessageDlg('Saada "'+ scrNimi + '" konf?', mtConfirmation,
                    [mbOk, mbCancel], 0) = mrOk) then
                    suunaScript(0, sTag)
                end // end if cnfKonf
              else
                suunaScript(0, sTag);
            end // end if tcpc.connected
          else
            Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);

          scr_radio[0].Checked:= True;
        end // end of scr_radio[0]
      else if scr_radio[1].Checked then
        begin
          if uHost2.is_connection_alive then
            begin
              if (uHost2.cnfKonf) then
                begin
                  if (MessageDlg('Saada "'+ scrNimi + '" konf?', mtConfirmation,
                    [mbOk, mbCancel], 0) = mrOk) then
                    suunaScript(1, sTag)
                end // end if cnfKonf
              else
                suunaScript(1, sTag);
            end // end if tcpc.connected
          else
            Application.MessageBox('Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);

          scr_radio[0].Checked:= True;
        end // end of scr_radio[1]
      else if scr_radio[2].Checked then
        begin
          suunaScript(2, sTag);
        end; // end of scr_radio[2]
    except on E:Exception do
      uHost2.writeErrorLog('Error @ launchScript ('+IntToStr(sTag)+'): ' + E.Message);
    end; // end of try block
end;

procedure TuScriptTS.suunaScript(kuhu: byte; scriptID: SmallInt);
var
  i       : Smallint;
  sText   : string; // konfitext
  sReaCnt : SmallInt; // scripAssistanti'i counter
  temp    : string;
begin
  case kuhu of
    0:
      begin
        try
          for i:= 0 to uHost2.konfid[scriptID].konf_text_ridu-1 do
            begin
              sText:= koolonKontroll(uHost2.konfid[scriptID].konf_text[i]);
              uHost2.writeLn_to_terminal(sText);
            end; // end of for i loop
          except on E:Exception do
            uHost2.writeErrorLog('Error @ sending script1 ' + uHost2.konfid[scriptID].konf_nimi + ': ' + #13#10 + E.Message);
          end; // end of try block
      end; // end of case 0
    1:
      begin
        try
          sReaCnt:= -1;
          temp:= '';
          for i:= 0 to uHost2.konfid[scriptID].konf_text_ridu-1 do
            begin
              inc(sReaCnt);
              sText:= koolonKontroll(uHost2.konfid[scriptID].konf_text[i], False);
              uHost2.writeLn_to_terminal(':script add name = lsakonf command = "' + sText +'"');
              temp:= temp + ',' + IntToStr(sReaCnt);
            end;
          temp:= Copy(temp, 2, MaxInt);
          inc(sReaCnt);
          uHost2.writeLn_to_terminal(':script add name = lsakonf command = "script delete name lsakonf"');
          uHost2.writeLn_to_terminal(':script run name = lsakonf pars=' + temp + ',' + IntToStr(sReaCnt));
        except on E:Exception do
          uHost2.writeErrorLog('Error @ sending script2 ' + uHost2.konfid[scriptID].konf_nimi + ': ' + #13#10 + E.Message);
        end; // end of try block
      end; // end of case 1
    2:
      begin
//        if (NOT uScriptEditor.Showing) then
          uScriptEditor.Show;
        uScriptEditor.scrText.Clear;
        uScriptEditor.scrAssCB.Checked:= False;

        if (uHost2.konfid[scriptID].konf_scrAssistant) then
          uScriptEditor.scrAssCB.Checked:= True;
          
        for i:= 0 to uHost2.konfid[scriptID].konf_text_ridu-1 do
          begin
            sText:= koolonKontroll(uHost2.konfid[scriptID].konf_text[i]);
            uScriptEditor.scrText.Lines.Add(sText)
          end;
      end; // end of case 2
  end; // end of case block
end;

function TuScriptTS.koolonKontroll(sisend: string; peab: boolean = True): string;
begin
  if (Length(sisend) > 0) then
    begin
      if (peab) then
        begin
          if (sisend[1] <> ':') then // lisame kooloni
            Result:= ':' + sisend
          else
            Result:= sisend;
        end // end of if peab
      else
        begin
          if (sisend[1] = ':') then // eemaldame kooloni
            Result:= Copy(sisend, 2, MaxInt)
          else
            Result:= sisend;
        end;
    end // end of Length(sisend)
  else
    Result:= sisend;
end;

end.
