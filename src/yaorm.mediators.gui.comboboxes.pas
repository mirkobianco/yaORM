(*
  yet another ORM - for FreePascal
  ORM GUI Combobox Mediator

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Mediators.GUI.ComboBoxes;

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
  { TGUIComboBoxMediator<TItem> }

  TGUIComboBoxMediator<TItem: TPersistent; TComboBoxControl: TCustomComboBox> = class(TPersistent, IFPObserver)
  public
  type
    TItemDescFunc = function(const AItem: TItem): string;
  strict private
    FListMediator: TListMediator<TItem>;
    FItemDescFunc: TItemDescFunc;
    FGUIControl: TComboBoxControl;
    FUpdateCount: integer;
    FOriginalOnExit: TNotifyEvent;
    FOriginalOnSelect: TNotifyEvent;
    FOriginalOnDrawItem: TDrawItemEvent;
    FMediatorOnDrawItem: TDrawItemEvent;

    procedure DoExit(ASender : TObject);
    procedure DoSelect(ASender : TObject);
    procedure DoDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);

    procedure DetachEventsFromGUIControl;
    procedure InitializeListElements;
    procedure FinalizeListElements;
    function GetItemIndex(const AItem: TItem): integer;

    //IFPObserver
    procedure FPOObservedChanged(ASender : TObject; Operation : TFPObservedOperation; Data : Pointer);
  public
    constructor Create(const AGUIControl: TComboBoxControl;
                       const AListMediator: TListMediator<TItem>;
                       const AItemDescFunc: TItemDescFunc;
                       const AOnDrawItem: TDrawItemEvent);
    destructor Destroy; override;

    procedure DisableControl;
    procedure EnableControl;
  end;

implementation

{ TGUIComboBoxMediator<TItem, TComboBoxControl> }

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.DoExit(ASender: TObject);
begin
  FGUIControl.FPONotifyObservers(ASender, ooChange, nil);
    if Assigned(FOriginalOnExit) then
      FOriginalOnExit(ASender);
end;

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.DoSelect(ASender: TObject);
var
  LItem: TItem;
begin
  if Assigned(FOriginalOnSelect) then
    FOriginalOnSelect(ASender);

  if FGUIControl.ItemIndex = -1 then
    Exit;

  LItem := FGUIControl.Items.Objects[FGUIControl.ItemIndex] as TItem;
  FListMediator.ChangeSelectedItem(LItem);
  FPONotifyObservers(FListMediator.List, ooCustom, Pointer(LItem));
end;

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.DoDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
  if Assigned(FOriginalOnDrawItem) then
    FOriginalOnDrawItem(Control, Index, ARect, State);
  if Assigned(FMediatorOnDrawItem) then
    FMediatorOnDrawItem(Control, Index, ARect, State);
end;

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.DetachEventsFromGUIControl;
begin
  if Assigned(FGUIControl) then
  begin
    FGUIControl.OnExit := FOriginalOnExit;
    FGUIControl.OnSelect := FOriginalOnSelect;
    FGUIControl.OnDrawItem := FOriginalOnDrawItem;
  end;
end;

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.InitializeListElements;
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

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.FinalizeListElements;
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

function TGUIComboBoxMediator<TItem, TComboBoxControl>.GetItemIndex(const AItem: TItem): integer;
begin
  result := FGUIControl.Items.IndexOfObject(AItem);
end;

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
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
    ooCustom: begin
      LIndex := GetItemIndex(LItem);
      if LIndex <> -1 then
        FGUIControl.ItemIndex := LIndex;
    end;
  end;
end;

constructor TGUIComboBoxMediator<TItem, TComboBoxControl>.Create(const AGUIControl: TComboBoxControl;
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
  FOriginalOnSelect := FGUIControl.OnSelect;
  FOriginalOnDrawItem := FGUIControl.OnDrawItem;

  FGUIControl.OnExit := DoExit;
  FGUIControl.OnSelect := DoSelect;
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

  if FGUIControl.Items.Count > 0 then
  begin
    FGuiControl.ItemIndex := 0;
    DoSelect(FGUIControl);
  end;
end;

destructor TGUIComboBoxMediator<TItem, TComboBoxControl>.Destroy;
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

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.DisableControl;
begin
  Inc(FUpdateCount);
end;

procedure TGUIComboBoxMediator<TItem, TComboBoxControl>.EnableControl;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount <> 0 then
    Exit;

  FPOObservedChanged(FListMediator.List, ooChange, nil);
  FPOObservedChanged(FGUIControl, ooChange, nil);
end;

end.
