(*
  yet another ORM - for FreePascal
  ORM 1to1 relationship classes

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Relationships.OneToOne;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  Variants,
  TypInfo,
  yaORM.Types,
  yaORM.Collections,
  yaORM;

type

  { TyaOneToOneRelationship }

  TyaOneToOneRelationship<TMasterObject: TPersistent; TLinkedObject: TPersistent> = class(TPersistent)
  strict private
  var
    FMasterObject: Pointer; //TMasterObject;
    FMasterObjectLinkedKeys: TStringArray;
    FLinkedObject: TLinkedObject;
    FMasterORM: Pointer; //IyaORM<TMasterObject>;
    FLinkedORM: Pointer; //IyaORM<TLinkedObject>;
    FCheckIsEnabled: boolean;

    function GetLinkedObject: TLinkedObject;
    procedure SetLinkedObject(const ALinkedObject: TLinkedObject);
    procedure CheckMasterObject;
  public
    constructor Create(const AMasterObject: TMasterObject;
                       const AMasterObjectLinkedKeys: TORMStringArray;
                       const AMasterORM: IyaORM<TMasterObject>;
                       const ALinkedORM: IyaORM<TLinkedObject>);
    destructor Destroy; override;

    procedure CheckLinkedObject;

    property LinkedObject: TLinkedObject read GetLinkedObject write SetLinkedObject;
  end;

implementation

{ TyaOneToOneRelationship }

constructor TyaOneToOneRelationship<TMasterObject, TLinkedObject>.Create(const AMasterObject: TMasterObject;
                                                                         const AMasterObjectLinkedKeys: TORMStringArray;
                                                                         const AMasterORM: IyaORM<TMasterObject>;
                                                                         const ALinkedORM: IyaORM<TLinkedObject>);
begin
  FMasterObject := AMasterObject;
  FMasterObjectLinkedKeys := AMasterObjectLinkedKeys;
  FMasterORM := AMasterORM;
  FLinkedORM := ALinkedORM;
  FCheckIsEnabled := true;
  CheckLinkedObject;
end;

destructor TyaOneToOneRelationship<TMasterObject, TLinkedObject>.Destroy;
begin
  FreeAndNil(FLinkedObject);
  FMasterORM := nil;
  FLinkedORM := nil;
  inherited Destroy;
end;

procedure TyaOneToOneRelationship<TMasterObject, TLinkedObject>.CheckLinkedObject;
var
  LKey: string;
  LIsNull: boolean;
  LKeyValues: TORMVariantArray;
begin
  if not FCheckIsEnabled then
    Exit;

  CheckMasterObject;

  LIsNull := false;
  SetLength(LKeyValues, Length(FMasterObjectLinkedKeys));
  for LKey in FMasterObjectLinkedKeys do
  begin
    if VariantIsEmptyOrNull(GetPropValue(FMasterObject, LKey)) then
      LIsNull := true;
  end;

  LKeyValues := IyaORM<TMasterObject>(FMasterORM).GetFieldValues(FMasterObjectLinkedKeys, FMasterObject);

  FreeAndNil(FLinkedObject);
  if LIsNull then
    Exit;

  IyaORM<TLinkedObject>(FLinkedORM).Load(LKeyValues, FLinkedObject);
  FPONotifyObservers(Self, ooChange, Pointer(FLinkedObject));
end;

function TyaOneToOneRelationship<TMasterObject, TLinkedObject>.GetLinkedObject: TLinkedObject;
begin
  result := FLinkedObject;
end;

procedure TyaOneToOneRelationship<TMasterObject, TLinkedObject>.SetLinkedObject(const ALinkedObject: TLinkedObject);
var
  LIndex: integer;
begin
  CheckMasterObject;

  FreeAndNil(FLinkedObject);
  FLinkedObject := ALinkedObject;
  FCheckIsEnabled := false;

  for LIndex := Low(IyaORM<TLinkedObject>(FLinkedORM).GetPropertyKeyFields) to High(IyaORM<TLinkedObject>(FLinkedORM).GetPropertyKeyFields) do
    SetPropValue(FMasterObject, FMasterObjectLinkedKeys[LIndex], GetPropValue(FLinkedObject, IyaORM<TLinkedObject>(FLinkedORM).GetPropertyKeyFields[LIndex]));

  FCheckIsEnabled := true;
  FPONotifyObservers(Self, ooChange, Pointer(FLinkedObject));
end;

procedure TyaOneToOneRelationship<TMasterObject, TDetailObject>.CheckMasterObject;
begin
  if not Assigned(FMasterObject) then
    raise EyaORMException.Create('TyaOneToOneRelationship: FMasterObject is not assigned.');
end;

end.

