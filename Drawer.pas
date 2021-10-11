unit Drawer;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, ExtCtrls,Graphics,Forms;

type
  TDrawerPlacement=(dpLeft,dpRight,dpTop,dpBottom);

  TDrawerEvent=procedure(Sender:TObject;var Allow:Boolean) of object;

  TDrawer = class(TCustomControl)
   private
    FPlacement:TDrawerPlacement;
    FArrowColor:TColor;
    FClosed:Boolean;
    FAnimationPause:Integer;
    FAutoOpenDelay,FAutoCloseDelay:Integer;
    FCaptionText,FCaptionImage:TBitmap;
    FCaptionSize:Integer;
    FAnimating:Boolean;
    FDelayTime:Integer;
    FR1,FR2:HRgn;
    FCloseOnExit,FOpenOnEnter:Boolean;
    FOnOpen,FOnClose,FOnPaint:TNotifyEvent;
    FOnOpening,FOnClosing:TDrawerEvent;
    FImmediateRefresh,FImmediateParentRefresh:Boolean;
    procedure SetPlacement(Value:TDrawerPlacement);
    procedure SetClosed(Value:Boolean);
    procedure SetArrowColor(Value:TColor);
    procedure WMNCCalcSize(var Msg:TWMNCCalcSize);message WM_NCCalcSize;
    procedure WMNCHitTest(var Msg:TWMNCHitTest);message WM_NCHitTest;
    procedure WMNCPaint(var Msg:TWMNCPaint);message WM_NCPaint;
    procedure WMNCLButtonDown(var Msg:TWMNCLButtonDown);message WM_NCLButtonDown;
    procedure WMNCLButtonDblClk(var Msg:TWMNCLButtonDblClk);message WM_NCLButtonDblClk;
    procedure CMTextChanged(var Msg:TMessage);message CM_TextChanged;
    procedure CMFontChanged(var Msg:TMessage);message CM_FontChanged;
    procedure CMColorChanged(var Msg:TMessage);message CM_ColorChanged;
    procedure CMEnter(var Msg:TMessage);message CM_Enter;
    procedure CMExit(var Msg:TMessage);message CM_Exit;
    procedure TimerEvent(Wnd:HWnd);
    procedure SetCaptionSize(Value:Integer);
   protected
    procedure Loaded;override;
    procedure Paint;override;
    property CaptionSize:Integer read FCaptionSize write SetCaptionSize;
    procedure UpdateRegion;
    procedure UpdateCaptionBitmap;
    procedure UpdateCaption(CaptPict:TBitmap;Contrast:Boolean);
    procedure UpdateObliqueRegions;
   public
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
    procedure SetBounds(ALeft,ATop,AWidth,AHeight:Integer);override;
    procedure Open;
    procedure Close;
   published
    property Closed:Boolean read FClosed write SetClosed default True;
    property Placement:TDrawerPlacement read FPlacement write SetPlacement default dpLeft;
    property AutoOpenDelay:Integer read FAutoOpenDelay write FAutoOpenDelay default 1000;
    property AutoCloseDelay:Integer read FAutoCloseDelay write FAutoCloseDelay default 3000;
    property ArrowColor:TColor read FArrowColor write SetArrowColor default clBtnText;
    property ImmediateRefresh:Boolean read FImmediateRefresh write FImmediateRefresh default True;
    property ImmediateParentRefresh:Boolean read FImmediateParentRefresh write FImmediateParentRefresh default True;
    property OpenOnEnter:Boolean read FOpenOnEnter write FOpenOnEnter default True;
    property CloseOnExit:Boolean read FCloseOnExit write FCloseOnExit default True;
    property AnimationPause:Integer read FAnimationPause write FAnimationPause default 1000;
    property Anchors;
    property Font;
    property ParentFont;
    property Caption;
    property Color;
    property ParentColor;
    property TabOrder;
    property TabStop;
    property OnOpen:TNotifyEvent read FOnOpen write FOnOpen;
    property OnClose:TNotifyEvent read FOnClose write FOnClose;
    property OnPaint:TNotifyEvent read FOnPaint write FOnPaint;
    property OnClosing:TDrawerEvent read FOnClosing write FOnClosing;
    property OnOpening:TDrawerEvent read FOnOpening write FOnOpening;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
    property OnKeyDown;
    property OnKeyUp;
    property OnKeyPress;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
  end;

procedure Register;

implementation

{$R Drawer.dcr}

const TimerResolution=100;

type TScanLine=array[0..10000] of TRGBTriple;
     PScanLine=^TScanLine;

     TDrawersList=class
                   private
                    FTimer:TTimer;
                    FList:TList;
                    procedure TimerEvent(Sender:TObject);
                   public
                    constructor Create;
                    destructor Destroy;override;
                    procedure AddDrawer(Drawer:TDrawer);
                    procedure RemoveDrawer(Drawer:TDrawer);
                  end;

var DrawersList:TDrawersList;

{TDrawersList}

constructor TDrawersList.Create;
 begin
  inherited;
  FList:=TList.Create;
  FTimer:=TTimer.Create(nil);
  FTimer.Interval:=0;
  FTimer.OnTimer:=TimerEvent
 end;

destructor TDrawersList.Destroy;
 begin
  FList.Free;
  FTimer.Free;
  inherited
 end;

procedure TDrawersList.TimerEvent(Sender:TObject);
 var Wnd:HWnd;
     I:Integer;
  begin
   Wnd:=WindowFromPoint(Mouse.CursorPos);
   for I:=0 to FList.Count-1 do
    TDrawer(FList[I]).TimerEvent(Wnd)
  end;

procedure TDrawersList.AddDrawer(Drawer:TDrawer);
 begin
  if not (csDesigning in Drawer.ComponentState) then
   begin
    if FList.IndexOf(Drawer)<0 then
     FList.Add(Drawer);
    if FTimer.Interval=0 then
     FTimer.Interval:=TimerResolution
   end
 end;

procedure TDrawersList.RemoveDrawer(Drawer:TDrawer);
 var Index:Integer;
  begin
   Index:=FList.IndexOf(Drawer);
   while Index>=0 do
    begin
     FList.Delete(Index);
     Index:=FList.IndexOf(Drawer)
    end;
   if FList.Count=0 then
    FTimer.Interval:=0
  end;

{TDrawer}

constructor TDrawer.Create(AOwner:TComponent);
 begin
  inherited;
  FPlacement:=dpLeft;
  ControlStyle:=[csAcceptsControls,csOpaque];
  FArrowColor:=clBtnText;
  FClosed:=True;
  FAnimationPause:=1000;
  FAutoOpenDelay:=1000;
  FAutoCloseDelay:=3000;
  FCaptionText:=TBitmap.Create;
  FCaptionImage:=TBitmap.Create;
  FCaptionSize:=10;
  FAnimating:=False;
  FOpenOnEnter:=True;
  FCloseOnExit:=True;
  ImmediateRefresh:=True;
  ImmediateParentRefresh:=True;
  DrawersList.AddDrawer(Self)
 end;

destructor TDrawer.Destroy;
 begin
  DrawersList.RemoveDrawer(Self);
  if FR1<>0 then
   DeleteObject(FR1);
  if FR2<>0 then
   DeleteObject(FR2);
  FCaptionImage.Free;
  FCaptionText.Free;
  inherited
 end;

procedure TDrawer.Loaded;
 begin
  inherited;
  UpdateObliqueRegions;
  SetBounds(Left,Top,Width,Height);
  UpdateRegion
 end;

procedure TDrawer.WMNCCalcSize(var Msg:TWMNCCalcSize);
 begin
  inherited;
  with Msg.CalcSize_Params^ do
   begin
    InflateRect(rgrc[0],-2,-2);
    case FPlacement of
     dpLeft:Dec(rgrc[0].Right,FCaptionSize-2);
     dpRight:Inc(rgrc[0].Left,FCaptionSize-2);
     dpTop:Dec(rgrc[0].Bottom,FCaptionSize-2);
     dpBottom:Inc(rgrc[0].Top,FCaptionSize-2)
    end
   end;
  Msg.Result:=0
 end;

procedure TDrawer.WMNCHitTest(var Msg:TWMNCHitTest);
 var Pt:TPoint;
  begin
   Msg.Result:=HTClient;
   if not (csDesigning in ComponentState) then
    begin
     Pt:=ScreenToClient(Point(Msg.XPos,Msg.YPos));
     if (Pt.X<2) or (Pt.X>Width-2) or (Pt.Y<2) or (Pt.Y>Height-2) then
      Msg.Result:=HTBorder;
     case FPlacement of
      dpLeft:if Pt.X>Width-FCaptionSize then
              Msg.Result:=HTCaption;
      dpRight:if Pt.X<FCaptionSize then
               Msg.Result:=HTCaption;
      dpTop:if Pt.Y>Height-FCaptionSize then
             Msg.Result:=HTCaption;
      dpBottom:if Pt.Y<FCaptionSize then
                Msg.Result:=HTCaption
     end
    end
  end;

procedure TDrawer.WMNCPaint(var Msg:TWMNCPaint);
 var DC:HDC;
     R:TRect;
     Canvas:TCanvas;
  begin
   DC:=GetWindowDC(Handle);
   try
    Canvas:=TCanvas.Create;
    try
     Canvas.Handle:=DC;
     R:=BoundsRect;
     OffsetRect(R,-R.Left,-R.Top);
     Frame3D(Canvas,R,clBtnHighlight,clBtnShadow,1);
     Frame3D(Canvas,R,clBtnShadow,clBtnHighlight,1);
     if FPlacement in [dpRight,dpBottom] then
      Canvas.Draw(0,0,FCaptionImage)
     else if FPlacement=dpLeft then
      Canvas.Draw(Width-FCaptionSize,0,FCaptionImage)
     else
      Canvas.Draw(0,Height-FCaptionSize,FCaptionImage)
    finally
     Canvas.Free
    end
   finally
    ReleaseDC(Handle,DC)
   end;
   Msg.Result:=0
  end;

procedure TDrawer.SetPlacement(Value:TDrawerPlacement);
 begin
  if Value<>FPlacement then
   begin
    FPlacement:=Value;
    RecreateWnd;
    UpdateCaptionBitmap;
    UpdateObliqueRegions;
    UpdateRegion
   end
 end;

procedure TDrawer.Open;
 var P:Integer;
     InitCounterValue,CounterValue,PauseLength:Int64;
     Allow:Boolean;
  begin
   Allow:=True;
   if FClosed and Assigned(FOnOpening) then
    FOnOpening(Self,Allow);
   if not Allow then
    Exit;
   BringToFront;
   if FClosed then
    begin
     FClosed:=False;
     if FAnimationPause<=0 then
      SetBounds(Left,Top,Width,Height)
     else
      begin
       FAnimating:=True;
       QueryPerformanceFrequency(PauseLength);
       PauseLength:=(PauseLength*FAnimationPause) div 1000000;
       case FPlacement of
        dpLeft:for P:=Left to 0 do
                begin
                 QueryPerformanceCounter(InitCounterValue);
                 Left:=P;
                 if FImmediateRefresh then
                  Refresh;
                 repeat
                  QueryPerformanceCounter(CounterValue)
                 until CounterValue-InitCounterValue>=PauseLength
                end;
        dpRight:for P:=Left downto Parent.ClientWidth-Width do
                 begin
                  QueryPerformanceCounter(InitCounterValue);
                  Left:=P;
                  if FImmediateRefresh then
                   Refresh;
                  repeat
                   QueryPerformanceCounter(CounterValue)
                  until CounterValue-InitCounterValue>=PauseLength
                 end;
        dpTop:for P:=Top to 0 do
               begin
                QueryPerformanceCounter(InitCounterValue);
                Top:=P;
                if FImmediateRefresh then
                 Refresh;
                repeat
                 QueryPerformanceCounter(CounterValue)
                until CounterValue-InitCounterValue>=PauseLength
               end;
        dpBottom:for P:=Top downto Parent.ClientHeight-Height do
                  begin
                   QueryPerformanceCounter(InitCounterValue);
                   Top:=P;
                   if FImmediateRefresh then
                    Refresh;
                   repeat
                    QueryPerformanceCounter(CounterValue)
                   until CounterValue-InitCounterValue>=PauseLength
                  end;
       end;
       FAnimating:=False
      end;
     if FCaptionText.Empty then
      UpdateCaption(FCaptionImage,False);
     Perform(WM_NCPaint,0,0);
     if not ContainsControl(Screen.ActiveControl) then
      SelectFirst;
     if Assigned(FOnOpen) then
      FOnOpen(Self)
    end
  end;

procedure TDrawer.Close;
 var P:Integer;
     InitCounterValue,CounterValue,PauseLength:Int64;
     Allow:Boolean;
  begin
   if not FClosed then
    begin
     Allow:=True;
     if Assigned(FOnClosing) then
      FOnClosing(Self,Allow);
     if not Allow then
      Exit;
     FClosed:=True;
     if FAnimationPause<=0 then
      SetBounds(Left,Top,Width,Height)
     else
      begin
       FAnimating:=True;
       QueryPerformanceFrequency(PauseLength);
       PauseLength:=(PauseLength*FAnimationPause) div 1000000;
       case FPlacement of
        dpLeft:for P:=Left downto FCaptionSize-Width do
                begin
                 QueryPerformanceCounter(InitCounterValue);
                 Left:=P;
                 if FImmediateRefresh then
                  Refresh;
                 if ImmediateParentRefresh then
                  Parent.Refresh;
                 repeat
                  QueryPerformanceCounter(CounterValue)
                 until CounterValue-InitCounterValue>=PauseLength
                end;
        dpRight:for P:=Left to Parent.ClientWidth-FCaptionSize do
                 begin
                  QueryPerformanceCounter(InitCounterValue);
                  Left:=P;
                  if FImmediateRefresh then
                   Refresh;
                  if ImmediateParentRefresh then
                   Parent.Refresh;
                  repeat
                   QueryPerformanceCounter(CounterValue)
                  until CounterValue-InitCounterValue>=PauseLength
                 end;
        dpTop:for P:=Top downto FCaptionSize-Height do
               begin
                QueryPerformanceCounter(InitCounterValue);
                Top:=P;
                if FImmediateRefresh then
                 Refresh;
                if ImmediateParentRefresh then
                 Parent.Refresh;
                repeat
                 QueryPerformanceCounter(CounterValue)
                until CounterValue-InitCounterValue>=PauseLength
               end;
        dpBottom:for P:=Top to Parent.ClientHeight-FCaptionSize do
                  begin
                   QueryPerformanceCounter(InitCounterValue);
                   Top:=P;
                   if FImmediateRefresh then
                    Refresh;
                   if ImmediateParentRefresh then
                    Parent.Refresh;
                   repeat
                    QueryPerformanceCounter(CounterValue)
                   until CounterValue-InitCounterValue>=PauseLength
                  end;
       end;
       FAnimating:=False
      end;
     if FCaptionText.Empty then
      UpdateCaption(FCaptionImage,False);
     Perform(WM_NCPaint,0,0);
     if Assigned(FOnClose) then
      FOnClose(Self)
    end
  end;

procedure TDrawer.WMNCLButtonDown(var Msg:TWMNCLButtonDown);
 begin
  if Msg.HitTest=HTCaption then
   begin
    if not (csDesigning in ComponentState) then
     if FClosed then
      Open
     else
      Close;
    Msg.Result:=0
   end
  else
   inherited
 end;

procedure TDrawer.WMNCLButtonDblClk(var Msg:TWMNCLButtonDblClk);
 begin
  if Msg.HitTest=HTCaption then
   Msg.Result:=0
  else
   inherited
 end;

procedure TDrawer.SetClosed(Value:Boolean);
 begin
  if Value<>FClosed then
   if Value then
    Close
   else
    Open
 end;

procedure TDrawer.TimerEvent(Wnd:HWnd);
 var InWindow:Boolean;
  begin
   InWindow:=(Wnd=Self.Handle) or IsChild(Self.Handle,Wnd);
   if FClosed and (FAutoOpenDelay>0) then
    if InWindow then
     begin
      Inc(FDelayTime,TimerResolution);
      if FDelayTime>=FAutoOpenDelay then
       begin
        Open;
        FDelayTime:=0
       end
     end
    else
     FDelayTime:=0
   else if not FClosed and (FAutoCloseDelay>0) then
    if InWindow then
     FDelayTime:=0
    else
     begin
      Inc(FDelayTime,TimerResolution);
      if FDelayTime>=FAutoCloseDelay then
       begin
        Close;
        FDelayTime:=0
       end
     end
  end;

procedure TDrawer.Paint;
 begin
  Canvas.Brush.Style:=bsSolid;
  Canvas.Brush.Color:=Color;
  Canvas.FillRect(ClientRect);
  if Assigned(FOnPaint) then
   FOnPaint(Self)
 end;

procedure TDrawer.CMTextChanged(var Msg:TMessage);
 begin
  inherited;
  UpdateCaptionBitmap
 end;

procedure TDrawer.SetCaptionSize(Value:Integer);
 begin
  if FCaptionSize<>Value then
   begin
    FCaptionSize:=Value;
    RecreateWnd;
    UpdateObliqueRegions;
    UpdateCaption(FCaptionImage,False);
    UpdateRegion
   end
 end;

procedure TDrawer.UpdateObliqueRegions;
 var C,X,Y,DX,DY:Integer;
     R1:HRgn;
     Capt:TBitmap;
     P:PScanLine;
  begin
   if FR1<>0 then
    begin
     DeleteObject(FR1);
     FR1:=0
    end;
   if FR2<>0 then
    begin
     DeleteObject(FR2);
     FR2:=0
    end;
   if not FCaptionText.Empty then
    begin
     FR1:=CreateRectRgn(0,0,0,0);
     FR2:=CreateRectRgn(0,0,0,0);
     Capt:=TBitmap.Create;
     try
      UpdateCaption(Capt,True);
      case FPlacement of
       dpLeft:begin
               C:=(Height-FCaptionText.Height) div 2;
               DX:=FCaptionText.Width-5;
               DY:=2+DX div 2;
               for X:=10 to FCaptionSize-2 do
                begin
                 Y:=C-2;
                 while Y>0 do
                  begin
                   P:=Capt.ScanLine[Y];
                   if P[X].rgbtBlue=0 then
                    Break;
                   Dec(Y)
                  end;
                 if X=FCaptionSize-2 then
                  R1:=CreateRectRgn(X,-DY-2,X+2,Y-C-1)
                 else
                  R1:=CreateRectRgn(X,-DY-2,X+1,Y-C-1);
                 CombineRgn(FR1,FR1,R1,Rgn_Or);
                 DeleteObject(R1);
                 Y:=C+FCaptionText.Height+1;
                 while Y<Height do
                  begin
                   P:=Capt.ScanLine[Y];
                   if P[X].rgbtBlue=0 then
                    Break;
                   Inc(Y)
                  end;
                 if X=FCaptionSize-2 then
                  R1:=CreateRectRgn(X,Y+2-C-FCaptionText.Height,X+2,DY+2)
                 else
                  R1:=CreateRectRgn(X,Y+2-C-FCaptionText.Height,X+1,DY+2);
                 CombineRgn(FR2,FR2,R1,Rgn_Or);
                 DeleteObject(R1)
                end
              end;
       dpRight:begin
                C:=(Height-FCaptionText.Height) div 2;
                DX:=FCaptionText.Width-5;
                DY:=2+DX div 2;
                for X:=FCaptionSize-11 downto 1 do
                 begin
                  Y:=C-2;
                  while Y>0 do
                   begin
                    P:=Capt.ScanLine[Y];
                    if P[X].rgbtBlue=0 then
                     Break;
                    Dec(Y)
                   end;
                  if X=1 then
                   R1:=CreateRectRgn(0,-DY-2,2,Y-C-1)
                  else
                   R1:=CreateRectRgn(X,-DY-2,X+1,Y-C-1);
                  CombineRgn(FR1,FR1,R1,Rgn_Or);
                  DeleteObject(R1);
                  Y:=C+FCaptionText.Height+1;
                  while Y<Height do
                   begin
                    P:=Capt.ScanLine[Y];
                    if P[X].rgbtBlue=0 then
                     Break;
                    Inc(Y)
                   end;
                  if X=1 then
                   R1:=CreateRectRgn(0,Y+2-C-FCaptionText.Height,2,DY+2)
                  else
                   R1:=CreateRectRgn(X,Y+2-C-FCaptionText.Height,X+1,DY+2);
                  CombineRgn(FR2,FR2,R1,Rgn_Or);
                  DeleteObject(R1)
                 end
               end;
       dpTop:begin
              C:=(Width-FCaptionText.Width) div 2;
              DY:=FCaptionText.Height-5;
              DX:=2+DY div 2;
              for Y:=10 to FCaptionSize-2 do
               begin
                P:=Capt.ScanLine[Y];
                X:=C-2;
                while X>0 do
                 begin
                  if P[X].rgbtBlue=0 then
                   Break;
                  Dec(X)
                 end;
                if Y=FCaptionSize-2 then
                 R1:=CreateRectRgn(-DX-2,Y,X-C-1,Y+2)
                else
                 R1:=CreateRectRgn(-DX-2,Y,X-C-1,Y+1);
                CombineRgn(FR1,FR1,R1,Rgn_Or);
                DeleteObject(R1);
                X:=C+FCaptionText.Width+1;
                while X<Width do
                 begin
                  if P[X].rgbtBlue=0 then
                   Break;
                  Inc(X)
                 end;
                if Y=FCaptionSize-2 then
                 R1:=CreateRectRgn(X+2-FCaptionText.Width-C,Y,DX+2,Y+2)
                else
                 R1:=CreateRectRgn(X+2-FCaptionText.Width-C,Y,DX+2,Y+1);
                CombineRgn(FR2,FR2,R1,Rgn_Or);
                DeleteObject(R1)
               end
             end;
       dpBottom:begin
                 C:=(Width-FCaptionText.Width) div 2;
                 DY:=FCaptionText.Height-5;
                 DX:=2+DY div 2;
                 for Y:=FCaptionSize-11 downto 0 do
                  begin
                   P:=Capt.ScanLine[Y];
                   X:=C-2;
                   while X>0 do
                    begin
                     if P[X].rgbtBlue=0 then
                      Break;
                     Dec(X)
                    end;
                   if Y=1 then
                    R1:=CreateRectRgn(-DX-2,0,X-C-1,2)
                   else
                    R1:=CreateRectRgn(-DX-2,Y,X-C-1,Y+1);
                   CombineRgn(FR1,FR1,R1,Rgn_Or);
                   DeleteObject(R1);
                   X:=C+FCaptionText.Width+1;
                   while X<Width do
                    begin
                     if P[X].rgbtBlue=0 then
                      Break;
                     Inc(X)
                    end;
                   if Y=1 then
                    R1:=CreateRectRgn(X+2-FCaptionText.Width-C,0,DX+2,2)
                   else
                    R1:=CreateRectRgn(X+2-FCaptionText.Width-C,Y,DX+2,Y+1);
                   CombineRgn(FR2,FR2,R1,Rgn_Or);
                   DeleteObject(R1)
                  end
                end
      end
     finally
      Capt.Free
     end
    end;
  end;

procedure TDrawer.UpdateRegion;
 var C,DX,DY:Integer;
     R1,R2:HRgn;
  begin
   if not Assigned(Parent) then
    Exit;
   if FCaptionText.Empty then
    SetWindowRgn(Handle,0,True)
   else
    begin
     R1:=CreateRectRgn(0,0,Width,Height);
     case FPlacement of
      dpLeft:begin
              C:=(Height-FCaptionText.Height) div 2;
              DX:=FCaptionText.Width-5;
              DY:=2+DX div 2;
              R2:=CreateRectRgn(0,0,1,1);
              CombineRgn(R2,FR1,0,Rgn_Copy);
              OffsetRgn(R2,Width-FCaptionSize,C);
              CombineRgn(R1,R1,R2,Rgn_Diff);
              CombineRgn(R2,FR2,0,Rgn_Copy);
              OffsetRgn(R2,Width-FCaptionSize,C+FCaptionText.Height);
              CombineRgn(R1,R1,R2,Rgn_Diff);
              DeleteObject(R2);
              R2:=CreateRectRgn(Width-FCaptionSize+10,0,Width,C-DY-2);
              CombineRgn(R1,R1,R2,Rgn_Diff);
              DeleteObject(R2);
              R2:=CreateRectRgn(Width-FCaptionSize+10,C+FCaptionText.Height+DY+2,Width,Height);
              CombineRgn(R1,R1,R2,Rgn_Diff);
              DeleteObject(R2)
             end;
      dpRight:begin
               C:=(Height-FCaptionText.Height) div 2;
               DX:=FCaptionText.Width-5;
               DY:=2+DX div 2;
               R2:=CreateRectRgn(0,0,1,1);
               CombineRgn(R2,FR1,0,Rgn_Copy);
               OffsetRgn(R2,0,C);
               CombineRgn(R1,R1,R2,Rgn_Diff);
               CombineRgn(R2,FR2,0,Rgn_Copy);
               OffsetRgn(R2,0,C+FCaptionText.Height);
               CombineRgn(R1,R1,R2,Rgn_Diff);
               DeleteObject(R2);
               R2:=CreateRectRgn(0,0,FCaptionSize-10,C-DY-2);
               CombineRgn(R1,R1,R2,Rgn_Diff);
               DeleteObject(R2);
               R2:=CreateRectRgn(0,C+FCaptionText.Height+DY+2,FCaptionSize-10,Height);
               CombineRgn(R1,R1,R2,Rgn_Diff);
               DeleteObject(R2)
              end;
      dpTop:begin
             C:=(Width-FCaptionText.Width) div 2;
             DY:=FCaptionText.Height-5;
             DX:=2+DY div 2;
             R2:=CreateRectRgn(0,0,1,1);
             CombineRgn(R2,FR1,0,Rgn_Copy);
             OffsetRgn(R2,C,Height-FCaptionSize);
             CombineRgn(R1,R1,R2,Rgn_Diff);
             CombineRgn(R2,FR2,0,Rgn_Copy);
             OffsetRgn(R2,C+FCaptionText.Width,Height-FCaptionSize);
             CombineRgn(R1,R1,R2,Rgn_Diff);
             DeleteObject(R2);
             R2:=CreateRectRgn(0,Height-FCaptionSize+10,C-DX-2,Height);
             CombineRgn(R1,R1,R2,Rgn_Diff);
             DeleteObject(R2);
             R2:=CreateRectRgn(C+FCaptionText.Width+DX+2,Height-FCaptionSize+10,Width,Height);
             CombineRgn(R1,R1,R2,Rgn_Diff);
             DeleteObject(R2)
            end;
      dpBottom:begin
                C:=(Width-FCaptionText.Width) div 2;
                DY:=FCaptionText.Height-5;
                DX:=2+DY div 2;
                R2:=CreateRectRgn(0,0,1,1);
                CombineRgn(R2,FR1,0,Rgn_Copy);
                OffsetRgn(R2,C,0);
                CombineRgn(R1,R1,R2,Rgn_Diff);
                CombineRgn(R2,FR2,0,Rgn_Copy);
                OffsetRgn(R2,C+FCaptionText.Width,0);
                CombineRgn(R1,R1,R2,Rgn_Diff);
                DeleteObject(R2);
                R2:=CreateRectRgn(0,0,C-DX-2,FCaptionSize-10);
                CombineRgn(R1,R1,R2,Rgn_Diff);
                DeleteObject(R2);
                R2:=CreateRectRgn(C+FCaptionText.Width+DX+2,0,Width,FCaptionSize-10);
                CombineRgn(R1,R1,R2,Rgn_Diff);
                DeleteObject(R2)
               end
     end;
     SetWindowRgn(Handle,R1,True)
    end;
   Perform(WM_NCPaint,0,0)
  end;

procedure TDrawer.UpdateCaptionBitmap;
 var FullCaption:TBitmap;
     TextSize:TSize;
     X,Y,Leftmost,Rightmost,Topmost,Bottommost:Integer;
     RVal,GVal,BVal:Byte;
     P1,P2:PScanLine;
  begin
   if Caption='' then
    begin
     FCaptionText.Width:=0;
     FCaptionText.Height:=0;
     CaptionSize:=10;
     UpdateCaption(FCaptionImage,False)
    end
   else
    begin
     FullCaption:=TBitmap.Create;
     try
      FullCaption.PixelFormat:=pf24Bit;
      FullCaption.Width:=1;
      FullCaption.Height:=1;
      FullCaption.Canvas.Font:=Font;
      TextSize:=FullCaption.Canvas.TextExtent(Caption);
      FullCaption.Width:=TextSize.CX;
      FullCaption.Height:=TextSize.CY;
      FullCaption.Canvas.Brush.Style:=bsSolid;
      if Font.Color=clWhite then
       FullCaption.Canvas.Brush.Color:=clBlack
      else
       FullCaption.Canvas.Brush.Color:=clWhite;
      FullCaption.Canvas.FillRect(Rect(0,0,FullCaption.Width,FullCaption.Height));
      FullCaption.Canvas.TextOut(0,0,Caption);
      RVal:=GetRValue(ColorToRGB(Font.Color));
      GVal:=GetGValue(ColorToRGB(Font.Color));
      BVal:=GetBValue(ColorToRGB(Font.Color));
      Leftmost:=MaxInt;
      Rightmost:=0;
      Topmost:=MaxInt;
      Bottommost:=0;
      for Y:=0 to FullCaption.Height-1 do
       begin
        P1:=FullCaption.ScanLine[Y];
        for X:=0 to FullCaption.Width-1 do
         if (P1[X].rgbtRed=RVal) and (P1[X].rgbtGreen=GVal) and (P1[X].rgbtBlue=BVal) then
          begin
           if X<Leftmost then
            Leftmost:=X;
           if X>Rightmost then
            Rightmost:=X;
           if Y<Topmost then
            Topmost:=Y;
           if Y>Bottommost then
            Bottommost:=Y
          end
       end;
      FCaptionText.PixelFormat:=pf24Bit;
      FCaptionText.Canvas.Brush.Style:=bsSolid;
      FCaptionText.Canvas.Brush.Color:=Color;
      if FPlacement in [dpLeft,dpRight] then
       begin
        FCaptionText.Width:=Bottommost-Topmost+1;
        FCaptionText.Height:=Rightmost-Leftmost+1;
        FCaptionText.Canvas.FillRect(Rect(0,0,FCaptionText.Width,FCaptionText.Height));
        for Y:=Topmost to Bottommost do
         begin
          P1:=FullCaption.ScanLine[Y];
          for X:=Leftmost to Rightmost do
           if (P1[X].rgbtRed=RVal) and (P1[X].rgbtGreen=GVal) and (P1[X].rgbtBlue=BVal) then
            begin
             P2:=FCaptionText.ScanLine[FCaptionText.Height-1-X+Leftmost];
             P2[Y-Topmost].rgbtRed:=RVal;
             P2[Y-Topmost].rgbtGreen:=GVal;
             P2[Y-Topmost].rgbtBlue:=BVal
            end
         end;
        if CaptionSize<>FCaptionText.Width+6 then
         CaptionSize:=FCaptionText.Width+6
        else
         begin
          UpdateCaption(FCaptionImage,False);
          UpdateRegion
         end
       end
      else
       begin
        FCaptionText.Width:=Rightmost-Leftmost+1;
        FCaptionText.Height:=Bottommost-Topmost+1;
        FCaptionText.Canvas.FillRect(Rect(0,0,FCaptionText.Width,FCaptionText.Height));
        for Y:=Topmost to Bottommost do
         begin
          P1:=FullCaption.ScanLine[Y];
          P2:=FCaptionText.ScanLine[Y-Topmost];
          for X:=Leftmost to Rightmost do
           if (P1[X].rgbtRed=RVal) and (P1[X].rgbtGreen=GVal) and (P1[X].rgbtBlue=BVal) then
            begin
             P2[X-Leftmost].rgbtRed:=RVal;
             P2[X-Leftmost].rgbtGreen:=GVal;
             P2[X-Leftmost].rgbtBlue:=BVal
            end
         end;
        if CaptionSize<>FCaptionText.Height+6 then
         CaptionSize:=FCaptionText.Height+6
        else
         begin
          UpdateCaption(FCaptionImage,False);
          UpdateRegion
         end
       end
     finally
      FullCaption.Free
     end
    end
  end;

procedure TDrawer.CMFontChanged(var Msg:TMessage);
 begin
  inherited;
  UpdateCaptionBitmap
 end;

procedure TDrawer.CMColorChanged(var Msg:TMessage);
 begin
  inherited;
  UpdateCaptionBitmap;
  Perform(WM_NCPaint,0,0)
 end;

procedure TDrawer.SetBounds(ALeft,ATop,AWidth,AHeight:Integer);
 var UpdateNeeded:Boolean;
  begin
   UpdateNeeded:=((Width<>AWidth) or (Height<>AHeight)) and Assigned(Parent);
   if Assigned(Parent) and not FAnimating and not (csDesigning in ComponentState) and not (csLoading in ComponentState) then
    begin
     case FPlacement of
      dpLeft:if FClosed then
              ALeft:=FCaptionSize-AWidth
             else
              ALeft:=0;
      dpRight:if FClosed then
               ALeft:=Parent.ClientWidth-FCaptionSize
              else
               ALeft:=Parent.ClientWidth-AWidth;
      dpTop:if FClosed then
             ATop:=FCaptionSize-AHeight
            else
             ATop:=0;
      dpBottom:if FClosed then
                ATop:=Parent.ClientHeight-FCaptionSize
               else
                ATop:=Parent.ClientHeight-AHeight
     end
    end;
   inherited;
   if UpdateNeeded then
    begin
     if ((FPlacement in [dpLeft,dpRight]) and (AHeight<>FCaptionImage.Height)) or ((FPlacement in [dpTop,dpBottom]) and (AWidth<>FCaptionImage.Width)) then
      UpdateCaption(FCaptionImage,False);
     if FCaptionText.Empty then
      Perform(WM_NCPaint,0,0)
     else
      UpdateRegion
    end
  end;

procedure TDrawer.UpdateCaption(CaptPict:TBitmap;Contrast:Boolean);
 var C,DX,DY:Integer;
     R,R1:TRect;
  begin
   if Contrast then
    CaptPict.PixelFormat:=pf24Bit
   else
    CaptPict.PixelFormat:=pfDevice;
   if FPlacement in [dpLeft,dpRight] then
    begin
     CaptPict.Width:=FCaptionSize;
     CaptPict.Height:=Height
    end
   else
    begin
     CaptPict.Width:=Width;
     CaptPict.Height:=FCaptionSize
    end;
   CaptPict.Canvas.Brush.Style:=bsSolid;
   if Contrast then
    CaptPict.Canvas.Brush.Color:=clWhite
   else
    CaptPict.Canvas.Brush.Color:=Color;
   CaptPict.Canvas.FillRect(Rect(0,0,CaptPict.Width,CaptPict.Height));
   case FPlacement of
    dpLeft:begin
            R:=Rect(1,0,5,Height);
            R1:=R;
            OffsetRect(R1,4,0);
            if Contrast then
             begin
              Frame3D(CaptPict.Canvas,R,clBlack,clBlack,1);
              Frame3D(CaptPict.Canvas,R1,clBlack,clBlack,1)
             end
            else
             begin
              Frame3D(CaptPict.Canvas,R,clBtnHighlight,clBtnShadow,1);
              Frame3D(CaptPict.Canvas,R1,clBtnHighlight,clBtnShadow,1)
             end;
            if FCaptionText.Empty then
             begin
              C:=Height div 2;
              CaptPict.Canvas.FillRect(Rect(2,C-5,8,C+6));
              CaptPict.Canvas.Pen.Color:=FArrowColor;
              CaptPict.Canvas.Pen.Style:=psSolid;
              CaptPict.Canvas.Pen.Width:=1;
              CaptPict.Canvas.Brush.Color:=FArrowColor;
              if FClosed then
               CaptPict.Canvas.Polygon([Point(6,C),Point(3,C-3),Point(3,C+3)])
              else
               CaptPict.Canvas.Polygon([Point(3,C),Point(6,C-3),Point(6,C+3)])
             end
            else
             begin
              C:=(Height-FCaptionText.Height) div 2;
              DX:=FCaptionText.Width-5;
              DY:=2+DX div 2;
              CaptPict.Canvas.FillRect(Rect(2,C-DY,9,C+FCaptionText.Height+DY));
              if not Contrast then
               CaptPict.Canvas.Draw(3,C,FCaptionText);
              CaptPict.Canvas.Pen.Style:=psSolid;
              CaptPict.Canvas.Pen.Width:=1;
              if Contrast then
               CaptPict.Canvas.Pen.Color:=clBlack
              else
               CaptPict.Canvas.Pen.Color:=clBtnShadow;
              CaptPict.Canvas.MoveTo(FCaptionSize-2-DX,C-DY);
              CaptPict.Canvas.LineTo(FCaptionSize-3,C-3);
              CaptPict.Canvas.LineTo(FCaptionSize-2,C-2);
              CaptPict.Canvas.LineTo(FCaptionSize-2,C+FCaptionText.Height+1);
              CaptPict.Canvas.LineTo(FCaptionSize-3,C+FCaptionText.Height+2);
              CaptPict.Canvas.LineTo(FCaptionSize-2-DX,C+FCaptionText.Height+DY-1);
              CaptPict.Canvas.LineTo(FCaptionSize-3-DX,C+FCaptionText.Height+DY)
             end
           end;
    dpRight:begin
             R:=Rect(FCaptionSize-9,0,FCaptionSize-5,Height);
             R1:=R;
             OffsetRect(R1,4,0);
             if Contrast then
              begin
               Frame3D(CaptPict.Canvas,R,clBlack,clBlack,1);
               Frame3D(CaptPict.Canvas,R1,clBlack,clBlack,1)
              end
             else
              begin
               Frame3D(CaptPict.Canvas,R,clBtnHighlight,clBtnShadow,1);
               Frame3D(CaptPict.Canvas,R1,clBtnHighlight,clBtnShadow,1)
              end;
             if FCaptionText.Empty then
              begin
               C:=Height div 2;
               CaptPict.Canvas.FillRect(Rect(2,C-5,8,C+6));
               CaptPict.Canvas.Pen.Color:=FArrowColor;
               CaptPict.Canvas.Pen.Style:=psSolid;
               CaptPict.Canvas.Pen.Width:=1;
               CaptPict.Canvas.Brush.Color:=FArrowColor;
               if FClosed then
                CaptPict.Canvas.Polygon([Point(3,C),Point(6,C-3),Point(6,C+3)])
               else
                CaptPict.Canvas.Polygon([Point(6,C),Point(3,C-3),Point(3,C+3)])
              end
             else
              begin
               C:=(Height-FCaptionText.Height) div 2;
               DX:=FCaptionText.Width-5;
               DY:=2+DX div 2;
               CaptPict.Canvas.FillRect(Rect(0,C-DY,FCaptionSize-2,C+FCaptionText.Height+DY));
               if not Contrast then
                CaptPict.Canvas.Draw(3,C,FCaptionText);
               CaptPict.Canvas.Pen.Style:=psSolid;
               CaptPict.Canvas.Pen.Width:=1;
               if Contrast then
                CaptPict.Canvas.Pen.Color:=clBlack
               else
                CaptPict.Canvas.Pen.Color:=clBtnHighlight;
               CaptPict.Canvas.MoveTo(1+DX,C-DY);
               CaptPict.Canvas.LineTo(2,C-3);
               CaptPict.Canvas.LineTo(1,C-2);
               CaptPict.Canvas.LineTo(1,C+FCaptionText.Height+1);
               CaptPict.Canvas.LineTo(2,C+FCaptionText.Height+2);
               if not Contrast then
                CaptPict.Canvas.Pen.Color:=clBtnShadow;
               CaptPict.Canvas.LineTo(1+DX,C+FCaptionText.Height+DY-1);
               CaptPict.Canvas.LineTo(2+DX,C+FCaptionText.Height+DY)
              end
            end;
    dpTop:begin
           R:=Rect(0,1,Width,5);
           R1:=R;
           OffsetRect(R1,0,4);
           if Contrast then
            begin
             Frame3D(CaptPict.Canvas,R,clBlack,clBlack,1);
             Frame3D(CaptPict.Canvas,R1,clBlack,clBlack,1)
            end
           else
            begin
             Frame3D(CaptPict.Canvas,R,clBtnHighlight,clBtnShadow,1);
             Frame3D(CaptPict.Canvas,R1,clBtnHighlight,clBtnShadow,1)
            end;
           if FCaptionText.Empty then
            begin
             C:=Width div 2;
             CaptPict.Canvas.FillRect(Rect(C-5,Height-8,C+6,Height-2));
             CaptPict.Canvas.Pen.Color:=FArrowColor;
             CaptPict.Canvas.Pen.Style:=psSolid;
             CaptPict.Canvas.Pen.Width:=1;
             CaptPict.Canvas.Brush.Color:=FArrowColor;
             if FClosed then
              CaptPict.Canvas.Polygon([Point(C,Height-4),Point(C-3,Height-7),Point(C+3,Height-7)])
             else
              CaptPict.Canvas.Polygon([Point(C,Height-7),Point(C-3,Height-4),Point(C+3,Height-4)])
            end
           else
            begin
             C:=(Width-FCaptionText.Width) div 2;
             DY:=FCaptionText.Height-5;
             DX:=2+DY div 2;
             CaptPict.Canvas.FillRect(Rect(C-DX,2,C+FCaptionText.Width+DX,FCaptionSize));
             CaptPict.Canvas.Draw(C,3,FCaptionText);
             CaptPict.Canvas.Pen.Style:=psSolid;
             CaptPict.Canvas.Pen.Width:=1;
             if Contrast then
              CaptPict.Canvas.Pen.Color:=clBlack
             else
              CaptPict.Canvas.Pen.Color:=clBtnShadow;
             CaptPict.Canvas.MoveTo(C-DX,FCaptionSize-2-DY);
             CaptPict.Canvas.LineTo(C-3,FCaptionSize-3);
             CaptPict.Canvas.LineTo(C-2,FCaptionSize-2);
             CaptPict.Canvas.LineTo(C+FCaptionText.Width+1,FCaptionSize-2);
             CaptPict.Canvas.LineTo(C+FCaptionText.Width+2,FCaptionSize-3);
             CaptPict.Canvas.LineTo(C+FCaptionText.Width+DX-1,FCaptionSize-2-DY);
             CaptPict.Canvas.LineTo(C+FCaptionText.Width+DX,FCaptionSize-3-DY)
            end
          end;
    dpBottom:begin
              R:=Rect(0,FCaptionSize-9,Width,FCaptionSize-5);
              R1:=R;
              OffsetRect(R1,0,4);
              if Contrast then
               begin
                Frame3D(CaptPict.Canvas,R,clBlack,clBlack,1);
                Frame3D(CaptPict.Canvas,R1,clBlack,clBlack,1)
               end
              else
               begin
                Frame3D(CaptPict.Canvas,R,clBtnHighlight,clBtnShadow,1);
                Frame3D(CaptPict.Canvas,R1,clBtnHighlight,clBtnShadow,1)
               end;
              if FCaptionText.Empty then
               begin
                C:=Width div 2;
                CaptPict.Canvas.FillRect(Rect(C-5,2,C+6,7));
                CaptPict.Canvas.Pen.Color:=FArrowColor;
                CaptPict.Canvas.Pen.Style:=psSolid;
                CaptPict.Canvas.Pen.Width:=1;
                CaptPict.Canvas.Brush.Color:=FArrowColor;
                if FClosed then
                 CaptPict.Canvas.Polygon([Point(C,3),Point(C-3,6),Point(C+3,6)])
                else
                 CaptPict.Canvas.Polygon([Point(C,6),Point(C-3,3),Point(C+3,3)])
               end
              else
               begin
                C:=(Width-FCaptionText.Width) div 2;
                DY:=FCaptionText.Height-5;
                DX:=2+DY div 2;
                CaptPict.Canvas.FillRect(Rect(C-DX,0,C+FCaptionText.Width+DX,FCaptionSize-2));
                if not Contrast then
                 CaptPict.Canvas.Draw(C,3,FCaptionText);
                CaptPict.Canvas.Pen.Style:=psSolid;
                CaptPict.Canvas.Pen.Width:=1;
                if Contrast then
                 CaptPict.Canvas.Pen.Color:=clBlack
                else
                 CaptPict.Canvas.Pen.Color:=clBtnHighlight;
                CaptPict.Canvas.MoveTo(C-DX,1+DY);
                CaptPict.Canvas.LineTo(C-3,2);
                CaptPict.Canvas.LineTo(C-2,1);
                CaptPict.Canvas.LineTo(C+FCaptionText.Width+1,1);
                CaptPict.Canvas.LineTo(C+FCaptionText.Width+2,2);
                if not Contrast then
                 CaptPict.Canvas.Pen.Color:=clBtnShadow;
                CaptPict.Canvas.LineTo(C+FCaptionText.Width+DX-1,1+DY);
                CaptPict.Canvas.LineTo(C+FCaptionText.Width+DX,2+DY)
               end
             end
   end
  end;

procedure TDrawer.SetArrowColor(Value:TColor);
 begin
  if Value<>FArrowColor then
   begin
    FArrowColor:=Value;
    if FCaptionText.Empty then
     begin
      UpdateCaptionBitmap;
      Perform(WM_NCPaint,0,0)
     end
   end
 end;

procedure TDrawer.CMEnter(var Msg:TMessage);
 begin
  inherited;
  if not FClosed then
   BringToFront
  else
   if FOpenOnEnter then
    Open
 end;

procedure TDrawer.CMExit(var Msg:TMessage);
 begin
  inherited;
  if FCloseOnExit then
   Close
 end;

procedure Register;
begin
  RegisterComponents('My Controls', [TDrawer]);
end;

initialization
 DrawersList:=TDrawersList.Create;

finalization
 DrawersList.Free;

end.

