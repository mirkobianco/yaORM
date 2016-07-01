(*
  yet another ORM - for FreePascal and Delphi
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
  yaORM;

type

  { TyaOneToOneRelationship }

  TyaOneToOneRelationship<TMasterObject: TObject; TLinkedObject: TObject> = class
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

  TyaOneToManyRelationship<TMasterObject: TObject; TDetailObject: TObject> = class
  strict private
  var
    FMasterObject: TMasterObject;
    FMasterObjectDetailKeys: TStringArray;
    FDetailObjects: TObjectList<TDetailObject>;
    FMasterORM: IyaORM<TMasterObject>;
    FDetailORM: IyaORM<TDetailObject>;
  public
    constructor Create(const AMasterObject: TMasterObject;
                       const AMasterObjectDetailKeys: TStringArray;
                       const AMasterORM: IyaORM<TMasterObject>;
                       const ADetailORM: IyaORM<TDetailObject>);
    destructor Destroy; override;

    procedure CheckDetailObjects;
    function GetDetailObjects: TObjectList<TDetailObject>;
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
  LIsNull := false;
  SetLength(LKeyValues, Length(FMasterObjectDetailKeys));
  for LKey in FMasterObjectDetailKeys do
    if VariantIsEmptyOrNull(FMasterORM.GetPropertyValue(FMasterObject, LKey)) then
      LIsNull := true;

  LKeyValues := FMasterORM.GetFieldValues(FMasterObjectDetailKeys, FMasterObject);

  FreeAndNil(FDetailObjects);
  if LIsNull then
    Exit;

  FDetailORM.LoadList(LKeyValues, FDetailObjects);
end;

function TyaOneToManyRelationship<TMasterObject, TDetailObject>.GetDetailObjects: TObjectList<TDetailObject>;
begin
  result := FDetailObjects;
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
  LIsNull := false;
  SetLength(LKeyValues, Length(FMasterObjectLinkedKeys));
  for LKey in FMasterObjectLinkedKeys do
  begin
    if VariantIsEmptyOrNull(FMasterORM.GetPropertyValue(FMasterObject, LKey)) then
      LIsNull := true;
  end;

  LKeyValues := FMasterORM.GetFieldValues(FMasterObjectLinkedKeys, FMasterObject);

  FreeAndNil(FLinkedObject);
  if LIsNull then
    Exit;

  FLinkedORM.Load(LKeyValues, FLinkedObject);
end;

function TyaOneToOneRelationship<TMasterObject, TLinkedObject>.GetLinkedObject: TLinkedObject;
begin
  result := FLinkedObject;
end;

procedure TyaOneToOneRelationship<TMasterObject, TLinkedObject>.SetLinkedObject(const ALinkedObject: TLinkedObject);
var
  LIndex: integer;
begin
  FreeAndNil(FLinkedObject);
  FLinkedObject := ALinkedObject;
  FCheckIsEnabled := false;

  for LIndex := Low(FLinkedORM.GetPropertyKeyFields) to High(FLinkedORM.GetPropertyKeyFields) do
    SetPropValue(FMasterObject, FMasterObjectLinkedKeys[LIndex], FLinkedORM.GetPropertyValue(FLinkedObject, FLinkedORM.GetPropertyKeyFields[LIndex]));

  FCheckIsEnabled := true;
end;

end.

