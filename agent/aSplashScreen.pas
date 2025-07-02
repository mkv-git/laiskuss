unit aSplashScreen;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TaSplash = class(TForm)
    splashLabel: TLabel;
    splashButton: TButton;
    Panel1: TPanel;
    procedure splashButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    splKinni: boolean;
    olek: boolean;
  end;

var
  aSplash: TaSplash;

implementation

{$R *.dfm}


procedure TaSplash.FormCreate(Sender: TObject);
begin
  splKinni:= False;
  olek:= False;
  splashLabel.Caption:= 'Laiskuss is loading...';
end;

procedure TaSplash.splashButtonClick(Sender: TObject);
begin
  splKinni:= True;
end;

end.
