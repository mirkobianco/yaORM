(*
  yet another ORM - for FreePascal
  ORM List (collection) Mediator

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Mediators.Lists;

{$mode Delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  TypInfo,
  fgl,
  yaORM.Types,
  yaORM.Collections,
  yaORM.Mediators.GUI.Properties;

type
  { TListMediator<TItem> }

  TListMediator<TItem: TPersistent> = class(TPersistent, IFPObserver)
  public
  type
    TItemDescFunc = function(const AItem: TItem): string;
    TGUIItemMediator = TGUIMediator<TItem>;
  strict private
    FList: TObjectList<TItem>;
    FUpdateCount: integer;

    FPropertyMediators: TFPGObjectList<TGUIItemMediator>;

    procedure InitializeListElements;
    procedure FinalizeListElements;

    //IFPObserver
    procedure FPOObservedChanged(ASender : TObject; Operation : TFPObservedOperation; Data : Pointer);
  public
    constructor Create(const AList: TObjectList<TItem>);
    destructor Destroy; override;

    procedure DisableControl;
    procedure EnableControl;

    procedure ChangeSelectedItem(const AItem: TItem);

    procedure AttachPropertyMediator(const AMediator: TGUIItemMediator);
    procedure DetachPropertyMediator(const AMediator: TGUIItemMediator);

    property List: TObjectList<TItem> read FList;
  end;

implementation

{ TListMediator<TItem> }

procedure TListMediator<TItem>.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
var
  LIntf: IFPObserved;
  LItem: TItem;
begin
  LItem := TItem(Data);
  case Operation of
    ooFree: begin
      if Supports(ASender, IFPObserved, LIntf) and Assigned(LIntf) then
        LIntf.FPODetachObserver(self);

      if ASender.InheritsFrom(TGUIItemMediator) then
        FPropertyMediators.Extract(ASender as TGUIItemMediator);
    end;
    ooChange: begin

    end;
    ooAddItem: begin
      if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
        LIntf.FPOAttachObserver(self);
    end;
    ooDeleteItem: begin
      if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
        LIntf.FPODetachObserver(self);
    end;
    ooCustom: begin
      FPONotifyObservers(Self, ooCustom, Pointer(LItem));
    end;
  end;
end;

constructor TListMediator<TItem>.Create(const AList: TObjectList<TItem>);
var
  LIntf: IFPObserved;
begin
  inherited Create;
  FList := AList;

  InitializeListElements;

  FUpdateCount := 0;

  { attach List }
  if Supports(FList, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  EnableControl;

  FPropertyMediators := TFPGObjectList<TGUIItemMediator>.Create(false);
end;

destructor TListMediator<TItem>.Destroy;
var
  LIntf: IFPObserved;
begin
  { detach List }
  if Supports(FList, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);

  FinalizeListElements;

  FreeAndNil(FPropertyMediators);

  inherited Destroy;
end;

procedure TListMediator<TItem>.DisableControl;
begin
  Inc(FUpdateCount);
end;

procedure TListMediator<TItem>.EnableControl;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount <> 0 then
    Exit;

  FPOObservedChanged(FList, ooChange, nil);
end;

procedure TListMediator<TItem>.InitializeListElements;
var
  LItem: TItem;
  LIndex: integer;
  LIntf: IFPObserved;
begin
  for LIndex := 0 to FList.Count - 1 do
  begin
    LItem := FList.Items[LIndex];
    if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
      LIntf.FPOAttachObserver(self);
  end;
end;

procedure TListMediator<TItem>.FinalizeListElements;
var
  LItem: TItem;
  LIndex: integer;
  LIntf: IFPObserved;
begin
  for LIndex := 0 to FList.Count - 1 do
  begin
    LItem := FList.Items[LIndex];
    if Supports(LItem, IFPObserved, LIntf) and Assigned(LIntf) then
      LIntf.FPODetachObserver(self);
  end;
end;

procedure TListMediator<TItem>.AttachPropertyMediator(const AMediator: TGUIItemMediator);
begin
  if not Assigned(AMediator) then
    Exit;

  FPropertyMediators.Add(AMediator);
  AMediator.FPOAttachObserver(self);
end;

procedure TListMediator<TItem>.DetachPropertyMediator(const AMediator: TGUIItemMediator);
begin
  if not Assigned(AMediator) then
    Exit;

  FPropertyMediators.Extract(AMediator);
  AMediator.FPODetachObserver(self);
end;

procedure TListMediator<TItem>.ChangeSelectedItem(const AItem: TItem);
var
  LMediator: TGUIItemMediator;
begin
  for LMediator in FPropertyMediators do
    LMediator.ChangeInstance(AItem);
end;

end.
