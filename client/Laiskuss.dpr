program Laiskuss;

uses
  ShareMem,
  Windows,
  Forms,
  SysUtils,
  ShellApi,
  Messages,
  uMain in 'uMain.pas' {uHost2},
  uStatusClass in 'uStatusClass.pas',
  uAlqClass in 'uAlqClass.pas',
  aSplashScreen in 'aSplashScreen.pas' {aSplash},
  uScriptClass in 'uScriptClass.pas',
  uScrEditor in 'uScrEditor.pas' {uScriptEditor},
  uInfoWnd in 'uInfoWnd.pas' {uInformant},
  uLoginForm in 'uLoginForm.pas' {LoginForm};

{$R *.res}

var
  ussike: HWND;
  uss_cnt: SmallInt;
  ussi_olek: array[0..1024] of char; {!r19}
begin
    try
      aSplash:= TaSplash.Create(Application);
      ussike:= FindWindow('TaHost', 'valmis');
      ussi_olek:= '';
      uss_cnt:= 0;
      if (ussike = 0) then
        begin
          aSplash.Show;
          ShellExecute(Application.Handle, 'open', PAnsiChar(ExtractFilePath(Application.ExeName) + '\LaiskussA.exe'), '-startUp -Laiskussist', nil, 0);
          aSplash.Update;
          repeat
            ussike:= FindWindow('TaHost', 'valmis');
            if (ussike <> 0) then
              SendMessage(ussike, WM_GETTEXT, sizeof(ussi_olek), integer(@ussi_olek));
            Sleep(200);
            inc(uss_cnt);
          until (strPas(ussi_olek) = 'valmis') OR (uss_cnt > 10);
          {!r16}
        end;
      Application.Initialize;
      aSplash.Update;
      Application.CreateForm(TuHost2, uHost2);
  Application.CreateForm(TuScriptEditor, uScriptEditor);
  Application.CreateForm(TuInformant, uInformant);
  Application.CreateForm(TLoginForm, LoginForm);
  finally
      aSplash.Hide;
      aSplash.Free;
    end;
    Application.Run;
end.
