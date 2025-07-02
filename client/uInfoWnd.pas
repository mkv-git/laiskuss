unit uInfoWnd;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ShellApi, structVault;

type
  TuInformant = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
  private
  // livelink vars
  	livelinkPanel: TPanel;
  	livelinkLabel: array[0..1] of TLabel;
    livelinkProgressbar: TProgressBar;
    livelinkButton: array[0..1] of TButton;
    livelinkCheckbox: TCheckBox;
    livelinkEdit: TEdit;
    livelinkImage: TImage;
    fileeNimi: string;
    llFiles: TStrArr;
  	procedure looLivelink;
    procedure closeLivelink(Sender: TObject);
    procedure uploadLivelink(Sender: TObject);
    procedure uploadToLiveLink;
  public


  // livelink procedures
  	procedure livelinkHandler;
  end;

var
  uInformant: TuInformant;

implementation

uses uMain;

{$R *.dfm}

procedure TuInformant.FormCreate(Sender: TObject);
begin
	try
		looLivelink;
  except on E:Exception do
  	uHost2.writeErrorLog('Exception @ creating llInfoWnd: ' + E.Message);
  end;
  KeyPreview:= True;
end;

procedure TuInformant.FormShow(Sender: TObject);
begin
  Top:= (uHost2.Top + uHost2.Height div 2) - (Height div 2);
  Left:= (uHost2.Left + uHost2.Width div 2) - (Width div 2);
end;

procedure TuInformant.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
    Close;
end;

procedure TuInformant.FormDestroy(Sender: TObject);
begin
//
end;

{*******************************************************************************
                                    LIVELINK
********************************************************************************}                                                                                              

procedure TuInformant.looLivelink;
const
	livelinkButton_caption: array[0..1] of string = 
  	('Save', 'Exit');
var
	i: SmallInt;
begin
	livelinkPanel:= TPanel.Create(Self);
	with livelinkPanel do
  	begin
      Parent:= uInformant;
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

  for i:= 0 to High(livelinkLabel) do
  	begin
    	livelinkLabel[i]:= TLabel.Create(Self);
      with livelinkLabel[i] do
      	begin
        	Parent:= livelinkPanel;
          AutoSize:= False;
          Layout:= tlCenter;
          Height:= 17;        
        end; // with
    end;

  with livelinkLabel[0] do
    begin
      Left:= 5;
      Top:= 20;
      Width:= livelinkPanel.Width - 15;
      Caption:= 'Waiting for trigger...';
    end;

  with livelinkLabel[1] do
    begin
      Width:= 50;
      Left:= livelinkPanel.Width - livelinkLabel[1].Width - 10;
      Top:= livelinkLabel[0].Top + livelinkLabel[0].Height + 15;
      Caption:= '0/10';
    end;
    
  livelinkProgressBar:= TProgressBar.Create(Self);
  with livelinkProgressBar do
    begin
      Parent:= livelinkPanel;
      Top:= livelinkLabel[1].Top;
      Left:= 5;
      Width:= livelinkPanel.Width - livelinkLabel[1].Width - 25;
      Min:= 0;
      Max:= 10;
    end;              

  livelinkEdit:= TEdit.Create(Self);
  with livelinkEdit do
  	begin
    	Parent:= livelinkPanel;
      AutoSize:= False;
      Top:= livelinkProgressBar.Top + 30;
      Left:= 5;
      Height:= 22;
      Width:= livelinkProgressBar.Width;
      Visible:= False;
    end;

  livelinkImage:= TImage.Create(Self);
  with livelinkImage do
  	begin
    	Parent:= livelinkPanel;
      Top:= livelinkEdit.Top;
      Left:= livelinkEdit.Left + livelinkEdit.Width + 5;
      Width:= 22;
      Height:= 22;
    end;

  for i:= 0 to High(livelinkButton) do
    begin
      livelinkButton[i]:= TButton.Create(Self);
      with livelinkButton[i] do
        begin
          Parent:= livelinkPanel;
          Top:= livelinkPanel.ClientHeight - 30;
          Left:= livelinkPanel.Width - 5 - (Length(livelinkButton) * 80) + (i * 80);
          Caption:= livelinkButton_caption[i];
        end; // with
    end;
  livelinkButton[0].OnClick:= uploadLivelink;
  livelinkButton[0].Visible:= False;
  livelinkButton[1].OnClick:= closeLivelink;

  livelinkCheckBox:= TCheckBox.Create(Self);
  with livelinkCheckBox do
  	begin
    	Parent:= livelinkPanel;
      Left:= 7;
      Width:= 150;
      Top:= livelinkButton[1].Top;
      Caption:= 'Save image to disk...';
    	Visible:= False;
    end;  
end;

procedure TuInformant.livelinkHandler;
var
  kaustOlemas: boolean;
  sResult: TSearchRec;
  lCnt: SmallInt;
begin
	llFiles:= nil;
  livelinkPanel.Visible:= True;
  with uInformant do
    begin
      Width:= livelinkPanel.ClientWidth + 5;
      Height:= livelinkPanel.ClientHeight + 21;
      Caption:= 'Upload bittone graph to Livelink (' + uHost2.pNumber + ')';
      Left:= Trunc(Screen.Width / 2) - Trunc(Width / 2);
      Top:= Trunc(Screen.Height / 2) - Trunc(Height / 2);
    	Show;
      FormStyle:= fsStayOnTop;
    end;

  try   
  	Sleep(100);
    uHost2.disGray(livelinkEdit, True);
    livelinkImage.Picture:= nil;
    livelinkProgressbar.Position:= 1;
  	livelinkLabel[1].Caption:= '1/10';
  	livelinkLabel[0].Caption:= 'Checking for livelink folder...';
	  kaustOlemas:= DirectoryExists(uHost2.liveLinkAdre);    

    Sleep(100);
    if (NOT kaustOlemas) then
    	begin
		    livelinkProgressbar.Position:= 2;
        livelinkLabel[1].Caption:= '2/10';
  			livelinkLabel[0].Caption:= 'Creating Livelink folder, please wait...';
	    	kaustOlemas:= uHost2.alqTs.createLivelinkFolder;
        Sleep(500);
        uHost2.alqTs.checkForLivelink;
      end;

    if kaustOlemas then
    	begin
      // livelink'i kaustas olevad failid array'sse
      	SetCurrentDir(uHost2.liveLinkAdre);
      	if (FindFirst('*.jpg', faAnyFile, sResult) = 0) then
        	begin
          	repeat
	          	lCnt:= Length(llFiles);
  	          SetLength(llFiles, lCnt+1);
    	        llFiles[lCnt]:= sResult.Name;
            until FindNext(sResult) <> 0;
            FindClose(sResult);
          end;

        SetCurrentDir(uHost2.lksPath);
      	livelinkProgressbar.Position:= 3;
        livelinkLabel[1].Caption:= '3/10';
        livelinkLabel[0].Caption:= 'Livelink folder status - OK...';

        livelinkLabel[0].Caption:= 'File name:';
        livelinkButton[0].Visible:= True;
        livelinkButton[0].Enabled:= True;
        livelinkEdit.Visible:= True;
        // ühenduse sidevahend + kuupäev
        if (Length(uHost2.pNumber) > 0) then
          fileeNimi:= uHost2.pNumber + '_' + DateToStr(Now)
        // ühenduse IP aadress + kuupäev
        else if (Length(uHost2.hostAddress) > 0) then
          fileeNimi:= uHost2.hostAddress + '_' + DateToStr(Now)
        else
        // kuupäev
          fileeNimi:= DateToStr(Now);
	        livelinkEdit.Text:= fileeNimi;
			end // kaustOlemas
    else
      begin
        livelinkProgressbar.Position:= 10;
        livelinkLabel[0].Caption:= 'Error on creating Livelink folder...';
      end;    
	except on E:Exception do
  	uHost2.writeErrorLog('Exception @ handlink livelinkImage: ' + E.Message);
  end;  
end;

procedure TuInformant.uploadToLiveLink;
var
	luba: boolean;
  leitud_nimi: string;
  i: SmallInt;
begin
	try
    leitud_nimi:= '';
    livelinkLabel[0].Font.Color:= clWindowText;
  	fileeNimi:= livelinkEdit.Text;
  	luba:= True;
  	for i:= 0 to High(lLFiles) do
    	if (AnsiCompareStr(llFiles[i], (fileeNimi + '.jpg')) = 0) then
      	begin
          leitud_nimi:= fileeNimi + '.jpg';
        	luba:= False;
         	break;
        end;
      
    if (luba) then
    	begin    
      	livelinkImage.Picture.LoadFromFile(uHost2.acceptImg);
        livelinkImage.Refresh;
        uHost2.disGray(livelinkEdit, False);
        livelinkEdit.Refresh;
        livelinkProgressbar.Position:= 7;
        livelinkLabel[0].Caption:= 'Uploading image, please wait...';
        livelinkLabel[0].Refresh;
        livelinkLabel[1].Caption:= '7/10';
        livelinkLabel[1].Refresh;
        livelinkButton[0].Enabled:= False;
        uHost2.alqTs.jpgAlq.SaveToFile(uHost2.liveLinkAdre + fileeNimi + '.jpg');
        livelinkProgressbar.Position:= 10;
        livelinkLabel[1].Caption:= '10/10';
        livelinkLabel[0].Caption:= 'Image upload complete...';
        livelinkCheckBox.Visible:= True;
        //ShellExecute(uHost2.Handle, PAnsiChar('open'), PAnsiChar(uHost2.liveLinkAdre),
          //nil, nil, SW_SHOW);       
      end
    else
      begin
        livelinkLabel[0].Font.Color:= $000000AA;
        livelinkLabel[0].Caption:= leitud_nimi + ' already exists...';
      	livelinkImage.Picture.LoadFromFile(uHost2.cancelImg);
      end;
  except on E:Exception do
  	uHost2.writeErrorLog('Exception @ uploading img to Livelink: ' + E.Message);
  end;
end;

procedure TuInformant.closeLivelink(Sender: TObject);
begin
	if (livelinkCheckbox.Checked) then
  	begin
    	uHost2.alqTs.alq_button[1].Click;
    end;
	Close;
end;

procedure TuInformant.uploadLivelink(Sender: TObject);
begin
	uploadToLiveLink;
end;

end.
