program Bird.Socket.Samples;

uses
  Vcl.Forms,
  Samples in 'src\Samples.pas' {FrmMainMenu},
  Bird.Socket.Client.Consts in '..\src\Bird.Socket.Client.Consts.pas',
  Bird.Socket.Client in '..\src\Bird.Socket.Client.pas',
  Bird.Socket.Client.Types in '..\src\Bird.Socket.Client.Types.pas',
  Bird.Socket.Client.ConnectionMonitor.Interfaces in '..\src\Bird.Socket.Client.ConnectionMonitor.Interfaces.pas',
  Bird.Socket.Client.ConnectionMonitor in '..\src\Bird.Socket.Client.ConnectionMonitor.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMainMenu, FrmMainMenu);
  Application.Run;
end.
