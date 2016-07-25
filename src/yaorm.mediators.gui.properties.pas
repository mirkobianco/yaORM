(*
  yet another ORM - for FreePascal
  ORM GUI Single Component Mediator

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Mediators.GUI.Properties;

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
  { TGUIPropertyMediator<TItem, TGUIControl> }

  TGUIPropertyMediator<TItem: TPersistent; TGUIControl: TWinControl> = class(TGUIMediator<TItem>, IFPObserver)
  strict private
    FGUIControl: TGUIControl;
    FGUIControlPropertyName: string;
    FInstance: TItem;
    FInstancePropertyName: string;
    FUpdateCount: integer;
    FOriginalOnExit: TNotifyEvent;

    procedure DoExit(ASender : TObject);
    procedure DetachEventsFromGUIControl;

    //IFPObserver
    procedure FPOObservedChanged(ASender : TObject; Operation : TFPObservedOperation; Data : Pointer);
  public
    constructor Create(const AGUIControl: TGUIControl;
                       const AGUIControlPropertyName: string;
                       const AInstance: TItem;
                       const AInstancePropertyName: string); reintroduce;
    destructor Destroy; override;

    procedure ChangeInstance(const AInstance: TItem); override;

    procedure DisableControl;
    procedure EnableControl;
  end;

implementation

{ TGUIPropertyMediator<TItem, TGUIControl> }

procedure TGUIPropertyMediator<TItem, TGUIControl>.ChangeInstance(const AInstance: TItem);
var
  LIntf: IFPObserved;
begin
  DisableControl;

  if Supports(FInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);
  FInstance := AInstance;
  if Supports(FInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  EnableControl;
end;

procedure TGUIPropertyMediator<TItem, TGUIControl>.DetachEventsFromGUIControl;
begin
  if Assigned(FGUIControl) then
    FGUIControl.OnExit := FOriginalOnExit;
end;

procedure TGUIPropertyMediator<TItem, TGUIControl>.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);
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

    if Assigned(FGUIControl) and Assigned(FInstance) and (ASender = FGUIControl) then
      SetPropValue(FInstance, FInstancePropertyName, GetPropValue(FGUIControl, FGUIControlPropertyName));

    if Assigned(FGUIControl) and Assigned(FInstance) and (ASender = FInstance) then
      SetPropValue(FGUIControl, FGUIControlPropertyName, GetPropValue(FInstance, FInstancePropertyName));
  end;
end;

destructor TGUIPropertyMediator<TItem, TGUIControl>.Destroy;
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
  if Supports(FInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPODetachObserver(self);

  inherited Destroy;
end;

constructor TGUIPropertyMediator<TItem, TGUIControl>.Create(const AGUIControl: TGUIControl;
                                                            const AGUIControlPropertyName:
                                                            string; const AInstance: TItem;
                                                            const AInstancePropertyName: string);
var
  LIntf: IFPObserved;
begin                                        ;
  inherited Create(nil);
  FGUIControl := AGUIControl;
  FGUIControlPropertyName := AGUIControlPropertyName;
  FInstance := AInstance;
  FInstancePropertyName := AInstancePropertyName;

  FOriginalOnExit := AGUIControl.OnExit;

  FUpdateCount := 0;

  FGUIControl.OnExit := DoExit;

  { attach GUI Control }
  if Supports(FGUIControl, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  { attach Instance }
  if Supports(FInstance, IFPObserved, LIntf) and Assigned(LIntf) then
    LIntf.FPOAttachObserver(self);

  EnableControl;
end;

procedure TGUIPropertyMediator<TItem, TGUIControl>.DoExit(ASender: TObject);
begin
  FGUIControl.FPONotifyObservers(ASender, ooChange, nil);
  if Assigned(FOriginalOnExit) then
    FOriginalOnExit(ASender);
end;

procedure TGUIPropertyMediator<TItem, TGUIControl>.DisableControl;
begin
  Inc(FUpdateCount);
end;

procedure TGUIPropertyMediator<TItem, TGUIControl>.EnableControl;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);

  if FUpdateCount <> 0 then
    Exit;

  FPOObservedChanged(FInstance, ooChange, nil);
  FPOObservedChanged(FGUIControl, ooChange, nil);
end;

end.
