{******************************************************************************}
{                                                                              }
{                    Copyright (c) 2010-2015 BarklaySoft                       }
{                                                                              }
{******************************************************************************}
unit userDialog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, System.Variants, Vcl.ExtCtrls,
  System.Math, Winapi.MMSystem;

const
  {$NODEFINE mrNone}
  mrNone     = 0;
  {$NODEFINE mrOK}
  mrOk       = 1;
  {$NODEFINE mrCancel}
  mrCancel   = 2;
  {$NODEFINE mrAbort}
  mrAbort    = 3;
  {$NODEFINE mrRetry}
  mrRetry    = 4;
  {$NODEFINE mrIgnore}
  mrIgnore   = 5;
  {$NODEFINE mrYes}
  mrYes      = 6;
  {$NODEFINE mrNo}
  mrNo       = 7;
  {$NODEFINE mrClose}
  mrClose    = 8;
  {$NODEFINE mrHelp}
  mrHelp     = 9;
  {$NODEFINE mrTryAgain}
  mrTryAgain = 10;
  {$NODEFINE mrContinue}
  mrContinue = 11;
  {$NODEFINE mrAll}
  mrAll      = mrContinue+1;
  {$NODEFINE mrNoToAll}
  mrNoToAll  = mrAll+1;
  {$NODEFINE mrYesToAll}
  mrYesToAll = mrNoToAll+1;


type
  TMsgDlgType = (mtWarning, mtError, mtInform, mtConfirm, mtCustom);
  TMsgDlgBtn = (mbYes, mbNo, mbOK, mbCancel, mbAbort, mbRetry, mbIgnore, mbAll, mbNoToAll, mbYesToAll, mbHelp, mbClose);
  TMsgDlgButtons = set of TMsgDlgBtn;

  function MsgDlg(const DlgMsg:PChar):integer; overload;
  function MsgDlg(const DlgTtl,DlgMsg:PChar; DlgType:TMsgDlgType; DlgBtns:TMsgDlgButtons; DefBtn:TMsgDlgBtn):integer; overload;


implementation

{$R userDialog.res} /// Ресурсы...

procedure HideTaskBarButton(hWindow:HWND); /// Скрытие окна с панели задач...
var
  wndTemp: HWND;
begin
  wndTemp:=CreateWindow('STATIC',#0,WS_POPUP,0,0,0,0,0,0,0,nil);
  ShowWindow(hWindow,SW_HIDE);
  SetWindowLong(hWindow,GWL_HWNDPARENT,wndTemp);
  ShowWindow(hWindow,SW_SHOW);
end;

{ TMessageForm }

function GetAveCharSize(Canvas: TCanvas): TPoint;
{$IF DEFINED(CLR)}
var
  I: Integer;
  Buffer: string;
  Size: TSize;
begin
  SetLength(Buffer, 52);
  for I := 0 to 25 do Buffer[I + 1] := Chr(I + Ord('A'));
  for I := 0 to 25 do Buffer[I + 27] := Chr(I + Ord('a'));
  GetTextExtentPoint(Canvas.Handle, Buffer, 52, Size);
  Result.X := Size.cx div 52;
  Result.Y := Size.cy;
end;
{$ELSE}
var
  I: Integer;
  Buffer: array[0..51] of Char;
begin
  for I := 0 to 25 do Buffer[I] := Chr(I + Ord('A'));
  for I := 0 to 25 do Buffer[I + 26] := Chr(I + Ord('a'));
  GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
  Result.X := Result.X div 52;
  {$ENDIF}
end;

type
  TMessageForm = class(TForm)
  private
  { Секция частных объявлений }
    Text: TLabel;
    Image: TImage;
  protected
  { Cекция защищенных объявлений }
    procedure Show;
    procedure CreateParams(var Params:TCreateParams); override; /// Тень вокруг формы...
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;X, Y: Integer); override; /// Перемещение формы...
    procedure CustomKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function GetFormText: String;
  public
  { Cекция общих объявлений }
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); reintroduce;
    //structor Destroy; override;
  published
  { Cекция опубликованных объявлений }
  end;

{ TMessageForm }

constructor TMessageForm.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited CreateNew(AOwner,Dummy);
  Font.Assign(Screen.MessageFont);
end;

procedure TMessageForm.CreateParams(var Params: TCreateParams);
const
  CS_DROPSHADOW = $00020000;
begin
  inherited CreateParams(Params);
  Params.WindowClass.Style:=Params.WindowClass.Style or CS_DROPSHADOW;
  FormStyle:=fsStayOnTop;
end;

procedure TMessageForm.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  ReleaseCapture; perform(WM_SysCommand,$F012,0);
end;

procedure TMessageForm.Show;
begin
  inherited;
  HideTaskBarButton(Handle);
end;

procedure TMessageForm.CustomKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift=[ssCtrl]) and (Key=Word('C')) then Beep;
end;

function TMessageForm.GetFormText: String;
var
  DividerLine,ButtonCaptions: string;
  i: integer;
begin
  DividerLine:= StringOfChar('-',27)+sLineBreak;
  for i:=0 to ComponentCount-1 do
    if Components[I] is TButton then
      ButtonCaptions:=ButtonCaptions+TButton(Components[I]).Caption+StringOfChar(' ',3);
  ButtonCaptions:=StringReplace(ButtonCaptions,'&','',[rfReplaceAll]);
  Result:=Format('%s%s%s%s%s%s%s%s%s%s',[DividerLine,Caption,sLineBreak,DividerLine,Text.Caption,sLineBreak,DividerLine,ButtonCaptions,sLineBreak,DividerLine]);
end;

{ Message dialog constants}

const

  MsgDlgIconWarning = 'IWarning';
  MsgDlgIconError   = 'IError';
  MsgDlgIconInform  = 'IInform';
  MsgDlgIconConfirm = 'IConfirm';

  MsgDlgWarning = 'Внимание...';
  MsgDlgError   = 'Ошибка...';
  MsgDlgInform  = 'Сообщение...';
  MsgDlgConfirm = 'Запрос...';

  SMsgDlgYes      = 'Да';
  SMsgDlgNo       = '&Нет';
  SMsgDlgOK       = 'OK';
  SMsgDlgCancel   = 'Отмена';
  SMsgDlgHelp     = '&Help';
  SMsgDlgHelpNone = 'No help available';
  SMsgDlgHelpHelp = 'Help';
  SMsgDlgAbort    = '&Abort';
  SMsgDlgRetry    = '&Retry';
  SMsgDlgIgnore   = '&Ignore';
  SMsgDlgAll      = '&All';
  SMsgDlgNoToAll  = 'N&o to All';
  SMsgDlgYesToAll = 'Yes to &All';
  SMsgDlgClose    = '&Close';

var
  Captions: array[TMsgDlgType] of PChar = (MsgDlgWarning, MsgDlgError, MsgDlgInform, MsgDlgConfirm,nil);

  Icons: array[TMsgDlgType] of PChar = (MsgDlgIconWarning, MsgDlgIconError, MsgDlgIconInform, MsgDlgIconConfirm, nil);

  BtnCaptions: array[TMsgDlgBtn] of string = (SMsgDlgYes,
                                              SMsgDlgNo,
                                              SMsgDlgOK,
                                              SMsgDlgCancel,
                                              SMsgDlgAbort,
                                              SMsgDlgRetry,
                                              SMsgDlgIgnore,
                                              SMsgDlgAll,
                                              SMsgDlgNoToAll,
                                              SMsgDlgYesToAll,
                                              SMsgDlgHelp,
                                              SMsgDlgClose);

  BtnNames: array[TMsgDlgBtn] of string = ('Yes', 'No', 'OK', 'Cancel', 'Abort', 'Retry', 'Ignore', 'All', 'NoToAll', 'YesToAll', 'Help', 'Close');

  ModalResults: array[TMsgDlgBtn] of Integer = (mrYes, mrNo, mrOk, mrCancel, mrAbort, mrRetry, mrIgnore, mrAll, mrNoToAll, mrYesToAll, 0, mrClose);


function СreateMsgDlg(const DlgTtl,DlgMsg:PChar; DlgType:TMsgDlgType; DlgBtns:TMsgDlgButtons; DefBtn:TMsgDlgBtn):TForm;
const
  mcHorzMargin    = 8;
  mcVertMargin    = 8;
  mcHorzSpacing   = 10;
  mcVertSpacing   = 10;
  mcButtonWidth   = 60;
  mcButtonHeight  = 14;
  mcButtonSpacing = 4;
var
  DialogUnits: TPoint;
  HorzMargin,VertMargin  :integer;
  HorzSpacing,VertSpacing :integer;
  ButtonWidth, ButtonHeight:integer;
  ButtonSpacing, ButtonCount, ButtonGroupWidth:integer;
  IconTextWidth, IconTextHeight:integer;

  ButtonPos:integer;

  CaptionTextWidth:integer;

  ALeft:integer;
  IDButton,BtnCancel:TMsgDlgBtn;
  IDIcon:PChar;
  TextRect:TRect;
  Btn:TButton;
begin
  Result:=TMessageForm.CreateNew(Application);
  with Result do
    begin
      Font:=Screen.MessageFont;
      BiDiMode:=Application.BiDiMode;
      BorderStyle:=bsDialog;
      Canvas.Font:=Font;
      KeyPreview:=True;
      PopupMode:=pmAuto;
      Position:=poDesigned;
      OnKeyDown:=TMessageForm(Result).CustomKeyDown;
      DialogUnits:=GetAveCharSize(Canvas);
      HorzMargin:=MulDiv(mcHorzMargin,DialogUnits.X,4);
      VertMargin:=MulDiv(mcVertMargin,DialogUnits.Y,8);
      HorzSpacing:=MulDiv(mcHorzSpacing,DialogUnits.X,4);
      VertSpacing:=MulDiv(mcVertSpacing,DialogUnits.Y,8);
      ButtonWidth:=MulDiv(mcButtonWidth,DialogUnits.X,4);

      ButtonHeight:=MulDiv(mcButtonHeight,DialogUnits.Y,8);
      ButtonSpacing:=MulDiv(mcButtonSpacing,DialogUnits.X,4);
      SetRect(TextRect,0,0,Screen.Width div 2,0);
      DrawText(Canvas.Handle,DlgMsg,Length(DlgMsg)+1,TextRect,DT_EXPANDTABS or DT_CALCRECT or DT_WORDBREAK or DrawTextBiDiModeFlagsReadingOnly);

      IDIcon:=Icons[DlgType];
      IconTextWidth:=TextRect.Right;
      IconTextHeight:=TextRect.Bottom;

      if DlgType<>mtCustom then
        if IDIcon<>nil then
          begin
            Inc(IconTextWidth,32+HorzSpacing);
            if IconTextHeight<32 then IconTextHeight:=32;
          end;

      ButtonCount:=0;
      for IDButton:=Low(TMsgDlgBtn) to High(TMsgDlgBtn) do if IDButton in DlgBtns then Inc(ButtonCount);

      ButtonGroupWidth:=0;
      if ButtonCount<>0 then ButtonGroupWidth:=ButtonWidth*ButtonCount+ButtonSpacing*(ButtonCount-1);

      if DlgTtl=nil then
        if DlgType<>mtCustom then Caption:=Captions[DlgType]
      else Caption:='Cообщение...' else Caption:=DlgTtl;

      Canvas.Font.Size:=Font.Size+2;
      CaptionTextWidth:=Canvas.TextWidth(Caption)+2*HorzMargin;

      ClientWidth:=Max(Max(IconTextWidth,ButtonGroupWidth),CaptionTextWidth)+HorzMargin*2;
      ClientHeight:=IconTextHeight+ButtonHeight+VertSpacing+VertMargin*2;

      Left:=(Screen.Width div 2)-(Width div 2);
      Top:=(Screen.Height div 2)-(Height div 2);

      if IDIcon<>nil
        then

          TMessageForm(Result).Image:=TImage.Create(Result);
          with TMessageForm(Result).Image do
            begin
              Name:='Image';
              Parent:=Result;
              Picture.Icon.LoadFromStream(TResourceStream.Create(Hinstance,Icons[DlgType],RT_RCDATA));
              SetBounds(HorzMargin,VertMargin,32,32);
            end;

          TMessageForm(Result).Text:=TLabel.Create(Result);
          with TMessageForm(Result).Text do
            begin
              Name:='Message';
              Parent:=Result;
              WordWrap:=false;
              Caption:=DlgMsg;
              BoundsRect:=TextRect;
              BiDiMode:=Result.BiDiMode;
              ALeft:=IconTextWidth-TextRect.Right+HorzMargin;
              if UseRightToLeftAlignment then ALeft:=Result.ClientWidth-ALeft-Width;
              SetBounds(Left,VertMargin,TextRect.Right,TextRect.Bottom);
            end;

          if TMessageForm(Result).Image.Height>TMessageForm(Result).Text.Height then
            begin
              TMessageForm(Result).Image.SetBounds(HorzMargin,VertMargin,32,32);
              TMessageForm(Result).Text.SetBounds(ALeft,TMessageForm(Result).Image.Top+(TMessageForm(Result).Image.Height-TMessageForm(Result).Text.Height) div 2 ,TextRect.Right,TextRect.Bottom);
            end
          else
            begin
              TMessageForm(Result).Text.SetBounds(ALeft,VertMargin,TextRect.Right,TextRect.Bottom);
              TMessageForm(Result).Image.SetBounds(HorzMargin,TMessageForm(Result).Text.Top+(TMessageForm(Result).Text.Height-TMessageForm(Result).Image.Height) div 2 ,32,32);
            end;

          if mbCancel in DlgBtns then BtnCancel:=mbCancel else
          if mbNo in DlgBtns then BtnCancel:=mbNo else BtnCancel:=mbOk;

          if DlgBtns=[mbOk] then ButtonPos:=(ClientWidth-ButtonGroupWidth) div 2
          else ButtonPos:=(ClientWidth-mcHorzSpacing-ButtonGroupWidth);

          for IDButton:=Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
            if IDButton in DlgBtns then
              begin
                Btn:=TButton.Create(Result);
                with Btn do
                  begin
                    Name:=BtnNames[IDButton];
                    Parent:=Result;
                    Caption:=BtnCaptions[IDButton];
                    ModalResult:=ModalResults[IDButton];
                    if IDButton=DefBtn then
                      begin
                        Default:=True;
                        ActiveControl:=Btn;
                      end;
                    if IDButton=BtnCancel then Cancel:=True;
                    SetBounds(ButtonPos,IconTextHeight+VertMargin+VertSpacing,ButtonWidth,ButtonHeight);
                    Inc(ButtonPos,ButtonWidth+ButtonSpacing);
                  end;
              end;
        end;
end;

function MsgDlgPos(hWnd: HWND; MsgDlg:TForm; X,Y:Integer):integer;
begin
  with MsgDlg do
    try
      if X >= 0 then Left := X;
      if Y >= 0 then Top := Y;
      if (Y < 0) and (X < 0) then Position := poScreenCenter;
      Result := ShowModal;
    finally
      Free;
    end;
end;

function MsgDlg(const DlgMsg:PChar):integer;
begin
//  PlaySound('SConfirm', 0, SND_RESOURCE and SND_ASYNC);
  Result:=MsgDlgPos(0,СreateMsgDlg(nil,DlgMsg,mtInform,[mbOK],mbOK),-1,-1);
end;

function MsgDlg(const DlgTtl,DlgMsg:PChar; DlgType:TMsgDlgType; DlgBtns:TMsgDlgButtons; DefBtn:TMsgDlgBtn):integer;
begin
  Result:=MsgDlgPos(0,СreateMsgDlg(DlgTtl,DlgMsg,DlgType,DlgBtns,DefBtn),-1,-1);
end;



initialization
{ Инициализация модуля }

finalization
{ Завершение работы модуля }

end.