(*
  yet another ORM - for FreePascal
  ORM Delegated List (collection) Mediator

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Mediators.Lists.Delegated;

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
  yaORM.Mediators.GUI;

type
  { TDelegatedListMediator<TSourceItem, TDestItem> }

  TDelegatedListMediator<TSourceItem: TPersistent; TDestItem: TPersistent> = class(TPersistent, IFPObserver)
  public
  type
    TGUIItemMediator = TGUIMediator<TSourceItem>;
    TDestItemObjectList = TObjectList<TDestItem>;
    TGetDestInstanceFunc = function(const ASourceInstance: TSourceItem): TDestItemObjectList; //TObjectList<TDestItem>;
  strict private
    FSourceInstance: TSourceItem;
    FList: TObjectList<TSourceItem>;
    FGetDestInstanceFunc: TGetDestInstanceFunc;
    FUpdateCount: integer;

    FPropertyMediators: TFPGObjectList<TGUIItemMediator>;

    procedure InitializeListElements;
    procedure FinalizeListElements;

    //IFPObserver
    procedure FPOObservedChanged(ASender : TObject; Operation : TFPObservedOperation; Data : Pointer);
  public
    constructor Create(const ASourceInstance: TSourceItem;
                       const AGetDestInstanceFunc: TGetDestInstanceFunc);
    destructor Destroy; override;

    procedure DisableControl;
    procedure EnableControl;

    procedure ChangeSelectedItem(const AItem: TSourceItem);

    procedure AttachPropertyMediator(const AMediator: TGUIItemMediator);
    procedure DetachPropertyMediator(const AMediator: TGUIItemMediator);

    property List: TObjectList<TSourceItem> read FList;
  end;

implementation

{ TDelegatedListMediator<TSourceItem> }

procedure TDelegatedListMediator<TSourceItem, TDestItem>.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
var
  LIntf: IFPObserved;
  LItem: TSourceItem;
begin
  LItem := TSourceItem(Data);
  case Operation of
    ooFree: begin
      if Supports(ASender, IFPObserved, LIntf) and Assigned(LIntf) then
        LIntf.FPODetachObserver(self);

      if ASender.InheritsFrom(TGUIItemMediator) then
        FPropertyMediators.Extract(ASender as TGUIItemMediator);
    end;
    ooChange: begin
      if ASender.ClassType = TSourceItem then
      begin
        FinalizeListElements;
        if Supports(FList, IFPObserved, LIntf) and Assigned(LIntf) then
          LIntf.FPODetachObserver(self);

        FList := FGetDestInstanceFunc(TSourceItem(ASender));

        if Supports(FList, IFPObserved, LIntf) and Assigned(LIntf) then
          LIntf.FPOAttachObserver(self);
        InitializeListElements;
      end;
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

constructor TDelegatedListMediator<TSourceItem, TDestItem>.Create(const ASourceInstance: TSourceItem;
                                                                  const AGetDestInstanceFunc: TGetDestInstanceFunc);
var
  LIntf: IFPObserved;
begin
  inherited Create;
  FSourceInstance := ASourceInstance;
  FGetDestInstanceFunc := AGetDestInstanceFunc;
  FList := FGetDestInstanceFunc(ASourceInstance);

  InitializeListElements;

  FUpdateCount := 0;

  { attach Source Instance }
  if Supports(ASourceInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  { attach List }
  if Supports(FList, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  EnableControl;

  FPropertyMediators := TFPGObjectList<TGUIItemMediator>.Create(false);
end;

destructor TDelegatedListMediator<TSourceItem, TDestItem>.Destroy;
var
  LIntf: IFPObserved;
begin
  { detach Source Instance }
  if Supports(FSourceInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);

  { detach List }
  if Supports(FList, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);

  FinalizeListElements;

  FreeAndNil(FPropertyMediators);

  inherited Destroy;
end;

procedure TDelegatedListMediator<TSourceItem, TDestItem>.DisableControl;
begin
  Inc(FUpdateCount);
end;

procedure TDelegatedListMediator<TSourceItem, TDestItem>.EnableControl;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount <> 0 then
    Exit;

  FPOObservedChanged(FList, ooChange, nil);
end;

procedure TDelegatedListMediator<TSourceItem, TDestItem>.InitializeListElements;
var
  LItem: TSourceItem;
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

procedure TDelegatedListMediator<TSourceItem, TDestItem>.FinalizeListElements;
var
  LItem: TSourceItem;
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

procedure TDelegatedListMediator<TSourceItem, TDestItem>.AttachPropertyMediator(const AMediator: TGUIItemMediator);
begin
  if not Assigned(AMediator) then
    Exit;

  FPropertyMediators.Add(AMediator);
  AMediator.FPOAttachObserver(self);
end;

procedure TDelegatedListMediator<TSourceItem, TDestItem>.DetachPropertyMediator(const AMediator: TGUIItemMediator);
begin
  if not Assigned(AMediator) then
    Exit;

  FPropertyMediators.Extract(AMediator);
  AMediator.FPODetachObserver(self);
end;

procedure TDelegatedListMediator<TSourceItem, TDestItem>.ChangeSelectedItem(const AItem: TSourceItem);
var
  LMediator: TGUIItemMediator;
begin
  for LMediator in FPropertyMediators do
    LMediator.ChangeInstance(AItem);
end;

end.
