unit uAlqClass;

interface

uses
  Windows, Forms, SysUtils, Variants, Classes, Graphics, Controls, StdCtrls,
  ExtCtrls, Spin, structVault, Dialogs, Jpeg;

type
  toonid = array[0..520] of SmallInt;

type
  TMWEdit = class(TSpinEdit);
  TuAlqTS = class(TObject)
    public
      alq_memo: array[0..1] of TMemo;
      alq_button: array[0..2] of TButton;
      errors_list: array[0..5] of string;
      jpgAlq: TJpegImage;
      constructor Create;
      destructor Destroy; override;
// alq public procedures
      procedure resetGapCanvas; // clear alq_memo[0] & canvas
      procedure alqUpdate(state: boolean);
      function checkForLivelink:boolean;
      function createLivelinkFolder: boolean;
    private
      gap_panel: TPanel;
      gap_pos_panel: TPanel;
      gap_label: array[0..4] of TLabel;
      gap_img: TImage;
      gap_edit: array[0..1] of TEdit;
      tones: toonid;
      prevTones: toonid;
    // end var for alq elements

    // pinger var
      pingCnt: SmallInt; // pinger record counter
      pinger_panel: TPanel;
      ping_spin: array[0..5] of TMWEdit;
      ping_edit: array[0..1] of TEdit;
      ping_button: array[0..6] of TButton;
      ping_combobox: TCombobox;
      ping_label: array[0..3] of TLabel;
      isPingSelected: boolean;


    // end of pinger var

// alq private procedures
      procedure getAlqStatus(Sender: TObject);
      procedure tootleBitLoader;
      procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure isThereGaps(gapid: TIntArr);
      procedure spinEditMM(Sender: TObject; Shift: TShiftState; X, Y: Integer); // spinEdit mousemove handler
      procedure spinEditMouseWheel(Sender: TObject; Shift: TShiftState; // spindEdit mousewheel handler
        WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
      procedure createAlqImg;
      procedure saveAlqImg(Sender: TObject);
      procedure sendToLivelink(Sender: TObject);

// pinger procedures
      procedure looPinger; // pinger objektide loomine
      procedure setToDefault; // pinger objektide väärtused default'le
      procedure populatePinger; // pinger andmere laadimine combobox'i
      procedure populateFields(Sender: TObject); // ping_combobox onChange handler

  // button handlers
      procedure pb_ipMode(Sender: TObject);
      procedure pb_dnsLookup(Sender: TObject);
      function pb_checkTracePing(var aadress: string; var veakood: byte): boolean;
      procedure pb_trace(Sender: TObject);
      procedure pb_ping(Sender: TObject);
      procedure pb_new(Sender: TObject);
      procedure pb_change(Sender: TObject);
      procedure pb_delete(Sender: TObject);
  // edit handlers
      procedure pe_ipClick(Sender: TObject);
      procedure pe_ipKeyPress(Sender: TObject; var Key: Char);
      procedure pe_ipEnter(Sender: TObject);
      procedure pe_ipExit(Sender: TObject);

  // data processors
      function spinToEdit: string;
      function editToSpin(sisend: string): boolean;
  end;

implementation
uses uMain, uInfoWnd;


constructor TuAlqTS.Create;
const
  gap_labelT: array[0..2] of SmallInt = (8, 23, 101);
  snrm_button_caption: array[0..2] of string =
    ('SNRM ON', 'Start', 'Stop');
var
  i, b: SmallInt;
  bitStr, toneStr: string;
begin
{
alq_memo = TMemo:
  0 - GAP
  1 - Errors
}
  for i:= 0 to 1 do
    begin
      alq_memo[i]:= TMemo.Create(nil);
      alq_memo[i].Parent:= uHost2.alqTab;
      alq_memo[i].ReadOnly:= True;
      alq_memo[i].Top:= (i * 98);
      alq_memo[i].Left:= 0;
      alq_memo[i].Width:= (abs(i-1) * 80) + 161;
      alq_memo[i].Height:= (abs(i-1) * 9) + 85;
      alq_memo[i].Color:= $00ECE4DD;
    end;
  alq_memo[0].ScrollBars:= ssVertical;

{
alq_button = TButton:
  0 - get lq
  1 - screenshot
}
  for i:= 0 to High(alq_button) do
    begin
      alq_button[i]:= TButton.Create(nil);
      alq_button[i].Parent:= uHost2.alqTab;
      alq_button[i].Top:= alq_memo[1].Top + (i * 27);
      alq_button[i].Left:= alq_memo[1].Left + alq_memo[1].Width + 5;
      alq_button[i].Tag:= 233 + i;
    end;
  alq_button[0].Caption:= 'Refresh LQ';
  alq_button[0].OnClick:= getAlqStatus;
  alq_button[1].Caption:= 'Screenshot';
  alq_button[1].OnClick:= saveAlqImg;
  alq_button[2].Caption:= 'SS=>Livelink';
  alq_button[2].OnClick:= sendToLivelink;
  alq_button[2].Enabled:= False;

// gap_panel = TPanel (parent for alq_img & alq_label)

  gap_panel:= TPanel.Create(nil);
  gap_panel.Parent:= uHost2.alqTab;
  gap_panel.Top:= 0;
  gap_panel.Left:= alq_memo[0].Left + alq_memo[0].Width + 3;
  gap_panel.Width:= 545;
  gap_panel.Height:= 120;
  gap_panel.BevelInner:= bvNone;
  gap_panel.BevelOuter:= bvLowered;
  gap_panel.Color:= $00E4E4E4;

  gap_img:= TImage.Create(nil);
  gap_img.Parent:= gap_panel;
  gap_img.Top:= 23;
  gap_img.Left:= 18;
  gap_img.Height:= 76;
  gap_img.Width:= 520;
  gap_img.AutoSize:= False;
  gap_img.OnMouseMove:= ImageMouseMove;

  gap_pos_panel:= TPanel.Create(nil);
  with gap_pos_panel do
    begin
      Parent:= uHost2.alqTab;
      Top:= 0;
      Left:= gap_panel.Width + gap_panel.Left;
      Height:= gap_panel.Height;
      Width:= uHost2.alqTab.Width - alq_memo[0].Width - gap_panel.Width - 4;
      Color:= $00E4E4E4;
      BevelInner:= bvNone;
      BevelOuter:= bvLowered;
    end;

{
gap_label = TLabel:
  0 - top
  1 - left
  2 - bottom
}
  for i:= 0 to 2 do
    begin
      gap_label[i]:= TLabel.Create(nil);
      gap_label[i].Parent:= gap_panel;
      gap_label[i].AutoSize:= False;
      gap_label[i].Font.Size:= 8;
      gap_label[i].Top := gap_labelT[i];
      gap_label[i].Left:= (abs((i-1) mod 2)) * 18 + 2;
      gap_label[i].Width:= (abs((i-1) mod 2)) * 507 + 13;
      gap_label[i].Height:= (i mod 2) * 69 + 11;
    end;
  gap_label[1].Alignment:= taRightJustify;
//  gap_label number filling
  bitStr:= '';
  toneStr:= '';
  for b:= 5 downto 0 do
    bitStr:= bitStr + IntToStr(b*3) + #13;
  for b:= 0 to 15 do
    toneStr:= toneStr+ Format('%-8.d',[(b*32)]);
  gap_label[0].Caption:= toneStr;
  gap_label[1].Caption:= bitStr;
  gap_label[2].Caption:= toneStr;

{
gap_edit = TEdit:
  0: tone
  1: bit
}
  for i:= 0 to 1 do
    begin
      gap_edit[i]:= TEdit.Create(nil);
      gap_edit[i].Parent:= gap_pos_panel;
      gap_edit[i].ReadOnly:= True;
      gap_edit[i].Anchors:= [akBottom, akLeft];
      gap_edit[i].Top:= Trunc(gap_pos_panel.Height / 2) + ((i-1) * 25);// gap_img.Top + (i * 25);
      gap_edit[i].Left:= gap_pos_panel.Width - 42;
      gap_edit[i].Height:= 21;
      gap_edit[i].Width:= 40;
      gap_edit[i].Text:= '0';
    end;

{
gap_label= TLabel:
  3 - tone
  4 - bit
}
  for i:= 3 to 4 do
    begin
      gap_label[i]:= TLabel.Create(nil);
      gap_label[i].Parent:= gap_pos_panel;
      gap_label[i].AutoSize:= False;
      gap_label[i].Layout:= tlCenter;
      gap_label[i].Alignment:= taRightJustify;
      gap_label[i].Height:= 21;
      gap_label[i].Width:= 35;
      gap_label[i].Font.Style:= gap_label[i].Font.Style + [fsBold];
      gap_label[i].Anchors:= [akBottom, akLeft];
      gap_label[i].Top:= gap_edit[i-3].Top;
      gap_label[i].Left:= gap_edit[i-3].Left - gap_label[i].Width - 2;
    end;
  gap_label[3].Caption:= 'Tone:';
  gap_label[4].Caption:= 'Bits:';

  resetGapCanvas;
  looPinger;
  jpgAlq:= TJpegImage.Create;
end;

destructor TuAlqTS.Destroy;
var
  i: SmallInt;
begin
	try
  	FreeAndNil(jpgAlq);
  except on E:Exception do
  end;

  uHost2.vabadus(alq_memo);
  uHost2.vabadus(alq_button);
  uHost2.vabadus(gap_label);
  uHost2.vabadus(gap_edit);

  uHost2.vabadus(ping_label);
  uHost2.vabadus(ping_edit);
  uHost2.vabadus(ping_button);
  uHost2.vabadus(ping_combobox);
  try
    for i:= Low(ping_spin) to High(ping_spin) do
      begin
        ping_spin[i].Free;
        ping_spin[i]:= nil;
      end;
  except on E:Exception do
    uHost2.writeErrorLog('Error on freeing SpinEdit: ' + E.Message);
  end;

  try
    gap_img.Free;
  except on E:Exception do
    MessageBox(GetDesktopWindow, PAnsiChar('Error on freeing alq_img' + E.Message), 'Laiskuss annab teada', MB_ICONERROR);
  end;
  uHost2.vabadus(gap_pos_panel);
  uHost2.vabadus(gap_panel);
  uHost2.vabadus(pinger_panel);
end;

procedure TuAlqTS.alqUpdate(state: boolean);
begin
  alq_button[0].Enabled:= state;
  pinger_panel.Enabled:= state;
end;






{***************************************************************
                    GAP procedure
****************************************************************}

procedure TuAlqTS.resetGapCanvas;
var
  x, y: integer;
  it: TPoint;
begin
  it.X:= 0;
  it.Y:= 0;
  gap_img.Picture:= nil;
  gap_img.Canvas.Pen.Width:= 1;
  gap_img.Canvas.Pen.Color:= clGray;
  gap_img.Canvas.PenPos:= it;
  for x:= 0 to 15 do
    begin
      gap_img.Canvas.MoveTo(0,x*5);
      gap_img.Canvas.LineTo(520,x*5);
    end;
  for y:= 0 to 51 do
    begin
      gap_img.Canvas.MoveTo(y*10, 0);
      gap_img.Canvas.LineTo(y*10, 520);
    end;
  alq_memo[0].Clear;
end;

procedure TuAlqTS.getAlqStatus(Sender: TObject);
begin
  if Sender is TButton then
    if uHost2.is_connection_alive then
      begin

        if uHost2.statusTs.router_type = '' then
          uHost2.statusTs.get_router_type;
        if uHost2.statusTs.soft_version = '' then
          uHost2.statusTs.get_software_version;

        uHost2.st_loadInfo.Caption:= ' Updating bittone graph...';
        uHost2.haltOnRefresh(False);
        resetGapCanvas;
        alq_memo[0].Clear;
        if (uHost2.statusTs.router_type = 'TG789vn') OR
          (uHost2.statusTs.soft_version = '8.C.D.5') OR (uHost2.statusTs.soft_version = '8.C.D.9') then
          begin
            uHost2.statusTs.sendRequest(':xdsl debug bitloadinginfo');
          end
        else
          begin
            uHost2.statusTs.sendRequest(':adsl debug bitloadinginfo');
          end;
        tootleBitLoader;
        uHost2.haltOnRefresh(True);
        uHost2.st_loadInfo.Caption:= ' Bittone graph updated...';
      end
    else
      MessageBox(uHost2.Handle, 'Error: not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;


// bittone graph töötlemine
procedure TuAlqTS.tootleBitLoader;
var
  i, aCnt, gap_size: SmallInt;
  bpt: integer;
  toneDec, temp, tone: string;
  leitud: boolean;
  alq_blocks: TStrArr;
  gap_cnt: TIntArr;
begin
  try
    if (tones[0] <> 501) then
      prevTones:= tones;
    leitud:= False;
    bpt:= 0; // toonide loendur - värvimise jaoks
    for i:= 0 to uHost2.dataBuffer.Count-1 do
      begin
      // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
        if (i > uHost2.dataBuffer.Count) then
          break;

        temp:= uHost2.dataBuffer.Strings[i];
        if (AnsiPos('Tone :', temp) > 0) then
          begin
            leitud:= True;
          end;
        if leitud then
          begin
            toneDec:= Trim(Copy(temp, 1, AnsiPos(':', temp)-1));
            // kontrollime kas on ikka õige asi (toneDec peab olema number)

            if toneDec = 'Tone' then
              continue;
            if (Length(toneDec) > 0) AND (uMain.isInt(toneDec)) then
              begin
                tone:= Trim(Copy(temp, AnsiPos(':', temp)+1, MaxInt));
                uHost2.Explode2(tone, ' ', alq_blocks);
                for aCnt:= 0 to Length(alq_blocks)-1 do
                  begin
                    case bpt of
                      0..32:
                        gap_img.Canvas.Pen.Color:= clGreen;
                      33..37:
                        gap_img.Canvas.Pen.Color:= RGB(0,139,192);
                      38..510:
                        begin
                          gap_img.Canvas.Pen.Color:= RGB(0,139,192);
                          if (StrToInt(alq_blocks[aCnt]) = 0) then
                            begin
                              gap_size:= Length(gap_cnt);
                              SetLength(gap_cnt, gap_size +1);
                              gap_cnt[gap_size]:= StrToInt(toneDec) + aCnt;
                            end;
                        end;
                      511..MaxInt:
                        gap_img.Canvas.Pen.Color:= RGB(0,139,192);
                      else
                        gap_img.Canvas.Pen.Color:= clRed;
                    end; // end of case

                    gap_img.Canvas.MoveTo(StrToInt(toneDec) + aCnt, 75);
                    if (uMain.isInt(alq_blocks[aCnt])) then
                      gap_img.Canvas.LineTo(StrToInt(toneDec) + aCnt, 75 - StrToInt(alq_blocks[aCnt])*5);
                    try                        
                      tones[bpt]:= StrToint(alq_blocks[aCnt]);
                    except
                    end; // end of try
                    inc(bpt);
                    Application.ProcessMessages;
                  end; // end of for aCnt loop
              end; // end of toneDec
          end; // end of leitud
      end; // end for i loop
    isThereGaps(gap_cnt);
  except on E:Exception do
    uHost2.writeErrorLog('error @ creating gap_image: ' + E.Message);
  end;
end;

procedure TuAlqTS.ImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  gap_edit[0].Text:= IntToStr(X);
  gap_edit[1].Text:= IntToStr(tones[X]);
end;

procedure TuAlqTS.isThereGaps(gapid: TIntArr);
var
  i, bits, gap_end, gap_ridu: SmallInt;
  gap_riduStr: string;
begin
  if (Length(gapid) > 0) then
    begin
      try
        gap_ridu:= 1;
        repeat
          if (Length(IntToStr(gap_ridu)) < 2) then
            gap_riduStr:= '  ' + IntToStr(gap_ridu)
          else
            gap_riduStr:= IntToStr(gap_ridu);

          bits:= gapid[0];
          i:= 1;
          if (gapid[1] = (gapid[0]+1)) then // kui 2 esimest tooni on samad ehk 0 siis korjame neid kokku
            begin
              repeat
                inc(i);
                gap_end:= gapid[i];
              until (bits+i <> gap_end);
              alq_memo[0].Lines.Add(
                gap_riduStr + ':  '
                + IntToStr(Round(bits* (4.3125))) + ' - '
                + IntToStr(Round(gapid[i-1]* (4.3125))) + ' kHz = Tone ('
                + IntToStr(bits) + ' - '
                + IntToStr(gapid[i-1]) + ')');
            end
          else
            begin
              alq_memo[0].Lines.Add(
                gap_riduStr + ':  '
                + IntToStr(Round(bits* (4.3125))) + ' kHz = Tone ('
                + IntToStr(bits) + ')');
            end;
          inc(gap_ridu);
          gapid:= Copy(gapid, i, MaxInt);
        until (Length(gapid) = 0);
      except on E:Exception do
        uHost2.writeErrorLog('Error @ isThereGaps: ' + E.Message);
      end; // end of try
    end // end of if
  else
    alq_memo[0].Lines.Add('N/A');
end;

procedure TuAlqTS.createAlqImg;
const
  col1: array[0..5] of string =
    ('Router:', 'Router S/N:', 'Router FW:', 'Router uptime:', 'DSL uptime:', 'DSL Resets');
  col2: array[0..5] of string =
    ('Margin:', 'Attenuation:', 'Max Speed:', 'Conf. Speed:', 'DSL Standard:', 'PVC:');
  col3: array[0..5] of string =
    ('Received FEC:', 'Received CRC:', 'Received HEC:', 'Transmitted FEC:', 'Transmitted CRC:', 'Transmitted HEC:');
  lq_ext: array[0..1] of string = (' dB', ' kbps');
var
  bMap: TBitMap;
  imgDesc: string; // daatum + P number + IP address
  lisaP: string; // kui p number on olemas siis viskame selle pildile + @

  i, j: SmallInt;
  imgH, imgW: SmallInt; // gap_img dimensioonid

  dslamStr: string;
  taust: TRect;
begin
// init
  bMap:= TBitmap.Create;
  try
    imgW:= gap_panel.Width;
    imgH:= gap_panel.Height;

    bMap.Width:= imgW;
    bMap.Height:= imgH + 135;

    LongTimeFormat:= 'hh:nn:ss';
    if (uHost2.pNumber <> '') then
      lisaP:= uHost2.pNumber + ' @ ' + uHost2.hostAddress
    else
      lisaP:= uHost2.hostAddress;

    if (uHost2.statusTs.lq_label[3].Caption <> '') AND (uHost2.statusTs.lq_label[3].Caption <> 'N/A') then
      dslamStr:= 'DSLAM: ' + uHost2.statusTs.lq_label[3].Caption
    else
      dslamStr:= '';

  // daatum + P number + IP address
    imgDesc:= Format('%-34s%-35s%s', [DateTimeToStr(Now), lisaP, dslamStr]);
    LongTimeFormat:= 'hh:nn:ss';


  // img creation
    gap_panel.PaintTo(bMap.Canvas, 0, 0);
    bMap.Canvas.Brush.Color:= $00F0EAE3;
    taust.Left:= 0;
    taust.Right:= imgW;
    taust.Top:= imgH;
    taust.Bottom:= imgH + 135;
    bMap.Canvas.FillRect(taust);


  // separator
    bMap.Canvas.Pen.Color:= clSilver;
    bMap.Canvas.MoveTo(0, imgH + 21);
    bMap.Canvas.LineTo(bMap.Width, imgH + 21);


    bMap.Canvas.Font.Size:= 9;
    bMap.Canvas.Font.Style:= bMap.Canvas.Font.Style + [fsBold];
    bMap.Canvas.TextOut(5, gap_panel.Height + 3, imgDesc);
    bMap.Canvas.Font.Style:= bMap.Canvas.Font.Style - [fsBold];

  // esimene kolonn
    for i:= 0 to 5 do
      begin
        if (i > 1) then // Modem Access Code'i meil ei ole vaja
          j:= i+1
        else
          j:= i;
        bMap.Canvas.TextOut(5, imgH + (i*18) + 25, col1[i]);
        bMap.Canvas.TextOut(85, imgH + (i*18) + 25, uHost2.statusTs.ds_label[(j*2)+1].Caption);
      end;

  // teine kolonn
    for i:= 0 to 5 do
      bMap.Canvas.TextOut(182, imgH + (i*18) + 25, col2[i]);
    for i:= 0 to 3 do
      bMap.Canvas.TextOut(260, imgH + (i*18) + 25,
        uHost2.statusTs.lq_edit[i*2].Text + lq_ext[i div 2] + ' / ' + uHost2.statusTs.lq_edit[i*2+1].Text + lq_ext[i div 2]);

    bMap.Canvas.TextOut(260, imgH + (4*18) + 25, uHost2.statusTs.lq_label[1].Caption);
    bMap.Canvas.TextOut(260, imgH + (5*18) + 25, uHost2.statusTs.lq_label[5].Caption);

  // kolmas kolonn
    for i:= 0 to 5 do
      begin
        bMap.Canvas.TextOut(385, imgH + (i*18) + 25, col3[i]);
        bMap.Canvas.TextOut(475, imgH + (i*18) + 25, errors_list[i]);
      end;
    jpgAlq.Assign(bMap);
  finally
  	FreeAndNil(bMap);
  end;
end;

procedure TuAlqTS.saveAlqImg(Sender: TObject);
var
  svd: TSaveDialog;
  picKaust: string; // piltide kausta aadress
begin
  if (TButton(Sender).Tag = 234) then
    begin
      createAlqImg;
      svd:= TSaveDialog.Create(nil);
      picKaust:= uHost2.picSelectedPath + '\' + DateToStr(Now);
      try
        if (DirectoryExists(picKaust) = False) then
          CreateDir(picKaust);
        svd.InitialDir:= picKaust;
        svd.Title:= picKaust;
        svd.DefaultExt:= 'jpg';
        svd.Options:= svd.Options + [ofOverwritePrompt];

        // ühenduse sidevahend + kuupäev
        if (Length(uHost2.pNumber) > 0) then
          svd.FileName:= uHost2.pNumber + '_' + DateToStr(Now)
        // ühenduse IP aadress + kuupäev
        else if (Length(uHost2.hostAddress) > 0) then
          svd.FileName:= uHost2.hostAddress + '_' + DateToStr(Now)
        else
        // kuupäev
          svd.FileName:= DateToStr(Now);

          svd.Filter:= 'JPEG (*.jpg) | *.jpg';
          if svd.Execute then
            jpgAlq.SaveToFile(svd.FileName);
		  finally
    		svd.Free;
		  end;
  	end;
end;

function TuAlqTS.checkForLivelink: boolean;
var
	yy, mm, dd: Word;
	tulemus: boolean;
  i, handBreak, llArr: SmallInt;
  dirAdre: string;
begin
	tulemus:= False;
	if (uHost2.rawLiveLinkAdre <> '') then
  	try
      DecodeDate(Now, yy, mm, dd);
      handBreak:= 0;
      uHost2.livelinkLabel.Caption:= 'Connecting to Livelink...';
      // otsime viimase 4 aasta kausta
      for i:= 0 to (yy-(yy-3)) do
        begin
          dirAdre:= uHost2.rawLiveLinkAdre + IntToStr(yy - 3 + i) +
            '\' +  uHost2.pNumber + '\';
          if DirectoryExists(dirAdre) then
            begin
              if (tulemus = False) then
                begin
                  tulemus:= True;
                  uHost2.liveLinkAdre:= dirAdre;
                end;
              llArr:= Length(uHost2.liveLinkArray);
              SetLength(uHost2.liveLinkArray, llArr+1);
              uHost2.liveLinkArray[llArr].llAasta:= IntToStr(yy - 3 + i);
              uHost2.liveLinkArray[llArr].llAdre:= dirAdre;
            end;

        // juhul kui yy on mingi x number
          if handBreak > 10 then
            break;
          inc(handBreak);
        end; // for i loop
      if tulemus then
        uHost2.livelinkImage.Picture.LoadFromFile(uHost2.acceptImg)
      else
        begin
          uHost2.livelinkImage.Picture.LoadFromFile(uHost2.cancelImg);
          uHost2.liveLinkAdre:= uHost2.rawLiveLinkAdre + IntToStr(yy) +
            '\' + uHost2.pNumber + '\';
        end;
      if (Length(uHost2.liveLinkArray) > 1) then
        uHost2.livelinkLabel.Hint:= 'Click to expand...'
      else
        uHost2.livelinkLabel.Hint:= uHost2.liveLinkAdre;
      uHost2.livelinkLabel.Caption:= 'Livelink status';

    except on E:Exception do
    	uHost2.writeErrorLog('Exception @ checkForLivelink: ' + E.Message);
    end;
  Result:= tulemus;
end;

function TuAlqTS.createLivelinkFolder: boolean;
var
	tulemus: boolean;
begin
	tulemus:= False;
  try
  	if (uHost2.liveLinkAdre <> '') then
    	begin
		  	if CreateDir(uHost2.liveLinkAdre) then
        	tulemus:= True;
      end;
	except on E:Exception do
  	uHost2.writeErrorLog('Exception @ creating Livelink folder: ' + E.Message);
  end;    	
  uHost2.livelinkExists:= tulemus;
  Result:= tulemus;
end;

procedure TuAlqTS.sendToLivelink(Sender: TObject);
begin
	if Sender is TButton then
  	try
	    if (uHost2.liveLinkAdre <> '') then
      	begin
        	createAlqImg;
          uInformant.livelinkHandler;
        end;
    except on E:Exception do
    	uHost2.writeErrorLog('Exception @ sending img to Livelink: ' + E.Message);
    end;
end;

{***********************************************************
                  PINGER
***********************************************************}

procedure TuAlqTS.looPinger;
const
  ping_label_caption: array[0..3] of string =
    ('IP:', 'Size:', 'Count:', 'Preset:');
  ping_button_caption: array[0..6] of string =
    ('IP mode', 'DNS lookup', 'Ping', 'Traceroute', 'New', 'Modify', 'Delete');
var
  i, j, w: SmallInt;
begin
  pinger_panel:= TPanel.Create(nil);
  pinger_panel.Parent:= uHost2.alqTab;
  pinger_panel.BevelInner:= bvNone;
  pinger_panel.BevelOuter:= bvLowered;
  pinger_panel.Color:= $00E4E4E4;
  pinger_panel.Top:= gap_panel.Top + gap_panel.Height + 1;
  pinger_panel.Left:= gap_panel.Left;
  pinger_panel.Height:= uHost2.alqTab.Height - gap_panel.Height - 2;
  pinger_panel.Width:= uHost2.alqTab.Width - alq_memo[0].Width - 4;

{ ping_spin: TSpinEdit =
    0..3: IP
    4: size
    5: count
}
  j:= 0;
  w:= 0;
  for i:= 0 to 5 do
    begin
      ping_spin[i]:= TMWEdit.Create(nil);
      ping_spin[i].AutoSize:= False;
      ping_spin[i].Parent:= pinger_panel;
      ping_spin[i].Visible:= False;
      if (i > 3) then
        begin
          j:= 35 + (i-4)*45;
          w:= 10;
          ping_spin[i].Visible:= True;
        end;
      ping_spin[i].Top:= 7;
      ping_spin[i].Left:= i * 48 + 25 + j + (w * (i mod 2));
      ping_spin[i].Width:= 45 + w;
      ping_spin[i].Height:= 23;
      ping_spin[i].MinValue:= 0;
      ping_spin[i].MaxValue:= 255;
      ping_spin[i].OnMouseMove:= spinEditMM;
      ping_spin[i].Value:= 0;
      ping_spin[i].MaxLength:= 3;
    end;

  for i:= 4 to 5 do
    ping_spin[i].MaxLength:= 7;

  ping_spin[4].MaxValue:= 64;
  ping_spin[4].MaxValue:= 20028;
  ping_spin[5].MinValue:= 25;
  ping_spin[5].MaxValue:= 1000000;

// ping_combobox: TCombobox
  ping_combobox:= TCombobox.Create(nil);
  with ping_combobox do
    begin
      Parent:= pinger_panel;
      Style:= csDropDownList;
      Width:= 155;
      Top:= 7;
      Left:= pinger_panel.Width - ping_combobox.Width - 5;
      OnChange:= populateFields;
    end;

{ ping_button: TButton =
  0: IP mode
  1: DNS Lookup
  2: Ping
  3: Trace
  3: New
  4: Change
  5: Remove
}

  j:= 0;
  for i:= 0 to 6 do
    begin
      if (i > 1) then
        j:= 33;
      ping_button[i]:= TButton.Create(nil);
      ping_button[i].Parent:= pinger_panel;
      ping_button[i].Caption:= ping_button_caption[i];
      ping_button[i].Width:= 75;
      ping_button[i].Height:= 22;
      ping_button[i].Top:= 35;
      ping_button[i].Left:= i * 80 + 5 + j;
    end;

  for i:= 4 to 6 do
    ping_button[i].Left:= pinger_panel.Width - 240 + ((i-4) * 80);

  ping_button[0].OnClick:= pb_ipMode;
  ping_button[1].OnClick:= pb_dnsLookup;
  ping_button[2].OnClick:= pb_ping;
  ping_button[3].OnClick:= pb_trace;
  ping_button[4].OnClick:= pb_new;
  ping_button[5].OnClick:= pb_change;
  ping_button[6].OnClick:= pb_delete;


{ ping_edit: TEdit =
  0: IP
  1: Preset name
}
  for i:= 0 to 1 do
    begin
      ping_edit[i]:= TEdit.Create(nil);
      ping_edit[i].Parent:= pinger_panel;
      ping_edit[i].Top:= 7;
    end;

// IP
  ping_edit[0].Left:= ping_spin[0].Left;
  ping_edit[0].Width:= (ping_spin[3].Left + ping_spin[3].Width) - ping_spin[0].Left;
  ping_edit[0].OnKeyPress:= pe_ipKeyPress;
  ping_edit[0].OnClick:= pe_ipClick;
  ping_edit[0].OnEnter:= pe_ipEnter;
  ping_edit[0].OnExit:= pe_ipExit;

// Preset name
  ping_edit[1].Left:= ping_combobox.Left;
  ping_edit[1].Width:= ping_combobox.Width;
  ping_edit[1].Visible:= False;

{ ping_label: TLabel =
    0: ip
    1: size
    2: count
    3: preset
}
  for i:= 0 to 3 do
    begin
      ping_label[i]:= TLabel.Create(nil);
      ping_label[i].Parent:= pinger_panel;
      ping_label[i].Caption:= ping_label_caption[i];
      ping_label[i].Font.Style:= ping_label[i].Font.Style + [fsBold];
      ping_label[i].Alignment:= taRightJustify;
      ping_label[i].AutoSize:= False;
      ping_label[i].Layout:= tlCenter;
      ping_label[i].Top:= 7;
      ping_label[i].Width:= (ping_label[i].GetTextLen-1) * ping_label[i].Font.Size;
      ping_label[i].Height:= 22;
    end;
  ping_label[0].Left:= 7;
  ping_label[1].Left:= ping_spin[4].Left - ping_label[1].Width - 3;
  ping_label[2].Left:= ping_spin[5].Left - ping_label[2].Width - 3;
  ping_label[3].Left:= ping_combobox.Left - ping_label[3].Width - 3;

// default settings
  isPingSelected:= False;
  populatePinger;
  setToDefault;
end;
// end of looPinger

procedure TuAlqTS.setToDefault;
const
  ping_button_caption: array[0..2] of string =  ('New', 'Modify', 'Delete');
var
  i: SmallInt;
begin
  ping_edit[0].Visible:= True;
  ping_edit[0].Text:= uHost2.pingerid[0].ping_addr;
  ping_edit[1].Visible:= False;

  for i:= 0 to 3 do
    ping_spin[i].Visible:= False;
  ping_spin[4].Value:= 64;
  ping_spin[5].Value:= 25;

  ping_combobox.Visible:= True;
  ping_combobox.ItemIndex:= 0;

  for i:= 0 to 2 do
    ping_button[i+4].Caption:= ping_button_caption[i];

  ping_button[0].Enabled:= True;
  ping_button[4].Enabled:= True;
  ping_button[5].Enabled:= False; // Change
  ping_button[6].Enabled:= False; // Remove
end;

procedure TuAlqTS.populatePinger;
var
  i: SmallInt;
begin
  try
    ping_combobox.Clear;
    pingCnt:= Length(uHost2.pingerid);
    for i:= 0 to pingCnt-1 do
      begin
        ping_combobox.Items.Add(uHost2.pingerid[i].ping_name);
      end; // end for loop

  except on E:Exception do
    uHost2.writeErrorLog('Exception @ populatePinger: ' + E.Message);
  end; // end try block
end;

// pingCombobox'i itemi valimisel laetakse recordi andmed ping objektidesse
// OnChange handler
procedure TuAlqTS.populateFields(Sender: TObject);
var
  cBoxId: SmallInt;
  pAddr: string;
begin
  cBoxId:= 0;
  if Sender is TCombobox then
    try
      cBoxId:= TCombobox(Sender).ItemIndex;
      pAddr:= uHost2.pingerid[cBoxId].ping_addr;

      if (ping_edit[0].Visible) then
        ping_edit[0].Text:= pAddr
      else
        editToSpin(pAddr);

      ping_edit[1].Text:= uHost2.pingerid[cBoxId].ping_name;

      ping_spin[4].Value:= uHost2.pingerid[cBoxId].ping_size;
      ping_spin[5].Value:= uHost2.pingerid[cBoxId].ping_count;

      ping_button[5].Enabled:= (cBoxId > 0);
      ping_button[6].Enabled:= (cBoxId > 0);
    except on E:Exception do
      uHost2.writeErrorLog('Exception @ populateFields (' + IntToStr(cBoxId) + '): ' + E.Message);
    end; // end of try block
end;

// ping_spin mouseWheel handler
procedure TuAlqTS.spinEditMM(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if Sender is TMWEdit then
    TMWEdit(Sender).OnMouseWheel := spinEditMouseWheel;
end;

procedure TuAlqTS.spinEditMouseWheel(Sender: TObject; Shift: TShiftState;
        WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if (Sender is TMWedit) then
    begin
      if (WheelDelta > 0) then
        TMWedit(Sender).UpClick(Self)
      else if (WheelDelta < 0) then
        TMWedit(Sender).DownClick(Self);
    end;
end;
// end of ping_spin mouseWheel handler


// Pinger button handlers

{
  IP aadressi sisestamise teine võimalus,
  pingEdit vahetab pingSpin vastu
}
procedure TuAlqTS.pb_ipMode(Sender: TObject);
var
  i: SmallInt;
  vastus, tulemus: string;
begin
  try
    if (ping_edit[0].Visible) then
      begin
        if editToSpin(ping_edit[0].Text) = False then
          if (uMain.dnsLookup(ping_edit[0].Text, vastus)) then
            begin
              if (uHost2.isIPValid(vastus, tulemus)) then
                editToSpin(tulemus)
              else
                begin
                  Application.MessageBox('Invalid IP address', 'Laiskuss annab teada', MB_ICONWARNING);
                  Exit;
                end; // end if ipValid = False
            end // end of dnsLookup
          else
            begin
              Application.MessageBox('Non-existent domain', 'Laiskuss annab teada', MB_ICONWARNING);
              Exit;
            end;
        ping_edit[0].Visible:= False;
        ping_button[1].Enabled:= False;
        for i:= 0 to 3 do
        	ping_spin[i].Visible:= True;
        // transform ip address string to 4 blocks
      end // end if visible
    else
      begin
        ping_edit[0].Visible:= True;
        ping_edit[0].Clear;
        ping_button[1].Enabled:= True;
        for i:= 0 to 3 do
          ping_spin[i].Visible:= False;
        ping_edit[0].Text:= spinToEdit;

        // transform ip address from 4 blocks to string
      end; // end else
  except on E:Exception do
    uHost2.writeErrorLog('Exception @ pb_ipMode: ' + E.Message);
  end;
end;

// DNS address lookup
procedure TuAlqTS.pb_dnsLookup(Sender: TObject);
var
  vastus: string;
begin
  vastus:= '';
  if (Sender is TButton) then
    try
      uMain.dnsLookup(ping_edit[0].Text, vastus);
      if (vastus <> '') then
        ping_edit[0].Text:= vastus
      else
        Application.MessageBox('Non-existent domain', 'Laiskuss annab teada', MB_ICONWARNING);
    except on E:Exception do
      uHost2.writeErrorLog('Exception @ pb_dnsLookup: ' + E.Message);
    end; // end of try block
end;

function TuAlqTS.pb_checkTracePing(var aadress: string; var veakood: byte): boolean;
var
  tulemus: boolean;
  vastus: string;
begin
  veakood:= 0;
  if (ping_edit[0].Visible) then
    begin
      if (uHost2.isIPValid(ping_edit[0].Text, vastus)) then
        begin
          aadress:= vastus;
          tulemus:= True;
        end
      else
        if uMain.dnsLookup(ping_edit[0].Text, vastus) then
          begin
            if (uHost2.isIPValid(vastus, aadress)) then
              tulemus:= True
            else
              begin
                tulemus:= False;
                veakood:= 1;
              end;
          end
        else
          begin
            veakood:= 2;
            tulemus:= False;
          end; // end if dnsLookup = False
    end // end if ping_edit visible
  else
    begin
      aadress:= spinToEdit;
      tulemus:= True;
    end;

  Result:= tulemus;
end;

// address traceroute from router
procedure TuAlqTS.pb_trace(Sender: TObject);
var
  vastus, viga: string;
  kood: byte;
begin
  if uHost2.is_connection_alive then
    begin
      if pb_checkTracePing(vastus, kood) then
        uHost2.writeLn_to_terminal(':traceroute addr ' + vastus)
      else
        begin
          if kood = 1 then
            viga:= 'Invalid IP address'
          else if kood = 2 then
            viga:= 'Non-existent domain';
          Application.MessageBox(PAnsiChar('Error: ' + viga), 'Laiskuss annab teada', MB_ICONWARNING);
        end;
    end // end if connected
  else
    Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

// ping address from router
procedure TuAlqTS.pb_ping(Sender: TObject);
var
  vastus, viga: string;
  kood: byte;
begin
  if uHost2.is_connection_alive then
    begin
      if pb_checkTracePing(vastus, kood) then
        uHost2.writeLn_to_terminal(':ping proto ip addr ' + vastus +
          ' size ' + ping_spin[4].Text + ' count ' + ping_spin[5].Text)
      else
        begin
          if kood = 1 then
            viga:= 'Invalid IP address'
          else if kood = 2 then
            viga:= 'Non-existent domain';
          Application.MessageBox(PAnsiChar('Error: ' + viga), 'Laiskuss annab teada', MB_ICONWARNING);
        end;
    end // end if connected
  else
    Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

// add new ping preset
procedure TuAlqTS.pb_new(Sender: TObject);
var
  i: SmallInt;
begin
  if (TButton(Sender).Caption = 'New') then
    begin
    // ping_edit välja aktiveermine
      if (ping_edit[0].Visible = False) then
        begin
          ping_edit[0].Visible:= True;
          ping_button[1].Enabled:= True;
          for i:= 0 to 3 do
            ping_spin[i].Visible:= False;
          ping_edit[0].Text:= spinToEdit;
        end;

      ping_button[0].Enabled:= False;

    // Preset name field aktiveerimine
      ping_combobox.Visible:= False;
      ping_edit[1].Visible:= True;

      ping_button[4].Caption:= 'Cancel';
      ping_button[5].Caption:= 'Add';
      ping_button[5].Enabled:= True;
    end // end of "New"
  else if (TButton(Sender).Caption = 'Cancel') then
    begin
      setToDefault;
    end; // end of "Cancel"
end;

// change ping preset
procedure TuAlqTS.pb_change(Sender: TObject);
var
  i: SmallInt;
begin
  if (TButton(Sender).Caption = 'Add') then
    begin
      SetLength(uHost2.pingerid, pingCnt+1);

      with uHost2.pingerid[pingCnt] do
        begin
          ping_name:= ping_edit[1].Text;
          ping_addr:= ping_edit[0].Text;
          ping_size:= ping_spin[4].Value;
          ping_count:= ping_spin[5].Value;
        end;
      inc(pingCnt);

      if (uMain.pingSave(uHost2.userPath, uHost2.pingerid) = False) then
        begin
          Application.MessageBox('Failed to save "Ping" preset data',
            'Laiskuss annab teada', MB_ICONERROR);
          uHost2.writeErrorLog('Failed to save Pinger(add): ' + uMain.GetLastIpError);
        end;

      populatePinger;
      setToDefault;
    end // end if "Add"

  else if (TButton(Sender).Caption = 'Save') then
    begin
    
      with uHost2.pingerid[ping_combobox.ItemIndex] do
        begin
          ping_name:= ping_edit[1].Text;
          ping_addr:= ping_edit[0].Text;
          ping_size:= ping_spin[4].Value;
          ping_count:= ping_spin[5].Value;
        end;

      if (uMain.pingSave(uHost2.userPath, uHost2.pingerid) = False) then
        begin
          Application.MessageBox('Failed to save "Ping" preset data',
            'Laiskuss annab teada', MB_ICONERROR);
          uHost2.writeErrorLog('Failed to save Pinger(add): ' + uMain.GetLastIpError);
        end;

      populatePinger;
      setToDefault;
    end // end if "Save"

  else if (TButton(Sender).Caption = 'Modify') then
    begin
    // ping_edit välja aktiveermine
      if (ping_edit[0].Visible = False) then
        begin
          ping_edit[0].Visible:= True;
          ping_button[1].Enabled:= True;
          for i:= 0 to 3 do
            ping_spin[i].Visible:= False;
          ping_edit[0].Text:= spinToEdit;
        end;

      ping_button[0].Enabled:= False;

    // Preset name field aktiveerimine
      ping_combobox.Visible:= False;
      ping_edit[1].Visible:= True;

      ping_button[4].Enabled:= False;
      ping_button[5].Caption:= 'Save';
      ping_button[6].Caption:= 'Cancel';
    end; // end if "Modify"
end;

// delete ping preset
procedure TuAlqTS.pb_delete(Sender: TObject);
var
  i, valitud: SmallInt;
  temp: pingKog;
begin
  if (TButton(Sender).Caption = 'Delete') then
    begin
      if MessageDlg('Delete preset "' + ping_edit[1].Text + '" ?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          SetLength(temp, pingCnt);
          temp:= uHost2.pingerid;
          pingCnt:= 0;
          valitud:= ping_combobox.ItemIndex;

          for i:= 0 to Length(temp)-1 do
            if (valitud <> i) then
              begin
                SetLength(uHost2.pingerid, pingCnt+1);
                uHost2.pingerid[pingCnt]:= temp[i];
                Inc(pingCnt);
              end;

          if (uMain.pingSave(uHost2.userPath, uHost2.pingerid) = False) then
            begin
              Application.MessageBox('Failed to delete "Ping" preset data',
                'Laiskuss annab teada', MB_ICONERROR);
              uHost2.writeErrorLog('Failed to delete Pinger: ' + uMain.GetLastIpError);
            end;
          temp:= nil;
          populatePinger;
        end; // end of MessageDlg
        setToDefault;
    end // end if "Add"
  else if (TButton(Sender).Caption = 'Cancel') then
    begin
      setToDefault;
    end; // end if "Change"
end;

////// Pinger edit handlers
procedure TuAlqTS.pe_ipKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    ping_button[1].Click;
end;

procedure TuAlqTS.pe_ipClick(Sender: TObject);
begin
// kui ping_edit[0] ei ole fokuseeritud siis selekteerime kogu teksti,
  if (isPingSelected = False) then
    ping_edit[0].SelectAll;

// teisel vajutusel ei tohi enam selekteerida kogu teksti
  isPingSelected:= True;
end;

procedure TuAlqTS.pe_ipEnter(Sender: TObject);
begin
end;

procedure TuAlqTS.pe_ipExit(Sender: TObject);
begin
  isPingSelected:= False;
end;

// data processors

function TuAlqTS.spinToEdit: string;
var
  i: SmallInt;
  vastus: string;
begin
  vastus:= '';
  for i:= 0 to 3 do
    vastus:= vastus + ping_spin[i].Text + '.';
  Delete(vastus, Length(vastus), 1);
  Result:= vastus;
end;

function TuAlqTS.editToSpin(sisend: string): boolean;
var
  i: SmallInt;
  vastus: string;
  pingid: TStrArr;
  tulemus: boolean;
begin
	pingid:= nil;
  tulemus:= False;
  try
  if (uHost2.isIPValid(sisend, vastus)) then
    begin    
      pingid:= explode(vastus, '.');
      for i:= 0 to 3 do
        begin
          ping_spin[i].Text:= pingid[i];
        end; // end for loop
      tulemus:= True;
    end;
  except on E:Exception do
    uHost2.writeErrorLog('Exception @ editToSpin conversion: ' + E.Message);
  end;
  Result:= tulemus;
end;



end.
