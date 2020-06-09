program Bird.Socket.Samples;

uses
  Vcl.Forms,
  Samples.Client in 'src\Samples.Client.pas' {FrmMainMenu},
  WebSocket.Client.Consts in '..\src\WebSocket.Client.Consts.pas',
  WebSocket.Client in '..\src\WebSocket.Client.pas',
  WebSocket.Client.Types in '..\src\WebSocket.Client.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMainMenu, FrmMainMenu);
  Application.Run;
end.
