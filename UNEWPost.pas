unit UNEWPost;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, Winapi.MMSystem, Winapi.ShellApi;

  function Execute(Value:integer):boolean; overload; /// Процедура вызова звукового сообщения...
  function Execute(Index:integer; GName,GPost,GURL: string):integer; overload; /// Процедура вызова сообщения...

type
  TFNEWPost = class(TForm)
  private
  { Секция частных объявлений }
    FPost: TLabel;
    FText: TLabel;
    FLink: TLabel;
    FIndex: integer;
    procedure ClickNEWPost(Sender: TObject);
  protected
  { Cекция защищенных объявлений }
    procedure Show;
    procedure WMClose(var Message: TWMClose); message WM_CLOSE;
    procedure CreateParams(var Params:TCreateParams); override; /// Тень вокруг формы...
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;X, Y: Integer); override; /// Перемещение формы...
  public
  { Cекция общих объявлений }
    constructor CreateNew(AOwner: TComponent); reintroduce;
    destructor Destroy; override;
  published
  { Cекция опубликованных объявлений }
  end;

implementation

{$R UNEWPost.res} /// Ресурс звука сообщения...

uses UMain;

const
  Sound = 'newpost';

var
  tada: Pointer;

procedure SetVolume(const newvol:word); /// Установка уровня громкости сообщения...
var
  hWO: HWAVEOUT;
  waveF: TWAVEFORMATEX;
  vol: DWORD;
begin
  FillChar(waveF,SizeOf(waveF),0);
  waveOutOpen(@hWO,WAVE_MAPPER,@waveF,0,0,0);
  vol:=newvol+newvol shl 16;
  waveOutSetVolume(hWO,vol);
  waveOutClose(hWO);
end;

procedure HideTaskBarButton(hWindow:HWND); /// Скрытие окна с панели задач...
var
  wndTemp: HWND;
begin
  wndTemp:=CreateWindow('STATIC',#0,WS_POPUP,0,0,0,0,0,0,0,nil);
  ShowWindow(hWindow,SW_HIDE);
  SetWindowLong(hWindow,GWL_HWNDPARENT,wndTemp);
  ShowWindow(hWindow,SW_SHOW);
end;

{ TFNEWPost }

procedure TFNEWPost.ClickNEWPost(Sender: TObject);
begin
  ShellExecute(Handle,'open',PChar(FLink.Caption),nil,nil,SW_NORMAL);
  Destroy;
end;

procedure TFNEWPost.WMClose(var Message: TWMClose);
begin
  Destroy;
end;

constructor TFNEWPost.CreateNew(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  AlphaBlend:=true;
  AlphaBlendValue:=200;
  BorderIcons:=[biSystemMenu];
  BorderStyle:=bsToolWindow;
  Caption:='';
  Width:=390;
  Height:=102;
  Position:=poDesigned;
  Left:=Screen.Width-Width-ROUND(Screen.Width*0.01);
  Top:=Screen.Height-Height-ROUND(Screen.Height*0.05);
  OnClick:=ClickNEWPost;
  FPost:=TLabel.Create(nil);
    FPost.Parent:=self;
    FPost.Align:=alTop;
    FPost.Caption:=' Новая запись на стене группы : ';
    FPost.Font.Style:=[fsBold];
    FPost.OnClick:=ClickNEWPost;
  FText:=TLabel.Create(nil);
    FText.Parent:=self;
    FText.AutoSize:=false;
    FText.Caption:='';
    FText.EllipsisPosition:=epEndEllipsis;
    FText.Height:=50;
    FText.Left:=58;
    FText.Top:=15;
    FText.Width:=320;
    FText.WordWrap:=true;
    FText.OnClick:=ClickNEWPost;
  FLink:=TLabel.Create(nil);
    FLink.Parent:=self;
    FLink.Align:=alBottom;
    FLink.Alignment:=taRightJustify;
    FLink.Font.Style:=[fsBold,fsUnderline];
    FLink.Caption:='';
    FLink.OnClick:=ClickNEWPost;
end;

procedure TFNEWPost.CreateParams(var Params: TCreateParams);
const
  CS_DROPSHADOW = $00020000;
begin
  inherited CreateParams(Params);
  Params.WindowClass.Style:=Params.WindowClass.Style or CS_DROPSHADOW;
end;

procedure TFNEWPost.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  ReleaseCapture; perform(WM_SysCommand,$F012,0);
end;

destructor TFNEWPost.Destroy;
begin
  FPost.Destroy;
  FText.Destroy;
  FLink.Destroy;
  inherited Destroy;
end;

procedure TFNEWPost.Show;
begin
  inherited;
  HideTaskBarButton(Handle);
end;

function Execute(Value:integer):boolean; overload; /// Процедура вызова звукового сообщения...
begin
try
  SetVolume(TRUNC((65535*Value)/100));
  sndPlaySound(tada,SND_MEMORY or SND_NODEFAULT or SND_ASYNC);
  result:=true;
except
  result:=false;
end;
end;

function Execute(Index:integer; GName,GPost,GURL: string):integer; overload; /// Процедура вызова сообщения...
begin
try
  Result:=Integer(TFNEWPost.CreateNew(Application));
  with TFNEWPost(Result)  do
    begin
      Caption:=GName;
      FText.Caption:=GPost;
      FLink.Caption:=GURL;
      FIndex:=Index;
      Show;
    end;
except
  result:=0;
end;
end;

initialization
{ Инициализация модуля }
  tada:=Pointer(FindResource(hInstance,PChar(Sound),'wave'));
  if tada<>nil then
    begin
      tada:=Pointer(LoadResource(hInstance,HRSRC(tada)));
      if tada<>nil then tada:=LockResource(HGLOBAL(tada));
    end;

finalization
{ Завершение работы модуля }

end.
