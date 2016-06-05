(*
  yet another ORM - for FreePascal and Delphi
  Core ORM classes

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM;
{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  StrUtils,
  Dialogs,
  Variants,
  DB,
  TypInfo,
  yaORM.Types;

type
  IyaFilter = interface(IInterface)
    ['{6A7913DF-AE1A-E611-9BDD-080027BF4002}']
    procedure Clear;
    procedure AddCondition(const PropertyName: string; const FilterType: TFilterType; const Value: variant);
    procedure AddAnd;
    procedure AddOr;
    procedure AddNot;
    procedure AddOpenBracket;
    procedure AddClosedBracket;

    function AsString: string;
    procedure SetQueryParams(const Params: TParams);
  end;

  { IyaORM }

  IyaORM<T: TObject> = interface(IInterface)
    ['{E88D8D4D-B71E-E611-9290-080027BF4002}']
    function GetObject(const Fields: TFields): T;
    procedure GetObjects(const Dataset: TDataset; out List: TObjectList<T>);
    procedure SetObjects(const List: TObjectList<T>; const Dataset: TDataset);
    procedure SetObject(const Instance: T; const Dataset: TDataset);

    function New: T;
    function Clone(const Instance: T): T;
    function NewFilter: IyaFilter;

    function GetPropertyKeyFields: TStringArray;
    function GetFieldName(const PropertyName: string): string;
    function GetPropertyValue(const Instance: T; const PropertyName: string): variant;
    function ConvertToFieldValue(const PropertyName: string; const PropertyValue: variant): variant;
    function GetFieldValues(const FieldNames: TStringArray; const Instance: T): TVariantArray;

    function Load(const KeyValues: TVariantArray; out Instance: T): boolean;
    function LoadList(const SQL: string; out List: TObjectList<T>): boolean; overload;
    function LoadList(const Filter: IyaFilter; out List: TObjectList<T>): boolean; overload;
    function LoadList(const KeyValues: TVariantArray; out List: TObjectList<T>): boolean; overload;
    procedure Insert(const Instance: T);
    procedure Update(const Instance: T);
    procedure Delete(const Instance: T); overload;
    procedure Delete(const KeyValues: TVariantArray); overload;
    procedure Delete(const Filter: IyaFilter); overload;
  end;

  { TyaFilter }

  TyaFilter<T: TObject> = class(TInterfacedObject, IyaFilter)
  strict private
  var
    FList: TList<TyaFilterCondition>;
    FORMPointer: Pointer;
  public
    constructor Create(const ORM: IyaORM<T>);
    destructor Destroy; override;

//  IyaFilter<T: IyaObject>
    procedure Clear;
    procedure AddCondition(const PropertyName: string; const FilterType: TFilterType; const Value: variant);
    procedure AddAnd;
    procedure AddOr;
    procedure AddNot;
    procedure AddOpenBracket;
    procedure AddClosedBracket;

    function AsString: string;
    procedure SetQueryParams(const Params: TParams);
  end;

  { TyaAbstractORM }

  TyaAbstractORM<T: TObject> = class(TInterfacedObject, IyaORM<T>)
  public
  type
    TFactoryFunc = function: T of object;
  strict private
    procedure PrepareKeyValuesParams(const KeyValues: TVariantArray; const Params: TParams);
    procedure PrepareFilterParams(const Filter: IyaFilter; const Params: TParams);
    procedure CopyInstanceToFields(const Instance: T; const Fields: TFields);
    function Concat(const StringArray: TStringArray; const Separator: string): string; overload;
    function Concat(const StringArray: TStringArray; const Separator: string; const Prefix: string): string; overload;
    function ConvertFieldKeyArrayToFieldKeyStr: string;
    function GetFieldNames(const Instance: T): TStringArray;
    function GetPropertyNames(const Instance: T): TStringArray;
    function HasSameKeys(const Instance: T; const Fields: TFields): boolean;
  strict protected
  var
    FFactoryFunc: TFactoryFunc;
    FTableName: string;
    FPropertyKeyFields: TStringArray;
    FFieldKeyFields: TStringArray;
    FFieldKeyFieldsStr: string;
    FFieldToPropertyMap: TDictionary<string, string>;
    FFieldToPropertyConversionFunc: TConversionFunc;
    FPropertytoFieldConversionFunc: TConversionFunc;

    procedure CopyFieldsToInstance(const Fields: TFields; const Instance: T);
    procedure CopyInstanceToParams(const Instance: T; const Params: TParams);
    function GetKeyValues(const Instance: T): TVariantArray;

    procedure CreateSelectSQL(const Instance: T; const SQL: TStrings);
    procedure CreateInsertSQL(const Instance: T; const SQL: TStrings);
    procedure CreateUpdateSQL(const Instance: T; const SQL: TStrings);
    procedure CreateDeleteSQL(const SQL: TStrings);
    procedure AddKeyValuesConditions(const KeyValues: TVariantArray; const SQL: TStrings; const Params: TParams);
    procedure AddFilterConditions(const Filter: IyaFilter; const SQL: TStrings; const Params: TParams);
  public
    constructor Create(const FactoryFunc: TFactoryFunc;
                       const TableName: string;
                       const PropertyKeyFields: TStringArray;
                       const FieldToPropertyMap: TDictionary<string, string> = nil;
                       const FieldToPropertyConversionFunc: TConversionFunc = nil;
                       const PropertytoFieldConversionFunc: TConversionFunc = nil); reintroduce;
    destructor Destroy; override;

    //IyaORM
    function GetObject(const Fields: TFields): T;
    procedure GetObjects(const Dataset: TDataset; out List: TObjectList<T>);
    procedure SetObjects(const List: TObjectList<T>; const Dataset: TDataset);
    procedure SetObject(const Instance: T; const Dataset: TDataset);

    function New: T;
    function Clone(const Instance: T): T;
    function NewFilter: IyaFilter;
    function GetPropertyKeyFields: TStringArray;
    function GetFieldName(const PropertyName: string): string;
    function GetPropertyValue(const Instance: T; const PropertyName: string): variant;
    procedure SetPropertyValue(const Instance: T; const PropertyName: string; const PropertyValue: variant);
    function ConvertToFieldValue(const PropertyName: string; const PropertyValue: variant): variant;
    function ConvertToPropertyValue(const FieldName: string; const FieldValue: variant): variant;
    function GetFieldValues(const FieldNames: TStringArray; const Instance: T): TVariantArray;
    function Load(const KeyValues: TVariantArray; out Instance: T): boolean; virtual;
    function LoadList(const SQL: string; out List: TObjectList<T>): boolean; overload; virtual; abstract;
    function LoadList(const Filter: IyaFilter; out List: TObjectList<T>): boolean; overload; virtual; abstract;
    function LoadList(const KeyValues: TVariantArray; out List: TObjectList<T>): boolean; overload; virtual; abstract;
    procedure Insert(const Instance: T); virtual; abstract;
    procedure Update(const Instance: T); virtual; abstract;
    procedure Delete(const Instance: T); overload; virtual; abstract;
    procedure Delete(const KeyValues: TVariantArray); overload; virtual;
    procedure Delete(const Filter: IyaFilter); overload; virtual; abstract;
  end;

implementation

{ yaORM }

function TyaAbstractORM<T>.GetPropertyValue(const Instance: T; const PropertyName: string): variant;
var
  PropInfo: PPropInfo;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.GetPropertyValue: Instance not assigned.');
  result := null;
  PropInfo := GetPropInfo(PTypeInfo(Instance.ClassInfo), PropertyName);
  if assigned(PropInfo) then
    result := GetPropValue(Instance, PropInfo);
end;

procedure TyaAbstractORM<T>.SetPropertyValue(const Instance: T; const PropertyName: string; const PropertyValue: variant);
var
  PropInfo: PPropInfo;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.SetPropertyValue: Instance not assigned.');
  PropInfo := GetPropInfo(PTypeInfo(Instance.ClassInfo), PropertyName);
  if assigned(PropInfo) then
    SetPropValue(Instance, PropInfo, PropertyValue);
end;

constructor TyaAbstractORM<T>.Create(const FactoryFunc: TFactoryFunc;
                                     const TableName: string;
                                     const PropertyKeyFields: TStringArray;
                                     const FieldToPropertyMap: TDictionary<string, string>;
                                     const FieldToPropertyConversionFunc: TConversionFunc;
                                     const PropertytoFieldConversionFunc: TConversionFunc);
var
  Index: integer;
begin
  inherited Create;
  FFactoryFunc := FactoryFunc;
  FTableName := TableName;
  FPropertyKeyFields := PropertyKeyFields;
  FFieldToPropertyMap := FieldToPropertyMap;
  if not Assigned(FFieldToPropertyMap) then
    FFieldToPropertyMap := TDictionary<string, string>.Create;
  FFieldToPropertyConversionFunc := FieldToPropertyConversionFunc;
  FPropertytoFieldConversionFunc := PropertytoFieldConversionFunc;

  SetLength(FFieldKeyFields, Length(FPropertyKeyFields));
  for Index := Low(FFieldKeyFields) to High(FFieldKeyFields) do
    FFieldKeyFields[Index] := GetFieldName(FPropertyKeyFields[Index]);

end;

destructor TyaAbstractORM<T>.Destroy;
begin
  FreeAndNil(FFieldToPropertyMap);
  inherited Destroy;
end;

procedure TyaAbstractORM<T>.CopyFieldsToInstance(const Fields: TFields; const Instance: T);
var
  Index: integer;
  Field: TField;
  PropInfo: PPropInfo;
  PropertyName: string;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyFieldsToInstance: Instance not assigned.');
  if not Assigned(Fields) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyFieldsToInstance: Fields not assigned.');

  for Index := 0 to Fields.Count - 1 do
  begin
    Field := Fields[Index];

    PropertyName := '';
    if not FFieldToPropertyMap.{$IFDEF FPC}TryGetData{$ELSE}TryGetValue{$ENDIF}(Field.FieldName, PropertyName) or PropertyName.IsEmpty then
      PropertyName := Field.FieldName;

    PropInfo := GetPropInfo(PTypeInfo(Instance.ClassInfo), PropertyName);
    if assigned(PropInfo) then
      SetPropValue(Instance, PropertyName, ConvertToPropertyValue(Field.FieldName, Field.Value));
  end;
end;

procedure TyaAbstractORM<T>.CopyInstanceToFields(const Instance: T; const Fields: TFields);
var
  Index: integer;
  Field: TField;
  PropertyName: string;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToFields: Instance not assigned.');
  if not Assigned(Fields) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToFields: Fields not assigned.');

  for Index := 0 to Fields.Count - 1 do
  begin
    Field := Fields[Index];

    PropertyName := '';
    if not FFieldToPropertyMap.{$IFDEF FPC}TryGetData{$ELSE}TryGetValue{$ENDIF}(Field.FieldName, PropertyName) or PropertyName.IsEmpty then
      PropertyName := Field.FieldName;

    Field.Value := ConvertToFieldValue(PropertyName, GetPropertyValue(Instance, PropertyName));
  end;
end;

procedure TyaAbstractORM<T>.CopyInstanceToParams(const Instance: T; const Params: TParams);
var
  Index: integer;
  Param: TParam;
  PropertyName: string;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToParams: Instance not assigned.');
  if not Assigned(Params) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToParams: Params not assigned.');

  for Index := 0 to Params.Count - 1 do
  begin
    Param := Params[Index];

    PropertyName := '';
    if not FFieldToPropertyMap.{$IFDEF FPC}TryGetData{$ELSE}TryGetValue{$ENDIF}(Param.Name, PropertyName) or PropertyName.IsEmpty then
      PropertyName := Param.Name;

    Param.Value := ConvertToFieldValue(PropertyName, GetPropertyValue(Instance, PropertyName));
  end;
end;

function TyaAbstractORM<T>.GetFieldNames(const Instance: T): TStringArray;
var
  PT: PTypeData;
  Count,
{$IFDEF FPC}
  DataIndex,
{$ENDIF}
  Index: integer;
{$IFNDEF FPC}
  Key,
{$ENDIF}
  FieldName: string;
  PP: PPropList;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.GetFieldNames: Instance not assigned.');

  PT := GetTypeData(Instance.ClassInfo);
  Count := PT^.PropCount;
  SetLength(result, Count);
  GetMem (PP, Count * SizeOf(Pointer));
  GetPropInfos(Instance.ClassInfo, PP);
  for Index := 0 to Count - 1 do
  begin
    FieldName := PP^[Index]^.Name;
{$IFDEF FPC}
    DataIndex := FFieldToPropertyMap.IndexOfData(FieldName);
    if DataIndex <> -1 then
      FieldName := FFieldToPropertyMap.Keys[DataIndex];
{$ELSE}
    for Key in FFieldToPropertyMap.Keys do
      if UpperCase(FFieldToPropertyMap.Items[Key]) = UpperCase(FieldName) then
        FieldName := Key;
{$ENDIF}
    result[Index] := FieldName;
  end;
  FreeMem(PP);
end;

function TyaAbstractORM<T>.GetPropertyNames(const Instance: T): TStringArray;
var
  PT: PTypeData;
  Count,
  Index: integer;
  PP: PPropList;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.GetPropertyNames: Instance not assigned.');

  PT := GetTypeData(Instance.ClassInfo);
  Count := PT^.PropCount;
  SetLength(result, Count);
  GetMem (PP, Count * SizeOf(Pointer));
  GetPropInfos(Instance.ClassInfo, PP);
  for Index := 0 to Count - 1 do
    result[Index] := PP^[Index]^.Name;
  FreeMem(PP);
end;

function TyaAbstractORM<T>.GetFieldName(const PropertyName: string): string;
var
{$IFDEF FPC}
  DataIndex: integer;
{$ELSE}
  Key: string;
{$ENDIF}
begin
  result := PropertyName;
  if not Assigned(FFieldToPropertyMap) then
    Exit;
{$IFDEF FPC}
  DataIndex := FFieldToPropertyMap.IndexOfData(PropertyName);
  if DataIndex <> -1 then
    result := FFieldToPropertyMap.Keys[DataIndex];
{$ELSE}
  for Key in FFieldToPropertyMap.Keys do
    if UpperCase(FFieldToPropertyMap.Items[Key]) = UpperCase(PropertyName) then
      FieldName := Key;
{$ENDIF}
end;

function TyaAbstractORM<T>.ConvertToFieldValue(const PropertyName: string; const PropertyValue: variant): variant;
begin
  result := PropertyValue;
  if Assigned(FPropertytoFieldConversionFunc) then
    result := FPropertytoFieldConversionFunc(PropertyName, PropertyValue);
end;

function TyaAbstractORM<T>.ConvertToPropertyValue(const FieldName: string; const FieldValue: variant): variant;
begin
  result := FieldValue;
  if Assigned(FFieldToPropertyConversionFunc) then
    result := FFieldToPropertyConversionFunc(FieldName, FieldValue);
end;

function TyaAbstractORM<T>.HasSameKeys(const Instance: T; const Fields: TFields): boolean;
var
  KeyIndex: integer;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.HasSameKeys: Instance not assigned.');
  if not Assigned(Fields) then
    raise EyaORMException.Create('TyaAbstractORM<T>.HasSameKeys: Fields not assigned.');

  result := true;
  for KeyIndex := Low(FFieldKeyFields) to High(FFieldKeyFields) do
    result := result and VarSameValue(Fields.FieldByName(FFieldKeyFields[KeyIndex]).Value, GetPropertyValue(Instance, FPropertyKeyFields[KeyIndex]));
end;

procedure TyaAbstractORM<T>.CreateSelectSQL(const Instance: T; const SQL: TStrings);
var
  FieldNames: TStringArray;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateSelectSQL: Instance not assigned.');
  if not Assigned(SQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateSelectSQL: SQL not assigned.');

  FieldNames := GetFieldNames(Instance);

  SQL.Clear;
  SQL.Add('SELECT');
  SQL.Add(Format('%s', [Concat(FieldNames, ',')]));
  SQL.Add(Format('FROM %s', [FTableName]));
end;

procedure TyaAbstractORM<T>.CreateInsertSQL(const Instance: T; const SQL: TStrings);
var
  FieldNames: TStringArray;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateInsertSQL: Instance not assigned.');
  if not Assigned(SQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateInsertSQL: SQL not assigned.');

  FieldNames := GetFieldNames(Instance);
  SQL.Add(Format('INSERT INTO %s', [FTableName]));
  SQL.Add(Format('(%s)', [Concat(FieldNames, ',')]));
  SQL.Add('VALUES');
  SQL.Add(Format('(%s)', [Concat(FieldNames, ',', ':')]));
end;

procedure TyaAbstractORM<T>.CreateUpdateSQL(const Instance: T; const SQL: TStrings);
var
  FieldNames: TStringArray;
  Index,
  KeyIndex: integer;
  First,
  Found: boolean;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateUpdateSQL: Instance not assigned.');
  if not Assigned(SQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateUpdateSQL: SQL not assigned.');

  FieldNames := GetFieldNames(Instance);

  SQL.Add(Format('UPDATE %s', [FTableName]));
  SQL.Add('SET');

  First := true;
  for Index := Low(FieldNames) to High(FieldNames) do
  begin
    Found := false;
    for KeyIndex := Low(FFieldKeyFields) to High(FFieldKeyFields) do
      if SameText(FFieldKeyFields[KeyIndex], FieldNames[Index]) then
      begin
        Found := true;
        Break;
      end;
    if not Found then
    begin
      SQL.Add(Format('%s %s =:%s', [IfThen(not First, ','), FieldNames[Index], FieldNames[Index]]));
      First := false;
    end;
  end;

  if Length(FFieldKeyFields) > 0 then
  begin
    SQL.Add('WHERE');
    for Index := Low(FFieldKeyFields) to High(FFieldKeyFields) do
      SQL.Add(Format('%s = :%s %s', [FFieldKeyFields[Index], FFieldKeyFields[Index], IfThen(Index < Low(FFieldKeyFields), 'AND')]));
  end;
end;

procedure TyaAbstractORM<T>.CreateDeleteSQL(const SQL: TStrings);
begin
  if not Assigned(SQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateDeleteSQL: SQL not assigned.');

  SQL.Clear;
  SQL.Add(Format('DELETE FROM %s', [FTableName]));
end;

procedure TyaAbstractORM<T>.AddKeyValuesConditions(const KeyValues: TVariantArray; const SQL: TStrings; const Params: TParams);
var
  Index: integer;
begin
  if not Assigned(Params) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddKeyValuesConditions: Params not assigned.');
  if not Assigned(SQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddKeyValuesConditions: SQL not assigned.');

  if Length(KeyValues) > 0 then
  begin
    SQL.Add('WHERE');
    for Index := Low(KeyValues) to High(KeyValues) do
      SQL.Add(Format('%s = :%s %s', [FFieldKeyFields[Index], FFieldKeyFields[Index], IfThen(Index < Low(FFieldKeyFields), 'AND')]));
  end;
  PrepareKeyValuesParams(KeyValues, Params);
end;

procedure TyaAbstractORM<T>.AddFilterConditions(const Filter: IyaFilter; const SQL: TStrings; const Params: TParams);
var
  FilterString: string;
begin
  if not Assigned(Filter) then
    Exit;
  if not Assigned(SQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddFilterConditions: SQL not assigned.');
  if not Assigned(Params) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddFilterConditions: Params not assigned.');

  FilterString := Filter.AsString;
  if not FilterString.IsEmpty then
    SQL.Add(Format('WHERE %s', [FilterString]));

  PrepareFilterParams(Filter, Params);
end;

procedure TyaAbstractORM<T>.PrepareKeyValuesParams(const KeyValues: TVariantArray; const Params: TParams);
var
  Index: integer;
begin
  if not Assigned(Params) then
    raise EyaORMException.Create('TyaAbstractORM<T>.PrepareKeyValuesParams: Params not assigned.');

  for Index := Low(KeyValues) to High(KeyValues) do
    Params[Index].Value := KeyValues[Index];
end;

procedure TyaAbstractORM<T>.PrepareFilterParams(const Filter: IyaFilter; const Params: TParams);
var
  FilterString: string;
begin
  if not Assigned(Filter) then
    Exit;

  if not Assigned(Params) then
    raise EyaORMException.Create('TyaAbstractORM<T>.PrepareFilterParams: Params not assigned.');

  FilterString := Filter.AsString;
  if not FilterString.IsEmpty then
    Filter.SetQueryParams(Params);
end;

function TyaAbstractORM<T>.Concat(const StringArray: TStringArray; const Separator: string): string;
var
  Key: string;
begin
  result := '';
  for Key in StringArray do
  begin
    if not result.IsEmpty then
      result := result + Separator;
    result := result + Key;
  end;
end;

function TyaAbstractORM<T>.Concat(const StringArray: TStringArray; const Separator: string; const Prefix: string): string;
var
  Key: string;
begin
  result := '';
  for Key in StringArray do
  begin
    if not result.IsEmpty then
      result := result + Separator;
    result := result + Prefix + Key;
  end;
end;

function TyaAbstractORM<T>.ConvertFieldKeyArrayToFieldKeyStr: string;
begin
  if FFieldKeyFieldsStr.IsEmpty then
    FFieldKeyFieldsStr := Concat(FFieldKeyFields, ';');
  Exit(FFieldKeyFieldsStr);
end;

function TyaAbstractORM<T>.GetKeyValues(const Instance: T): TVariantArray;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('yaORM.GetKeyValues: Instance not assigned.');

  result := GetFieldValues(FPropertyKeyFields, Instance);
end;

function TyaAbstractORM<T>.GetObject(const Fields: TFields): T;
begin
  if not Assigned(Fields) then
    raise EyaORMException.Create('yaORM.GetObject: Fields not assigned.');

  result := New;
  CopyFieldsToInstance(Fields, result);
end;

procedure TyaAbstractORM<T>.GetObjects(const Dataset: TDataset; out List: TObjectList<T>);
begin
  if not Assigned(Dataset) then
    raise EyaORMException.Create('yaORM.GetObjects: Dataset not assigned.');

  List := TObjectList<T>.Create;

  Dataset.First;
  while not Dataset.EOF do
  begin
    List.Add(GetObject(Dataset.Fields));
    Dataset.Next;
  end;
end;

procedure TyaAbstractORM<T>.SetObjects(const List: TObjectList<T>; const Dataset: TDataset);
var
  Instance: T;
  Found: boolean;
begin
  if not Assigned(Dataset) then
    raise EyaORMException.Create('yaORM.SetObjects: Dataset not assigned.');
  if not Assigned(List) then
    raise EyaORMException.Create('yaORM.SetObjects: List not assigned.');

  Dataset.First;
  while not Dataset.EOF do
  begin
    Found := false;
    for Instance in List do
      Found := Found or HasSameKeys(Instance, Dataset.Fields);
    if Found then
      Dataset.Next
    else
      Dataset.Delete;
  end;

  for Instance in List do
    SetObject(Instance, Dataset);
end;

procedure TyaAbstractORM<T>.SetObject(const Instance: T; const Dataset: TDataset);
begin
  if not Assigned(Dataset) then
    raise EyaORMException.Create('yaORM.SetObject: Dataset not assigned.');
  if not Assigned(Instance) then
    raise EyaORMException.Create('yaORM.SetObject: Instance not assigned.');

  if DataSet.Locate(ConvertFieldKeyArrayToFieldKeyStr, VarArrayOf(GetKeyValues(Instance)), []) then
    Dataset.Edit
  else
    Dataset.Insert;

  CopyInstanceToFields(Instance, Dataset.Fields);

  Dataset.Post;
end;

function TyaAbstractORM<T>.New: T;
begin
  result := FFactoryFunc();
end;

function TyaAbstractORM<T>.Clone(const Instance: T): T;
var
  PropertyNames: TStringArray;
  PropertyName: string;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('yaORM.Clone: Instance not assigned.');

  result := New;
  PropertyNames := GetPropertyNames(result);
  for PropertyName in PropertyNames do
    SetPropValue(result, PropertyName, GetPropertyValue(Instance, PropertyName));
end;

function TyaAbstractORM<T>.NewFilter: IyaFilter;
begin
  result := TyaFilter<T>.Create(self);
end;

function TyaAbstractORM<T>.GetPropertyKeyFields: TStringArray;
begin
  result := FPropertyKeyFields;
end;

function TyaAbstractORM<T>.GetFieldValues(const FieldNames: TStringArray; const Instance: T): TVariantArray;
var
  KeyIndex: integer;
  PropertyName: string;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('yaORM.GetFieldValues: Instance not assigned.');

  SetLength(result, Length(FieldNames));
  for KeyIndex := 0 to High(FieldNames) do
  begin
    PropertyName := FieldNames[KeyIndex];
    result[KeyIndex] := ConvertToFieldValue(PropertyName, GetPropertyValue(Instance, PropertyName));
  end;
end;

function TyaAbstractORM<T>.Load(const KeyValues: TVariantArray; out Instance: T): boolean;
begin
  result := false;
  if Length(KeyValues) <> Length(FPropertyKeyFields) then
    raise EyaORMException.Create('yaORM.Load: Number of KeyValues is incorrect.');
end;

procedure TyaAbstractORM<T>.Delete(const KeyValues: TVariantArray);
begin
  if Length(KeyValues) <> Length(FPropertyKeyFields) then
    raise EyaORMException.Create('yaORM.Delete: Number of KeyValues is incorrect.');
end;

{ TyaFilter }

constructor TyaFilter<T>.Create(const ORM: IyaORM<T>);
begin
  if not Assigned(ORM) then
    raise EyaORMException.Create('TyaFilter.Create: ORM is not assigned.');
  FList := TList<TyaFilterCondition>.Create;
  FORMPointer := ORM;
end;

destructor TyaFilter<T>.Destroy;
begin
  FList.Clear;
  FreeAndNil(FList);
end;

procedure TyaFilter<T>.Clear;
begin
  FList.Clear;
end;

procedure TyaFilter<T>.AddCondition(const PropertyName: string; const FilterType: TFilterType; const Value: variant);
var
  Condition: TyaFilterCondition;
  FieldName: string;
begin
  FieldName := IyaORM<T>(FORMPointer).GetFieldName(PropertyName);

  if FieldName.IsEmpty then
    raise EyaORMException.CreateFmt('TyaFilter.AddCondition: Property "%s" does not exist.', [PropertyName]);

  Condition.FieldName := FieldName;
  Condition.FilterType := FilterType;
  Condition.Value := IyaORM<T>(FORMPointer).ConvertToFieldValue(PropertyName, Value);
  FList.Add({%H-}Condition);
end;

procedure TyaFilter<T>.AddAnd;
var
  Condition: TyaFilterCondition;
begin
  Condition.FilterType := ftAnd;
  FList.Add({%H-}Condition);
end;

procedure TyaFilter<T>.AddOr;
var
  Condition: TyaFilterCondition;
begin
  Condition.FilterType := ftOr;
  FList.Add({%H-}Condition);
end;

procedure TyaFilter<T>.AddNot;
var
  Condition: TyaFilterCondition;
begin
  Condition.FilterType := ftNot;
  FList.Add({%H-}Condition);
end;

procedure TyaFilter<T>.AddOpenBracket;
var
  Condition: TyaFilterCondition;
begin
  Condition.FilterType := ftOpenedBracket;
  FList.Add({%H-}Condition);
end;

procedure TyaFilter<T>.AddClosedBracket;
var
  Condition: TyaFilterCondition;
begin
  Condition.FilterType := ftClosedBracket;
  FList.Add({%H-}Condition);
end;

function TyaFilter<T>.AsString: string;
var
  Condition: TyaFilterCondition;
begin
  result := '';
  with FList.GetEnumerator do
  begin
    while MoveNext do
    begin
      Condition := Current;
      case Condition.FilterType of
        ftEqual,
        ftUnequal,
        ftLessThan,
        ftLessThanOrEqual,
        ftMoreThan,
        ftMoreThanOrEqual: result := result + ' ' + Format(FilterStrings[Condition.FilterType], [Condition.FieldName, Condition.FieldName]);
        ftIsNull,
        ftIsNotNull: result := result + ' ' + Format(FilterStrings[Condition.FilterType], [Condition.FieldName]);
        ftContains,
        ftStartsWith,
        ftEndsWith: result := result + ' ' + Format(FilterStrings[Condition.FilterType], [Condition.FieldName, Condition.Value]);
        ftAnd,
        ftOr,
        ftNot,
        ftOpenedBracket,
        ftClosedBracket: result := result + ' ' + FilterStrings[Condition.FilterType];
      end;
    end;
    Free;
  end;
end;

procedure TyaFilter<T>.SetQueryParams(const Params: TParams);
var
  Condition: TyaFilterCondition;
begin
  if not Assigned(Params) then
    raise EyaORMException.Create('TyaFilter<T>.SetQueryParams: Params not assigned.');

  with FList.GetEnumerator do
  begin
    while MoveNext do
    begin
      Condition := Current;
      case Condition.FilterType of
        ftEqual,
        ftUnequal,
        ftLessThan,
        ftLessThanOrEqual,
        ftMoreThan,
        ftMoreThanOrEqual: Params.ParamValues[Condition.FieldName] := Condition.Value;
      end;
    end;
    Free;
  end;
end;

end.

