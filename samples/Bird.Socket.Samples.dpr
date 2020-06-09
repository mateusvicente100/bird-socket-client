program Bird.Socket.Samples;

uses
  Vcl.Forms,
  Samples in 'src\Samples.pas' {FrmMainMenu},
  Bird.Socket.Client.Consts in '..\src\Bird.Socket.Client.Consts.pas',
  Bird.Socket.Client in '..\src\Bird.Socket.Client.pas',
  Bird.Socket.Client.Types in '..\src\Bird.Socket.Client.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMainMenu, FrmMainMenu);
  Application.Run;
end.
