(*
  yet another ORM - for FreePascal
  ORM GUI Mediators

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.GUIMediators;

{$mode Delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  TypInfo,

  yaORM;

type
  { TGUIMediator<TImen, TGUIControl> }

  TGUIMediator<TItem: TCollectionItem; TGUIControl: TWinControl> = class(TObject, IFPObserver)
  strict private
    FOrm: IyaORM<TItem>;
    FGUIControl: TGUIControl;
    FGUIControlPropertyName: string;
    FInstance: TItem;
    FInstancePropertyName: string;

    procedure FOnExit(ASender : TObject);

    //IFPObserver
    procedure FPOObservedChanged(ASender : TObject; Operation : TFPObservedOperation; Data : Pointer);
  public
    constructor Create(const AOrm: IyaORM<TItem>; const AGUIControl: TGUIControl; const AGUIControlPropertyName: string; const AInstance: TItem; const AInstancePropertyName: string);
    destructor Destroy; override;
  end;

implementation

{ TGUIMediator<TItem, TGUIControl> }

procedure TGUIMediator<TItem, TGUIControl>.FPOObservedChanged(ASender: TObject; Operation: TFPObservedOperation; Data: Pointer);

var
  LIntf: IFPObserved;
begin
  if Operation = ooFree then
  begin
    if Supports(ASender, IFPObserved, LIntf) and
       Assigned(LIntf) then
      LIntf.FPODetachObserver(self);
  end
  else
    if Assigned(FInstance) and
       Assigned(FGUIControl) then
    begin
      if ASender = FInstance then
        SetPropValue(FGUIControl, FGUIControlPropertyName, GetPropValue(FInstance, FInstancePropertyName))
      else
        SetPropValue(FInstance, FInstancePropertyName, GetPropValue(FGUIControl, FGUIControlPropertyName));
    end;
end;

destructor TGUIMediator<TItem, TGUIControl>.Destroy;
var
  LIntf: IFPObserved;
begin
  { detach GUI Control }
  if Supports(FGUIControl, IFPObserved, LIntf) then
    LIntf.FPODetachObserver(self);

  { detach Instance }
  if Supports(FInstance, IFPObserved, LIntf) then
    LIntf.FPODetachObserver(self);

  inherited Destroy;
end;

constructor TGUIMediator<TItem, TGUIControl>.Create(const AOrm: IyaORM<TItem>; const AGUIControl: TGUIControl; const AGUIControlPropertyName: string; const AInstance: TItem; const AInstancePropertyName: string);
var
  LIntf: IFPObserved;
begin
  FOrm := AOrm;
  FGUIControl := AGUIControl;
  FGUIControlPropertyName := AGUIControlPropertyName;
  FInstance := AInstance;
  FInstancePropertyName := AInstancePropertyName;

  FGUIControl.OnExit := FOnExit;

  { attach GUI Control }
  if Supports(FGUIControl, IFPObserved, LIntf) then
    LIntf.FPOAttachObserver(self);

  { attach Instance }
  if Supports(FInstance, IFPObserved, LIntf) then
    LIntf.FPOAttachObserver(self);
end;

procedure TGUIMediator<TItem, TGUIControl>.FOnExit(ASender: TObject);
begin
  FGUIControl.FPONotifyObservers(ASender, ooChange, nil);
end;

end.

