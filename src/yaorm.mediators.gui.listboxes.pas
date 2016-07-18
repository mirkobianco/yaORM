(*
  yet another ORM - for FreePascal
  ORM GUI Listbox Mediator

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Mediators.GUI.ListBoxes;

{$mode Delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  TypInfo,
  StdCtrls,
  fgl,
  yaORM.Types,
  yaORM.Collections,
  yaORM.Mediators.Lists;

type
  { TGUIListMediator<TItem> }

  TGUIListMediator<TItem: TPersistent; TListControl: TCustomListBox> = class(TPersistent, IFPObserver)
  public
  type
    TItemDescFunc = function(const AItem: TItem): string;
  strict private
    FListMediator: TListMediator<TItem>;
    FItemDescFunc: TItemDescFunc;
    FGUIControl: TListControl;
    FUpdateCount: integer;
    FOriginalOnExit: TNotifyEvent;
    FOriginalOnClick: TNotifyEvent;
    FOriginalOnDrawItem: TDrawItemEvent;
    FMediatorOnDrawItem: TDrawItemEvent;

    procedure DoExit(ASender : TObject);
    procedure DoClick(ASender : TObject);
    procedure DoDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);

    procedure DetachEventsFromGUIControl;
    procedure InitializeListElements;
    procedure FinalizeListElements;
    function GetItemIndex(const AItem: TItem): integer;

    //IFPObserver
    procedure FPOObservedChanged(ASender : TObject; Operation : TFPObservedOperation; Data : Pointer);
  public
    constructor Create(const AGUIControl: TListControl;
                       const AListMediator: TListMediator<TItem>;
                       const AItemDescFunc: TItemDescFunc;
                       const AOnDrawItem: TDrawItemEvent);
    destructor Destroy; override;

    procedure DisableControl;
    procedure EnableControl;
  end;

implementation

{ TGUIListMediator<TItem, TListControl> }

procedure TGUIListMediator<TItem, TListControl>.DetachEventsFromGUIControl;
begin
  if Assigned(FGUIControl) then
  begin
    FGUIControl.OnExit := FOriginalOnExit;
    FGUIControl.OnClick := FOriginalOnClick;
    FGUIControl.OnDrawItem := FOriginalOnDrawItem;
  end;
end;

procedure TGUIListMediator<TItem, TListControl>.DoExit(ASender: TObject);
begin
  FGUIControl.FPONotifyObservers(ASender, ooChange, nil);
  if Assigned(FOriginalOnExit) then
    FOriginalOnExit(ASender);
end;

procedure TGUIListMediator<TItem, TListControl>.DoClick(ASender: TObject);
var
  LItem: TItem;
begin
  if Assigned(FOriginalOnClick) then
    FOriginalOnClick(ASender);

  if FGUIControl.ItemIndex = -1 then
    Exit;

  LItem := FGUIControl.Items.Objects[FGUIControl.ItemIndex] as TItem;
  FListMediator.ChangeSelectedItem(LItem);
  FPONotifyObservers(Self, ooCustom, Pointer(LItem));
end;

procedure TGUIListMediator<TItem, TListControl>.DoDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
  if Assigned(FOriginalOnDrawItem) then
    FOriginalOnDrawItem(Control, Index, ARect, State);
  if Assigned(FMediatorOnDrawItem) then
    FMediatorOnDrawItem(Control, Index, ARect, State);
end;

procedure TGUIListMediator<TItem, TListControl>.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
var
  LIntf: IFPObserved;
  LItems: TStrings;
  LItem: TItem;
  LIndex: integer;
begin
  LItems := FGUIControl.Items;
  LItem := TItem(Data);
  case Operation of
    ooFree: begin
      if Supports(ASender, IFPObserved, LIntf) and Assigned(LIntf) then
        LIntf.FPODetachObserver(self);

      if ASender = FGUIControl then
        DetachEventsFromGUIControl;

    end;
    ooChange: begin
      if Assigned(LItem) then
      begin
        LIndex := LItems.IndexOfObject(LItem);
        if LIndex <> -1 then
          LItems.Strings[LIndex] := FItemDescFunc(LItem);
      end
      else
        for LIndex := 0 to LItems.Count - 1 do
          LItems.Strings[LIndex] := FItemDescFunc(LItems.Objects[LIndex] as TItem);
    end;
    ooAddItem: begin
      LItems.AddObject(FItemDescFunc(LItem), LItem);
      if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
        LIntf.FPOAttachObserver(self);
    end;
    ooDeleteItem: begin
      LIndex := GetItemIndex(LItem);
      if LIndex <> -1 then
      begin
        LItems.Delete(LIndex);
        if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
          LIntf.FPODetachObserver(self);
      end;
    end;
    oocustom:begin
      LIndex := LItems.IndexOfObject(LItem);
      if LIndex <> -1 then
        FGUIControl.ItemIndex := LIndex;
    end;
  end;
end;

function TGUIListMediator<TItem, TListControl>.GetItemIndex(const AItem: TItem): integer;
begin
  result := FGUIControl.Items.IndexOfObject(AItem);
end;

constructor TGUIListMediator<TItem, TListControl>.Create(const AGUIControl: TListControl;
                                                        const AListMediator: TListMediator<TItem>;
                                                        const AItemDescFunc: TItemDescFunc;
                                                        const AOnDrawItem: TDrawItemEvent);
var
  LIntf: IFPObserved;
begin
  inherited Create;
  FGUIControl := AGUIControl;
  FListMediator := AListMediator;
  FItemDescFunc := AItemDescFunc;

  InitializeListElements;

  FUpdateCount := 0;

  FMediatorOnDrawItem := AOnDrawItem;
  FOriginalOnExit := FGUIControl.OnExit;
  FOriginalOnClick := FGUIControl.OnClick;
  FOriginalOnDrawItem := FGUIControl.OnDrawItem;

  FGUIControl.OnExit := DoExit;
  FGUIControl.OnClick := DoClick;
  FGUIControl.OnDrawItem := DoDrawItem;

  { attach GUI Control }
  if Supports(FGUIControl, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  { attach ListMediator }
  if Supports(FListMediator, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  { Attach List }
  if Supports(FListMediator.List, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  { Attach self to ListMediator }
  if Supports(Self, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(FListMediator);

  EnableControl;

  if FGUIControl.Count > 0 then
  begin
    FGuiControl.ItemIndex := 0;
    DoClick(FGUIControl);
  end;
end;

destructor TGUIListMediator<TItem, TListControl>.Destroy;
var
  LIntf: IFPObserved;
begin
  { detach GUI Control }
  if Supports(FGUIControl, IFPObserved, LIntf) and Assigned(LIntf) then
  begin
    LIntf.FPODetachObserver(self);
    DetachEventsFromGUIControl;
  end;

  { Detach ListMediator }
  if Supports(FListMediator, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);

  { Detach List }
  if Supports(FListMediator.List, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);

  { Detach self from ListMediator }
  if Supports(Self, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(FListMediator);

  FinalizeListElements;

  inherited Destroy;
end;

procedure TGUIListMediator<TItem, TListControl>.DisableControl;
begin
  Inc(FUpdateCount);
end;

procedure TGUIListMediator<TItem, TListControl>.EnableControl;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount <> 0 then
    Exit;

  FPOObservedChanged(FListMediator.List, ooChange, nil);
  FPOObservedChanged(FGUIControl, ooChange, nil);
end;

procedure TGUIListMediator<TItem, TListControl>.InitializeListElements;
var
  LItems: TStrings;
  LItem: TItem;
  LIndex: integer;
  LIntf: IFPObserved;
begin
  LItems := FGUIControl.Items;
  LItems.Clear;
  for LIndex := 0 to FListMediator.List.Count - 1 do
  begin
    LItem := FListMediator.List.Items[LIndex];
    LItems.AddObject(FItemDescFunc(LItem), LItem);
    if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
      LIntf.FPOAttachObserver(self);
  end;
end;

procedure TGUIListMediator<TItem, TListControl>.FinalizeListElements;
var
  LItem: TItem;
  LIndex: integer;
  LIntf: IFPObserved;
begin
  for LIndex := 0 to FListMediator.List.Count - 1 do
  begin
    LItem := FListMediator.List.Items[LIndex];
    if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
      LIntf.FPODetachObserver(self);
  end;
  FGUIControl.Items.Clear;
end;

end.
