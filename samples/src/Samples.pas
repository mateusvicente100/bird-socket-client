unit Samples;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.Grids, Vcl.DBGrids, Bird.Socket.Client, Bird.Socket.Client.Types;

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
    FBirdSocket: TBirdSocketClient;
    procedure Log(const AValue: string);
  end;

var
  FrmMainMenu: TFrmMainMenu;

implementation

{$R *.dfm}

procedure TFrmMainMenu.btnSendClick(Sender: TObject);
begin
  FBirdSocket.Send(edtText.Text);
end;

procedure TFrmMainMenu.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FBirdSocket.Connected then
    FBirdSocket.Disconnect;
  FBirdSocket.Free;
end;

procedure TFrmMainMenu.FormCreate(Sender: TObject);
begin
  FBirdSocket := TBirdSocketClient.New('ws://localhost:8080');
  FBirdSocket.AddEventListener(TEventType.MESSAGE,
    procedure(const AText: string)
    begin
      Log(AText);
    end);
  FBirdSocket.Connect;
  FBirdSocket.Send('Hello Server');
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
