{******************************************************************************}
{                                                                              }
{                       Copyright (c) 2010-2015 Baklay                         }
{                                                                              }
{******************************************************************************}
unit OAuthForm;

interface

uses
  System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, SHDocVw,
  Winapi.Windows, Winapi.Messages, System.DateUtils, REST.Authenticator.OAuth,
  Winapi.WinInet;

  function Logauth(out AOAuth: TOAuth2Authenticator; out AUserId: string; const AAppID,AAppKey,AAppScope: string): boolean; overload; /// Процедура авторизации...
  function Logauth(out AOAuth: TOAuth2Authenticator; const AAppID,AAppKey,AAppScope: string): boolean; overload; /// Процедура авторизации...

  function LogOut(out AOAuth: TOAuth2Authenticator; out AUserId: string): boolean; overload; /// Процедура реавторизации...
  function LogOut(out AOAuth: TOAuth2Authenticator): boolean; overload; /// Процедура реавторизации...


implementation

procedure HideTaskBarButton(hWindow:HWND); /// Скрытие окна с панели задач...
var
  wndTemp: HWND;
begin
  wndTemp:=CreateWindow('STATIC',#0,WS_POPUP,0,0,0,0,0,0,0,nil);
  ShowWindow(hWindow,SW_HIDE);
  SetWindowLong(hWindow,GWL_HWNDPARENT,wndTemp);
  ShowWindow(hWindow,SW_SHOW);
end;

const
  EndPoint = 'https://oauth.vk.com/authorize';

type
  TOAuth2WebFormRedirectEvent = procedure(const AURL: string; var DoCloseWebView : boolean) of object;
  TOAuth2WebFormTitleChangedEvent = procedure(const ATitle: string; var DoCloseWebView : boolean) of object;

type
  TOAuthForm = class(TForm)
    FBevel: TBevel;
    FBrowser: TWebBrowser;
    FLabel: TLabel;
    FOAuth: TOAuth2Authenticator;
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure BrowserTitleChange(ASender: TObject; const Text: WideString);
    procedure BrowserNavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
    procedure BrowserBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
    procedure BrowserDocumentComplete(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
    procedure AfterRedirect(const AURL: string; var DoCloseWebView: boolean);
  private
  { Секция частных объявлений }
    FUserId: string;
    FLastURL: string;
    FLastTitle: string;
    FOnBeforeRedirect: TOAuth2WebFormRedirectEvent;
    FOnAfterRedirect: TOAuth2WebFormRedirectEvent;
    FOnBrowserTitleChanged : TOAuth2WebFormTitleChangedEvent;
  protected
  { Cекция защищенных объявлений }
    procedure CreateParams(var Params:TCreateParams); override; /// Тень вокруг формы...
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;X, Y: Integer); override; /// Перемещение формы...
  public
  { Cекция общих объявлений }
    constructor CreateNew(AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    property LastTitle: string read FLastTitle;
    property LastURL: string read FLastURL;
    property OnAfterRedirect: TOAuth2WebFormRedirectEvent read FOnAfterRedirect write FOnAfterRedirect;
    property OnBeforeRedirect: TOAuth2WebFormRedirectEvent read FOnBeforeRedirect write FOnBeforeRedirect;
    property OnTitleChanged : TOAuth2WebFormTitleChangedEvent read FOnBrowserTitleChanged write FOnBrowserTitleChanged;
  published
  { Cекция опубликованных объявлений }
  end;

{ TOAuthForm }

procedure TOAuthForm.AfterRedirect(const AURL: string; var DoCloseWebView: boolean);
var
  i:integer;
  StrURL: string;
  Params: TStringList;
begin
  i:=pos('#access_token=',AURL);
  if (i>0) and (FOAuth.AccessToken=EmptyStr) then
    begin
      StrURL:=AURL;
      Delete(StrURL,1,i);
      Params:=TStringList.Create;
      try
        Params.Delimiter:='&';
        Params.DelimitedText:=StrURL;
        FOAuth.AccessToken:=Params.Values['access_token'];
        FOAuth.AccessTokenExpiry:=IncSecond(Now,StrToInt(Params.Values['expires_in']));
        FUserId:=Params.Values['user_id'];
      finally
        Params.Free;
      end;
      Close;
    end;
end;

procedure TOAuthForm.BrowserBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
var
  LDoCloseForm: boolean;
begin
  if Assigned(FOnBeforeRedirect) then
  begin
    LDoCloseForm:=FALSE;
    FOnBeforeRedirect(URL,LDoCloseForm);
    if LDoCloseForm then
      begin
        Cancel:=TRUE;
        self.Close;
      end;
  end;
end;

procedure TOAuthForm.BrowserDocumentComplete(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
begin
  TControl(FBrowser).Parent.Height:=FBrowser.OleObject.Document.Body.ScrollHeight+50;
  TControl(FBrowser).Parent.Width:=FBrowser.OleObject.Document.Body.ScrollWidth;
  FBrowser.OleObject.Document.Body.Style.OverflowX:='hidden';
  FBrowser.OleObject.Document.Body.Style.OverflowY:='hidden';
end;

procedure TOAuthForm.BrowserNavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
var
  LDoCloseForm: boolean;
begin
  FLastURL:=VarToStrDef(URL,'');
  if Assigned(FOnAfterRedirect) then
    begin
      LDoCloseForm:=FALSE;
      FOnAfterRedirect(FLastURL,LDoCloseForm);
      if LDoCloseForm then self.Close;
    end;
end;

procedure TOAuthForm.BrowserTitleChange(ASender: TObject; const Text: WideString);
var
  LCloseForm: boolean;
begin
  if (Text<>FLastTitle) then
  begin
    FLastTitle:=Text;
    if Assigned(FOnBrowserTitleChanged) then
      begin
        LCloseForm:=FALSE;
        FOnBrowserTitleChanged(FLastTitle,LCloseForm);
        if LCloseForm then self.Close;
      end;
  end;
end;

procedure TOAuthForm.CreateParams(var Params: TCreateParams);
const
  CS_DROPSHADOW = $00020000;
begin
  inherited CreateParams(Params);
  Params.WindowClass.Style:=Params.WindowClass.Style or CS_DROPSHADOW;
end;

procedure TOAuthForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key=#27) then Close;
end;

procedure TOAuthForm.FormShow(Sender: TObject);
begin
  HideTaskBarButton(Handle);
end;

procedure TOAuthForm.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  ReleaseCapture; perform(WM_SysCommand,$F012,0);
end;

constructor TOAuthForm.CreateNew(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FOnAfterRedirect:=NIL;
  FOnBeforeRedirect:=NIL;
  FOnBrowserTitleChanged:=NIL;
  FLastTitle:='';
  FLastURL:='';
  FUserId:='';
  BorderIcons:=[biSystemMenu];
  BorderStyle:=bsDialog;
  Caption:='OAuth-авторизация пользователя на сайте ВКонтакте';
  KeyPreview:=true;
  OldCreateOrder:=false;
  Height:=240; Width:=378;
  Position:=poDesktopCenter;
  OnShow:=FormShow;
  OnKeyPress:=FormKeyPress;
  OnAfterRedirect:=AfterRedirect;
  FOAuth:=TOAuth2Authenticator.Create(self);
  FBrowser:=TWebBrowser.Create(self);
    TWinControl(FBrowser).Parent:=self;
    FBrowser.Align:=alClient;
    FBrowser.AlignWithMargins:=true;
    FBrowser.Silent:=true;
    FBrowser.Height:=274; FBrowser.Width:=492;
    FBrowser.OnTitleChange:=BrowserTitleChange;
    FBrowser.OnNavigateComplete2:=BrowserNavigateComplete2;
    FBrowser.OnBeforeNavigate2:=BrowserBeforeNavigate2;
    FBrowser.OnDocumentComplete:=BrowserDocumentComplete;
  FLabel:=TLabel.Create(self);
    FLabel.Parent:=self;
    FLabel.Align:=alBottom;
    FLabel.AlignWithMargins:=true;
    FLabel.Font.Style:=[fsBold];
    FLabel.Caption:='Это окно будет автоматически закрыто после авторизации...';
  FBevel:=TBevel.Create(self);
    FBevel.Parent:=self;
    FBevel.Align:=alBottom;
    FBevel.AlignWithMargins:=true;
    FBevel.Height:=2;
end;

destructor TOAuthForm.Destroy;
begin
  FBrowser.Destroy;
  FBevel.Destroy;
  FLabel.Destroy;
  FOAuth.Destroy;
  inherited Destroy;
end;

function Logauth(out AOAuth: TOAuth2Authenticator; out AUserId: string; const AAppID,AAppKey,AAppScope: string): boolean; /// Процедура авторизации...
begin
  with TOAuthForm.CreateNew(nil) do
    begin
      try
        FOAuth.AccessToken:=EmptyStr;
        FOAuth.ClientID:=AAppID;
        FOAuth.ClientSecret:=AAppKey;
        FOAuth.Scope:=AAppScope;
        FOAuth.ResponseType:=TOAuth2ResponseType.rtTOKEN;
        FOAuth.AuthorizationEndpoint:=EndPoint;
        FBrowser.Navigate(FOAuth.AuthorizationRequestURI);
        ShowModal;
      finally
        AOAuth.Assign(FOAuth);
        AUserId:=FUserId;
        if (AOAuth.AccessToken<>'') and (AUserId<>'') then result:=true else result:=false;
        Destroy;
      end;
    end;
end;

function Logauth(out AOAuth: TOAuth2Authenticator; const AAppID,AAppKey,AAppScope: string): boolean; /// Процедура авторизации...
begin
  with TOAuthForm.CreateNew(nil) do
    begin
      try
        FOAuth.AccessToken:=EmptyStr;
        FOAuth.ClientID:=AAppID;
        FOAuth.ClientSecret:=AAppKey;
        FOAuth.Scope:=AAppScope;
        FOAuth.ResponseType:=TOAuth2ResponseType.rtTOKEN;
        FOAuth.AuthorizationEndpoint:=EndPoint;
        FBrowser.Navigate(FOAuth.AuthorizationRequestURI);
        ShowModal;
      finally
        AOAuth.Assign(FOAuth);
        if (AOAuth.AccessToken<>'') then result:=true else result:=false;
        Destroy;
      end;
    end;
end;

procedure DeleteWebBrowserCache;
var
  lpEntryInfo: PInternetCacheEntryInfo;
  hCacheDir: LongWord;
  dwEntrySize: LongWord;
begin
  dwEntrySize:=0;
  FindFirstUrlCacheEntry(nil,TInternetCacheEntryInfo(nil^),dwEntrySize);
  GetMem(lpEntryInfo,dwEntrySize);
  if dwEntrySize>0 then lpEntryInfo^.dwStructSize:=dwEntrySize;
  hCacheDir:=FindFirstUrlCacheEntry(nil,lpEntryInfo^,dwEntrySize);
  if hCacheDir<>0 then
    begin
      repeat
        DeleteUrlCacheEntry(lpEntryInfo^.lpszSourceUrlName);
        FreeMem(lpEntryInfo, dwEntrySize);
        dwEntrySize:=0;
        FindNextUrlCacheEntry(hCacheDir,TInternetCacheEntryInfo(nil^),dwEntrySize);
        GetMem(lpEntryInfo,dwEntrySize);
        if dwEntrySize>0 then lpEntryInfo^.dwStructSize:=dwEntrySize;
      until not FindNextUrlCacheEntry(hCacheDir,lpEntryInfo^,dwEntrySize);
    end;
  FreeMem(lpEntryInfo,dwEntrySize);
  FindCloseUrlCache(hCacheDir);
end;

function Logout(out AOAuth: TOAuth2Authenticator; out AUserId: string): boolean; /// Процедура реавторизации...
begin
  try
    DeleteWebBrowserCache;
  finally
    if (AOAuth.AccessToken='') and (AUserId='') then result:=true else result:=false;
  end;
end;

function Logout(out AOAuth: TOAuth2Authenticator): boolean; /// Процедура реавторизации...
begin
  try
    DeleteWebBrowserCache;
  finally
    if (AOAuth.AccessToken='') then result:=true else result:=false;
  end;
end;

initialization
{ Инициализация модуля }

finalization
{ Завершение работы модуля }

end.

