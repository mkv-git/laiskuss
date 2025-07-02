unit uScrEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TuScriptEditor = class(TForm)
    scrText: TMemo;
    cancelB: TButton;
    sendB: TButton;
    copyB: TButton;
    scrAssCB: TCheckBox;
    script_editor_control_panel: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure copyBClick(Sender: TObject);
    procedure sendBClick(Sender: TObject);
    procedure cancelBClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  uScriptEditor: TuScriptEditor;

implementation

uses uMain;

{$R *.dfm}

procedure TuScriptEditor.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight:= 200;
  Constraints.MinWidth:= 400;
  KeyPreview:= True;
end;

procedure TuScriptEditor.FormShow(Sender: TObject);
begin
  scrAssCB.Checked:= False;
  scrText.Clear;
  sendB.Enabled:= uHost2.is_connection_alive;
end;

procedure TuScriptEditor.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
    Close;
end;

procedure TuScriptEditor.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if uHost2.is_connection_alive then
    uHost2.scrTs.Set_rbState(True);
end;

procedure TuScriptEditor.copyBClick(Sender: TObject);
begin
  scrText.SelectAll;
  scrText.CopyToClipboard;
end;

procedure TuScriptEditor.sendBClick(Sender: TObject);
var
  i       : SmallInt;
  sReaCnt : SmallInt; // scripAssistanti'i counter
  temp    : string;
  sText   : string; // konfitext
begin
  uHost2.scrTs.Set_rbState(True);
  if (scrAssCB.Checked = False) then
    begin
      for i:= 0 to scrText.Lines.Count -1 do
        begin
          sText:= uHost2.scrTs.koolonKontroll(scrText.Lines.Strings[i]);
          uHost2.writeLn_to_terminal(sText);
        end;
    end
  else
    try
      sReaCnt:= -1;
      temp:= '';
      for i:= 0 to scrText.Lines.Count -1 do
        begin
          inc(sReaCnt);
          sText:= uHost2.scrTs.koolonKontroll(scrText.Lines.Strings[i], False);
          uHost2.writeLn_to_terminal(':script add name = lsaKonf command = "' + sText +'"');
          temp:= temp + ',' + IntToStr(sReaCnt);
        end;
      temp:= Copy(temp, 2, MaxInt);
      inc(sReaCnt);
      uHost2.writeLn_to_terminal(':script add name = lsaKonf command = "script delete name lsaKonf"');
      uHost2.writeLn_to_terminal(':script run name = lsaKonf pars=' + temp + ',' + IntToStr(sReaCnt));
    except on E:Exception do
      uHost2.writeErrorLog('Error @ sending script from scrEditor : ' + E.Message);
    end; // end of try block
  Close;
end;

procedure TuScriptEditor.cancelBClick(Sender: TObject);
begin
  Close;
end;





end.
