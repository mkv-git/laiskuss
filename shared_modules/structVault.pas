unit structVault;

interface

type
  CONNECTION_TYPES = (TELNET, SSH, SERIAL);
  
  TAuthSettings = packed record
    asOSid    : string[95]; // kasutaja oSid
    asRights  : Word; // Õiguste tase
    asLevel		: Word; // lisaõiguste tase
    asDate    : TDateTime; //string[20]; // ticket'i kehtivusaeg
    asAlias   : boolean; // kas on kasutusel mitte ET domeeni oSid 
  end;

  TSectKog = packed record
    sect_nimi: string[20]; //sektor nimi
    sect_ID: string[8]; // sektori ID
    sect_size: byte; // sektori laius
    sect_date: LongWord; // viimase sünkimise aeg
  end;

  TKonfKog = packed record
    konf_id: string[10];  //nuppu ID
    konf_pl_id: string[8];        //nuppu asukoht
    konf_nimi: string[15];  //nuppu nimi
    konf_text: array of shortstring; //konfi tekst - str pikkus 256
    konf_text_ridu: word; //konfi teksti reakontroll
    konf_hint: string[100]; //vihje
    konf_hintAllow, konf_scrAssistant: boolean; //vihje näitamise lubadus, konfi käivitamine script assistantiga
    konf_date: LongWord; // viimase sünkimise aeg
  end;

  TMacrKog = packed record
    macr_id: string[10]; // nuppu ID
    macr_nimi: string[15]; // macro nimi;
    macr_text: shortstring; //macro tekst
    macr_cnf, macr_hintAllow: boolean; // macro kinnitus + vihje luba
    macr_hint: string[100]; //vihje
    macr_date: LongWord; // viimase sünkimise aeg
  end;

  TSkmTrash = packed record
    skm_type: byte; // sector = 1, konf = 2, macro = 3
    skm_id  : string[10]; // sectori, konfi või macro ID
  end;

// login history data
  TLoginHistory = record
    hHost: string[30];
    hPort: Word;
    hUser: string[30];
    hPass: string[130];
    hType: CONNECTION_TYPES; // telnet, telnet@estpak, serial
    hLogin : byte; // autentimise tüüp (helpdesk = 0, normal account = 1, ask for password = 2, interactite = 3)
  end;


// hotkey registri data
  THotKeys = record
    action: Word;
    shortcut: string[40];
  end;

// const hotkey list nimekirja jaoks
  THotKeyList = record
    hkNimi: string;
    hkID: Word;
  end;

// siteManager listing
  TSiteManager = packed record
    smName    : string[25];
    smGrpId   : Word; // Gruppi ID
    smLevelId : SmallInt; // siteManager item level
    smID      : integer; // Objekti ID
    smChild   : byte; // kas tegemist on gruppiga = 0 või hostiga = 1
  end;

// siteManager data
  TSmData = packed record
    smID    : integer; // siteManager objekti ID
    smLogin : byte; // autentimise tüüp (helpdesk = 0, normal account = 1, ask for password = 2, interactite = 3)
    smUser  : string[50]; // kasutajanimi
    smPswd  : string[130]; // parool
    smDesc  : string[255]; // kirjeldus
    smType  : byte; // ühenduse tüüp (telnet = 1, serial = 2)
    smHost  : string[50]; // ühenduse aadress
    smPort  : Word; // ühenduse port (telnet)
    smCom   : byte; // COM tüüp (COM1 = 1, COM3 = 3);
    smBps   : byte; // Bits per second
    smData  : byte; // Data bits
    smPar   : byte; // Parity (None = 1, Even = 2, Odd = 3, Mark = 4, Space = 5)
    smStop  : byte; // Stop bits (1 = 1, 1.5 = 2, 2 = 3);
    smFlow  : byte; // Flow control (Xon/Xoff = 1, Hardware = 2, None = 3)
  end;

// pinger data record
  TPingKog = packed record
    ping_name:  string[50];
    ping_addr:  string[50];
    ping_size:  WORD;
    ping_count: WORD;
  end;

  TMacs = record
    nimi: string[50];
    macAadress: string[20];
  end;

  TVlanArr = record
    vlanNimi: string;
    intfNimi: array of string;
  end;

  TPortForward = packed record
    pfID      : string[3];
    pfIntf    : string[50];
    pfProt    : string[10];
    pfPortOut : string[15];
    pfPortIn  : string[15];
    pfIpAddr  : string[40];
    pfFlag    : string;
  end;

  TVoipData = packed record
    voip_index: byte;
    voip_port : byte;
    voip_uri  : string[50];
    voip_user : string[50];
    voip_stat : boolean;
    voip_reg  : boolean;
  end;

  TIpAddress = packed record
    ip_adre: string[20];
    ip_mac: string[20];
  end;

// arrays of vars
  TStrArr = array of string;
  TIntArr= array of SmallInt;

// sectori, konfi ja macro kustutamisel visatakse andmed faili (offline'i joks) sünkimiseks mySql'ga.
  TTrash = packed record
    skmType: byte; // sector = 1, konf, byte
    skmID: string[10];
  end;

// struct for MaxSpeed Msg's

	PPortData = ^TPortData;
	TPortData = packed record
  	pdAccessID: string[10];
    pdMaxDown	: string[10];
    pdMaxUp		: string[10];
    pdType		: Byte;
  end;

  PPortSpec = ^TPortSpec;
  TPortSpec = packed record 
  	psAccessID: string[10];
    pType			: Byte;
  end;

  PSshAuthData = ^TSshAuthData;
  TSshAuthData = packed record
    sshUsername: string[20];
    sshPassword: string[255];
    sshRequestData: boolean;
    sshFailedLogin: boolean;
  end;

implementation

end.
