library funcSet;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  ShareMem, Windows, SysUtils, Classes, Registry, WinInet, structVault,
  DateUtils, ShFolder;

type  
  SectKog = array of TSectKog;
  KonfKog = array of TKonfKog;
  MacrKog = array of TMacrKog;

const
  servAdre = 'http://laiskuss.elion.ee/'; // Serveri aadresss
  f_sect = 'lks_sekt_u.l2f'; // Sektorikogumiku failinimi
  f_konf = 'lks_konf.l2f'; // Konfikogumiku failinimi
  f_macr = 'lks_macr_u.l2f'; // Makrokogumiku failinimi
  kon_fail_nimi: shortstring = 'Konfifail Laiskussi jaoks'; // konfikogumiku faili header
  konf_faili_versioon: SmallInt = 1;
  // Sets UnixStartDate to TDateTime of 01/01/1970
  UnixStartDate: TDateTime = 25569;

var
  ErrorCode: string;
  authSettings: TAuthSettings;
  sectFile: File of TSectKog;
  konfFile: File;
  macrFile: File of TMacrKog;
  kon_fail_vers: SmallInt; // konfikogumiku faili versioon

{$R *.res}

{************** General procedures ********************}

function GetLastDllError: string; stdcall;
begin
  Result:= ErrorCode;
end;

{ HTTP tehtud p‰ringute parsimine
 v‰‰rtused tagastatakse [xxx]kood[/xxx] kujul
}


function sulu_parser(sisend: string; otsing: string): string; stdcall;
var
  temp1, temp2, vastus: string;
  itemp1, itemp2: word;
begin
  vastus:= '';
  try
    temp1:= '[' + otsing + ']';
    temp2:= '[/' + otsing + ']';
    itemp1:= AnsiPos(temp1, sisend);
    itemp2:= AnsiPos(temp2, sisend);
    vastus:= Copy(sisend, itemp1 + Length(temp1), itemp2 - (itemp1 + Length(temp1)));
  except on E:Exception do
    ErrorCode:= 'Error on parsing sulud: ' + E.Message;
  end;
  Result:= vastus;
end;

function explode(sisend: string; delim: string): TStrArr; stdcall;
var
  iPos  : SmallInt;
  pidur : SmallInt;
  blokkid: TStrArr;
begin
  ErrorCode:= '';
  sisend:= Trim(sisend) + delim;
  pidur:= 0;
  SetLength(blokkid, pidur);
  try
    repeat
      iPos:= AnsiPos(delim, sisend);
      SetLength(blokkid, pidur+1);
      blokkid[pidur]:= Trim(Copy(sisend, 1, iPos-1));
      Delete(sisend, 1, iPos + Length(delim) - 1);
      sisend:= TrimLeft(sisend);
      inc(pidur);
    until ((sisend = '') OR (pidur = Length(sisend)+100));
  except on E:Exception do
    ErrorCode:= 'Error on processing explode: ' + E.Message;
  end;
  Result:= blokkid;
end;

{
  HTTP response koodid:
  -1 - vale p‰ring
  400 - p‰ring ınnestus
}

function checkForResponse(sisend: string): SmallInt; stdcall;
var
  vastus: SmallInt;
begin
  vastus:= -1;
  try
    vastus:= StrToInt(sulu_parser(sisend, 'response'));
  except on E:Exception do
    ErrorCode:= 'Response check error: ' + E.Message;
  end;
  Result:= vastus;
end;

function isInt(str: string): boolean; stdcall;
begin
  try
    StrToInt(str);
    Result := True;
  except on E:EconvertError do
    Result := False;
  end;
end;


function IntToBool(sisend: shortInt): boolean; stdcall;
begin
  Result:= False;
  try
    if sisend <= 0 then
      Result:= False
    else if sisend > 0 then
      Result:= True;
  except on E:Exception do
    ErrorCode:= 'Error on converting int to bool: ' + E.Message;
  end;
end;

function BoolToInt(sisend: boolean): shortInt; stdcall;
begin
  Result:= 0;
  try
    if sisend then
      Result:= 1
    else if sisend = False then
      Result:= 0;
  except on E:Exception do
    ErrorCode:= 'Error on converting bool to int: ' + E.Message;
  end;
end;

// stringi maskimine
function encStr(inpt: string): string; stdcall;
var
  i: integer;
begin
  Result := '';
  for i:= 0 to Length(inpt) do
    Result:= Result + IntToHex(Ord(inpt[i]) + i + 1,2);
end;

// stringi demaskimine
function decStr(inpt: string): string; stdcall;
var
  i: integer;
begin
  Result:= '';
  for i:= 2 to Length(inpt) div 2 do
    Result := Result + Char(StrToInt('$'+Copy(inpt,(i-1)*2+1,2)) - i);
end;

function findFileSize(filee: string): integer; stdcall;
var
  fHandle: THandle;
  fSize: LongWord;
begin
  fHandle := CreateFile(PCHar(filee), GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  fSize:= GetFileSize(fHandle, nil);
  Result:= fSize;
  CloseHandle(fHandle);
end;


// Known folders



function getKnownPath(tyyp: ShortInt): string; stdcall;
var
  path: array [0..MAX_PATH] of char;
  kaust: integer;
  vastus: string;
begin
  vastus := '';
  kaust:= 0;
  if (tyyp >= 0) then
    try
      case tyyp of
        0: kaust:= CSIDL_APPDATA;
        1: kaust:= CSIDL_MYPICTURES;
      end;

      if SUCCEEDED(SHGetFolderPath(0,kaust,0,0,@path[0])) then
        vastus := path;
    except on E:Exception do
      ErrorCode:= E.Message;
    end;
  Result:= vastus;
end;

{****************** HTTP Procedures *******************}

// faili allalaadimise wrapper, parameetrid: URL, failinimi
function dl_file(aUrl: PAnsiChar; failiNimi: string): boolean; stdcall;
var
  hSession, hService: HINTERNET;
  buffer: array[1..1024] of byte;
  cuBytesRead: DWORD;
  f: file;
begin
  hSession:= InternetOpen(PAnsiChar('Laiskuss'),
    INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  try
    hService:= InternetOpenUrl(hSession, aUrl, nil, 0, 0, 0);
    try
      AssignFile(f, failiNimi);
      ReWrite(f, 1);
      repeat
        InternetReadFile(hService, @buffer, sizeof(buffer), cuBytesRead);
        BlockWrite(f, buffer, cuBytesRead);
      until cuBytesRead = 0;
      CloseFile(f);
    finally
      InternetCloseHandle(hService);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
  Result:= True;
end;


// teksti allalaadimise wrapper,
function dl_text(aUrl: PAnsiChar; var vastus: string): boolean; stdcall;
var
  hSession, hService: HINTERNET;
  buffer: array[0..1024+1] of char;
  cuBytesRead: DWORD;
begin
  Result:= False;
  vastus:= '';
  hSession:= InternetOpen('Laiskuss', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  try
    if assigned(hSession) then
      begin
        hService:= InternetOpenUrl(hSession, aUrl, nil, 0, INTERNET_FLAG_RELOAD, 0);
        if assigned(hService) then
          try
            while True do
              begin
                InternetReadFile(hService, @buffer, sizeof(buffer), cuBytesRead);
                if cuBytesRead = 0 then break;
                buffer[cuBytesRead]:= #0;
                vastus:= vastus + buffer;
              end;
              Result:= True;
          finally
            InternetCloseHandle(hService);
          end;
      end;
  finally
    InternetCloseHandle(hSession);
  end;
end;


{

//********************** autentimise protseduurid ****************************//
getKasutaja - tagastab sisseloginud kasutajanime
getSid - tagastab objectSid'i stringina

}

function getKasutaja: string; stdcall;
var
  buffer: string;
  bufSize: DWORD;
begin
  bufSize:= 255;
  Setlength(buffer, bufSize);
  GetUserName(PAnsiChar(buffer), bufSize);
  Result:= buffer;
end;

function getSid: string;
var
  kasutaja, sSid: string;
  i, subAuthorityCnt: Word;
  pSid, refDomain: array[0..255] of byte;
  cSid, c_refDomain, peUse: DWORD;
  sidIdentifier: TSidIdentifierAuthority;
  sidAuthority: Double;
begin
  Result:= '';
  try
    ZeroMemory(@pSid, SizeOf(pSid));
    ZeroMemory(@refDomain, SizeOf(refDomain));
    kasutaja:= getKasutaja;

    LookupAccountName(nil, PAnsiChar(kasutaja), @pSid, cSid, @refDomain, c_refDomain, peUse);
    sSid:= 'S-1-';
    sidIdentifier:= GetSidIdentifierAuthority(@pSid)^;
    sidAuthority:= 0;

    for i:= 0 to 5 do
      sidAuthority:= sidAuthority + (sidIdentifier.value[i] shl (8* (5-i)));
    sSid:= sSid + FloatToStr(sidAuthority) + '-';

    subAuthorityCnt:= GetSidSubAuthorityCount(@pSid)^;
    for i:= 0 to subAuthorityCnt-1 do
      sSid:= sSid + IntToStr(GetSidSubAuthority(@pSid, i)^) + '-';

    Result:= Copy(sSid, 1, Length(sSid)-1);
  except on E:Exception do
    ErrorCode:= 'Error on oSid location: ' + E.Message;
  end;
end;

function getAuthData(fSid: string; var level: Word; var alias: boolean; sAlias: boolean = False): SmallInt;
const
  par: array[0..3] of string =
    ('lks_vers', 'lks_hk', 'lks_avers', 'lks_ter');
var
  vastus, aData, aLevel, aAlias, dummy, lisa: string;
  andmed: array[0..3] of string;
  lReg: TRegistry;
  i: SmallInt;
begin
  Result:= -1;
  lReg:= TRegistry.Create;
  try
    try
    // nullime andmete array, juhul kui mingi registri data on puudu
      for i:= 0 to High(andmed) do
        andmed[i]:= '';
      dummy:= '';

      lReg.RootKey:= HKEY_CURRENT_USER;

    // Laiskussi andmed
      if lReg.OpenKey('SOFTWARE\Laiskuss2', False) then
        begin
          if lReg.ValueExists('lksVers') then
            andmed[0]:= lReg.ReadString('lksVers'); // laiskussi version

          if lReg.ValueExists('allowHotkeys') then
            andmed[1]:= IntToStr(lReg.ReadInteger('allowHotkeys')); // is hotKeys allowed
        end;
      lReg.CloseKey;

    // Ussike andmed
      if lReg.OpenKey('SOFTWARE\Laiskuss2\Ussike', False) then
        begin
          if lReg.ValueExists('ussVers') then
            andmed[2]:= lReg.ReadString('ussVers'); // ussike versioon

        end;
      lReg.CloseKey;

    // telnet setting
      if lReg.OpenKey('SOFTWARE\Classes\telnet\shell\open\command', False) then
        begin
          if lReg.ValueExists('') then
            dummy:= lReg.ReadString(''); // Is Laiskuss default telnet

          if (AnsiPos('Laiskuss', dummy) > 0) then
            andmed[3]:= '1'
          else
            andmed[3]:= '0';
        end;

    except
    end;
  finally
    lReg.CloseKey;
    lReg.Free;
  end;

// andmed kasutaja statistika jaoks, mis saadetakse serverisse
  try
    lisa:= '';
    for i:= 0 to 3 do
      begin
        lisa:= lisa + '&' + par[i] + '=' + andmed[i];
      end;
  except
  end;

  try
    if (dl_text(PAnsiChar(servAdre +
      'uss_remote2/check_rights.php?kasutaja=' + PAnsiChar(getKasutaja) + '&oSid=' + fSid +
      '&alias='+IntToStr(BoolToInt(sAlias)) + lisa), vastus)) then
      if (checkForResponse(vastus) = 400) then
        begin
          aAlias:= sulu_parser(vastus, 'alias');
          if (isInt(aAlias)) then
            alias:= IntToBool(StrToInt(aAlias))
          else
            alias:= False;

          aData:= sulu_parser(vastus, 'tavakasutaja');
          if (isInt(aData)) then
            Result:= StrToInt(aData)
          else
            Result:= -1;

          aLevel:= sulu_parser(vastus, 'kasutajaLv2');
          if (isInt(aLevel)) then
          	level:= StrToInt(aLevel)
          else
          	level:= 0;
        end;
        ErrorCode:= vastus;
  except on E:Exception do
    ErrorCode:= 'AuthData retrieval error: ' + E.Message;
  end;
end;

procedure idendiKasutaja(var tulem: boolean; var siider: string; sendStat: boolean = False); stdcall;
var
  reg, reg2: TRegistry;
  tulemus: boolean;
  kasutaja: string;
  aData: SmallInt;
  aDate: TDateTime;
  pAlias, aAlias: boolean;
  aLevel: Word;
begin
  tulemus:= False;
  if (siider = '') then
  	siider:= getSid;      
  kasutaja:= getKasutaja;
  aDate:= Now;
  pAlias:= False;
  ErrorCode:= '';
  try
    reg:= TRegistry.Create;
    try
      reg.RootKey:= HKEY_CURRENT_USER;
  // kas Registris on sisselogimise andmed olemas, kui jah siis vırdlusse,
  // kui ei siis tehakse p‰ring serverile,
      if reg.OpenKey('software\Laiskuss2', True) then
        if reg.valueExists('authData') then
          begin
            reg.readBinaryData('authData', authSettings, SizeOf(authSettings));
            pAlias:= authSettings.asAlias;
            if (authSettings.asRights = 5) AND (AnsiCompareStr(decStr(authSettings.asOSid), siider) = 0) AND
              (CompareDate(authSettings.asDate, Now) >= 0) AND (NOT sendStat) then
              tulemus:= True
            else
              begin
                aData:= getAuthData(siider, aLevel, aAlias, pAlias);
                authSettings.asRights:= aData;
                authSettings.asLevel:= aLevel;
                authSettings.asDate:= IncMonth(aDate);//FormatDateTime('yyyymmdd', IncMonth(aDate));
                authSettings.asOSid:= encStr(siider);
                authSettings.asAlias:= pAlias;
                reg.writeBinaryData('authData', authSettings, SizeOf(authSettings));
                if aData = 5 then
                  tulemus:= True;
              end;
          end
        else
          begin
            aData:= getAuthData(siider, aLevel, aAlias, pAlias);
            authSettings.asRights:= aData;
            authSettings.asLevel:= aLevel;
            authSettings.asDate:= IncMonth(aDate); //FormatDateTime('yyyymmdd', IncMonth(aDate));
            authSettings.asOSid:= encStr(siider);
            authSettings.asAlias:= pAlias;
            reg.writeBinaryData('authData', authSettings, SizeOf(authSettings));
            if aData = 5 then
              tulemus:= True;
          end;
    finally
      reg.CloseKey;
      reg.Free;
    end;
  except on E:Exception do
    begin
      ErrorCode:= 'Registry data is corrupted: ' + E.Message;
      reg2:= TRegistry.Create;
      try
        reg2.RootKey:= HKEY_CURRENT_USER;
        if reg2.OpenKey('software\Laiskuss2', True) then
          begin
            if (reg2.ValueExists('authData')) then
              reg2.DeleteValue('authData');
          end;
      finally
        reg2.CloseKey;
        reg2.Free;
      end; // reg2 try
    end; // exception
  end; // try
  tulem:= tulemus;
end;

{
//********************** konfide allalaadimine ****************************//

lae_sectorid, lae_konfid ja lae_macrod - konfide allalaadimine laiskussi jaoks.
parameetrid:
1) aUrl - konfide aadress
2) tagastab array of Sectorid, Konfid ja Kacrod
funktsioonid tagastavad massiivi arvu.

kıik konfidega seotud p‰ringud tagastavada response koodi:
 -1 == vigane p‰ring
 100 == p‰ring ıige, kuid leitud 0 tulemust
 200 == p‰ring ıige, leitud n tulmust

}

// sektorid

function sectorLoad(kaust: string; var sectors: SectKog): boolean; stdcall;
var
  tulemus: boolean;
  i, sectCnt, sectSize: smallInt;
begin
  tulemus:= False;
  sectSize:= 0;
  if (FileExists(kaust + f_sect)) then
    begin
      try
        AssignFile(sectFile, kaust + f_sect);
        Reset(sectFile);
        sectCnt:= FileSize(sectFile);
        SetLength(sectors, sectCnt);
        if (sectCnt > 0) then
          for i:= 0 to sectCnt-1 do
            begin
             Read(sectFile, sectors[i]);
             sectSize:= sectSize + sectors[i].sect_size;
            end;
        CloseFile(sectFile);
        if (Length(sectors) > 0) then
          tulemus:= True;
      except on E:Exception do
        ErrorCode:= 'Sector load: ' + E.Message;
      end;
    end;
  try
    sectCnt:= Length(sectors);
    SetLength(sectors, sectCnt+1);
    sectors[sectCnt].sect_nimi:= 'Default';
    sectors[sectCnt].sect_ID:= 'De29lt39';
    sectors[sectCnt].sect_size:= 10 - sectSize;
    sectors[sectCnt].sect_date:= 0;
    tulemus:= True;
  except on E:Exception do
    ErrorCode:= 'Default sector create: ' + E.Message;
  end;
  Result:= tulemus;
end;


function sectorSave(kaust: string; sectors: SectKog): boolean; stdcall;
var
  tulemus: boolean;
  i: smallInt;
begin
  tulemus:= False;
  try
    AssignFile(sectFile, kaust + f_sect);
    ReWrite(sectFile);
    for i:= 0 to Length(sectors)-2 do
      Write(sectFile, sectors[i]);
    CloseFile(sectFile);
    tulemus:= True;
  except on E:Exception do
    ErrorCode:= 'Sector save: ' + E.Message;
  end;
  Result:= tulemus;
end;


// Konfid

function konfLoad(kaust: string; var konfid: KonfKog): boolean; stdcall;
var
  i, j, konfCnt: smallInt;
  failiAsum, nimi: shortstring;
  tulemus: boolean;
begin
  tulemus:= False;
  failiAsum:= kaust + f_konf;
  if ((FileExists(failiAsum)) AND (findFileSize(failiAsum) > sizeOf(TKonfKog))) then
    begin
      try
        AssignFile(konfFile, failiAsum);
        Reset(konfFile, 1);
        blockRead(konfFile, nimi, sizeof(nimi));
        blockRead(konfFile, kon_fail_vers, sizeof(kon_fail_vers));
        blockRead(konfFile, konfCnt, sizeof(konfCnt));
        SetLength(konfid, konfCnt);
        for j:= 0 to konfCnt-1 do
          with konfid[j] do
            begin
              blockRead(konfFile, konf_ID, sizeof(konf_ID));
              blockRead(konfFile, konf_pl_ID, sizeof(konf_pl_ID));
              blockRead(konfFile, konf_nimi, sizeof(konf_nimi));
              blockRead(konfFile, konf_hint, sizeof(konf_hint));
              blockRead(konfFile, konf_hintAllow, sizeof(konf_hintAllow));
              blockRead(konfFile, konf_scrAssistant, sizeof(konf_scrAssistant));
              blockRead(konfFile, konf_date, sizeof(konf_date));
              blockRead(konfFile, konf_text_ridu, sizeof(konf_text_ridu));
              SetLength(konf_text, konf_text_ridu+1);
              for i:= 0 to (konf_text_ridu)-1 do
                blockRead(konfFile, konf_text[i], sizeof(konf_text[i]));
            end;
        tulemus:= True;
        CloseFile(konfFile);
      except on E:Exception do
        ErrorCode:= 'Konfide faili laadimisel tekkis viga: ' + E.Message;
      end;
    end
  else
    ErrorCode:= 'Konfide fail puudub vıi on vigane...';
  Result:= tulemus;
end;

function konfSave(kaust: string; konfid: KonfKog): boolean; stdcall;
var
  tulemus: boolean;
  i, j, konfCnt: SmallInt;
begin
  tulemus:= False;
  try
    AssignFile(konfFile, kaust + f_konf);
    ReWrite(konfFile, 1);
    konfCnt:= Length(konfid);
    kon_fail_vers:= konf_faili_versioon;
    blockWrite(konfFile, kon_fail_nimi, sizeof(kon_fail_nimi));
    blockWrite(konfFile, kon_fail_vers, sizeof(kon_fail_vers));
    blockWrite(konfFile, konfCnt, sizeof(konfCnt));
    for i:= 0 to konfCnt-1 do
      with konfid[i] do
        begin
          blockWrite(konfFile, konf_ID, sizeof(konf_ID));
          blockWrite(konfFile, konf_pl_ID, sizeof(konf_pl_ID));
          blockWrite(konfFile, konf_nimi, sizeof(konf_nimi));
          blockWrite(konfFile, konf_hint, sizeof(konf_hint));
          blockWrite(konfFile, konf_hintAllow, sizeof(konf_hintAllow));
          blockWrite(konfFile, konf_scrAssistant, sizeof(konf_scrAssistant));
          blockWrite(konfFile, konf_date, sizeof(konf_date));
          blockWrite(konfFile, konf_text_ridu, sizeof(konf_text_ridu));
          for j:= 0 to konf_text_ridu -1 do
            blockWrite(konfFile, konf_text[j], sizeof(konf_text[j]));
      end;
    tulemus:= True;
    CloseFile(konfFile);
  except on E:Exception do
    ErrorCode:= E.Message;
  end;
  Result:= tulemus;
end;

// Macrod

function macroLoad(kaust: string; var macrod: MacrKog): boolean; stdcall;
var
  tulemus: boolean;
  i, macrCnt: smallInt;
begin
  tulemus:= False;
  if FileExists(kaust + f_macr) then
    begin
      AssignFile(macrFile, kaust + f_macr);
      Reset(macrFile);
      macrCnt:= FileSize(macrFile);
      SetLength(macrod, macrCnt);
      if (macrCnt > 0) then
        for i:= 0 to macrCnt-1 do
          Read(macrFile, macrod[i]);
      CloseFile(macrFile);
      if (Length(macrod) > 0) then
        tulemus:= True;
    end;
  Result:= tulemus;
end;

function macroSave(kaust: string; macrod: MacrKog): boolean; stdcall;
var
  tulemus: boolean;
  i: smallInt;
begin
  tulemus:= False;
  try
    AssignFile(macrFile, kaust + f_macr);
    ReWrite(macrFile);
    for i:= 0 to Length(macrod)-1 do
      Write(macrFile, macrod[i]);
    CloseFile(MacrFile);
    tulemus:= True;
  except on E:Exception do
    ErrorCode:= 'macrosalvestus: ' + E.Message;
  end;
  Result:= tulemus;
end;


// Unix time conversion

function getBias: Integer;
var
  zoneInfo: TTimeZoneInformation;
begin
  case GetTimeZoneInformation(zoneInfo) of
    1: Result:= -(zoneInfo.StandardBias - zoneInfo.Bias) div (24 * 60); // Standart
    2: Result:= -(zoneInfo.DaylightBias - zoneInfo.Bias) div (24 * 60); // Daylight
  else
    Result:= 0;
  end;
end;

function DateToUnix(aeg: TDateTime): LongWord; stdcall;
begin
  Result:= Round((aeg - UnixStartDate) * 86400) + getBias;
end;

function UnixToDate(unix: LongWord): TDateTime; stdcall;
begin
  Result := (UnixStartDate + (unix / 86400)) - getBias;
  //Result := EncodeDate(1970,1,1) + (unix/(24*3600));
end;

// Dll funktsioonide eksport
exports GetLastDllError;
exports sulu_parser;
exports explode;
exports getKasutaja;
exports idendiKasutaja;
exports isInt;
exports IntToBool;
exports BoolToInt;
exports encStr;
exports decStr;
exports findFileSize;
exports getKnownPath;
exports konfLoad;
exports konfSave;
exports sectorLoad;
exports sectorSave;
exports macroLoad;
exports macroSave;
exports DateToUnix;
exports UnixToDate;

begin
end.
