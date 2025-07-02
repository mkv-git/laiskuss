unit aInfoWnd;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, structVault, ShellApi, Registry, ExtCtrls;

type
  TaInformant = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
  // updater vars
    update_label: array[0..1] of TLabel;
    update_panel: TPanel;
    update_progress: TProgressbar;
    update_button: array[0..1] of TButton;

  // about vars
    about_label: array[0..3] of TLabel;
    about_panel: TPanel;
    about_info_panel: TPanel;
    about_button: TButton;
    
  // updater
    procedure startUpdate(Sender: TObject);
    procedure cancelUpdate(Sender: TObject);
    procedure valmistaUpdater;

  // about
    procedure valmistaAbout;
    procedure closeAbout(Sender: TObject);
  public
  // updater
    procedure updateSetup(remote: boolean = False);
    function checkVers(showProgress: boolean = False): boolean;
  // About
    procedure showAbout;
  end;

var
  aInformant: TaInformant;

implementation

uses aMain;

{$R *.dfm}


procedure TaInformant.FormCreate(Sender: TObject);
begin
  valmistaUpdater;
  valmistaAbout;
  KeyPreview:= True;
end;

procedure TaInformant.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  aHost.pmUpdates.Enabled:= True;
  aHost.pmAbout.Enabled:= True;
end;

procedure TaInformant.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
    Close;
end;


procedure TaInformant.FormDestroy(Sender: TObject);
begin
//
end;


{***************************************************************
  UPDATER
***************************************************************}

procedure TaInformant.valmistaUpdater;
const
  update_button_caption: array[0..1] of string =
    ('Download', 'Exit');
var
  i: SmallInt;
begin
  update_panel:= TPanel.Create(Self);
  with update_panel do
    begin
      Parent:= aInformant;
      AutoSize:= False;
      Width:= 400;
      Height:= 150;
      Left:= 0;
      Top:= 0;
      Visible:= False;
      Color:= $00E6DAD0;
      BevelInner:= bvSpace;
      BevelOuter:= bvLowered;
    end;

  for i:= 0 to High(update_label) do
    begin
      update_label[i]:= TLabel.Create(Self);
      with update_label[i] do
        begin
          Parent:= update_panel;
          AutoSize:= False;
          Layout:= tlCenter;
          Height:= 17;
        end;
    end;
  with update_label[0] do
    begin
      Left:= 5;
      Top:= 20;
      Width:= update_panel.Width - 15;
      Caption:= 'Waiting for trigger...';
    end;

  with update_label[1] do
    begin
      Width:= 50;
      Left:= update_panel.Width - update_label[1].Width - 10;
      Top:= update_label[0].Top + update_label[0].Height + 15;
      Caption:= '0/0';
    end;

  update_progress:= TProgressBar.Create(Self);
  with update_progress do
    begin
      Parent:= update_panel;
      Top:= update_label[1].Top;
      Left:= 5;
      Width:= update_panel.Width - update_label[1].Width - 25;
      Min:= 0;
      Max:= 10;
    end;

  for i:= 0 to High(update_button) do
    begin
      update_button[i]:= TButton.Create(Self);
      with update_button[i] do
        begin
          Parent:= update_panel;
          Top:= update_panel.ClientHeight - 30;
          Left:= update_panel.Width - 5 - (Length(update_button) * 80) + (i * 80);
          Caption:= update_button_caption[i];
        end; // with
    end;
    update_button[0].OnClick:= startUpdate;
    update_button[1].OnClick:= cancelUpdate;
end;

procedure TaInformant.updateSetup(remote: boolean = False);
begin
  aHost.pmUpdates.Enabled:= False;
  aHost.pmAbout.Enabled:= False;
  update_panel.Visible:= True;
  about_panel.Visible:= False;
  with aInformant do
    begin
      Width:= update_panel.ClientWidth + 5;
      Height:= update_panel.ClientHeight + 21;
      Caption:= 'Updater';
      Left:= Trunc(Screen.Width / 2) - Trunc(Width / 2);
      Top:= Trunc(Screen.Height / 2) - Trunc(Height / 2);
      Show;
    end;
  update_button[0].Caption:= 'Download';
  update_button[0].Visible:= True;
  update_progress.Visible:= True;
  update_progress.Position:= 0;
  update_label[0].Caption:= 'Waiting for trigger...';
  update_label[1].Caption:= '0/0';
  update_label[1].Visible:= True;
  if (remote) then
    update_button[0].Click;
end;

procedure TaInformant.startUpdate(Sender: TObject);
begin
  aInformant.BringToFront;
  if (Sender is TButton) then
    if (TButton(Sender).Caption = 'Download') then
      begin
        update_button[0].Enabled:= False;
        checkVers(True);
        update_button[0].Enabled:= True;
        update_progress.Visible:= False;
        update_label[1].Visible:= False;
      end
    else
      begin                                                       //PAnsiChar('-noShowComplete')
        ShellExecute(GetDesktopWindow, PAnsiChar('open'), PAnsiChar(aHost.lksPath + '\updater.exe'), 
        	PAnsiChar(aHost.lksPath), nil, SW_SHOWNORMAL);
          Close;
      end;
end;

procedure TaInformant.cancelUpdate(Sender: TObject);
begin
  if (Sender is TButton) then
    begin
      aInformant.Close;
    end;
end;


function TaInformant.checkVers(showProgress: boolean = False): boolean;
var
  vastus, versioon, failid, dir, temp_dir: string;
  full_versioon: string[20];
  fail: TStrArr;
  i: SmallInt;
  ms: TMemoryStream;
  dummy: File;
  tulemus: boolean;
  uReg: TRegistry;
  updVersioon: string;
  upd_olemas: boolean;
begin
  if showProgress then
    begin
      update_label[0].Caption:= 'Connecting to the server...';
      update_label[1].Caption:= '0/0';
      update_progress.Position:= 0;
    end;
  tulemus:= False;
  fail:= nil;
  failid:= '';
  temp_dir:= aHost.lksPath + 'temp\';
  // check for new updater
  try
    uReg:= TRegistry.Create;
    ms:= TMemoryStream.Create;
    try
      uReg.RootKey:= HKEY_CURRENT_USER;
      if uReg.OpenKey('SOFTWARE\Laiskuss2', True) then
        updVersioon:= aHost.isRegValid(uReg, 'updVers', '');

      // update Laiskuss version number
      aHost.lksVers:= aHost.isRegValid(uReg, 'lksVers', '1.0.0.0'); // Laiskussi versioon

      // check if new version available
      vastus:= aHost.aHttp.Get(servAdre + 'uss_remote2/updater.php?versioon=' +
        updVersioon + '&tyyp=2' + '&kasutaja=' + aHost.etUser);

      upd_olemas:= FileExists(aHost.lksPath + '\updater.exe');

      if (AnsiCompareStr(sulu_parser(vastus, 'newVers'), '1') = 0) OR 
      	(updVersioon = '') OR (upd_olemas = False) then
        begin
          aHost.aHttp.Get(servAdre + 'dl/updater.exe', ms);
          ms.SaveToFile(aHost.lksPath + '\updater.exe');
        end; // vers Comp

    finally
      begin
        ms.Free;
        uReg.CloseKey;
        uReg.Free;
      end;
    end;

  except on E:Exception do
    aHost.WriteErrorLog('Exception @ checking new version: ' + E.Message);
  end;

  try
  // check for new Laiskuss
    vastus:= aHost.aHttp.Get(servAdre + 'uss_remote2/updater.php?versioon=' +
      aHost.lksVers + '&tyyp=1' + '&kasutaja=' + aHost.etUser);
    if (aHost.aHttp.ResponseCode = 200) then
      begin
        versioon:= sulu_parser(vastus, 'versioon');
        full_versioon:= sulu_parser(vastus, 'fullVers');
        failid:= sulu_parser(vastus, 'failid');

        if (versioon <> '-1') AND (failid <> '') AND
          (NOT FileExists(temp_dir + versioon + '.inst')) then
          begin
            if (NOT DirectoryExists(temp_dir)) then
              try
                CreateDir(temp_dir);
              except
              end;

            AssignFile(dummy, temp_dir + versioon + '.inst');
            ReWrite(dummy, 1);
            BlockWrite(dummy, full_versioon, SizeOf(full_versioon));
            fail:= explode(failid, '#');

            if showProgress then
              begin
                update_label[0].Caption:= 'Found new version: ' + full_versioon;
                update_label[1].Caption:= '0/'+IntToStr(Length(fail)-1);
                update_progress.Max:= High(fail)-1;
              end;

            ms:= TMemoryStream.Create;
            try
              for i:= 0 to Length(fail)-1 do
                begin
                  if (Length(fail[i]) > 3) then
                    begin
                      ms.Clear;
                      aHost.aHttp.Get(servAdre + 'dl/' + versioon + '/' + fail[i], ms);
                      if (showProgress) then
                        begin
                          update_label[0].Caption:= 'Downloading... ' + fail[i];
                          update_label[0].Update;
                        end;

                      if (AnsiPos('/', fail[i]) > 0) then
                        begin
                          dir:= Trim(Copy(fail[i], 1, AnsiPos('/', fail[i])-1));
                          if (DirectoryExists(temp_dir + dir) = False) then
                            CreateDir(temp_dir + dir);
                        end;
                      ms.SaveToFile(temp_dir + fail[i]);
                      BlockWrite(dummy, fail[i], Length(fail[i])+1);
                      if showProgress then
                        begin
                          update_label[1].Caption:= IntToStr(i+1)+'/'+IntToStr(Length(fail)-1);
                          update_label[1].Update;
                          update_progress.Position:= i;
                        end; // showProgress
                    end; // Length(fail[i])
                  Sleep(200);
                end; // for i loop;
            finally
              begin
                if showProgress then
                  begin
                    update_button[0].Caption:= 'Install';
                    update_label[0].Caption:= 'Download complete... press "Install" to apply changes.';
                  end;
                ms.Free;
                tulemus:= True;
              end; // finally
            end; // try block
            CloseFile(dummy);
          end // new version
        else if (FileExists(temp_dir + versioon + '.inst')) then
          begin
            tulemus:= True;
            update_button[0].Caption:= 'Install';
            update_label[0].Caption:= 'Press "Install" to install new version (' + full_versioon +')...';
          end
        else
        	begin
	          update_label[0].Caption:= 'Laiskuss is up to date...';
            update_button[0].Visible:= False;
          end;
      end; // ResponseCode
  except on E:Exception do
    begin
      aHost.WriteErrorLog('Exception @ checking new version: ' + E.Message);
      tulemus:= False;
    end;
  end;
  Result:= tulemus;
end;

{***************************************************************
  About
***************************************************************}

procedure TaInformant.valmistaAbout;
var
  i: SmallInt;
begin
  about_panel:= TPanel.Create(Self);
  with about_panel do
    begin
      Parent:= aInformant;
      AutoSize:= False;
      Width:= 275;
      Height:= 165;
      Left:= 0;
      Top:= 0;
      Visible:= False;
      Color:= $00E6DAD0;
      BevelInner:= bvSpace;
      BevelOuter:= bvLowered;
    end;

  about_info_panel:= TPanel.Create(Self);
  with about_info_panel do
    begin
      Parent:= about_panel;
      AutoSize:= False;
      Width:= about_panel.Width - 20;
      Height:= 110;
      Left:= 10;
      Top:= 10;
      BevelInner:= bvLowered;
      BevelOuter:= bvNone;
      Color:= $00EDE2DE;//$00E4E4E4;
    end;

  for i:= 0 to High(about_label) do
    begin
      about_label[i]:= TLabel.Create(Self);
      with about_label[i] do
        begin
          Parent:= about_info_panel;
          AutoSize:= False;
          Layout:= tlCenter;
          Width:= about_info_panel.Width - 20;
          Height:= 17;
          Left:= 10;
          Top:= (Height + 7) * i + 10;
          Alignment:= taCenter;
        end;
    end;

  about_button:= TButton.Create(Self);
  with about_button do
    begin
      Parent:= about_panel;
      Top:= about_info_panel.Top + about_info_panel.Height + 10;
      Left:= (about_panel.Width div 2) - (Width div 2);
      Caption:= 'OK';
      OnClick:= closeAbout;
    end;
end;

procedure TaInformant.closeAbout(Sender: TObject);
begin
  Close;
end;

procedure TaInformant.showAbout;
var
  aReg: TRegistry;
  auth: TAuthSettings;
  Y,M,D: Word;
begin
  DecodeDate(Now, Y, M, D);
  aHost.pmUpdates.Enabled:= False;
  aHost.pmAbout.Enabled:= False;
  with aInformant do
    begin
      Width:= about_panel.Width + 5;
      Height:= about_panel.Height + 21;
      Caption:= 'About';
      Left:= Trunc(Screen.Width / 2) - Trunc(Width / 2);
      Top:= Trunc(Screen.Height / 2) - Trunc(Height / 2);
      Show;
    end;
  update_panel.Visible:= False;
  about_panel.Visible:= True;

  try
    aReg:= TRegistry.Create;
    try
      aReg.RootKey:= HKEY_CURRENT_USER;
      if aReg.OpenKey('Software\Laiskuss2', False) then
        begin
          about_label[0].Caption:= 'Laiskuss ver. ' + aHost.isRegValid(aReg, 'lksVers', '2.0');
          about_label[0].Font.Style:= about_label[0].Font.Style + [fsBold];
          about_label[2].Caption:= 'Web: http://laiskuss.elion.ee';
          about_label[1].Caption:= #169+' 2009 - ' + IntToStr(Y) + ' Maksim Konovalov';
          if (aReg.ValueExists('authData')) then
            aReg.ReadBinaryData('authData', auth, SizeOf(auth));
          about_label[3].Caption:= 'Subscription expires: ' + DateToStr(auth.asDate);
        end;
    finally
      aReg.Free;
    end;
  except on E:Exception do
    aHost.writeErrorLog('Exception @ reading aReg (about): ' + E.Message);
  end;
end;


end.
