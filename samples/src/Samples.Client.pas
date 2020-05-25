unit Samples.Client;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.Grids, Vcl.DBGrids, WebSocket.Client, WebSocket.Client.Types;

type
  TFrmMainMenu = class(TForm)
    Panel3: TPanel;
    Panel4: TPanel;
    mtServerLog: TFDMemTable;
    mtServerLogID: TIntegerField;
    mtServerLogDATE: TDateField;
    dsServerLog: TDataSource;
    DBGridLog: TDBGrid;
    mtServerLogMESSAGE: TStringField;
    Panel5: TPanel;
    Panel6: TPanel;
    btnSend: TButton;
    edtText: TEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FWebSocket: TWebSocketClient;
    procedure Log(const AValue: string);
  end;

var
  FrmMainMenu: TFrmMainMenu;

implementation

{$R *.dfm}

procedure TFrmMainMenu.btnSendClick(Sender: TObject);
begin
  FWebSocket.Send(edtText.Text);
end;

procedure TFrmMainMenu.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FWebSocket.Connected then
    FWebSocket.Disconnect;
  FWebSocket.DisposeOf;
end;

procedure TFrmMainMenu.FormCreate(Sender: TObject);
begin
  FWebSocket := TWebSocketClient.New('ws://localhost:8080');
  FWebSocket.AddEventListener(TEventType.MESSAGE,
    procedure(const AText: string)
    begin
      Log(AText);
    end);
  FWebSocket.Connect;
  FWebSocket.Send('Hello Server');
end;

procedure TFrmMainMenu.Log(const AValue: string);
begin
  mtServerLog.DisableControls;
  try
    if not mtServerLog.Active then
      mtServerLog.Open;
    mtServerLog.Append;
    mtServerLogMESSAGE.AsString := AValue;
    mtServerLogDATE.AsDateTime := Now;
    mtServerLog.Post;
  finally
    TThread.Synchronize(TThread.Current,
      procedure
      begin
        mtServerLog.EnableControls;
      end);
  end;
end;

end.
