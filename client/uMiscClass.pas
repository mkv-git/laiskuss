unit uMiscClass;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, StdCtrls, Buttons,
  ComCtrls, Forms, WinInet, Dialogs, structVault, ExtCtrls, StrUtils;


type
  TuMiscTS = Class(TObject)
    public
    // global variables
      pf_button: array[0..3] of TButton;
      vm_button: array[0..1] of TButton;
      voip_update: TButton;

    // procedures
      constructor Create;
      destructor Destroy; override;
      procedure setToDefault;
      procedure miscUpdate(state: boolean);
      procedure updateMiscTab;
    // vlan manager procedures
      procedure getVlanData;
    private
    // global vars
      misc_gb_arr: array[0..2] of TGroupBox;

    // port forwarder vars
      pfArr: array of TPortForward;
      pf_listview: TListView;
      pf_radiobutton: array[0..2] of TRadioButton;

      // add port forward panel
      pf_panel: TPanel;
      isNewPfOpen: boolean;
      pf_panel_label: array[0..4] of TLabel;
      pf_panel_combobox: array[0..2] of TCombobox;
      pf_panel_memo: array[0..2] of TMemo;
      pf_panel_radiobutton: array[0..2] of TRadioButton;

    // end of port forwarder vars

    // vlan manager vars
      vlanArr: array of TVlanArr;
      vm_combobox: array[0..3] of TCombobox;
      vm_radiobutton: array[0..3] of TRadioButton;
      vm_label: TLabel;

    // voip vars
      voip_edit: array[0..2] of TEdit;
      voip_button: array[0..5] of TButton;
      voip_info_label: array[0..6] of TLabel;
      voip_data_label: array[0..5] of TLabel;
      voipData: array[0..2] of TVoipData;
      voip_image: array[0..5] of TImage;


    // port forwarder procedures
      procedure newPF(Sender: TObject); // New button handler - lisab pordisuunamised ruuterisse
      procedure deletePF(Sender: TObject); // Delete button handler - kustutad pordisuunamised ruuterist
      procedure updatePF(Sender: TObject); // Update button handler - korjab pordisuunamised ruuterist
      procedure copyPF(Sender: TObject); // Copy button handler - kopeerib maplist'i andmed clipboard'i

      procedure switchPF(Sender: TObject); // radioButton onclick handler
      procedure loadPFData(tag: SmallInt); // load data according radiobutton state
      procedure getNatData; // load port forward data from telnet
      procedure sendNatData(single: boolean = False); // send port forward to telnet
      procedure restoreNatData; // copy-paste NAT list
      procedure deleteNatData; // delete port forward
      procedure OnEnterPF(Sender: TObject);
      procedure OnExitPF(Sender: TObject);
      function checkBeforeSend(var errorLog: string): boolean;

      // pf_panel
      procedure activateNewPf(state: boolean = True);
      procedure changePfMode(Sender: TObject);

    // vlan manager procedures
      procedure updateVM(Sender: TObject); // button[0] handler
      procedure setVM(Sender: TObject); // button[1] handler
      procedure onChangeVM(Sender: TObject); // combobox handler
      procedure switchVM(Sender: TObject); // radiobutton handler
      procedure checkRB(kumb: SmallInt); // radioButton state & combobox selection kontroll

    // voip procedures
      procedure updateVoip(Sender: TObject);
      procedure voip_button1(Sender: TObject);
      procedure voip_button2(Sender: TObject);
      procedure getVoipData;
      procedure getVoipData789; // 789 ruuteri jaoks
      procedure populateVoip(sisend: string; port: byte);
      procedure clearVoipObjects(rida: byte = 0);
      procedure fillVoipObjects;
      procedure addVoip(fxp: string);
      procedure deleteVoip(uri: string);


  end;

var
  uMiscTS: TuMiscTS;

implementation
uses
  uMain;

constructor TuMiscTS.Create;
const
  misc_gb_caption: array[0..2] of string =
    ('Port forwarder', 'Vlan interface manager', 'VOIP');

  pf_button_caption: array[0..3] of string =
    ('New', 'Delete', 'Update', 'Copy');
  pf_radiobutton_caption: array[0..2] of string =
    ('All', 'Dynamic', 'Static');
  pf_radiobutton_hint: array[0..2] of string =
    ('Show all ports', 'Show only client''s dynamic ports', 'Show only client''s static ports');
  pf_radiobutton_width: array[0..2] of SmallInt = (35, 60, 50);
  pf_listview_caption: array[0..6] of string =
    ('ID', 'Interface', 'Protocol', 'Port out', 'Port in', 'IP address', 'Flag');
  pf_listview_width: array[0..6] of SmallInt =
    (23, 54, 51, 75, 75, 81, 53);

  pf_panel_label_caption: array[0..4] of string =
    ('Interface', 'IP address', 'Protocol', 'Port IN', 'Port OUT');
  pf_panel_combobox_items: array[0..2] of string = ('any', 'tcp', 'udp');
  pf_panel_radiobutton_caption: array[0..2] of string = 
  	('Single', 'Double', 'Restore  - Mode');

  vm_radiobutton_caption: array[0..3] of string = (
    'Switch intf', 'Shift intf', 'Delete intf', 'Delete vlan');
  vm_radiobutton_width: array[0..3] of SmallInt = (72, 60, 70, 75);
  vm_button_caption: array[0..1] of string = ('Change', 'Update');

  voip_label_caption: array[0..6] of string = (
  'COM', 'FXS1', 'FXS2', 'URI', 'Username', 'Registered', 'Status');
  voip_label_width: array[3..6] of SmallInt = (75, 125, 65, 38);
  voip_button_caption: array[0..1] of string = ('OK', 'Add');
var
  i, j: SmallInt;
begin

{
  misc_gb_arr: TGroupbox =
    0: Port forward
    1: Vlan
    2: VOIP
}
  for i:= 0 to Length(misc_gb_arr)-1 do
    begin
      misc_gb_arr[i]:= TGroupbox.Create(nil);
      misc_gb_arr[i].Parent:= uHost2.miscTab;
      misc_gb_arr[i].Caption:= misc_gb_caption[i];
      misc_gb_arr[i].Left:= 300 + i*200;
    end;

///////// Port forwarder

  with misc_gb_arr[0] do
    begin
      Top:= 0;
      Left:= 0;
      Width:= Round(uHost2.miscTab.Width / 2);
      Height:= uHost2.miscTab.Height;
    end;


// pf_listview: TListView = pordisuunamise andmed
  pf_listview:= TListview.Create(nil);
  with pf_listview do
    begin
      Parent:= misc_gb_arr[0];
      Top:= 14;
      Left:= 2;
      Height:= misc_gb_arr[0].Height - 28 - Top;
      Width:= misc_gb_arr[0].Width - 4;
      ViewStyle:= vsReport;
      Color:= $00ECE4DD;
      ReadOnly:= True;
      RowSelect:= True;
      MultiSelect:= True;
      HideSelection:= False;
      OnClick:= OnEnterPF;
      OnExit:= OnExitPF;
      for i:= 0 to Length(pf_listview_caption)-1 do
        begin
          Columns.Add.Caption:= pf_listview_caption[i];
          Column[i].Width:= pf_listview_width[i];
        end;
    end;

{
  pf_button: TButton =
    0: New
    1: Delete
    2: Update
}
  for i:= 0 to Length(pf_button)-1 do
    begin
      pf_button[i]:= TButton.Create(nil);
      pf_button[i].Parent:= misc_gb_arr[0];
      pf_button[i].Height:= 22;
      pf_button[i].Top:= misc_gb_arr[0].Height - pf_button[i].Height - 4;
      pf_button[i].Width:= 55;
      pf_button[i].Left:= i * (pf_button[i].Width + 5) + 2;
      pf_button[i].Caption:= pf_button_caption[i];
    end;

    pf_button[0].OnClick:= newPF;
    pf_button[1].OnClick:= deletePF;
    pf_button[2].OnClick:= updatePF;
    pf_button[3].OnClick:= copyPF;

{
  pf_radiobutton: TRadioButton =
    0: All
    1: dynamic
    2: static
}
  for i:= 0 to Length(pf_radiobutton)-1 do
    begin
      pf_radiobutton[i]:= TRadioButton.Create(nil);
      with pf_radiobutton[i] do
        begin
          Parent:= misc_gb_arr[0];
          Width:= pf_radiobutton_width[i];
          Height:= 22;
          Top:= misc_gb_arr[0].Height - pf_button[i].Height - 4;
          Caption:= pf_radiobutton_caption[i];
          ShowHint:= True;
          Hint:= pf_radiobutton_hint[i];
          Tag:= i;
          OnClick:= switchPF;
        end;
    end;
  pf_radiobutton[2].Left:= misc_gb_arr[0].Width - pf_radiobutton[2].Width - 5;
  pf_radiobutton[1].Left:= pf_radiobutton[2].Left - pf_radiobutton[1].Width - 5;
  pf_radiobutton[0].Left:= pf_radiobutton[1].Left - pf_radiobutton[0].Width - 5;

// port forwarder new panel objects
  pf_panel:= TPanel.Create(nil);
  with pf_panel do
    begin
      Parent:= misc_gb_arr[0];
      Width:= pf_listview.Width - 2;
      Height:= pf_listview.Height - 2;
      Top:= pf_listview.Top + 1;
      Left:= pf_listview.Left + 1;
      Color:= $00E6DAD0;
      Visible:= False;
    end;

{
  pf_panel_label: TLabel =
    0: interface
    1: protocol
    2: ip
    3: port in
    4: port out
}
  for i:= 0 to High(pf_panel_label) do
    begin
      pf_panel_label[i]:= TLabel.Create(nil);
      with pf_panel_label[i] do
        begin
          Parent:= pf_panel;
          AutoSize:= False;
          Layout:= tlCenter;
          Caption:= pf_panel_label_caption[i];
          Width:= 50;
          Height:= 21;
          Left:= 5;
          Top:= i * 26 + 6;
        end; // with
    end; // for i loop


{
  pf_panel_combobox: TCombobox =
    0: interface
    1: ip
    2: protocol
}
  for i:= 0 to High(pf_panel_combobox) do
    begin
      pf_panel_combobox[i]:= TCombobox.Create(nil);
      with pf_panel_combobox[i] do
        begin
          Visible:= True;
          Parent:= pf_panel;
          Width:= 125;
          Top:= pf_panel_label[i].Top;
          Left:= pf_panel_label[i].Left + pf_panel_label[i].Width + 5;
          if (i > 1) then
            begin
              Style:= csDropDownList;
              for j:= 0 to Length(pf_panel_combobox_items)-1 do
                Items.Add(pf_panel_combobox_items[j]);
            end;
        end; // with

      // AnimateWindow hack
      ShowWindow(pf_panel_combobox[i].Handle, SW_SHOW);
    end; // for i loop
{
  pf_panel_memo: TMemo =
    0: port in
    1: port out
    2: port list
}
  for i:= 0 to High(pf_panel_memo) do
    begin
      pf_panel_memo[i]:= TMemo.Create(nil);
      with pf_panel_memo[i] do
        begin
          Parent:= pf_panel;
          Height:= 22;
          Width:= pf_panel.Width - 65;
          Top:= i * (Height + 5) + 84;
          Left:= 60;
          Scrollbars:= ssVertical;
        end; // with
      // AnimateWindow hack
      ShowWindow(pf_panel_memo[i].Handle, SW_SHOW);
    end; //
    pf_panel_memo[2].Top:= pf_panel_combobox[1].Top;
    pf_panel_memo[2].Height:= 102;
    pf_panel_memo[2].ScrollBars:= ssBoth;
		ShowWindow(pf_panel_memo[2].Handle, SW_HIDE);

  for i:= 0 to High(pf_panel_radiobutton) do
  	begin
    	pf_panel_radiobutton[i]:= TRadioButton.Create(nil);
      with pf_panel_radiobutton[i] do
      	begin
        	Parent:= pf_panel;
          Top:= pf_panel_combobox[0].Top;
          Width:= 55;
          Left:= 75 * i + (pf_panel_combobox[i].Left + pf_panel_combobox[i].Width) + 15;
          Caption:= pf_panel_radiobutton_caption[i];
          OnClick:= changePfMode;
          Tag:= i;
        end;
      ShowWindow(pf_panel_radiobutton[i].Handle, SW_SHOW);
    end;
  pf_panel_radiobutton[1].Checked:= True;

////////// VLAN interface manager
  with misc_gb_arr[1] do
    begin
      Width:= uHost2.miscTab.Width - misc_gb_arr[0].Width;
      Height:= 70;
      Top:= uHost2.miscTab.Height - Height;
      Left:= misc_gb_arr[0].Left + misc_gb_arr[0].Width;
    end;
{
  vm_combobox: TCombobox =
    0: vlan #1
    1: intf #1
    2: vlan #2
    3: intf #2
}
  j:= 0;
  for i:= 0 to Length(vm_combobox)-1 do
    begin
      vm_combobox[i]:= TCombobox.Create(nil);
      vm_combobox[i].Parent:= misc_gb_arr[1];
      if (i > 1) then
        j:= 20;
      vm_combobox[i].Width:= Round((misc_gb_arr[1].Width) / 4) - 11;
      vm_combobox[i].Top:= 15;
      vm_combobox[i].Left:= i * (vm_combobox[i].Width + 5) + 5 + j;
      vm_combobox[i].Style:= csDropDownList;
      vm_combobox[i].Tag:= i;
      vm_combobox[i].OnChange:= onChangeVM;
    end;

  vm_label:= TLabel.Create(nil);
  with vm_label do
    begin
      Parent:= misc_gb_arr[1];
      AutoSize:= False;
      Alignment:= taCenter;
      Layout:= tlCenter;
      Font.Style:= Font.Style + [fsBold];
      Font.Size:= 10;
      Height:= 20;
      Width:= 20;
      Top:= vm_combobox[1].Top;
      Left:= vm_combobox[2].Left - Width - 2;
      Caption:= '<->';
    end;

{
  vm_radiobutton: TRadiobutton=
    0: Switch interface
    1: Shift interface
    2: Delete interface
    3: Delete vlan
}

  for i:= 0 to Length(vm_radiobutton)-1 do
    begin
      vm_radiobutton[i]:= TRadiobutton.Create(nil);
      vm_radiobutton[i].Parent:= misc_gb_arr[1];
      vm_radiobutton[i].Caption:= vm_radiobutton_caption[i];
      vm_radiobutton[i].Width:= vm_radiobutton_width[i];
      vm_radiobutton[i].Height:= 22;
      vm_radiobutton[i].Top:= vm_combobox[0].Top + vm_combobox[0].Height + 4;
      vm_radiobutton[i].Tag:= i;
      vm_radiobutton[i].OnClick:= switchVM;
      if (i > 0) then
        vm_radiobutton[i].Left:= vm_radiobutton[i-1].Left + (vm_radiobutton[i-1].Width) + 5
      else
        vm_radiobutton[i].Left:= 5;
    end;


{
  vm_button: TButton =
    0: Ok
    1: Update
}
  for i:= 0 to Length(vm_button)-1 do
    begin
      vm_button[i]:= TButton.Create(nil);
      with vm_button[i] do
        begin
          Parent:= misc_gb_arr[1];
          Caption:= vm_button_caption[i];
          Width:= 50;
          Height:= 22;
          Top:= vm_combobox[3].Top + vm_combobox[3].Height + 3;
      end;
  end;
  vm_button[1].Left:= misc_gb_arr[1].Width - vm_button[1].Width - 5;
  vm_button[0].Left:= vm_button[1].Left - vm_button[0].Width - 5;

  vm_button[0].OnClick:= setVM;
  vm_button[1].OnClick:= updateVM;


// VOIP account manager
  with misc_gb_arr[2] do
    begin
      Width:= uHost2.miscTab.Width - misc_gb_arr[0].Width;
      Height:= uHost2.miscTab.Height - misc_gb_arr[1].Height;
      Top:= 0;
      Left:= misc_gb_arr[0].Left + misc_gb_arr[0].Width;
    end;

{
  voip_info_label: TLabel =
    0: COM
    1: FXS1
    2: FXS2
    3: URI
    4: Status/Username
    5: Register/Password
}

  for i:= 0 to Length(voip_info_label)-1 do
    begin
      voip_info_label[i]:= TLabel.Create(nil);
      with voip_info_label[i] do
        begin
          Parent:= misc_gb_arr[2];
          AutoSize:= False;
          Layout:= tlCenter;
          Font.Style:= Font.Style + [fsBold];
          Caption:= voip_label_caption[i];
          Height:= 21;
          Top:= 10;
        end; // with
    end;

  // voip ports left & top
  for i:= 0 to 2 do
    begin
      voip_info_label[i].Left:= 5;
      voip_info_label[i].Top:= (i * (voip_info_label[i].Height + 4)) + 35;
      voip_info_label[i].Width:= 35;
    end;

  for i:= 3 to Length(voip_info_label)-1 do
    begin
      voip_info_label[i].Width:= voip_label_width[i];
      voip_info_label[i].Left:= voip_info_label[i-1].Width + voip_info_label[i-1].Left + 5;
    end;

{ voip_data_label: TLabel =

com:   4 - uri, 5 user
fxs1:  0 - uri, 1 user
fxs2:  2 - uri, 3 user
}
  for i:= 0 to Length(voip_data_label)-1 do
    begin
      voip_data_label[i]:= TLabel.Create(nil);
      with voip_data_label[i] do
        begin
          Parent:= misc_gb_arr[2];
          AutoSize:= False;
          Layout:= tlCenter;
          Width:= voip_label_width[(i mod 2)+3];
          Height:= 21;
          Top:= voip_info_label[i div 2].Top;
          Left:= voip_info_label[(i mod 2)+3].Left;
          Color:= $00D7D5C4;
        end;
    end;

{
  voip_edit: TEdit =
    0: URI
    1: Password

}
  for i:= 0 to Length(voip_edit)-1 do
    begin
      voip_edit[i]:= TEdit.Create(nil);
      with voip_edit[i] do
        begin
          Parent:= misc_gb_arr[2];
          Height:= 21;
          Width:= voip_label_width[(i mod 2)+3];
          Left:= voip_info_label[(i mod 2)+3].Left;
          Top:= voip_info_label[i div 2].Top;
        end;
    end;
    voip_edit[2].Left:= voip_info_label[5].Left;
    voip_edit[2].Width:= 100;

{
  voip_button: TButton =
    0..2: OK
    3..5: add/delete/cancel
}

  for i:= 0 to Length(voip_button)-1 do
    begin
      voip_button[i]:= TButton.Create(nil);
      voip_button[i].Parent:= misc_gb_arr[2];
      voip_button[i].Height:= 22;
      voip_button[i].Width:= (i div 3) * 20 + 25;
      voip_button[i].Caption:= voip_button_caption[i div 3];
      voip_button[i].Top:= voip_info_label[i mod 3].Top;
      voip_button[i].Left:= (misc_gb_arr[2].Width - 123) + (((i div 3) * 28) + 45);
      voip_button[i].Tag:= i;
    end;

  for i:= 0 to 2 do
    begin
      voip_button[i].OnClick:= voip_button1;
      voip_button[i+3].OnClick:= voip_button2;
    end;

{ voip_image: TImage =

com:   0 - status, 1 registered
fxs1:  2 - status, 3 registered
fxs2:  4 - status, 5 registered
}
  for i:= 0 to 5 do
    begin
      voip_image[i]:= TImage.Create(nil);
      with voip_image[i] do
        begin
          Parent:= misc_gb_arr[2];
          Height:= 22;
          Width:= 22;
          Top:= voip_info_label[i div 2].Top - 2;
          Left:= voip_info_label[(i mod 2) + 5].Left + ((Abs(i-1) mod 2) * 15) + 5;
        end;
    end;

  voip_update:= TButton.Create(nil);
  with voip_update do
    begin
      Parent:= misc_gb_arr[2];
      Height:= 21;
      Width:= 60;
      Top:= voip_info_label[3].Top;
      Left:= misc_gb_arr[2].Width - Width - 5;
      Caption:= 'Refresh';
      OnClick:= updateVoip;
    end;

  setToDefault;
  isNewPfOpen:= False;
  pf_button[0].Enabled:= true;
end;


destructor TuMiscTS.Destroy;
var
  i: SmallInt;
begin

// destroy port forward
  uHost2.vabadus(pf_panel_label);
  uHost2.vabadus(pf_panel_combobox);
  uHost2.vabadus(pf_panel_memo);
  uHost2.vabadus(pf_panel_radiobutton);

  try
    pf_listview.Free;
  except on E:Exception do
    uHost2.writeErrorLog('Excpetion with freeing pw_listview: ' + E.Message);
  end;
  uHost2.vabadus(pf_button);
  uHost2.vabadus(pf_radiobutton);
  uHost2.vabadus(pf_panel);

// destroy vlan manager
  uHost2.vabadus(vm_combobox);
  uHost2.vabadus(vm_radiobutton);
  uHost2.vabadus(vm_label);
  uHost2.vabadus(vm_button);

// destroy VOIP
  uHost2.vabadus(voip_info_label);
  uHost2.vabadus(voip_data_label);
  uHost2.vabadus(voip_update);
  uHost2.vabadus(voip_button);
  uHost2.vabadus(voip_edit);

  try
    for i:= 0 to 5 do
      voip_image[i].Free;
  except on E:Exception do
    uHost2.writeErrorLog('Exception on freeing voipImage: ' + E.Message);
  end;


// destroy groupbox
  uHost2.vabadus(misc_gb_arr);
end;

procedure TuMiscTS.setToDefault;
var
  i: SmallInt;
begin
  clearVoipObjects;
  pf_panel.Visible:= False;
  pf_listview.Enabled:= False;
  pf_button[0].Enabled:= False;
  pf_button[1].Enabled:= False;
  pf_radiobutton[0].Checked:= True;
  pf_radiobutton[1].Enabled:= False;
  pf_radiobutton[2].Enabled:= False;

  vm_radiobutton[0].Checked:= True;
  for i:= 0 to Length(vm_radiobutton)-1 do
    vm_radiobutton[i].Enabled:= False;
  for i:= 0 to Length(vm_combobox)-1 do
    uHost2.disGray(vm_combobox[i], False);
                                    
  for i:= 0 to 2 do
    begin
      voip_edit[i].Visible:= False;
      voip_button[i].Visible:= False;
    end;
end;

// andmete korjamisel lülitatakse välja kõik objektid, mis suudavad käivitada oma
// classi andmete korjamist
procedure TuMiscTS.miscUpdate(state: boolean);
var
  i: SmallInt;
begin
  for i:= Low(misc_gb_arr) to High(misc_gb_arr) do
    misc_gb_arr[i].Enabled:= state;
end;

procedure TuMiscTs.updateMiscTab;
begin
	if (uHost2.is_connection_alive) then
  	begin
      pf_button[2].Click;
      vm_button[1].Click;
      voip_update.Click;
    end
  else
    Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

{*********************
  PORT FORWARDER
*********************}

procedure TuMiscTS.activateNewPf(state: boolean = True);
var
  i: SmallInt;
begin
  for i:= 0 to Length(pf_panel_combobox)-1 do
    pf_panel_combobox[i].ItemIndex:= 0;

  pf_button[1].Enabled:= state;

  for i:= 2 to High(pf_button) do
    pf_button[i].Visible:= NOT state;
  for i:= 0 to 2 do
    pf_radiobutton[i].Visible:= NOT state;

  if state then
    begin
      pf_button[0].Caption:= 'Cancel';
      pf_button[1].Caption:= 'Add';
    end
  else
    begin
      pf_button[0].Caption:= 'New';
      pf_button[1].Caption:= 'Delete';
    end;
end;

procedure TuMiscTS.changePfMode(Sender: TObject);
var
	i: SmallInt;
begin
	try
  	pf_panel_label[1].Caption:= 'IP address';
    pf_panel_label[3].Caption:= 'Port IN';
    pf_panel_memo[0].Height:= 22;
    for i:= 1 to 2 do
      begin
        ShowWindow(pf_panel_combobox[i].Handle, SW_SHOW);
        ShowWindow(pf_panel_memo[i-1].Handle, SW_SHOW);
      end;
    ShowWindow(pf_panel_memo[2].Handle, SW_HIDE);
    for i:= 2 to High(pf_panel_label) do
      pf_panel_label[i].Visible:= True; 
  
  	case (TRadioButton(Sender).Tag) of
    	0: begin
        	for i:= 1 to 2 do
          	ShowWindow(pf_panel_combobox[i].Handle, SW_SHOW);
            
          pf_panel_label[High(pf_panel_label)].Visible:= False;
        	pf_panel_label[3].Caption:= 'Port';            
          
          ShowWindow(pf_panel_memo[0].Handle, SW_SHOW);
          ShowWindow(pf_panel_memo[1].Handle, SW_HIDE);
          ShowWindow(pf_panel_memo[2].Handle, SW_HIDE);
			    pf_panel_memo[0].Height:= 49;
        end;
      2:
      	begin
        	for i:= 1 to 2 do
          	begin
	            ShowWindow(pf_panel_combobox[i].Handle, SW_HIDE);
              ShowWindow(pf_panel_memo[i-1].Handle, SW_HIDE);
            end;
            
					pf_panel_label[1].Caption:= 'NAT list';
          for i:= 2 to High(pf_panel_label) do
	          pf_panel_label[i].Visible:= False;
            
          ShowWindow(pf_panel_memo[2].Handle, SW_SHOW);
        end;
    end;
  except on E:Exception do
  	uHost2.writeErrorLog('Exception @ changing PF mode: ' + E.Message);
  end;
end;

procedure TuMiscTS.newPF(Sender: TObject);
var
  Flags: DWORD;
  Handle: HWND;
begin
  Handle:= pf_panel.Handle;
  if isNewPfOpen then
    begin
      Flags:= AW_HIDE OR AW_VER_NEGATIVE;
      activateNewPf(False);
    end
  else
    begin
      Flags:= AW_ACTIVATE OR AW_VER_POSITIVE;
      activateNewPf(True);
    end;

  isNewPfOpen:= NOT isNewPfOpen;
  Flags:= Flags OR AW_SLIDE;
  AnimateWindow(Handle, 100, Flags);
end;

procedure TuMiscTS.deletePF(Sender: TObject);
var
  vastus: string;
  tulemus: string;
  errCnt: SmallInt;
  errLog: string;
  i: SmallInt;
begin
  errCnt:= 0;
  errLog:= '';
  if (pf_button[1].Caption = 'Add') then
    begin
      if (Length(pf_panel_combobox[0].Text) = 0) then
        begin
          inc(errCnt);
          errLog:= 'Interface is missing';
        end;

      if (pf_panel_radiobutton[2].Checked = False) then
	      if (uHost2.isIPValid(pf_panel_combobox[1].Text, tulemus) = False)  AND (errCnt = 0) then
  	      begin
    	      inc(errCnt);
      	    errLog:= 'Invalid IP address';
        	end;

      if (errCnt = 0) then
        begin                      
        	if pf_panel_radiobutton[0].Checked then
          	begin
            	sendNatData(True);
            end // single mode
          else if pf_panel_radiobutton[1].Checked then
          	begin
		          if checkBeforeSend(vastus) then
    		        sendNatData
        		  else
            		Application.MessageBox(PAnsiChar('Unable to add port fowarding' +
		              #13#10 + 'Error: ' + vastus), 'Laiskuss annab teada', MB_ICONERROR);
            end // double mode
          else if pf_panel_radiobutton[2].Checked then
          	begin
            	restoreNatData;
            end; // restore mode
        end
      else
        Application.MessageBox(PAnsiChar('Unable to add port fowarding' +
          #13#10 + 'Error: ' + errLog), 'Laiskuss annab teada', MB_ICONERROR);

      for i:= 0 to High(pf_panel_memo) do
      	pf_panel_memo[i].Clear;  
    end // ADD
  else if (pf_button[1].Caption= 'Delete') then
    begin
    	if MessageDlg('Delete porf forward?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      	begin
          pf_button[1].Enabled:= False;
		    	deleteNatData;
        end;
    end;
end;

procedure TuMiscTS.updatePF(Sender: TObject);
var
  i: SmallInt;
begin
  if (uHost2.is_connection_alive) then
    begin
      uHost2.st_loadInfo.Caption:= ' Updating NAT maplist...';
      uHost2.disGray(pf_listview, True);
      uHost2.haltOnRefresh(False);
      pf_listview.Clear;
      pf_listview.Color:= $00ECE4DD;

      if (uHost2.statusTs.router_type = '') then
        uHost2.statusTs.getDevice;
      if (uHost2.statusTs.connectionIntf = '') then
        uHost2.statusTs.getConType;

      uHost2.statusTs.getIpAdre;
      getNatData;

      pf_button[0].Enabled:= True;
      pf_radiobutton[0].Checked:= True;
      pf_radiobutton[1].Enabled:= True;
      pf_radiobutton[2].Enabled:= True;
      for i:= 0 to 1 do
        begin
          pf_panel_combobox[i].Items.Clear;
          pf_panel_memo[i].Clear;
        end;


      try
        for i:= 0 to Length(uHost2.statusTs.ipArr)-1 do
          pf_panel_combobox[1].Items.Add(uHost2.statusTs.ipArr[i].ip_adre);
        pf_panel_combobox[0].Items.Add(uHost2.statusTs.connectionIntf);

        for i:= 0 to 2 do
          pf_panel_combobox[i].ItemIndex:= 0;
      except on E:Exception do
        uHost2.writeErrorLog('Exception @ populating new pf_panel: ' + E.Message);
      end;

      uHost2.haltOnRefresh(True);
      uHost2.st_loadInfo.Caption:= ' NAT maplist updated...';
    end
  else
    Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

procedure TuMiscTS.copyPF(Sender: TObject);
var
  i: SmallInt;
  selItem : TListItem;
  subItem : TStrings; // listView item'i andmed
  s: string;
begin
  if (Sender is TButton) then
    if (pf_listview.Items.Count > 0) then
      begin
        s:= '';
        for i:= 0 to pf_listview.Items.Count-1 do
          begin
            selItem:= pf_listview.Items.Item[i];
            if (selItem.Selected) then
              begin
                subItem:= pf_listview.Items.Item[i].SubItems;
                s:= s + Format('IN: %s:%-13s OUT: %-13s Prot: %3s Flag: %s',
                  [subItem[4], subItem[3], subItem[2], subItem[1], subItem[5]])+#13#10;
              end; // selected
          end; // for i loop
        uHost2.clp.AsText:= s;
      end
    else // items.count > 0
      Application.MessageBox('Nat maplist is empty...', 'Laiskuss annab teada', MB_ICONINFORMATION);
end;

procedure TuMiscTS.switchPF(Sender: TObject);
begin
  if (Sender is TRadioButton) then
    try
      pf_listview.Items.Clear;
      loadPFData(TRadioButton(Sender).Tag);
    except on E:Exception do
      uHost2.writeErrorLog('Exception @ loadPFData: ' + E.Message);
    end;
end;

procedure TuMiscTS.loadPFData(tag: SmallInt);
var
  i: SmallInt;
  lItem: TListItem;
  pfFlag: string;
begin
  if (tag = 0) then // Show all ports
    begin
      for i:= 0 to Length(pfArr)-1 do
        with pf_listview do
          begin
            lItem:= Items.Add;
            lItem.Caption:= pfArr[i].pfID;
            lItem.SubItems.Add(pfArr[i].pfIntf);
            lItem.SubItems.Add(pfArr[i].pfProt);
            lItem.SubItems.Add(pfArr[i].pfPortOut);
            lItem.SubItems.Add(pfArr[i].pfPortIn);
            lItem.SubItems.Add(pfArr[i].pfIpAddr);
            lItem.SubItems.Add(pfArr[i].pfFlag);
          end; // with
    end // tag = 0
  else if (tag > 0) then // show dynamic OR static ports only
    begin
      if (tag = 1) then
        pfFlag:= 'Dynamic'
      else
        pfFlag:= 'Static';
      for i:= 0 to Length(pfArr)-1 do
        if ((pfArr[i].pfFlag = pfFlag) AND (AnsiPos('192.168', pfArr[i].pfIpAddr) > 0)) then
          with pf_listview do
            begin
              lItem:= Items.Add;
              lItem.Caption:= pfArr[i].pfID;
              lItem.SubItems.Add(pfArr[i].pfIntf);
              lItem.SubItems.Add(pfArr[i].pfProt);
              lItem.SubItems.Add(pfArr[i].pfPortOut);
              lItem.SubItems.Add(pfArr[i].pfPortIn);
              lItem.SubItems.Add(pfArr[i].pfIpAddr);
              lItem.SubItems.Add(pfArr[i].pfFlag);
            end; // with
    end; // tag > 0
end;

procedure TuMiscTS.getNatData;
var
  i, pfCnt: SmallInt;
  temp, dummy, dummy2, flag: string;
  lItem: TListItem;
  blokkid: TStrArr;
  tempBlokk: TStrArr;
begin
  blokkid:= nil;
  tempBlokk:= nil;
  pfArr:= nil;
  SetLength(pfArr, 0);
  try
    uHost2.statusTs.sendRequest(':nat maplist expand enabled');
    for i:= 0 to uHost2.dataBuffer.Count-1 do
      begin
        // in case of emergency, use brake
        if (i > uHost2.dataBuffer.Count) then
          break;
        temp:= uHost2.dataBuffer.Strings[i];
        if ((AnsiPos('NAPT', temp) > 0) OR (AnsiPos('NAT', temp) > 0)) AND (AnsiPos('Description', temp) = 0) then
          begin
            dummy2:= '';
            pfCnt:= Length(pfArr);
            SetLength(pfArr, pfCnt+1);
            blokkid:= uMain.explode(temp, ' ');
// lItems:= {'ID' = 0, 'Intf', 'Prot', 'Port out', 'Port in', 'IP address', 'Flag'}
            with pf_listview do
              begin
                lItem:= Items.Add;
                lItem.Caption:= blokkid[0];
                lItem.SubItems.Add(blokkid[2]);
                pfArr[pfCnt].pfID:= blokkid[0];
                pfArr[pfCnt].pfIntf:= blokkid[2];

                // protocol
                dummy:= uHost2.dataBuffer.Strings[i+3];
                dummy2:= Trim(Copy(dummy, AnsiPos('.. ', dummy)+3, MaxInt));
                lItem.SubItems.Add(dummy2);
                pfArr[pfCnt].pfProt:= dummy2;

                // port out
                if (AnsiPos(':', blokkid[3]) > 0) then
                  begin
                    tempBlokk:= explode(blokkid[3], ':');
                    lItem.SubItems.Add(tempblokk[1]);
                    pfArr[pfCnt].pfPortOut:= tempBlokk[1];
                  end
                else
                  begin
                    lItem.SubItems.Add('N/A');
                    pfArr[pfCnt].pfPortOut:= 'N/A';
                  end;

                // port in
                if (AnsiPos(':', blokkid[4]) > 0) then
                  begin
                    tempBlokk:= explode(blokkid[4], ':');
                    lItem.SubItems.Add(tempblokk[1]);
                    lItem.SubItems.Add(tempBlokk[0]);
                    pfArr[pfCnt].pfPortIn:= tempBlokk[1];
                    pfArr[pfCnt].pfIpAddr:= tempBlokk[0];
                  end
                else
                  begin
                    lItem.SubItems.Add('N/A');
                    lItem.SubItems.Add(blokkid[4]);
                    pfArr[pfCnt].pfPortIn:= 'N/A';
                    pfArr[pfCnt].pfIpAddr:= blokkid[4];
                  end;

                // flag
                  dummy:= uHost2.dataBuffer.Strings[i+4];
                  flag:= Trim(Copy(dummy, AnsiPos('.. ', dummy)+3, MaxInt));
                  if (AnsiPos('Static', flag) > 0) then
                    begin
                      lItem.SubItems.Add('Static');
                      pfArr[pfCnt].pfFlag:= 'Static';
                    end
                  else
                    begin
                      lItem.SubItems.Add('Dynamic');
                      pfArr[pfCnt].pfFlag:= 'Dynamic';
                    end;
              end;
          end; // AnsiPos NAT + NAPT    
      end; // for i loop

  except on E:Exception do
    uHost2.writeErrorLog('Exception @ updatePF: ' + E.Message);
  end;
end;

procedure TuMiscTS.sendNatData(single: boolean = False);
var
  i: SmallInt;
  in_port: TStrArr;
  out_port: TStrArr;
  maplist, prot: string;
begin
  in_port:= nil;
  out_port:= nil;
	if uHost2.is_connection_alive then
    begin
      try
      	uHost2.haltOnRefresh(False);
        in_port:= explode(pf_panel_memo[0].Text, ';');
        if single then
	        out_port:= in_port //explode(pf_panel_memo[0].Text, ';')
        else          
	        out_port:= explode(pf_panel_memo[1].Text, ';');

        maplist:= '';
        uHost2.whereDoYouGo:= 1;

        case pf_panel_combobox[2].ItemIndex of
        	0: prot:= '';
          1: prot:= ' protocol tcp';
          2: prot:= ' protocol udp';
        end;
      
        uHost2.st_loadInfo.Caption:= ' Adding new port forward...';
        for i:= 0 to Length(in_port)-1 do
          begin
            maplist:= 'nat mapadd type napt intf ' +
              pf_panel_combobox[0].Text + // interface
              prot + // protocol
              ' inside_addr ' + pf_panel_combobox[1].Text + // ip address
              ' inside_port ' + in_port[i] + ' outside_port ' + out_port[i] + // ports
              ' mode=auto';

            uHost2.writeLn_to_terminal(maplist);
          end;

        pf_listview.Clear; 
        pf_radiobutton[0].Checked:= True;          
        pf_button[0].Click;
        uHost2.st_loadInfo.Caption:= ' Updating NAT maplist...';
        getNatData;
        uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
        uHost2.statusTS.sendRequest(':saveall');
        uHost2.st_loadInfo.Caption:= ' NAT maplist updated...';
        uHost2.haltOnRefresh(True);
      except on E:Exception do
        uHost2.writeErrorLog('Error @ sendNatData: ' + E.Message);
      end;
    end
	else
		Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONERROR);
end;

procedure TuMiscTS.restoreNatData;
var
	i: SmallInt;
  blokkid: TStrArr;
  prot, in_port, out_port, dummy: string;
begin
	blokkid:= nil;
	try
  	if uHost2.is_connection_alive then
    	begin
				uHost2.haltOnRefresh(False);
        for i:= 0 to pf_panel_memo[2].Lines.Count-1 do
        	begin
          	blokkid:= explode(pf_panel_memo[2].Lines[i], ':');
            
            dummy:= Trim(blokkid[4]);
            prot:= ' protocol ' + Trim(Copy(dummy, 1, AnsiPos(' ', dummy)));

            if (AnsiContainsStr(prot, 'any')) then
            	prot:= '';

            dummy:= Trim(blokkid[2]);
            in_port:= Trim(Copy(dummy, 1, AnsiPos(' ', dummy)));
            in_port:= AnsiReplaceStr(in_port, '[', '');
            in_port:= AnsiReplaceStr(in_port, ']', '');

            dummy:= Trim(blokkid[3]);
            out_port:= Trim(Copy(dummy, 1, AnsiPos(' ', dummy)));
            out_port:= AnsiReplaceStr(out_port, '[', '');
            out_port:= AnsiReplaceStr(out_port, ']', '');
                        
            uHost2.writeLn_to_terminal('nat mapadd type napt intf ' +
            	pf_panel_combobox[0].Text +  // interface
              prot + // protocol
              ' inside_addr ' + blokkid[1] + // ip address
              ' inside_port ' + in_port + // port IN
              ' outside_port ' + out_port + // port OUT
              ' mode=auto');
          end; // for i loop

        pf_listview.Clear; 
        pf_radiobutton[0].Checked:= True;           
        pf_button[0].Click;
        uHost2.st_loadInfo.Caption:= ' Updating NAT maplist...';
        getNatData;
        uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
        uHost2.statusTS.sendRequest(':saveall');
        uHost2.st_loadInfo.Caption:= ' NAT maplist updated...';
				uHost2.haltOnRefresh(True);
      end
    else
    	Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONERROR);
  except on E:Exception do
  	uHost2.writeErrorLog('Exception @ restoring Nat data: ' + E.Message);
  end;
end;

procedure TuMiscTS.deleteNatData;
var
	i: SmallInt;
  selItem : TListItem;
begin
	if uHost2.is_connection_alive then
  	begin
      try
      	uHost2.haltOnRefresh(False);
      	if (pf_listview.Items.Count > 0) then
        	begin
          	uHost2.whereDoYouGo:= 1;
          	uHost2.st_loadInfo.Caption:= ' Deleting port forward...';
          	for i:= pf_listview.Items.Count-1 downto 0 do
            	begin
              	selItem:= pf_listview.Items.Item[i];
                if (selItem.Selected) then
                	begin
                    uHost2.writeLn_to_terminal(':nat mapdelete intf ' + selItem.SubItems[0] +
                    	' index ' + selItem.Caption);                  
                  end; // selItem selected              
              end; // for i loop
		        pf_radiobutton[0].Checked:= True;
			      pf_listview.Clear;
          	uHost2.st_loadInfo.Caption:= ' Updating NAT maplist...';
            getNatData;
            uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
            uHost2.statusTS.sendRequest(':saveall');
            uHost2.st_loadInfo.Caption:= ' NAT maplist updated...'; 
		      	uHost2.haltOnRefresh(True);         
          end; // items.Count > 0
      except on E:Exception do
      	uHost2.writeErrorLog('Error @ deleteNatData: ' + E.Message);
      end;  
    end
	else
		Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONERROR);
end;

procedure TuMiscTS.OnEnterPF(Sender: TObject);
begin
	if (Sender is TListView) then
  	try
    	pf_button[1].Enabled:= True;    
    except on E:Exception do
    	uHost2.writeErrorLog('Exception @ selecting pf_listview: ' + E.Message);
    end;
end;

procedure TuMiscTS.OnExitPF(Sender: TObject);
begin
	if (Sender is TListView) then
  	try
    	//pf_button[1].Enabled:= False;    
    except on E:Exception do
    	uHost2.writeErrorLog('Exception @ selecting pf_listview: ' + E.Message);
    end;
end;

function TuMiscTS.checkBeforeSend(var errorLog: string): boolean;
var
  tulemus: boolean;
  in_port: TStrArr;
  out_port: TStrArr;
  multi_InPort: TStrArr;
  multi_OutPort: TStrArr;
  mp_cnt1, mp_cnt2: SmallInt;
  i: SmallInt;
  errCnt: SmallInt;

  function isMultiPort(sisend: string): boolean;
  begin
    if (AnsiPos('-', sisend) > 0) then
      Result:= True
    else
      Result:= False;
  end;

begin
  tulemus:= False;
  in_port:= nil;
  out_port:= nil;

  multi_InPort:= nil;
  multi_OutPort:= nil;
  try
    in_port:= explode(pf_panel_memo[0].Text, ';');
    out_port:= explode(pf_panel_memo[1].Text, ';');
    errorLog:= '';
    errCnt:= 0;

    if (Length(in_port[0]) = 0) then
      begin
        errorLog:= 'Inside port missing';
        inc(errCnt);
      end
    else if (Length(out_port[0]) = 0) then
      begin
        errorLog:= 'Outside port missing';
        inc(errCnt);
      end
    else
      begin
        if (Length(in_port) <> Length(out_port)) then
          begin
            errorLog:= 'Insise & outside ports mismatch';
          inc(errCnt);
          end;
      end;

    if (errCnt = 0) then
      begin
        for i:= 0 to Length(in_port)-1 do
          if (NOT isInt(in_port[i])) then
            begin
              if (isMultiPort(in_port[i])) then
                begin
                  mp_cnt1:= Length(multi_InPort);
                  SetLength(multi_InPort, mp_cnt1+1);
                  multi_InPort[mp_cnt1]:= in_port[i];
                end
              else
                begin
                  errorLog:= 'incorrect inside port: "' + in_port[i] + '"';
                  inc(errCnt);
                  break;
                end;
            end
          else
            begin
              if (StrToInt(in_port[i]) > 65535) then
                begin
                  errorLog:= 'invalid inside port: "' + in_port[i] + '".' +
                    ' Port must be from 1 to 65535';
                  inc(errCnt);
                  break;
                end;
            end;

        for i:= 0 to Length(out_port)-1 do
          if (NOT isInt(out_port[i])) then
            begin
              if (isMultiPort(out_port[i])) then
                begin
                  mp_cnt2:= Length(multi_OutPort);
                  SetLength(multi_OutPort, mp_cnt2+1);
                  multi_OutPort[mp_cnt2]:= out_port[i];
                end
              else
                begin
                  errorLog:= 'incorrect outside port: "' + out_port[i] + '"';
                  inc(errCnt);
                  break;
                end;
            end
          else
            begin
              if (StrToInt(out_port[i]) > 65535) then
                begin
                  errorLog:= 'invalid outside port: "' + out_port[i] + '".' +
                    ' Port must be from 1 to 65535';
                  inc(errCnt);
                  break;
                end;
            end;
      end;

    if (Length(multi_InPort) <> Length(multi_OutPort)) then
      begin
        inc(errCnt);
        errorLog:= 'Inside & outside multi ports mismatch';
      end;

    if (errCnt = 0) then
      begin
        for i:= 0 to Length(multi_InPort)-1 do
          begin
            if (multi_InPort[i] <> multi_OutPort[i]) then
              begin
                inc(errCnt);
                errorLog:= 'inside vs outside portrange mismatch: [' + multi_InPort[i] +
                  '] - [' + multi_OutPort[i] + ']';
                break;
              end; // port comp
          end; // for i loop
      end; // errCnt

    multi_InPort:= nil;
    multi_OutPort:= nil;
    in_port:= nil;
    out_port:= nil;

    if (errCnt = 0) then
      tulemus:= True;
  except on E:Exception do
    uHost2.writeErrorLog('Error @ checking Nat data: ' + E.Message);
  end;
  Result:= tulemus;
end;





{*********************************************************************
      VLAN MANAGER
*********************************************************************}

procedure TuMiscTS.updateVM(Sender: TObject);
var
  i: SmallInt;
begin
  if (uHost2.is_connection_alive) then
    begin
      uHost2.haltOnRefresh(False);
      uHost2.st_loadInfo.Caption:= ' Updating VLAN data...';
      getVlanData;
      for i:= 0 to Length(vm_radiobutton)-1 do
        vm_radiobutton[i].Enabled:= True;
      vm_radiobutton[0].Checked:= True;
      uHost2.haltOnRefresh(True);
      uHost2.st_loadInfo.Caption:= ' VLAN data updated...';
    end
  else
    Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
end;

procedure TuMiscTS.setVM(Sender: TObject);
var
    i: SmallInt;
  kumb: SmallInt;

  untag1, untag2, intf1, intf2, aIntf1, aIntf2: string;
  leftover: array[0..3] of string;

  procedure refreshVLAN;
  begin
    uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
    uHost2.statusTs.sendRequest(':saveall', False);
    vm_button[1].Click;
    uHost2.st_loadInfo.Caption:= ' VLAN data updated...';   
  end;
begin
    kumb:= -1;
    try
        for i:= 0 to High(vm_radiobutton) do
          if vm_radiobutton[i].Checked then
            begin
              kumb:= i;
            break;
          end;
  except on E:Exception do
      uHost2.writeErrorLog('Exception @ determing vm_radiobutton: ' + E.Message);
  end;

    try

    // korjame VLAN valitud andmed combobox'dest
      for i:= 0 to 3 do
        leftover[i]:= vm_combobox[i].Items[vm_combobox[i].ItemIndex];

    
  aIntf1:= leftover[1]; // vlanName from
  aIntf2:= leftover[3]; // vlanName to

// check if intf is untagged
  if (AnsiPos('*', aIntf1) > 0) then
      begin
        intf1:= AnsiReplaceStr(aIntf1, '*', '');
      intf2:= AnsiReplaceStr(aIntf2, '*', '');
      untag1:= ' untagged enabled';
    end
  else
      begin
        intf1:= aIntf1;
      untag1:= '';
    end;

// check if intf is untagged
  if (AnsiPos('*', aIntf2) > 0) then
      begin
      intf2:= AnsiReplaceStr(aIntf2, '*', '');
      untag2:= ' untagged enabled';
    end
  else
      begin
        intf2:= aIntf2;
      untag2:= '';
    end;
  
  except on E:Exception do
      uHost2.writeErrorLog('Exception @ populating leftovers: ' + E.Message);
  end;
    
    if (uHost2.is_connection_alive) then
      try
        uHost2.whereDoYouGo:= 2;
        case kumb of
          -1:
            begin
              Application.MessageBox('setVM has encountered a system error!', 'Laiskuss annab teada', MB_ICONERROR);
          end;
          0:
            begin
              if MessageDlg('Switch "' + intf1 + '" from "' + leftover[0] + 
                '" with "' + intf2 + '" from "' + leftover[2] + '" ?', mtWarning, mbOKCancel, 0) = mrOK then
                  begin
                    uHost2.st_loadInfo.Caption:= ' Request sent, please wait...';
                    uHost2.writeLn_to_terminal(':eth bridge vlan ifadd name ' +
                        leftover[2] + ' intf ' + intf1 + untag1);
                    uHost2.writeLn_to_terminal(':eth bridge vlan ifadd name ' +
                        leftover[0] + ' intf ' + intf2 + untag2);
                  uHost2.writeLn_to_terminal(':eth bridge vlan ifdelete name ' + 
                      leftover[0] + ' intf ' + intf1);
                  uHost2.writeLn_to_terminal(':eth bridge vlan ifdelete name ' + 
                      leftover[2] + ' intf ' + intf2);      
                  refreshVLAN;  
                end; // agreed to switch          
          end;

//****************************************************************************** 
                1:
            begin
              if MessageDlg('Shift "' + intf1 + '" from "' + leftover[0] + 
                '" to "' + leftover[2] + '" ?', mtWarning, mbOKCancel, 0) = mrOK  then
              begin
                  uHost2.st_loadInfo.Caption:= ' Request sent, please wait...';
                uHost2.writeLn_to_terminal(':eth bridge vlan ifadd name ' + 
                    leftover[2] + ' intf ' + intf1 + untag1);
                uHost2.writeLn_to_terminal(':eth bridge vlan ifdelete name ' +
                    leftover[0] + ' intf ' + intf1);
                refreshVLAN;
              end; // agreed to shift          
          end;

//******************************************************************************           
                2:
            begin
            if MessageDlg('Delete interface "' + intf1 + '" from "' + leftover[0] + '" ?',
                mtWarning, mbOkCancel, 0) = mrOK then
              begin
                                uHost2.st_loadInfo.Caption:= ' Request sent, please wait...';
                uHost2.writeLn_to_terminal(':eth bridge vlan ifdelete name ' +
                    leftover[0] + ' intf ' + intf1);
                refreshVLAN;
              end;
          end;

//****************************************************************************** 
                3:
            begin
            if MessageDlg('Delete vlan "' + leftover[0] + '" ?',
                mtWarning, mbOkCancel, 0) = mrOK then
              begin
                                uHost2.st_loadInfo.Caption:= ' Request sent, please wait...';
                uHost2.writeLn_to_terminal(':eth vlan delete name ' + leftover[0]);
                refreshVLAN;
              end;
          end;
            end; // case of
        
    except on E:Exception do
        uHost2.writeErrorLog('Exception @ setVM (' + IntToStr(kumb) + '): ' + E.Message);
    end
  else
    Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
  uHost2.whereDoYouGo:= 1;
end;


procedure TuMiscTS.getVlanData;
var
  i, c, found, vCnt, v, iCnt: SmallInt;
  temp: string;
  vlans: TStrArr;
begin
  vlans:= nil;
  try
    for c:= 0 to Length(vm_combobox)-1 do
      begin
        uHost2.disGray(vm_combobox[c], True);
        vm_combobox[c].Clear;
      end;
    vm_radiobutton[0].Checked:= True;
    vm_label.Caption:= '<->';
    found:= -1;

    SetLength(vlanArr, 0);
    vlanArr:= nil;


    uHost2.statusTs.sendRequest(':eth bridge vlan iflist');
    for i:= 0 to uHost2.dataBuffer.Count-1 do
      begin
        // in case of emergency, use brake
        if (i > uHost2.dataBuffer.Count) then
          break;
        if (AnsiPos('Vid', uHost2.dataBuffer.Strings[i]) > 0) then
          begin
            found:= i+2;
            break;
          end;
      end; // for i loop

    if (found > -1) then
      begin
        temp:= uhost2.dataBuffer.Strings[found];
        repeat
          vlans:= uMain.explode(temp, ' ');

          // vlan populating
          vCnt:= Length(vlanArr);
          SetLength(vlanArr, vCnt+1);
          vlanArr[vCnt].vlanNimi:= vlans[1];

          // intf populating
          for v:= 2 to Length(vlans)-1 do
            begin
              iCnt:= Length(vlanArr[vCnt].intfNimi);
              SetLength(vlanArr[vCnt].intfNimi, iCnt+1);
              if (AnsiPos(',', vlans[v]) > 0) then
                vlanArr[vCnt].intfNimi[iCnt]:= Copy(vlans[v], 1, AnsiPos(',', vlans[v])-1)
              else
                vlanArr[vCnt].intfNimi[iCnt]:= vlans[v];
            end;    

          inc(found);
          temp:= uhost2.dataBuffer.Strings[found];
        until ((AnsiPos('lks_lopp', temp) > 0) OR (found = uHost2.dataBuffer.Count-1));  
      end; // found

// sisestame Vlan'i nimed combobox'i 0 ja 2
  for i:= 0 to Length(vlanArr)-1 do
    begin
      vm_combobox[0].Items.Add(vlanArr[i].vlanNimi);
      vm_combobox[2].Items.Add(vlanArr[i].vlanNimi);
    end; // vl_combobox[0] & [2] population

// sisestame interface'd (vlanArr[0]) combobox'i 1 ja 3
  for i:= 0 to Length(vlanArr[0].intfNimi)-1 do
    begin
      vm_combobox[1].Items.Add(vlanArr[0].intfNimi[i]);
      vm_combobox[3].Items.Add(vlanArr[0].intfNimi[i]);
    end; // vl_combobox[1] & [3] population

  for i:= 0 to Length(vm_combobox)-1 do
    vm_combobox[i].ItemIndex:= 0;

  except on E:Exception do
    uHost2.writeErrorLog('Exception @ updateVM: ' + E.Message);
  end;
end;

procedure TuMiscTS.onChangeVM(Sender: TObject);
var
  i, selRB: SmallInt;
  valitud: SmallInt;
  vmText: array[0..3] of string;
begin
  selRB:= 0;
  try
    if (Sender is TCombobox) then
      begin
        valitud:= TCombobox(Sender).ItemIndex;
        if (TCombobox(Sender).Tag = 0) then
          begin
            vm_combobox[1].Clear;
            if (Length(vlanArr[valitud].intfNimi) = 0) then
              vm_combobox[1].Items.Add('Empty')
            else
              for i:= 0 to Length(vlanArr[valitud].intfNimi)-1 do
                vm_combobox[1].Items.Add(vlanArr[valitud].intfNimi[i]);
            vm_combobox[1].ItemIndex:= 0;
          end // Tag = 0
        else if (TCombobox(Sender).Tag = 2) then
          begin
            vm_combobox[3].Clear;
            if (Length(vlanArr[valitud].intfNimi) = 0) then
              vm_combobox[3].Items.Add('Empty')
            else
              for i:= 0 to Length(vlanArr[valitud].intfNimi)-1 do
                vm_combobox[3].Items.Add(vlanArr[valitud].intfNimi[i]);
            vm_combobox[3].ItemIndex:= 0;
          end; // Tag = 2

// Change radiobutton state
// valides combobox'i kontrollitakse konfliktseid vlan'e ja intf'e
        for i:= 0 to 3 do
          vmText[i]:= vm_combobox[i].Items[vm_combobox[i].ItemIndex];

        for i:= 0 to misc_gb_arr[1].ControlCount-1 do
          if (misc_gb_arr[1].Controls[i] is TRadioButton) then
            begin
              selRB:= misc_gb_arr[1].Controls[i].Tag;
              if vm_radiobutton[selRB].Checked then
                break;
            end; // is radioButton

        checkRB(selRB);

      end; // Sender
  except on E:Exception do
    uHost2.writeErrorLog('Exception @ changing vm_combo: ' + E.Message);
  end;
end;

procedure TuMiscTS.switchVM(Sender: TObject);
begin
  if (Sender is TRadiobutton) then
    checkRB(TRadiobutton(Sender).Tag);
end;

procedure TuMiscTS.checkRB(kumb: SmallInt);
const
  vmbc: array[0..3] of string = (
    'Switch', 'Shift', 'Delete', 'Delete');
var
  i, j: SmallInt;
  vmText: array[0..3] of string;
begin
  vm_button[0].Enabled:= True;
  for i:= 0 to Length(vm_combobox)-1 do
    uHost2.disGray(vm_combobox[i], True);
  for i:= 0 to 3 do
    vmText[i]:= vm_combobox[i].Items[vm_combobox[i].ItemIndex];

  vm_button[0].Caption:= vmbc[kumb];
  case kumb of
    0: // switch interface
      begin
        vm_label.Caption:= '<->';
        if (vmText[0] = vmText[2]) then  // sama VLAN'i nime konflikt
          vm_button[0].Enabled:= False;
      end; // case of 0

    1: // shift interface
      begin
        vm_label.Caption:= '->';
        uHost2.disGray(vm_combobox[3], False);

        if (vmText[0] = vmText[2]) then // sama VLAN'i nime konflikt
          vm_button[0].Enabled:= False
        else // kui VLAN'd on korras siis kontroll, et ethport intf ei oleks uues kohas juba olemas
          begin
            for i:= 0 to vm_combobox[3].Items.Count -1 do
              if (vmText[1] = vm_combobox[3].Items[i]) then
                begin
                  vm_button[0].Enabled:= False;
                  break;
                end; // if equal
          end; // if VLAN = OK
      end; // case of 1

    2: // delete interface
      begin
        vm_label.Caption:= 'x';
        for i:= 2 to 3 do
          uHost2.disGray(vm_combobox[i], False);
        vm_button[0].Enabled:= False;
        if (AnsiPos('ethport', vmText[1]) > 0) then
          begin
            for i:= 0 to Length(vlanArr)-1 do
              begin
              if (i <> vm_combobox[0].ItemIndex) then
                for j:= 0 to Length(vlanArr[i].intfNimi)-1 do
                  begin
                    if (vmText[1] = vlanArr[i].intfNimi[j]) then
                      begin
                        vm_button[0].Enabled:= True;
                        break;
                      end; // if equal
                  end; // for j loop
              end; // for i loop
          end; // AnsiPos
      end; // case of 2

    3: // delete vlan
      begin
        vm_label.Caption:= 'X';
        for i:= 1 to 3 do
          uHost2.disGray(vm_combobox[i], False);
      end; // case of 3
  end; // switch
end;




{*********************************************************************
      VOIP DATA MANAGER
*********************************************************************}

procedure TuMiscTS.updateVoip(Sender: TObject);
begin
  if (Sender is TButton) then
    begin
      if (uHost2.is_connection_alive) then
        begin
          uHost2.st_loadInfo.Caption:= ' Updating VoIP info...';
          uHost2.haltOnRefresh(False);
          clearVoipObjects;

          if uHost2.statusTs.router_type = '' then
            uHost2.statusTs.get_router_type;
          if uHost2.statusTs.soft_version = '' then
            uHost2.statusTs.get_software_version;

          if (uHost2.statusTs.router_type = 'TG789vn')  OR (uHost2.statusTs.soft_version = '8.C.D.5') OR (uHost2.statusTs.soft_version = '8.C.D.9')  then
            getVoipData789
          else
            getVoipData;
          fillVoipObjects;
          uHost2.st_loadInfo.Caption:= ' VoIP info updated';
          uHost2.haltOnRefresh(True);
        end
      else
        Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
    end;
end;


procedure TuMiscTS.voip_button1(Sender: TObject);
begin
  if (Sender is TButton) then
    try
      if (uHost2.is_connection_alive) then
        begin
          case TButton(Sender).Tag of
            0: addVoip('COMMON');
            1: addVoip('FXS1');
            2: addVoip('FXS2');
          end; // case
        end
      else
        Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
    except on E:Exception do
      uHost2.writeErrorLog('Exception @ voip_button1: ' + E.Message);
    end;
end;

procedure TuMiscTS.voip_button2(Sender: TObject);
var
  capt: string;
  i, bTag: SmallInt;
begin
  if (Sender is TButton) then
    try
      capt:= TButton(Sender).Caption;
      bTag:= TButton(Sender).Tag;

      if (capt = 'Add') then
        begin
          for i:= 0 to 2 do
            begin
              voip_button[i].Visible:= False;
              if (voip_button[i+3].Caption = 'Cancel') then
                voip_button[i+3].Caption:= 'Add';
              voip_edit[i].Clear;
              voip_edit[i].Visible:= True;
              voip_edit[i].Top:= voip_info_label[bTag-3].Top;
              voip_info_label[5].Caption:= 'Password';
              voip_info_label[6].Visible:= False;
            end; // for i loop
          voip_button[bTag-3].Visible:= True;
          voip_button[bTag].Caption:= 'Cancel';
        end // Add

      else if (capt = 'Delete') then
        begin
          if (uHost2.is_connection_alive) then
            begin
              if MessageDlg('Delete VOIP profile (' + voip_data_label[(bTag-3)*2].Caption + ')?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
                  deleteVoip(voip_data_label[(bTag-3)*2].Caption);
            end // tcpc.connected
          else
            Application.MessageBox('Error: Not connected', 'Laiskuss annab teada', MB_ICONWARNING);
        end // Delete

      else if (capt = 'Cancel') then
        begin
          clearVoipObjects(bTag-2);
        end; // Cancel
    except on E:Exception do
      uHost2.writeErrorLog('Exception @ voip_button2: ' + E.Message);
    end;
end;

procedure TuMiscTS.getVoipData;
var
  i: SmallInt;
  temp: string;
begin
  try
    if (uHost2.statusTs.isSoftOld) then
      uHost2.statusTs.sendRequest(':voice profile list SIP_URI all')
    else
      uHost2.statusTs.sendRequest(':voice profile list');
    for i:= 1 to uHost2.dataBuffer.Count-1 do
      begin
    // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
        if (i > uHost2.dataBuffer.Count) then
          break;

        temp:= uHost2.dataBuffer.Strings[i];
        if (AnsiPos('COMMON', temp) > 0) then
          populateVoip(temp, 0)
        else if (AnsiPos('FXS', temp) > 0) then
          populateVoip(temp, StrToInt(Copy(temp, AnsiPos('FXS', temp)+3, 1)));
      end; // for i loop
  except on E:Exception do
    uHost2.writeErrorLog('Error @ getVoipData: ' + E.Message);
  end;
end;

procedure TuMiscTS.getVoipData789;
var
  i, j, fxs: SmallInt;
  temp: string;
  blokkid: TStrArr;
begin
  blokkid:= nil;
  try
    uHost2.statusTs.sendRequest(':voice portmap list');
    for i:= 0 to uHost2.dataBuffer.Count-3 do
      begin
    // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
        if (i > uHost2.dataBuffer.Count) then
          break;

        temp:= uHost2.dataBuffer.Strings[i];
        if (AnsiPos('COMMON', temp) > 0) then
          begin
            blokkid:= explode(temp, '|');
            voipData[0].voip_index:= StrToInt(blokkid[1]);
            voipData[0].voip_port:= 0;
            voipData[0].voip_uri:= blokkid[2];
          end
        else if (AnsiPos('FXS', temp) > 0) then
          try
            blokkid:= explode(temp, '|');
            fxs:= StrToInt(Copy(temp, AnsiPos('FXS', temp)+3, 1));
            voipData[fxs].voip_port:= fxs;
            voipData[fxs].voip_uri:= blokkid[2];
            voipData[fxs].voip_uri:= blokkid[2];
          except
          end;
      end; // for i loop
  except on E:Exception do
    uHost2.writeErrorLog('Error @ getVoipData789 (1): ' + E.Message);
  end;

  blokkid:= nil;

  try
    uHost2.statusTs.sendRequest(':voice profile list');
    for i:= 0 to uHost2.dataBuffer.Count-3 do
      begin
    // kui dataBuffer't tühjendatakse (disconnect või ükskõik mis muul põhjusel, ABORT
        if (i > uHost2.dataBuffer.Count) then
          break;
        temp:= uHost2.dataBuffer.Strings[i];
        for j:= 0 to 2 do
          if (AnsiPos(voipData[j].voip_uri, temp) > 0) then
            begin
              blokkid:= explode(temp, '|');
              voipData[j].voip_user:= blokkid[3];

              // staatus
              if (blokkid[6] = 'Enabled') then
                voipData[j].voip_stat:= True
              else
                voipData[j].voip_stat:= False;

              // registered
              if (blokkid[7] = 'Registered') then
                voipData[j].voip_reg:= True
              else
                voipData[j].voip_reg:= False;
            end;
      end; // for i loop
  except on E:Exception do
    uHost2.writeErrorLog('Error @ getVoipData789 (2): ' + E.Message);
  end;
end;


procedure TuMiscTS.populateVoip(sisend: string; port: byte);
var
  voipStr: TStrArr;
  i: SmallInt;
begin
  voipStr:= nil;
  try
    voipStr:= uMain.explode(sisend, ' ');

    with voipData[port] do
      begin
        voip_index:= StrToInt(voipStr[0]);
        voip_port:= port;
        voip_uri:= voipStr[2];

      // kui displayName on kasutusel siis username'i leiame järgmisest blokkist
        if (AnsiPos('@', voipStr[3]) > 0) then
          voip_user:= voipStr[3]
        else
          begin
            voip_user:= voipStr[4];
          end;

      // Oleku otsing
        for i:= 3 to High(voipStr) do
          if (voipStr[i] = 'Disabled') OR (voipStr[i] = 'Enabled') then
            begin
              if (voipStr[i] = 'Enabled') then
                voip_stat:= True
              else
                voip_stat:= False;
              break;
            end;

      // Kas on registreeritud
        for i:= 4 to High(voipStr) do
          if (voipStr[i] = 'Registered') then
            begin
              if (voipStr[i-1] <> 'Not') then
                voip_reg:= True
              else
                voip_reg:= False;
            end;

      end; // with
  except on E:Exception do
    uHost2.writeErrorLog('Exception @ populateVoip: ' + E.Message);
  end; // try block
end;


procedure TuMiscTS.clearVoipObjects(rida: byte = 0);
var
  i, v: SmallInt;
begin
  try
    for i:= 0 to 2 do
      voip_edit[i].Visible:= False;

    voip_info_label[5].Caption:= 'Registered';
    voip_info_label[6].Visible:= True;

    if (rida = 1) OR (rida = 0) then
      begin
        for i:= 0 to 1 do
          begin
            voip_data_label[i].Visible:= True;
            voip_data_label[i].Caption:= '';
            voip_image[i].Picture:= nil;
          end;
        voip_button[0].Visible:= False;
        voip_button[3].Caption:= 'Add';
      end; // COMMON

    if (rida = 2) OR (rida = 0) then
      begin
        for i:= 2 to 3 do
          begin
            voip_data_label[i].Visible:= True;
            voip_data_label[i].Caption:= '';
            voip_image[i].Picture:= nil;
          end;
        voip_button[1].Visible:= False;
        voip_button[4].Caption:= 'Add';
      end; // FXS1

    if (rida = 3) OR (rida = 0) then
      begin
        for i:= 4 to 5 do
          begin
            voip_data_label[i].Visible:= True;
            voip_data_label[i].Caption:= '';
            voip_image[i].Picture:= nil;
          end;
        voip_button[2].Visible:= False;
        voip_button[5].Caption:= 'Add';
      end; // FXS2

  except on E:Exception do
    uHost2.writeErrorLog('Error @ crealVoipObjects(' + IntToStr(rida) + '): ' + E.Message);
  end;

// voipData array nullimine
  if (rida = 0) then
    for v:= 0 to 2 do
      try
          FillChar(voipData[v], SizeOf(TVoipData), 0);
      except on E:Exception do
        uHost2.writeErrorLog('Error @ resetting voipData['+IntToStr(v)+']: ' + E.Message);
      end; // try block
end;

procedure TuMiscTS.fillVoipObjects;
var
  i, j: SmallInt;
begin
  try
    j:= 0;
    for i:= 0 to 2 do
      begin
        with voipData[i] do
          begin
            if (Length(voip_uri) > 0) then
              voip_button[i+3].Caption:= 'Delete'
            else
              voip_button[i+3].Caption:= 'Add';

            voip_data_label[j].Caption:= voip_uri;
            voip_data_label[j+1].Caption:= voip_user;

            try
              if (voip_stat) then
                voip_image[j+1].Picture.LoadFromFile(uHost2.acceptImg)
              else
                voip_image[j+1].Picture.LoadFromFile(uHost2.cancelImg);
            except on E:Exception do
              uHost2.writeErrorLog('Exception @ loadingImg1: ' + E.Message);
            end;

            try
              if (voip_reg) then
                voip_image[j].Picture.LoadFromFile(uHost2.acceptImg)
              else
                voip_image[j].Picture.LoadFromFile(uHost2.cancelImg);
            except on E:Exception do
              uHost2.writeErrorLog('Exception @ loadingImg2: ' + E.Message);
            end;
          end; // FXS1/FXS2
        inc(j, 2);
      end; // for i loop
  except on E:Exception do
    uHost2.writeErrorLog('Error @ fillVoipObjects:' + E.Message);
  end;
end;

procedure TuMiscTS.addVoip(fxp: string);
var
  lisa: string;
begin
  try
    if uHost2.statusTs.router_type = '' then
      uHost2.statusTs.get_router_type;
    if uHost2.statusTs.soft_version = '' then
      uHost2.statusTs.get_software_version;

    uHost2.whereDoYouGo:= 2;
    if (fxp = 'COMMON') then
      begin
        if (Length(voipData[1].voip_uri) > 0) then
          uHost2.writeLn_to_terminal(':voice profile delete SIP_URI ' + voipData[1].voip_uri)
        else if (Length(voipData[2].voip_uri) > 0) then
          uHost2.writeLn_to_terminal(':voice profile delete SIP_URI ' + voipData[2].voip_uri)
      end;
    if (uHost2.statusTs.router_type = 'TG789vn') OR (uHost2.statusTs.soft_version = '8.C.D.5') OR (uHost2.statusTs.soft_version = '8.C.D.9') then
      begin
        lisa:= ' enable enabled'
      end
    else
      lisa:= '';

    uHost2.writeLn_to_terminal(':service system modify name VOIP_SIP state disabled');
    uHost2.writeLn_to_terminal(':voice sip config primproxyaddr 217.159.187.60 proxyport 5060');
    uHost2.writeLn_to_terminal(':voice sip config secproxyaddr 0.0.0.0');
    uHost2.writeLn_to_terminal(':voice sip config primregaddr elion.ee');
    if (uHost2.statusTs.router_type = 'TG784') OR (uHost2.statusTs.router_type = 'TG789vn')  OR (uHost2.statusTs.soft_version = '8.C.D.5') OR (uHost2.statusTs.soft_version = '8.C.D.9')  then
      uHost2.writeLn_to_terminal(':voice tone descrtable modify tone release patternentryid 1');

    if (uHost2.statusTs.isEthConnection) then
      uHost2.writeLn_to_terminal(':voice sip config regexpire 120')
    else
      uHost2.writeLn_to_terminal(':voice sip config regexpire 600');
    uHost2.writeLn_to_terminal(':connection appconfig application SIP SIP_ALG disabled');

    uHost2.writeLn_to_terminal(':voice profile add SIP_URI ' + voip_edit[0].Text +
      ' username ' + voip_edit[1].Text + ' password ' + voip_edit[2].Text + ' voiceport ' + fxp + lisa);
    uHost2.writeLn_to_terminal(':service system modify name VOIP_SIP state enabled');

    uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
    uHost2.statusTs.sendRequest(':saveall');
    voip_update.Click;

  except on E:Exception do
    uHost2.writeErrorLog('Error @ addVoip:' + E.Message);
  end;
end;

procedure TuMiscTS.deleteVoip(uri: string);
begin
  try
    uHost2.st_loadInfo.Caption:= ' Deleting ' + uri + ' account...';
    uHost2.whereDoYouGo:= 2;
    uHost2.writeLn_to_terminal(':voice profile delete SIP_URI ' + uri);
    uHost2.st_loadInfo.Caption:= ' Saving changes, please wait...';
    uHost2.statusTs.sendRequest(':saveall');
    voip_update.Click;
  except on E:Exception do
    uHost2.writeErrorLog('Error @ deleteVoip:' + E.Message);
  end;
end;


end.

