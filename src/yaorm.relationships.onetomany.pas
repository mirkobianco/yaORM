(*
  yet another ORM - for FreePascal
  ORM 1toN relationship classes

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Relationships.OneToMany;

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

  { TyaOneToManyRelationship }

  TyaOneToManyRelationship<TMasterObject: TCollectionItem; TDetailObject: TCollectionItem> = class(TPersistent)
  strict private
  var
    FMasterObject: Pointer; //TMasterObject;
    FMasterObjectDetailKeys: TORMStringArray;
    FDetailObjects: TObjectList<TDetailObject>;
    FMasterORM: Pointer; //IyaORM<TMasterObject>;
    FDetailORM: Pointer; //IyaORM<TDetailObject>;

    procedure CheckMasterObject;
  public
    constructor Create(const AMasterObject: TMasterObject;
                       const AMasterObjectDetailKeys: TORMStringArray;
                       const AMasterORM: IyaORM<TMasterObject>;
                       const ADetailORM: IyaORM<TDetailObject>);
    destructor Destroy; override;

    procedure CheckDetailObjects;
    function GetDetailObjects: TObjectList<TDetailObject>;
  end;

implementation

{ TyaOneToManyRelationship }

constructor TyaOneToManyRelationship<TMasterObject, TDetailObject>.Create(const AMasterObject: TMasterObject;
                                                                          const AMasterObjectDetailKeys: TORMStringArray;
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
  LKeyValues: TORMVariantArray;
begin
  CheckMasterObject;

  LIsNull := false;
  SetLength(LKeyValues, Length(FMasterObjectDetailKeys));
  for LKey in FMasterObjectDetailKeys do
    if VariantIsEmptyOrNull(GetPropValue(FMasterObject, LKey)) then
      LIsNull := true;

  LKeyValues := IyaORM<TMasterObject>(FMasterORM).GetFieldValues(FMasterObjectDetailKeys, FMasterObject);

  FreeAndNil(FDetailObjects);
  if LIsNull then
    Exit;

  IyaORM<TDetailObject>(FDetailORM).LoadList(LKeyValues, FDetailObjects);
  FPONotifyObservers(Self, ooChange, Pointer(FDetailObjects));
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

end.

