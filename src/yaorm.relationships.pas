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
    procedure SetLinkedObject(const LinkedObject: TLinkedObject);
  public
    constructor Create(const MasterObject: TMasterObject;
                       const MasterObjectLinkedKeys: TStringArray;
                       const MasterORM: IyaORM<TMasterObject>;
                       const LinkedORM: IyaORM<TLinkedObject>);
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
    constructor Create(const MasterObject: TMasterObject;
                       const MasterObjectDetailKeys: TStringArray;
                       const MasterORM: IyaORM<TMasterObject>;
                       const DetailORM: IyaORM<TDetailObject>);
    destructor Destroy; override;

    procedure CheckDetailObjects;
    function GetDetailObjects: TObjectList<TDetailObject>;
  end;

implementation

{ TyaOneToManyRelationship }

constructor TyaOneToManyRelationship<TMasterObject, TDetailObject>.Create(const MasterObject: TMasterObject;
                                                                          const MasterObjectDetailKeys: TStringArray;
                                                                          const MasterORM: IyaORM<TMasterObject>;
                                                                          const DetailORM: IyaORM<TDetailObject>);
begin
  FMasterObject := MasterObject;
  FMasterObjectDetailKeys := MasterObjectDetailKeys;
  FMasterORM := MasterORM;
  FDetailORM := DetailORM;
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
  Key: string;
  IsNull: boolean;
  KeyValues: TVariantArray;
begin
  IsNull := false;
  SetLength(KeyValues, Length(FMasterObjectDetailKeys));
  for Key in FMasterObjectDetailKeys do
    if VariantIsEmptyOrNull(FMasterORM.GetPropertyValue(FMasterObject, Key)) then
      IsNull := true;

  KeyValues := FMasterORM.GetFieldValues(FMasterObjectDetailKeys, FMasterObject);

  FreeAndNil(FDetailObjects);
  if IsNull then
    Exit;

  FDetailORM.LoadList(KeyValues, FDetailObjects);
end;

function TyaOneToManyRelationship<TMasterObject, TDetailObject>.GetDetailObjects: TObjectList<TDetailObject>;
begin
  result := FDetailObjects;
end;

{ TyaOneToOneRelationship }

constructor TyaOneToOneRelationship<TMasterObject, TLinkedObject>.Create(const MasterObject: TMasterObject;
                                                                         const MasterObjectLinkedKeys: TStringArray;
                                                                         const MasterORM: IyaORM<TMasterObject>;
                                                                         const LinkedORM: IyaORM<TLinkedObject>);
begin
  FMasterObject := MasterObject;
  FMasterObjectLinkedKeys := MasterObjectLinkedKeys;
  FMasterORM := MasterORM;
  FLinkedORM := LinkedORM;
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
  Key: string;
  IsNull: boolean;
  KeyValues: TVariantArray;
begin
  if not FCheckIsEnabled then
    Exit;
  IsNull := false;
  SetLength(KeyValues, Length(FMasterObjectLinkedKeys));
  for Key in FMasterObjectLinkedKeys do
  begin
    if VariantIsEmptyOrNull(FMasterORM.GetPropertyValue(FMasterObject, Key)) then
      IsNull := true;
  end;

  KeyValues := FMasterORM.GetFieldValues(FMasterObjectLinkedKeys, FMasterObject);

  FreeAndNil(FLinkedObject);
  if IsNull then
    Exit;

  FLinkedORM.Load(KeyValues, FLinkedObject);
end;

function TyaOneToOneRelationship<TMasterObject, TLinkedObject>.GetLinkedObject: TLinkedObject;
begin
  result := FLinkedObject;
end;

procedure TyaOneToOneRelationship<TMasterObject, TLinkedObject>.SetLinkedObject(const LinkedObject: TLinkedObject);
var
  Index: integer;
begin
  FreeAndNil(FLinkedObject);
  FLinkedObject := LinkedObject;
  FCheckIsEnabled := false;

  for Index := Low(FLinkedORM.GetPropertyKeyFields) to High(FLinkedORM.GetPropertyKeyFields) do
    SetPropValue(FMasterObject, FMasterObjectLinkedKeys[Index], FLinkedORM.GetPropertyValue(FLinkedObject, FLinkedORM.GetPropertyKeyFields[Index]));

  FCheckIsEnabled := true;
end;

end.

