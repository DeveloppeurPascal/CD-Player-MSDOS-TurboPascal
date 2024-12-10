unit Unit1;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, MPlayer, Grids, Calendar, ExtCtrls, Outline, StdCtrls,
  FileCtrl;

type
  TForm1 = class(TForm)
    MediaPlayer1: TMediaPlayer;
    procedure FormCreate(Sender: TObject);
  private
    { Private-déclarations }
  public
    { Public-déclarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
begin
  MediaPlayer1.DeviceType := dtCDAudio;
  MediaPlayer1.AutoOpen := True;
  MediaPlayer1.Open;
  MediaPlayer1.Play;
end;

end.

