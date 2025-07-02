library ipTools;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

{
  IP tools functions:
    dns, trace, ping, port forward check
}

uses
  ShareMem, Windows, SysUtils, Classes, WinSock, structVault;


type
  PingKog = array of TPingKog;
  TSunB = packed record
    s_b1, s_b2, s_b3, s_b4: byte;
  end;

  TSunW = packed record
    s_w1, s_w2: word;
  end;

  PIPAddr = ^TIPAddr;
  TIPAddr = record
    case integer of
      0: (S_un_b: TSunB);
      1: (S_un_w: TSunW);
      2: (S_addr: longword);
  end;

 IPAddr = TIPAddr;

const
  f_ping = 'lks_ping.ldbf'; // Ping preset faili nimi

var
  ErrorCode: string;
  pingFile: File of TPingKog;


{$R *.res}

{************** General procedures ********************}

function GetLastIpError: string; stdcall;
begin
  Result:= ErrorCode;
end;


{****************
  DNS Services
****************}

function dnsLookup(sisse: string; var vastus: string): boolean; stdcall;
type
   TaPinAddr = array[0..10] of PinAddr;
   PaPinAddr = ^TaPinAddr;
var
   ws: TWsaData;
   phe: PHostEnt;
   s: string;
   pAdr: PaPinAddr;
   i: integer;
begin
   WSAStartup($101, ws);
   phe := GetHostByName(PAnsiChar(sisse));
   if phe <> nil then
     begin
       pAdr := PaPinAddr(phe^.h_addr_list);
       i:= 0;
       while (pAdr^[i] <> nil) do
         begin
           s:= inet_ntoa(pAdr^[i]^);
           inc(i);
         end;
       vastus:= s;
       Result:= True;
     end
   else
     begin
       Result:= False;
       vastus:= '';
     end;
   WsaCleanUp;
end;


{***************************************
              PINGER
***************************************}

function pingLoad(kaust: string; var pingerid: PingKog): boolean; stdcall;
var
  tulemus: boolean;
  i: SmallInt;
begin
  tulemus:= False;
  ErrorCode:= '';

// Lisame default pingeri (www.neti.ee - 195.50.209.244
  try
    SetLength(pingerid, 1);
    with pingerid[0] do
      begin
        ping_name:= 'www.neti.ee';
        ping_addr:= '195.50.209.244';
        ping_size:= 64;
        ping_count:= 25;
      end;
  except on E:Exception do
    ErrorCode:= 'Exception @ create default pinger: ' + E.Message;
  end;

  if (FileExists(kaust + f_ping)) then
    begin
      try
        AssignFile(pingFile, kaust + f_ping);
        Reset(pingFile);
        for i:= 0 to FileSize(pingFile)-1 do
          begin
            SetLength(pingerid, i+2);
            Read(pingFile, pingerid[i+1]);
          end; // end for loop
        CloseFile(pingFile);

        if Length(pingerid) > 0 then
          tulemus:= True;
      except on E:Exception do
      // kui tekkis viga ka default pingeri määramisel siis tahaksime sellest ka teada saada
        if (Length(ErrorCode) > 0) then
          ErrorCode:= ErrorCode + #13#10 + 'Exception @ loadPingData: ' + E.Message
        else
          ErrorCode:= 'Exception @ loadPingData: ' + E.Message
      end; // end try block
    end; // end if fileExists

  Result:= tulemus;
end;

function pingSave(kaust: string; pingerid: PingKog): boolean; stdcall;
var
  tulemus: boolean;
  i: SmallInt;
begin
  tulemus:= False;
  ErrorCode:= '';
  try
    AssignFile(pingFile, kaust + f_ping);
    ReWrite(pingFile);
  // 1'st alates kuna 1 kirje on default, mida ei salvestata failile
    for i:= 1 to Length(pingerid)-1 do
      Write(pingFile, pingerid[i]);
      
    tulemus:= True;
    CloseFile(pingFile);
  except on E:Exception do
    ErrorCode:= 'Exception @ savePingData: ' + E.Message;
  end; // end of try block
  Result:= tulemus;
end;


{*******************************************************************************
                                    ICMP Pinger
********************************************************************************}                                                                                              






// DLL function export
exports GetLastIpError;
exports dnsLookup;
exports pingLoad;
exports pingSave;

begin
end.

