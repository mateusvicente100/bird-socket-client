unit Samples;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Bird.Socket.Client;

type
  TFrmMainMenu = class(TForm)
    Panel1: TPanel;
    edtServer: TEdit;
    btnDisconnect: TButton;
    btnConnect: TButton;
    Panel7: TPanel;
    imgHeader: TImage;
    lblServer: TLabel;
    btnSend: TButton;
    edtText: TEdit;
    btnClear: TButton;
    Label1: TLabel;
    ListBoxLog: TListBox;
    imgClose: TImage;
    procedure btnSendClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure imgCloseClick(Sender: TObject);
  private
    FBirdSocket: TBirdSocketClient;
    procedure Connect;
    procedure Disconnect;
    procedure Log(const AValue: string);
    procedure HandlerButtons(const AConnected: Boolean);
  end;

var
  FrmMainMenu: TFrmMainMenu;

implementation

{$R *.dfm}

procedure TFrmMainMenu.btnClearClick(Sender: TObject);
begin
  ListBoxLog.Clear;
end;

procedure TFrmMainMenu.btnConnectClick(Sender: TObject);
begin
  Connect;
end;

procedure TFrmMainMenu.btnDisconnectClick(Sender: TObject);
begin
  Disconnect;
end;

procedure TFrmMainMenu.btnSendClick(Sender: TObject);
begin
  FBirdSocket.Send(edtText.Text);
end;

procedure TFrmMainMenu.Connect;
begin
  try
    FBirdSocket := TBirdSocketClient.New(edtServer.Text);
    FBirdSocket.AddEventListener(TEventType.MESSAGE,
      procedure(const AText: string)
      begin
        Log(AText);
      end);
    FBirdSocket.Connect;
    FBirdSocket.Send('Hello Server');
    HandlerButtons(True);
  except
    on E:Exception do
    begin
      Disconnect;
      Log(E.Message);
    end;
  end
end;

procedure TFrmMainMenu.Disconnect;
begin
  try
    if not Assigned(FBirdSocket) then
      Exit;
    if FBirdSocket.Connected then
      FBirdSocket.Disconnect;
    FreeAndNil(FBirdSocket);
    HandlerButtons(False);
  except
    on E:Exception do
      Log(E.Message);
  end
end;

procedure TFrmMainMenu.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Disconnect;
end;

procedure TFrmMainMenu.FormShow(Sender: TObject);
begin
  HandlerButtons(False);
end;

procedure TFrmMainMenu.HandlerButtons(const AConnected: Boolean);
begin
  btnSend.Enabled := AConnected;
  btnDisconnect.Enabled := AConnected;
  btnConnect.Enabled := not(AConnected);
end;

procedure TFrmMainMenu.imgCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmMainMenu.Log(const AValue: string);
begin
  ListBoxLog.Items.Add(Format('%s | %s', [FormatDateTime('dd/mm/yyyy hh:mm:ss', Now), AValue]));
end;

end.
