program Freelancer;

uses
  Vcl.Forms,
  UMain in 'UMain.pas' {FMain},
  UNEWPost in 'UNEWPost.pas',
  Vcl.Themes,
  Vcl.Styles,
  userDialog in 'userDialog.pas',
  OAuthForm in 'OAuthForm.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('TabletDark');
  Application.Title := 'Freelancer - фриланс по группам ¬контакте';
  Application.CreateForm(TFMain, FMain);
  Application.Run;
end.
