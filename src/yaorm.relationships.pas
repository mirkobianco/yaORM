(*
  yet another ORM - for FreePascal
  ORM relationship classes

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Relationships;

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

  TyaOneToOneRelationship<TMasterObject: TCollectionItem; TLinkedObject: TCollectionItem> = class
  strict private
  var
    FMasterObject: TMasterObject;
    FMasterObjectLinkedKeys: TStringArray;
    FLinkedObject: TLinkedObject;
    FMasterORM: IyaORM<TMasterObject>;
    FLinkedORM: IyaORM<TLinkedObject>;
    FCheckIsEnabled: boolean;

    function GetLinkedObject: TLinkedObject;
    procedure SetLinkedObject(const ALinkedObject: TLinkedObject);
    procedure CheckMasterObject;
  public
    constructor Create(const AMasterObject: TMasterObject;
                       const AMasterObjectLinkedKeys: TStringArray;
                       const AMasterORM: IyaORM<TMasterObject>;
                       const ALinkedORM: IyaORM<TLinkedObject>);
    destructor Destroy; override;

    procedure CheckLinkedObject;

    property LinkedObject: TLinkedObject read GetLinkedObject write SetLinkedObject;

  end;

  { TyaOneToManyRelationship }

  TyaOneToManyRelationship<TMasterObject: TCollectionItem; TDetailObject: TCollectionItem> = class
  strict private
  var
    FMasterObject: TMasterObject;
    FMasterObjectDetailKeys: TStringArray;
    FDetailObjects: TORMCollection<TDetailObject>;
    FMasterORM: IyaORM<TMasterObject>;
    FDetailORM: IyaORM<TDetailObject>;

    procedure CheckMasterObject;
  public
    constructor Create(const AMasterObject: TMasterObject;
                       const AMasterObjectDetailKeys: TStringArray;
                       const AMasterORM: IyaORM<TMasterObject>;
                       const ADetailORM: IyaORM<TDetailObject>);
    destructor Destroy; override;

    procedure CheckDetailObjects;
    function GetDetailObjects: TCollection;
  end;

implementation

{ TyaOneToManyRelationship }

constructor TyaOneToManyRelationship<TMasterObject, TDetailObject>.Create(const AMasterObject: TMasterObject;
                                                                          const AMasterObjectDetailKeys: TStringArray;
                                                                          const AMasterORM: IyaORM<TMasterObject>;
                                                                          const ADetailORM: IyaORM<TDetailObject>);
begin
  FMasterObject := AMasterObject;
  FMasterObjectDetailKeys := AMasterObjectDetailKeys;
  FMasterORM := AMasterORM;
  FDetailORM := ADetailORM;
  CheckDetailObjects;
end;

destructor TyaOneToManyRelationship<TMasterObject, TDetailObject>.Destroy;
begin
  FDetailObjects.Clear;
  FreeAndNil(FDetailObjects);

  inherited Destroy;
end;

procedure TyaOneToManyRelationship<TMasterObject, TDetailObject>.CheckDetailObjects;
var
  LKey: string;
  LIsNull: boolean;
  LKeyValues: TVariantArray;
begin
  CheckMasterObject;

  LIsNull := false;
  SetLength(LKeyValues, Length(FMasterObjectDetailKeys));
  for LKey in FMasterObjectDetailKeys do
    if VariantIsEmptyOrNull(GetPropValue(FMasterObject, LKey)) then
      LIsNull := true;

  LKeyValues := FMasterORM.GetFieldValues(FMasterObjectDetailKeys, FMasterObject);

  FreeAndNil(FDetailObjects);
  if LIsNull then
    Exit;

  FDetailORM.LoadCollection(LKeyValues, FDetailObjects);
end;

function TyaOneToManyRelationship<TMasterObject, TDetailObject>.GetDetailObjects: TCollection;
begin
  result := FDetailObjects;
end;

procedure TyaOneToManyRelationship<TMasterObject, TDetailObject>.CheckMasterObject;
begin
  if not Assigned(FMasterObject) then
    raise EyaORMException.Create('TyaOneToManyRelationship: FMasterObject is not assigned.');
end;

{ TyaOneToOneRelationship }

constructor TyaOneToOneRelationship<TMasterObject, TLinkedObject>.Create(const AMasterObject: TMasterObject;
                                                                         const AMasterObjectLinkedKeys: TStringArray;
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

  inherited Destroy;
end;

procedure TyaOneToOneRelationship<TMasterObject, TLinkedObject>.CheckLinkedObject;
var
  LKey: string;
  LIsNull: boolean;
  LKeyValues: TVariantArray;
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

  LKeyValues := FMasterORM.GetFieldValues(FMasterObjectLinkedKeys, FMasterObject);

  FreeAndNil(FLinkedObject);
  if LIsNull then
    Exit;

  if not FLinkedORM.Load(LKeyValues, FLinkedObject) then
    raise EyaORMException.Create('TyaOneToOneRelationship: Object not found.');
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

  for LIndex := Low(FLinkedORM.GetPropertyKeyFields) to High(FLinkedORM.GetPropertyKeyFields) do
    SetPropValue(FMasterObject, FMasterObjectLinkedKeys[LIndex], GetPropValue(FLinkedObject, FLinkedORM.GetPropertyKeyFields[LIndex]));

  FCheckIsEnabled := true;
end;

procedure TyaOneToOneRelationship<TMasterObject, TDetailObject>.CheckMasterObject;
begin
  if not Assigned(FMasterObject) then
    raise EyaORMException.Create('TyaOneToOneRelationship: FMasterObject is not assigned.');
end;

end.

