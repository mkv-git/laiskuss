program LaiskussA;

uses
  ShareMem,
  SysUtils,
  Forms,
  Windows,
  ShellApi,
  aMain in 'aMain.pas' {aHost},
  aToolsOpt in 'aToolsOpt.pas' {aOptions},
  aScriptDB in 'aScriptDB.pas' {aScrKog},
  aSplashScreen in 'aSplashScreen.pas' {aSplash},
  aInfoWnd in 'aInfoWnd.pas' {aInformant};

{$R *.res}

var
  Th: THandle;
begin
  Th:= CreateMutex(nil, True, 'Laiskuss2_agent');
  if (GetLastError <> ERROR_ALREADY_EXISTS) then
    begin
      aSplash:= TaSplash.Create(Application);
      try
        if (FindCmdLineSwitch('startUp') = False) then
          aSplash.Show;
        if (FindCmdLineSwitch('Laiskussist')) then
          aSplash.olek:= True;

        Application.Initialize;
        aSplash.Update;
        Application.ShowMainForm:= False;
        Application.Title := 'Laiskussi Agent';
  Application.CreateForm(TaHost, aHost);
  Application.CreateForm(TaOptions, aOptions);
  Application.CreateForm(TaScrKog, aScrKog);
  Application.CreateForm(TaInformant, aInformant);
  finally
        aSplash.Hide;
        aSplash.Free;
      end;
      Application.Run;
      if Th <> 0 then
        CloseHandle(Th);
    end;
end.
