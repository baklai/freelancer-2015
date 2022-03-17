unit UMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, REST.Client, REST.Authenticator.OAuth, Data.Bind.ObjectScope,
  System.DateUtils, REST.Types, System.JSON, Vcl.ImgList, REST.Response.Adapter,
  Winapi.UrlMon, Vcl.Imaging.jpeg, Vcl.ExtCtrls, System.Math, Winapi.ShellApi,
  Vcl.Buttons, Vcl.CategoryButtons, Vcl.Menus, Winapi.MMSystem, Vcl.ComCtrls,
  System.Win.Registry, SHDocVw, Vcl.ButtonGroup, Data.Bind.Components,
  IPPeerClient, Vcl.Themes, Vcl.Styles, VCL.SysStyles, Winapi.WinInet,
  System.ImageList;

  procedure SMSNill(Index: integer); /// Обнулить сообщения

const
  AppVersion  = '5.37';
  AppScope    = 'friends,notes';
  BaseURL     = 'https://api.vk.com/method';

type
  TOptions = class(TObject)
  private
  { Секция частных объявлений }
    FREGCatalog    : string;
    FAPPDirectory  : string;
    FAppID         : string;
    FAppKey        : string;
    FAppIDKey      : boolean;
    FLogPass       : boolean;
    FAutorun       : boolean;
    FMassage       : boolean;
    FSound         : boolean;
    FSoundValue    : integer;
    FTimerValue    : integer;
    FProxyEnable   : boolean;
    FProxyName     : string;
    FProxyPort     : string;
  protected
  { Cекция защищенных объявлений }
  public
  { Cекция общих объявлений }
    procedure SetOptions(); /// Сохранение настроек программы в реестр
    procedure GetOptions(); /// Загрузка настроек программы из реестра
    procedure Autorun(Flag:boolean; ParName,ParPath:string); /// Автозагрузка программы
    procedure AssignOptions(var AppID,AppKey:TLabeledEdit; var TimerValue:TUpDown; var AppIDKey,LogPass,Proxy,Autorun,Massage,Sound:TCheckBox; var Timer:TTimer; var SoundValue:TTrackBar; var Client:TRESTClient);
    constructor Create(APPDirectory,REGCatalog:string); virtual; /// Создание экземпляра класса
    destructor Destroy; override; /// Уничтожение экземпляра класса
  end;

type
  TVKGroup = record
    Item    : TGrpButtonItem;
    Post    : integer;
    ID      : string;
    URL     : string;
    Caption : string;
    FotoUrl : string;
    Text    : string;
  end;

type
  TVKGroupList = array of TVKGroup;

var
  Options       : TOptions;
  NVKGroup      : integer;
  VKGroupList   : TVKGroupList;
  Authorization : boolean;

  TimeFix: LongWord;

type
  TFMain = class(TForm)
    VKClient: TRESTClient;
    VKRequest: TRESTRequest;
    VKResponse: TRESTResponse;
    VKAuthenticator: TOAuth2Authenticator;
    VKImageList: TImageList;
    TrayIcon: TTrayIcon;
    PopupMenu: TPopupMenu;
    NSitesVisit: TMenuItem;
    NSMSNill: TMenuItem;
    N1: TMenuItem;
    Timer: TTimer;
    NOpenAllGroup: TMenuItem;
    N2: TMenuItem;
    NUpdateWallGroup: TMenuItem;
    NOpenGroup: TMenuItem;
    PageControl: TPageControl;
    TabSheetOptions: TTabSheet;
    TabSheetGroup: TTabSheet;
    ButtonGroup: TButtonGroup;
    GroupBox1: TGroupBox;
    SBEnter: TSpeedButton;
    LEAppID: TLabeledEdit;
    LEAppKey: TLabeledEdit;
    CBAppIDKey: TCheckBox;
    GroupBox2: TGroupBox;
    ISound: TImage;
    CBSound: TCheckBox;
    CBMassage: TCheckBox;
    CBAutorun: TCheckBox;
    TBSoundValue: TTrackBar;
    LEInterval: TLabeledEdit;
    CBProxy: TCheckBox;
    N3: TMenuItem;
    NExit: TMenuItem;
    TIImageList: TImageList;
    LCopyright: TLabel;
    UDInterval: TUpDown;
    CBLogPass: TCheckBox;
    SBSaveOptions: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonGroupClick(Sender: TObject);
    procedure NSMSNillClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
    procedure LEAppIDChange(Sender: TObject);
    procedure LEAppKeyChange(Sender: TObject);
    procedure CBAppIDKeyClick(Sender: TObject);
    procedure CBAutorunClick(Sender: TObject);
    procedure CBMassageClick(Sender: TObject);
    procedure CBSoundClick(Sender: TObject);
    procedure TBSoundValueChange(Sender: TObject);
    procedure NOpenAllGroupClick(Sender: TObject);
    procedure LEIntervalChange(Sender: TObject);
    procedure SBEnterClick(Sender: TObject);
    procedure CBProxyClick(Sender: TObject);
    procedure NExitClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure NSitesVisitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CBLogPassClick(Sender: TObject);
    procedure SBSaveOptionsClick(Sender: TObject);
  private
  { Cекция частных объявлений }
    function Minimaze(Hint:string; Index:integer): boolean; /// Минимизация программы
    function InternetConnection:boolean;  /// Проверка наличия подключения к интернету
    function FreelanceEnter():boolean; /// Аторизация на сайте и получение ссылок на группы
    function GetAuthorization: boolean; /// Авторизация пользовательского приложения
    function GetFaveLinks(out NEWGroupList:TVKGroupList):integer; /// Возвращает массив ссылок, добавленные в закладки текущим пользователем
    function GetWall(var NEWVKGroup:TVKGroup):boolean; /// Получение записи со стены сообщества
    function GetServerTime(var NEWDate:int64):boolean; /// Получение даты сервиса
  protected
  { Cекция защищенных объявлений }
    procedure CreateParams(var Params:TCreateParams); override; /// Тень вокруг формы...
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;X, Y: Integer); override; /// Перемещение формы...
    procedure WMSysCommand(var Msg:TMessage); message WM_SYSCOMMAND; /// Отслеживание сообщения минимизации
  public
  { Cекция общих объявлений }
  published
  { Cекция опубликованных объявлений }
  end;

var
  FMain: TFMain;

implementation

{$R *.dfm}

uses DBXJSON, DBXJSONCommon, DBXJSONReflect, UNEWPost, userDialog, OAuthForm;

procedure Pause(Second:integer); /// Пауза...
var
  WTime:TTime;
begin
  WTime:=EncodeTime(0,0,Second,0)+Time;
  repeat
    Application.ProcessMessages;
    Sleep(10);
  until Time>=WTime;
end;

function DateTimeToUNIXTimeFAST(DelphiTime:TDateTime): LongWord;
begin
  Result:=Round((DelphiTime-25569)*86400);
end;

{$REGION 'Класс настроек программы TOptions'}

{ TOptions }

procedure TOptions.Autorun(Flag: boolean; ParName, ParPath: string);
var
  Registry: TRegistry;
begin
try
  Registry:=TRegistry.Create;
  with Registry do
    begin
      RootKey:=HKEY_CURRENT_USER;
      OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',false);
      if Flag=true then WriteString(ParName,ParPath) else DeleteValue(ParName);
      CloseKey;
    end;
finally
  FreeAndNil(Registry);
end;
end;

constructor TOptions.Create(APPDirectory,REGCatalog:string); /// Создание экземпляра класса
begin
  FREGCatalog:=REGCatalog; FAPPDirectory:=APPDirectory; GetOptions;
  if (FAppIDKey=true) and ((FAppID='') or (FAppKey='')) then
    begin
      InputQuery('Авторизация','ID приложения : ',FAppID);
      InputQuery('Авторизация','Защищенный ключ : ',FAppKey);
    end;
  if (FProxyEnable=true) and ((FProxyName='') or (FProxyPort='0')) then
    begin
      InputQuery('Настройка прокси-сервера','Прокси-адресс : ',FProxyName);
      InputQuery('Настройка прокси-сервера','Прокси-порт : ',FProxyPort);
    end;
end;

destructor TOptions.Destroy; /// Уничтожение экземпляра класса
begin
  SetOptions; /// Сохранение настроек
end;

procedure TOptions.SetOptions; /// Сохранение настроек программы в реестр
var
  Registry: TRegistry;
begin
try
  Registry:=TRegistry.Create;
  with Registry do
    begin
      RootKey:=HKEY_CURRENT_USER;
      OpenKey('\SOFTWARE\'+FREGCatalog,true);
      WriteBool('AppIDKey',FAppIDKey);
      if FAppIDKey=true then begin WriteString('AppID',FAppID); WriteString('AppKey',FAppKey); end
      else begin WriteString('AppID',''); WriteString('AppKey',''); end;
      WriteBool('LogPass',FLogPass);
      WriteBool('ProxyEnable',FProxyEnable);
      if FProxyEnable=true then begin WriteString('ProxyName',FProxyName); WriteString('ProxyPort',FProxyPort); end
      else begin WriteString('ProxyName',''); WriteString('ProxyPort','0'); end;
      WriteBool('Autorun',FAutorun);
      WriteBool('Massage',FMassage);
      WriteBool('Sound',FSound);
      WriteInteger('SoundValue',FSoundValue);
      WriteInteger('TimerValue',FTimerValue);
      CloseKey;
    end;
  if FAutorun=true then Autorun(true,FREGCatalog,FAPPDirectory)
  else Autorun(false,FREGCatalog,FAPPDirectory);
finally
  FreeAndNil(Registry);
end;
end;

procedure TOptions.GetOptions; /// Загрузка настроек программы из реестра
var
  Registry: TRegistry;
begin
try
  Registry:=TRegistry.Create;
  with Registry do
    begin
      RootKey:=HKEY_CURRENT_USER;
      OpenKey('\SOFTWARE\'+FREGCatalog,true);
      if ValueExists('AppID')        then FAppID:=ReadString('AppID') else FAppID:='';
      if ValueExists('AppKey')       then FAppKey:=ReadString('AppKey') else FAppKey:='';
      if ValueExists('AppIDKey')     then FAppIDKey:=ReadBool('AppIDKey') else FAppIDKey:=false;
      if (FAppID='') or (FAppKey='') then FAppIDKey:=false;
      if ValueExists('LogPass')      then FLogPass:=ReadBool('LogPass') else FLogPass:=true;
      if ValueExists('ProxyName')    then FProxyName:=ReadString('ProxyName') else FAppID:='';
      if ValueExists('ProxyPort')    then FProxyPort:=ReadString('ProxyPort') else FProxyPort:='0';
      if ValueExists('ProxyEnable')  then FProxyEnable:=ReadBool('ProxyEnable') else FProxyEnable:=false;
      if (FProxyName='') or (FProxyPort='0') then FProxyEnable:=false;
      if ValueExists('Autorun')      then FAutorun:=ReadBool('Autorun') else FAutorun:=true;
      if ValueExists('Massage')      then FMassage:=ReadBool('Massage') else FMassage:=true;
      if ValueExists('Sound')        then FSound:=ReadBool('Sound') else FSound:=true;
      if ValueExists('SoundValue')   then FSoundValue:=ReadInteger('SoundValue') else FSoundValue:=50;
      if ValueExists('TimerValue')   then FTimerValue:=ReadInteger('TimerValue') else FTimerValue:=15;
      CloseKey;
    end;
  if FAutorun=true then Autorun(true,FREGCatalog,FAPPDirectory)
  else Autorun(false,FREGCatalog,FAPPDirectory);
finally
  FreeAndNil(Registry);
end;
end;

procedure TOptions.AssignOptions(var AppID,AppKey:TLabeledEdit; var TimerValue:TUpDown; var AppIDKey,LogPass,Proxy,Autorun,Massage,Sound:TCheckBox; var Timer:TTimer; var SoundValue:TTrackBar; var Client:TRESTClient);
var
  i:integer;
begin
  AppID.Text:=FAppID;
  AppKey.Text:=FAppKey;
  TimerValue.Position:=FTimerValue;
  Timer.Interval:=FTimerValue*60000;
  AppIDKey.Checked:=FAppIDKey;
  LogPass.Checked:=FLogPass;
  Autorun.Checked:=FAutorun;
  Massage.Checked:=FMassage;
  Sound.Checked:=FSound;
  SoundValue.Position:=FSoundValue;
  Sound.Caption:='Звуковой сигнал ( уровень : '+IntToStr(FSoundValue)+' %)';
  Proxy.Checked:=FProxyEnable;
  if FProxyEnable=true then
    begin
      if FProxyName='' then InputQuery('Настройка прокси-сервера','Прокси-адресс : ',FProxyName);
      if FProxyPort='0'  then InputQuery('Настройка прокси-сервера','Прокси-порт : ',FProxyPort);
      Client.ProxyServer:=FProxyName;
      Client.ProxyPort:=StrToInt(FProxyPort);
    end;
end;

{$ENDREGION}

{$REGION 'Настройки параметров фрилансера'}

procedure TFMain.LEAppIDChange(Sender: TObject);
begin
  Options.FAppID:=LEAppID.Text;
end;

procedure TFMain.LEAppKeyChange(Sender: TObject);
begin
  Options.FAppKey:=LEAppKey.Text;
end;

procedure TFMain.CBAppIDKeyClick(Sender: TObject);
begin
  Options.FAppIDKey:=CBAppIDKey.Checked;
end;

procedure TFMain.CBLogPassClick(Sender: TObject);
begin
  Options.FLogPass:=CBLogPass.Checked;
end;

procedure TFMain.CBAutorunClick(Sender: TObject);
begin
  Options.FAutorun:=CBAutorun.Checked;
end;

procedure TFMain.LEIntervalChange(Sender: TObject);
begin
  Options.FTimerValue:=StrToInt(LEInterval.Text);
  Timer.Interval:=Options.FTimerValue*60000;
end;

procedure TFMain.CBMassageClick(Sender: TObject);
begin
  Options.FMassage:=CBMassage.Checked;
end;

procedure TFMain.CBProxyClick(Sender: TObject);
begin
  Options.FProxyEnable:=CBProxy.Checked;
  if Options.FProxyEnable=true then
    begin
      if Options.FProxyName=''  then InputQuery('Настройка прокси-сервера','Прокси-адресс : ',Options.FProxyName);
      if Options.FProxyPort='0' then InputQuery('Настройка прокси-сервера','Прокси-порт : ',Options.FProxyPort);
      VKClient.ProxyServer:=Options.FProxyName;
      VKClient.ProxyPort:=StrToInt(Options.FProxyPort);
    end
  else
    begin
      Options.FProxyName:='';  VKClient.ProxyServer:=Options.FProxyName;
      Options.FProxyPort:='0'; VKClient.ProxyPort:=StrToInt(Options.FProxyPort);
    end;
end;

procedure TFMain.CBSoundClick(Sender: TObject);
begin
  Options.FSound:=CBSound.Checked;
end;

procedure TFMain.TBSoundValueChange(Sender: TObject);
begin
  Options.FSoundValue:=TBSoundValue.Position;
  CBSound.Caption:='Звуковой сигнал ( уровень : '+IntToStr(Options.FSoundValue)+' %)';
end;

procedure TFMain.SBSaveOptionsClick(Sender: TObject);
begin
  Options.SetOptions;
end;

{$ENDREGION}

procedure TFMain.CreateParams(var Params: TCreateParams);
const
  CS_DROPSHADOW = $00020000;
begin
  inherited CreateParams(Params);
  Params.WindowClass.Style:=Params.WindowClass.Style or CS_DROPSHADOW;
end;

procedure TFMain.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  ReleaseCapture; perform(WM_SysCommand,$F012,0);
end;

procedure TFMain.WMSysCommand(var Msg: TMessage); /// Отслеживание сообщения минимизации
begin
  if Msg.WParam=SC_MINIMIZE then Application.MainForm.Hide
  else inherited;
end;

procedure TFMain.TrayIconClick(Sender: TObject);
begin
  Application.MainForm.Show;
  Application.MainForm.WindowState:=wsNormal;
end;

function TFMain.Minimaze(Hint:string; Index:integer): boolean; /// Минимизация программы
begin
  Application.MainForm.Hide;
  TrayIcon.IconIndex:=Index;
  PostMessage(Handle,WM_SYSCOMMAND,SC_MINIMIZE,0);
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
  PageControl.Align:=alClient;
  FMain.ClientWidth:=422;
  FMain.ClientHeight:=416;
  TrayIcon.IconIndex:=0;
  Options:=TOptions.Create(ExtractFilePath(ParamStr(0))+ExtractFileName(ParamStr(0)),'Freelancer');
  Options.AssignOptions(LEAppID,LEAppKey,UDInterval,CBAppIDKey,CBLogPass,CBProxy,CBAutorun,CBMassage,CBSound,Timer,TBSoundValue,VKClient);
  if CBLogPass.Checked=false then OAuthForm.Logout(VKAuthenticator);
end;

procedure TFMain.SBEnterClick(Sender: TObject);
begin
  TimeFix:= DateTimeToUNIXTimeFAST(Now-1);

  FreelanceEnter;
end;

procedure TFMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  MsgBx:word;
  i:integer;
begin
  Application.MainForm.Hide;
  Timer.Enabled:=false;
  Authorization:=true;
  FreelanceEnter;
  Options.Destroy;
  CanClose:=true;
end;

function TFMain.InternetConnection:boolean; /// Проверка наличия подключения к интернету
var
  dwConnectionTypes:DWORD;
begin
  dwConnectionTypes:=INTERNET_CONNECTION_MODEM+INTERNET_CONNECTION_LAN+INTERNET_CONNECTION_PROXY;
  result:=InternetGetConnectedState(@dwConnectionTypes,0);
  if result=false then TrayIcon.IconIndex:=2;
end;

procedure TFMain.ButtonGroupClick(Sender: TObject);
begin
  if (NVKGroup<>0) and (VKGroupList<>nil) then
    PopupMenu.Popup(Mouse.CursorPos.x,Mouse.CursorPos.y)
  else
    begin
      MsgDlg(PChar('Freelancer - сообщение...'),PChar('Список групп пуст! Подключитесь к серверу!'),mtInform,[mbOk],mbOk);
      TrayIcon.IconIndex:=0;
      PageControl.ActivePage:=TabSheetOptions;
    end;
end;

procedure TFMain.PageControlChange(Sender: TObject); /// Переключение между закладками
begin
  if PageControl.ActivePage=TabSheetOptions then Timer.Enabled:=false
  else if Authorization=true then Timer.Enabled:=true;
end;

procedure TFMain.NExitClick(Sender: TObject); /// Закрытие программы из меню
begin
  FMain.Close;
end;

procedure TFMain.NSitesVisitClick(Sender: TObject); /// Открыть текущую группу
begin
  if Authorization=true then
    begin
      Timer.Enabled:=false;
      if InternetConnection=true then
        begin
          Minimaze('Открытие страницы текущей группы!',3);
          VKGroupList[ButtonGroup.ItemIndex].Item.ImageIndex:=ButtonGroup.ItemIndex;
          ShellExecute(Handle,'open',PChar(VKGroupList[ButtonGroup.ItemIndex].URL),nil,nil,SW_NORMAL);
          TrayIcon.IconIndex:=1;
        end;
      Timer.Enabled:=true;
    end else TrayIcon.IconIndex:=0;
  ButtonGroup.ItemIndex:=-1;
end;

procedure SMSNill(Index: integer); /// Обнулить сообщения при закрытии
begin

end;

procedure TFMain.NSMSNillClick(Sender: TObject); /// Обнулить сообщения
var
  i:integer;
begin
  if Authorization=true then
    begin
      Timer.Enabled:=false;
      Minimaze('Freelancer запущен и начинает слежку за группами!',3);
      for i:=Low(VKGroupList) to High(VKGroupList) do
        begin
          VKGroupList[i].Item.ImageIndex:=i;
          if VKGroupList[i].Post<>0 then if Assigned(TFNEWPost(VKGroupList[i].Post)) then FreeAndNil(TFNEWPost(VKGroupList[i].Post));
          VKGroupList[i].Post:=0;
        end;
      TrayIcon.IconIndex:=1;
      Timer.Enabled:=true;
    end else TrayIcon.IconIndex:=0;
  ButtonGroup.ItemIndex:=-1;
end;

procedure TFMain.NOpenAllGroupClick(Sender: TObject); /// Открыть все группы в браузере
var
  i:integer;
begin
  if Authorization=true then
    begin
      Timer.Enabled:=false;
      if InternetConnection=true then
        begin
          Minimaze('Открытие всех страниц групп из списка!',3);
          for i:=Low(VKGroupList) to High(VKGroupList) do
            begin
              VKGroupList[i].Item.ImageIndex:=i;
              ShellExecute(Handle,'open',PChar(VKGroupList[i].URL),nil,nil,SW_NORMAL);
              Pause(2);
            end;
          TrayIcon.IconIndex:=1;
        end;
      Timer.Enabled:=true;
    end else TrayIcon.IconIndex:=0;
  ButtonGroup.ItemIndex:=-1;
end;

procedure TFMain.TimerTimer(Sender: TObject); /// Событие таймера : проверка на наличие нового сообщения
var
  i: integer;
  bmp: TBitmap;
begin
  if Authorization=true then
    begin
      if InternetConnection=true then
        begin
          Minimaze('Запущенна проверка наличия новых сообщений!',3);
          for i:=Low(VKGroupList) to High(VKGroupList) do
            begin
              if GetWall(VKGroupList[i])=true then
                begin
                  VKGroupList[i].Item.ImageIndex:=-1;
                  if Options.FSound=true then UNEWPost.Execute(Options.FSoundValue);
                  if Options.FMassage=true then
                     UNEWPost.Execute(i,VKGroupList[i].Caption,VKGroupList[i].Text,VKGroupList[i].URL);
                end;
              Pause(2);
            end;
          TimeFix:= DateTimeToUNIXTimeFAST(Now);
          TrayIcon.IconIndex:=1;
        end;
    end else TrayIcon.IconIndex:=0;
end;

{$REGION 'Авторизация и запросы VK API'}

function TFMain.FreelanceEnter():boolean; /// Аторизация на сайте и получение ссылок на группы
var
  i:integer;
  bmp:TBitmap;
begin
try
  Timer.Enabled:=false;
  TrayIcon.IconIndex:=0;
  VKAuthenticator.ResetToDefaults;
  TabSheetGroup.Caption:=TabSheetGroup.Hint;
  ButtonGroup.Items.Clear; VKImageList.Clear; NVKGroup:=0; VKGroupList:=nil;
  if Authorization=false then
    begin
      if InternetConnection=true then
        begin
          if (Options.FAppID<>'') and (Options.FAppKey<>'') then
            begin
              if GetAuthorization=true then
                begin
                  Minimaze('Freelancer запущен и начинает слежку за группами!',3);
                  NVKGroup:=GetFaveLinks(VKGroupList);
                  for i:=Low(VKGroupList) to High(VKGroupList) do
                    begin
                      VKGroupList[i].Item:=TGrpButtonItem.Create(nil);
                      with VKGroupList[i].Item do
                        begin
                          Caption:=VKGroupList[i].Caption;
                          Hint:='Группа социальной сети "Вконтакте"'+#13+VKGroupList[i].Caption+#13+'URL:'+VKGroupList[i].URL+' (id'+VKGroupList[i].ID+')';
                        end;
                      ButtonGroup.Items.AddItem(VKGroupList[i].Item,i);
                    end;
                  Authorization:=true;
                  SBEnter.Caption:='Отключиться';
                  TabSheetGroup.Caption:=TabSheetGroup.Hint+' - '+'Количество групп : '+IntToStr(NVKGroup);
                  PageControl.ActivePage:=TabSheetGroup;
                  TrayIcon.IconIndex:=1;
                  Timer.Enabled:=true;
                  result:=true;
                end
              else MsgDlg(PChar('Freelancer - сообщение...'),PChar('Не удалось авторизоваться! Пожалуйста попробуйте позже!'),mtInform,[mbOk],mbOk);
            end
          else MsgDlg(PChar('Freelancer - сообщение...'),PChar('Введите ID приложения и Защищенный ключ!'),mtInform,[mbOk],mbOk);
        end;
    end
  else
    begin
      Timer.Enabled:=false;
      TrayIcon.IconIndex:=0;
      VKAuthenticator.ResetToDefaults;
      PageControl.ActivePage:=TabSheetOptions;
      TabSheetGroup.Caption:=TabSheetGroup.Hint;
      ButtonGroup.Items.Clear;
      VKImageList.Clear;
      Authorization:=false;
      SBEnter.Caption:='Подключиться';
      if CBLogPass.Checked=false then OAuthForm.Logout(VKAuthenticator);
      NVKGroup:=0; VKGroupList:=nil;
      result:=false;
    end;
except
  TrayIcon.IconIndex:=0;
  VKAuthenticator.ResetToDefaults;
  PageControl.ActivePage:=TabSheetOptions;
  TabSheetGroup.Caption:=TabSheetGroup.Hint;
  ButtonGroup.Items.Clear;
  VKImageList.Clear;
  Timer.Enabled:=false;
  Authorization:=false;
  SBEnter.Caption:='Подключиться';
  if CBLogPass.Checked=false then OAuthForm.Logout(VKAuthenticator);
  NVKGroup:=0; VKGroupList:=nil;
  result:=false;
end;
end;

function TFMain.GetAuthorization: boolean; /// Авторизация пользовательского приложения
begin
try
  VKClient.BaseURL:=BaseURL;
  VKClient.ProxyPort:=0;
  VKClient.ProxyServer:='';
  if OAuthForm.Logauth(VKAuthenticator,Options.FAppID,Options.FAppKey,AppScope)=true then
    begin
      result:=true;
    end
  else
    begin
      result:=false;
      VKAuthenticator:=nil;
    end;
except
  result:=false; VKAuthenticator:=nil;
end;
end;

function TFMain.GetServerTime(var NEWDate: int64): boolean;
var
  JsOb: TJSONObject;
  JsPair: TJSONPair;
  JsVal: TJSONValue;
begin
try
  VKRequest.Resource:='utils.getServerTime';
  VKRequest.Method:=TRESTRequestMethod.rmGET;
  VKRequest.Params.Clear;
  with VKRequest.Params.AddItem do
    begin
      name:='version';
      Value:=AppVersion;
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  VKRequest.Execute;
  JsOb:=TJSONObject.ParseJSONValue(VKResponse.Content) as TJSONObject;
  JsPair:=JsOb.Get('response');
  JsVal:=JsPair.JsonValue;
  NEWDate:=StrToInt(JsVal.ToString);
  VKRequest.Params.Clear;
  result:=true;
Except
  result:=false; NEWDate:=0;
end;
end;

function TFMain.GetFaveLinks(out NEWGroupList: TVKGroupList):integer; /// Возвращает массив ссылок, добавленные в закладки текущим пользователем
var
  Json:TJSONObject;
  jArr:TJSONArray;
  i:integer;
  function ID(IDGroup:string):string;
  var
    i:integer;
    s:Char;
    temp:string;
  begin
    temp:='';
    i:=Length(IDGroup);
    s:=IDGroup[i];
    while s<>'_' do
      begin
        temp:=temp+IDGroup[i];
        i:=i-1;
        s:=IDGroup[i];
      end;
    result:='';
    for i:=Length(temp) downto 1 do result:=result+temp[i];
  end;
begin
try
  VKRequest.Resource:='fave.getLinks';
  VKRequest.Method:=TRESTRequestMethod.rmGET;
  VKRequest.Params.Clear;
  with VKRequest.Params.AddItem do
    begin
      name:='version';
      Value:=AppVersion;
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  with VKRequest.Params.AddItem do
    begin
      name:='offset';
      Value:='0';
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  with VKRequest.Params.AddItem do
    begin
      name:='count';
      Value:='1000';
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  VKRequest.Execute;
  Json:=TJSONObject.ParseJSONValue(VKResponse.Content) as TJSONObject;
  jArr:=Json.Get('response').JsonValue as TJSONArray;
  result:=Pred(jArr.Size);
  SetLength(NEWGroupList,result);
  for i:=0 to Pred(jArr.Size)-1 do
    begin
      NEWGroupList[i].ID:=ID((jArr.Get(i+1) as TJSONObject).Get('id').JsonValue.value);
      NEWGroupList[i].URL:=(jArr.Get(i+1) as TJSONObject).Get('url').JsonValue.value;
      NEWGroupList[i].Caption:=(jArr.Get(i+1) as TJSONObject).Get('title').JsonValue.value;
      NEWGroupList[i].FotoUrl:=(jArr.Get(i+1) as TJSONObject).Get('image_src').JsonValue.value;
    end;
  VKRequest.Params.Clear;
Except
  result:=0; NEWGroupList:=nil;
end;
end;

function TFMain.GetWall(var NEWVKGroup: TVKGroup):boolean; /// Получение записи со стены сообщества
var
  Json:TJSONObject;
  jArr:TJSONArray;
  dataGroup:int64;
begin
try
  VKRequest.Resource:='wall.get';
  VKRequest.Method:=TRESTRequestMethod.rmGET;
  VKRequest.Params.Clear;
  with VKRequest.Params.AddItem do
    begin
      name:='version';
      Value:=AppVersion;
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  with VKRequest.Params.AddItem do
    begin
      name:='owner_id';
      Value:='-'+NEWVKGroup.ID;
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  with VKRequest.Params.AddItem do
    begin
      name:='count';
      Value:='1';
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  with VKRequest.Params.AddItem do
    begin
      name:='filter';
      Value:='others';
      Kind:=TRESTRequestParameterKind.pkGETorPOST;
      Options:=[poDoNotEncode];
    end;
  VKRequest.Execute;
  Json:=TJSONObject.ParseJSONValue(VKResponse.Content) as TJSONObject;
  jArr:=Json.Get('response').JsonValue as TJSONArray;
  dataGroup:=StrToInt((jArr.Get(1) as TJSONObject).Get('date').JsonValue.value);
   if (dataGroup >= TimeFix)  then
    begin
      NEWVKGroup.Text:=(jArr.Get(1) as TJSONObject).Get('text').JsonValue.value;
      result:=true;
    end
  else
    begin
      NEWVKGroup.Text:='';
      result:=false;
    end;
  VKRequest.Params.Clear;
Except
  result:=false;
  NEWVKGroup.Text:='';
end;
end;

{$ENDREGION}

initialization
{ Инициализация модуля }
  NVKGroup:=0;  VKGroupList:=nil; Authorization:=false;

finalization
{ Завершение работы модуля }

end.
