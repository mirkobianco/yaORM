(*
  yet another ORM - for FreePascal
  ORM GUI Delegated Component Mediator

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Mediators.GUI.Properties.Delegated;

{$mode Delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  TypInfo,
  yaORM.Types,
  yaORM.Mediators.GUI;

type
  { TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl> }

  TGUIDelegatedPropertyMediator<TSourceItem: TPersistent; TDestItem: TPersistent; TGUIControl: TWinControl> = class(TGUIMediator<TSourceItem>, IFPObserver)
  public
  type
    TGetDestInstanceFunc = function(const ASourceInstance: TSourceItem): TDestItem;
  strict private
    FGUIControl: TGUIControl;
    FGUIControlPropertyName: string;
    FSourceInstance: TSourceItem;
    FGetDestInstance: TGetDestInstanceFunc;
    FDestInstancePropertyName: string;
    FUpdateCount: integer;
    FOriginalOnExit: TNotifyEvent;

    procedure DoExit(ASender : TObject);
    procedure DetachEventsFromGUIControl;

    //IFPObserver
    procedure FPOObservedChanged(ASender : TObject; Operation : TFPObservedOperation; Data : Pointer);
  public
    constructor Create(const AGUIControl: TGUIControl;
                       const AGUIControlPropertyName: string;
                       const ASourceInstance: TSourceItem;
                       const AGetDestInstance: TGetDestInstanceFunc;
                       const ADestInstancePropertyName: string); reintroduce;
    destructor Destroy; override;

    procedure ChangeInstance(const AInstance: TSourceItem); override;

    procedure DisableControl;
    procedure EnableControl;
  end;

implementation

{ TGUIDelegatedPropertyMediator<<TSourceItem, TGUIControl> }

procedure TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.ChangeInstance(const AInstance: TSourceItem);
var
  LIntf: IFPObserved;
begin
  DisableControl;

  if Supports(FSourceInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);
  FSourceInstance := AInstance;
  if Supports(FSourceInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  EnableControl;
end;

procedure TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.DetachEventsFromGUIControl;
begin
  if Assigned(FGUIControl) then
    FGUIControl.OnExit := FOriginalOnExit;
end;

procedure TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
var
  LIntf: IFPObserved;
begin
  if Operation = ooFree then
  begin
    if Supports(ASender, IFPObserved, LIntf) and Assigned(LIntf) then
      LIntf.FPODetachObserver(self);

    if ASender = FGUIControl then
      DetachEventsFromGUIControl;
  end
  else
  begin
    if FUpdateCount <> 0 then
      Exit;

    if Assigned(FGUIControl) and Assigned(FSourceInstance) and (ASender = FGUIControl) then
      SetPropValue(FGetDestInstance(FSourceInstance), FDestInstancePropertyName, GetPropValue(FGUIControl, FGUIControlPropertyName));

    if Assigned(FGUIControl) and Assigned(FSourceInstance) and (ASender = FSourceInstance) then
      SetPropValue(FGUIControl, FGUIControlPropertyName, GetPropValue(FGetDestInstance(FSourceInstance), FDestInstancePropertyName));
  end;
end;

destructor TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.Destroy;
var
  LIntf: IFPObserved;
begin
  { detach GUI Control }
  if Supports(FGUIControl, IFPObserved, LIntf) and Assigned(LIntf) then
  begin
    LIntf.FPODetachObserver(self);
    DetachEventsFromGUIControl;
  end;

  { detach Instance }
  if Supports(FSourceInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);

  inherited Destroy;
end;

constructor TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.Create(const AGUIControl: TGUIControl;
                                                                              const AGUIControlPropertyName: string;
                                                                              const ASourceInstance: TSourceItem;
                                                                              const AGetDestInstance: TGetDestInstanceFunc;
                                                                              const ADestInstancePropertyName: string);
var
  LIntf: IFPObserved;
begin                                        ;
  inherited Create(nil);
  FGUIControl := AGUIControl;
  FGUIControlPropertyName := AGUIControlPropertyName;
  FSourceInstance := ASourceInstance;
  FGetDestInstance := AGetDestInstance;
  FDestInstancePropertyName := ADestInstancePropertyName;

  FOriginalOnExit := AGUIControl.OnExit;

  FUpdateCount := 0;

  FGUIControl.OnExit := DoExit;

  { attach GUI Control }
  if Supports(FGUIControl, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  { attach Instance }
  if Supports(FSourceInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  EnableControl;
end;

procedure TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.DoExit(ASender: TObject);
begin
  FGUIControl.FPONotifyObservers(ASender, ooChange, nil);
  if Assigned(FOriginalOnExit) then
    FOriginalOnExit(ASender);
end;

procedure TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.DisableControl;
begin
  Inc(FUpdateCount);
end;

procedure TGUIDelegatedPropertyMediator<TSourceItem, TDestItem, TGUIControl>.EnableControl;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount <> 0 then
    Exit;

  FPOObservedChanged(FSourceInstance, ooChange, nil);
  FPOObservedChanged(FGUIControl, ooChange, nil);
end;

end.
