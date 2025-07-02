unit uLoginForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TLoginForm = class(TForm)
    username_edit: TEdit;
    password_edit: TEdit;
    username_label: TLabel;
    password_label: TLabel;
    login_button: TButton;
    procedure login_buttonClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure password_editKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LoginForm: TLoginForm;

implementation

uses
  uMain;

{$R *.dfm}

procedure TLoginForm.login_buttonClick(Sender: TObject);
begin
  uHost2.ssh_auth_data.sshUsername:= username_edit.Text;
  uHost2.ssh_auth_data.sshPassword:= password_edit.Text;
  if (password_edit.Text <> '') then
    ModalResult:= mrOK;
end;

procedure TLoginForm.password_editKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    login_button.Click;
end;

procedure TLoginForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
    Close;
end;

procedure TLoginForm.FormCreate(Sender: TObject);
begin
  KeyPreview:= True;
end;

procedure TLoginForm.FormShow(Sender: TObject);
begin
  username_edit.Text:= uHost2.ssh_auth_data.sshUsername;
  password_edit.SetFocus;
end;



end.
