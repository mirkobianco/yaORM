(*
  yet another ORM - for FreePascal
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
  Variants,
  DB,
  TypInfo,
  yaORM.Types,
  yaORM.Collections;

type
  IyaFilter = interface(IInterface)
    ['{6A7913DF-AE1A-E611-9BDD-080027BF4002}']
    procedure Clear;
    procedure AddCondition(const APropertyName: string; const AFilterType: TFilterType; const AValue: variant);
    procedure AddAnd;
    procedure AddOr;
    procedure AddNot;
    procedure AddOpenBracket;
    procedure AddClosedBracket;

    function AsString: string;
    procedure SetQueryParams(const AParams: TParams);
  end;

  { IyaORM }

  IyaORM<T: TCollectionItem> = interface(IInterface)
    ['{E88D8D4D-B71E-E611-9290-080027BF4002}']
    function GetObject(const AFields: TFields): T;
    procedure GetObjects(const ADataset: TDataset; out OCollection: TORMCollection<T>);
    procedure SetObjects(const ACollection: TORMCollection<T>; const ADataset: TDataset);
    procedure SetObject(const AInstance: T; const ADataset: TDataset);

    function New: T;
    function Clone(const AInstance: T): T;
    function NewFilter: IyaFilter;

    function GetPropertyKeyFields: TStringArray;
    function GetFieldName(const APropertyName: string): string;
    function ConvertToFieldValue(const APropertyName: string; const APropertyValue: variant): variant;
    function GetFieldValues(const AFieldNames: TStringArray; const AInstance: T): TVariantArray;

    function Load(const AKeyValues: TVariantArray; out OInstance: T): boolean;
    function LoadCollection(const ASQL: string; out OCollection: TORMCollection<T>): boolean; overload;
    function LoadCollection(const AFilter: IyaFilter; out OCollection: TORMCollection<T>): boolean; overload;
    function LoadCollection(const AKeyValues: TVariantArray; out OCollection: TORMCollection<T>): boolean; overload;
    procedure Insert(const AInstance: T);
    procedure Update(const AInstance: T);
    procedure Delete(const AInstance: T); overload;
    procedure Delete(const AKeyValues: TVariantArray); overload;
    procedure Delete(const AFilter: IyaFilter); overload;
  end;

  { TyaFilter }

  TyaFilter<T: TCollectionItem> = class(TInterfacedObject, IyaFilter)
  strict private
  var
    FList: TList<TyaFilterCondition>;
    FORMPointer: Pointer;
  public
    constructor Create(const AORM: IyaORM<T>);
    destructor Destroy; override;

//  IyaFilter<T: IyaObject>
    procedure Clear;
    procedure AddCondition(const APropertyName: string; const AFilterType: TFilterType; const AValue: variant);
    procedure AddAnd;
    procedure AddOr;
    procedure AddNot;
    procedure AddOpenBracket;
    procedure AddClosedBracket;

    function AsString: string;
    procedure SetQueryParams(const AParams: TParams);
  end;

  { TyaAbstractORM }

  TyaAbstractORM<T: TCollectionItem> = class(TInterfacedObject, IyaORM<T>)
  public
  type
    TFactoryFunc = function: T of object;
  strict private
    procedure PrepareKeyValuesParams(const AKeyValues: TVariantArray; const AParams: TParams);
    procedure PrepareFilterParams(const AFilter: IyaFilter; const AParams: TParams);
    procedure CopyInstanceToFields(const AInstance: T; const AFields: TFields);
    function Concat(const AStringArray: TStringArray; const ASeparator: string): string; overload;
    function Concat(const AStringArray: TStringArray; const ASeparator: string; const APrefix: string): string; overload;
    function ConvertFieldKeyArrayToFieldKeyStr: string;
    function GetFieldNames(const AInstance: T): TStringArray;
    function GetPropertyNames(const AInstance: T): TStringArray;
    function HasSameKeys(const AInstance: T; const AFields: TFields): boolean;
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

    procedure CopyFieldsToInstance(const AFields: TFields; const AInstance: T);
    procedure CopyInstanceToParams(const AInstance: T; const AParams: TParams);
    function GetKeyValues(const AInstance: T): TVariantArray;

    procedure CreateSelectSQL(const AInstance: T; const ASQL: TStrings);
    procedure CreateInsertSQL(const AInstance: T; const ASQL: TStrings);
    procedure CreateUpdateSQL(const AInstance: T; const ASQL: TStrings);
    procedure CreateDeleteSQL(const ASQL: TStrings);
    procedure AddKeyValuesConditions(const AKeyValues: TVariantArray; const ASQL: TStrings; const AParams: TParams);
    procedure AddFilterConditions(const AFilter: IyaFilter; const ASQL: TStrings; const AParams: TParams);
  public
    constructor Create(const AFactoryFunc: TFactoryFunc;
                       const ATableName: string;
                       const APropertyKeyFields: TStringArray;
                       const AFieldToPropertyMap: TDictionary<string, string> = nil;
                       const AFieldToPropertyConversionFunc: TConversionFunc = nil;
                       const APropertytoFieldConversionFunc: TConversionFunc = nil); reintroduce;
    destructor Destroy; override;

    //IyaORM
    function GetObject(const AFields: TFields): T;
    procedure GetObjects(const ADataset: TDataset; out OCollection: TORMCollection<T>);
    procedure SetObjects(const ACollection: TORMCollection<T>; const ADataset: TDataset);
    procedure SetObject(const AInstance: T; const ADataset: TDataset);

    function New: T;
    function Clone(const AInstance: T): T;
    function NewFilter: IyaFilter;

    function GetPropertyKeyFields: TStringArray;
    function GetFieldName(const APropertyName: string): string;
    function ConvertToFieldValue(const APropertyName: string; const APropertyValue: variant): variant;
    function ConvertToPropertyValue(const AFieldName: string; const AFieldValue: variant): variant;
    function GetFieldValues(const AFieldNames: TStringArray; const AInstance: T): TVariantArray;

    function Load(const AKeyValues: TVariantArray; out OInstance: T): boolean; virtual;
    function LoadCollection(const ASQL: string; out OCollection: TORMCollection<T>): boolean; overload; virtual; abstract;
    function LoadCollection(const AFilter: IyaFilter; out OCollection: TORMCollection<T>): boolean; overload; virtual; abstract;
    function LoadCollection(const AKeyValues: TVariantArray; out OCollection: TORMCollection<T>): boolean; overload; virtual; abstract;
    procedure Insert(const AInstance: T); virtual; abstract;
    procedure Update(const AInstance: T); virtual; abstract;
    procedure Delete(const AInstance: T); overload; virtual; abstract;
    procedure Delete(const AKeyValues: TVariantArray); overload; virtual;
    procedure Delete(const AFilter: IyaFilter); overload; virtual; abstract;
  end;

implementation

{ yaORM }

constructor TyaAbstractORM<T>.Create(const AFactoryFunc: TFactoryFunc;
                                     const ATableName: string;
                                     const APropertyKeyFields: TStringArray;
                                     const AFieldToPropertyMap: TDictionary<string, string>;
                                     const AFieldToPropertyConversionFunc: TConversionFunc;
                                     const APropertytoFieldConversionFunc: TConversionFunc);
var
  LIndex: integer;
begin
  inherited Create;
  FFactoryFunc := AFactoryFunc;
  FTableName := ATableName;
  FPropertyKeyFields := APropertyKeyFields;
  FFieldToPropertyMap := AFieldToPropertyMap;
  if not Assigned(FFieldToPropertyMap) then
    FFieldToPropertyMap := TDictionary<string, string>.Create;
  FFieldToPropertyConversionFunc := AFieldToPropertyConversionFunc;
  FPropertytoFieldConversionFunc := APropertytoFieldConversionFunc;

  SetLength(FFieldKeyFields, Length(FPropertyKeyFields));
  for LIndex := Low(FFieldKeyFields) to High(FFieldKeyFields) do
    FFieldKeyFields[LIndex] := GetFieldName(FPropertyKeyFields[LIndex]);

end;

destructor TyaAbstractORM<T>.Destroy;
begin
  FreeAndNil(FFieldToPropertyMap);
  inherited Destroy;
end;

procedure TyaAbstractORM<T>.CopyFieldsToInstance(const AFields: TFields; const AInstance: T);
var
  LIndex: integer;
  LField: TField;
  LPropInfo: PPropInfo;
  LPropertyName: string;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyFieldsToInstance: Instance not assigned.');
  if not Assigned(AFields) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyFieldsToInstance: Fields not assigned.');

  for LIndex := 0 to AFields.Count - 1 do
  begin
    LField := AFields[LIndex];

    LPropertyName := '';
    if not FFieldToPropertyMap.{$IFDEF FPC}TryGetData{$ELSE}TryGetValue{$ENDIF}(LField.FieldName, LPropertyName) or LPropertyName.IsEmpty then
      LPropertyName := LField.FieldName;

    LPropInfo := GetPropInfo(PTypeInfo(AInstance.ClassInfo), LPropertyName);
    if assigned(LPropInfo) then
      SetPropValue(AInstance, LPropertyName, ConvertToPropertyValue(LField.FieldName, LField.Value));
  end;
end;

procedure TyaAbstractORM<T>.CopyInstanceToFields(const AInstance: T; const AFields: TFields);
var
  LIndex: integer;
  LField: TField;
  LPropertyName: string;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToFields: Instance not assigned.');
  if not Assigned(AFields) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToFields: Fields not assigned.');

  for LIndex := 0 to AFields.Count - 1 do
  begin
    LField := AFields[LIndex];

    LPropertyName := '';
    if not FFieldToPropertyMap.{$IFDEF FPC}TryGetData{$ELSE}TryGetValue{$ENDIF}(LField.FieldName, LPropertyName) or LPropertyName.IsEmpty then
      LPropertyName := LField.FieldName;

    LField.Value := ConvertToFieldValue(LPropertyName, GetPropValue(AInstance, LPropertyName));
  end;
end;

procedure TyaAbstractORM<T>.CopyInstanceToParams(const AInstance: T; const AParams: TParams);
var
  LIndex: integer;
  LParam: TParam;
  LPropertyName: string;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToParams: Instance not assigned.');
  if not Assigned(AParams) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CopyInstanceToParams: Params not assigned.');

  for LIndex := 0 to AParams.Count - 1 do
  begin
    LParam := AParams[LIndex];

    LPropertyName := '';
    if not FFieldToPropertyMap.{$IFDEF FPC}TryGetData{$ELSE}TryGetValue{$ENDIF}(LParam.Name, LPropertyName) or LPropertyName.IsEmpty then
      LPropertyName := LParam.Name;

    LParam.Value := ConvertToFieldValue(LPropertyName, GetPropValue(AInstance, LPropertyName));
  end;
end;

function TyaAbstractORM<T>.GetFieldNames(const AInstance: T): TStringArray;
var
  LPT: PTypeData;
  LCount,
{$IFDEF FPC}
  LDataIndex,
{$ENDIF}
  LIndex: integer;
{$IFNDEF FPC}
  LKey,
{$ENDIF}
  LPropertyName,
  LFieldName: string;
  LPP: PPropList;
begin
  SetLength(result, 0);
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.GetFieldNames: Instance not assigned.');

  LPT := GetTypeData(AInstance.ClassInfo);
  LCount := LPT^.PropCount;
  SetLength(result, LCount);
  GetMem (LPP, LCount * SizeOf(Pointer));
  GetPropInfos(AInstance.ClassInfo, LPP);
  for LIndex := 0 to LCount - 1 do
  begin
    LPropertyName := LPP^[LIndex]^.Name;
    LFieldName := LPropertyName;
{$IFDEF FPC}
    LDataIndex := FFieldToPropertyMap.IndexOfData(LPropertyName);
    if LDataIndex <> -1 then
      LFieldName := FFieldToPropertyMap.Keys[LDataIndex];
{$ELSE}
    for LKey in FFieldToPropertyMap.Keys do
      if UpperCase(FFieldToPropertyMap.Items[LKey]) = UpperCase(APropertyName) then
        FieldName := LKey;
{$ENDIF}
    result[LIndex] := LFieldName;
  end;
  FreeMem(LPP);
end;

function TyaAbstractORM<T>.GetPropertyNames(const AInstance: T): TStringArray;
var
  LPT: PTypeData;
  LCount,
  LIndex: integer;
  LPP: PPropList;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.GetPropertyNames: Instance not assigned.');

  LPT := GetTypeData(AInstance.ClassInfo);
  LCount := LPT^.PropCount;
  SetLength(result, LCount);
  GetMem (LPP, LCount * SizeOf(Pointer));
  GetPropInfos(AInstance.ClassInfo, LPP);
  for LIndex := 0 to LCount - 1 do
    result[LIndex] := LPP^[LIndex]^.Name;
  FreeMem(LPP);
end;

function TyaAbstractORM<T>.GetFieldName(const APropertyName: string): string;
var
{$IFDEF FPC}
  LDataIndex: integer;
{$ELSE}
  LKey: string;
{$ENDIF}
begin
  result := APropertyName;
  if not Assigned(FFieldToPropertyMap) then
    Exit;
{$IFDEF FPC}
  LDataIndex := FFieldToPropertyMap.IndexOfData(APropertyName);
  if LDataIndex <> -1 then
    result := FFieldToPropertyMap.Keys[LDataIndex];
{$ELSE}
  for LKey in FFieldToPropertyMap.Keys do
    if UpperCase(FFieldToPropertyMap.Items[LKey]) = UpperCase(APropertyName) then
      FieldName := LKey;
{$ENDIF}
end;

function TyaAbstractORM<T>.ConvertToFieldValue(const APropertyName: string; const APropertyValue: variant): variant;
begin
  result := APropertyValue;
  if Assigned(FPropertytoFieldConversionFunc) then
    result := FPropertytoFieldConversionFunc(APropertyName, APropertyValue);
end;

function TyaAbstractORM<T>.ConvertToPropertyValue(const AFieldName: string; const AFieldValue: variant): variant;
begin
  result := AFieldValue;
  if Assigned(FFieldToPropertyConversionFunc) then
    result := FFieldToPropertyConversionFunc(AFieldName, AFieldValue);
end;

function TyaAbstractORM<T>.HasSameKeys(const AInstance: T; const AFields: TFields): boolean;
var
  LKeyIndex: integer;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.HasSameKeys: Instance not assigned.');
  if not Assigned(AFields) then
    raise EyaORMException.Create('TyaAbstractORM<T>.HasSameKeys: Fields not assigned.');

  result := true;
  for LKeyIndex := Low(FFieldKeyFields) to High(FFieldKeyFields) do
    result := result and VarSameValue(AFields.FieldByName(FFieldKeyFields[LKeyIndex]).Value, GetPropValue(AInstance, FPropertyKeyFields[LKeyIndex]));
end;

procedure TyaAbstractORM<T>.CreateSelectSQL(const AInstance: T; const ASQL: TStrings);
var
  LFieldNames: TStringArray;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateSelectSQL: Instance not assigned.');
  if not Assigned(ASQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateSelectSQL: SQL not assigned.');

  LFieldNames := GetFieldNames(AInstance);

  ASQL.Clear;
  ASQL.Add('SELECT');
  ASQL.Add(Format('%s', [Concat(LFieldNames, ',')]));
  ASQL.Add(Format('FROM %s', [FTableName]));
end;

procedure TyaAbstractORM<T>.CreateInsertSQL(const AInstance: T; const ASQL: TStrings);
var
  LFieldNames: TStringArray;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateInsertSQL: Instance not assigned.');
  if not Assigned(ASQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateInsertSQL: SQL not assigned.');

  LFieldNames := GetFieldNames(AInstance);
  ASQL.Add(Format('INSERT INTO %s', [FTableName]));
  ASQL.Add(Format('(%s)', [Concat(LFieldNames, ',')]));
  ASQL.Add('VALUES');
  ASQL.Add(Format('(%s)', [Concat(LFieldNames, ',', ':')]));
end;

procedure TyaAbstractORM<T>.CreateUpdateSQL(const AInstance: T; const ASQL: TStrings);
var
  LFieldNames: TStringArray;
  LIndex,
  LKeyIndex: integer;
  LFirst,
  LFound: boolean;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateUpdateSQL: Instance not assigned.');
  if not Assigned(ASQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateUpdateSQL: SQL not assigned.');

  LFieldNames := GetFieldNames(AInstance);

  ASQL.Add(Format('UPDATE %s', [FTableName]));
  ASQL.Add('SET');

  LFirst := true;
  for LIndex := Low(LFieldNames) to High(LFieldNames) do
  begin
    LFound := false;
    for LKeyIndex := Low(FFieldKeyFields) to High(FFieldKeyFields) do
      if SameText(FFieldKeyFields[LKeyIndex], LFieldNames[LIndex]) then
      begin
        LFound := true;
        Break;
      end;
    if not LFound then
    begin
      ASQL.Add(Format('%s %s =:%s', [IfThen(not LFirst, ','), LFieldNames[LIndex], LFieldNames[LIndex]]));
      LFirst := false;
    end;
  end;

  if Length(FFieldKeyFields) > 0 then
  begin
    ASQL.Add('WHERE');
    for LIndex := Low(FFieldKeyFields) to High(FFieldKeyFields) do
      ASQL.Add(Format('%s = :%s %s', [FFieldKeyFields[LIndex], FFieldKeyFields[LIndex], IfThen(LIndex < Low(FFieldKeyFields), 'AND')]));
  end;
end;

procedure TyaAbstractORM<T>.CreateDeleteSQL(const ASQL: TStrings);
begin
  if not Assigned(ASQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.CreateDeleteSQL: SQL not assigned.');

  ASQL.Clear;
  ASQL.Add(Format('DELETE FROM %s', [FTableName]));
end;

procedure TyaAbstractORM<T>.AddKeyValuesConditions(const AKeyValues: TVariantArray; const ASQL: TStrings; const AParams: TParams);
var
  LIndex: integer;
begin
  if not Assigned(AParams) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddKeyValuesConditions: Params not assigned.');
  if not Assigned(ASQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddKeyValuesConditions: SQL not assigned.');

  if Length(AKeyValues) > 0 then
  begin
    ASQL.Add('WHERE');
    for LIndex := Low(AKeyValues) to High(AKeyValues) do
      ASQL.Add(Format('%s = :%s %s', [FFieldKeyFields[LIndex], FFieldKeyFields[LIndex], IfThen(LIndex < Low(FFieldKeyFields), 'AND')]));
  end;
  PrepareKeyValuesParams(AKeyValues, AParams);
end;

procedure TyaAbstractORM<T>.AddFilterConditions(const AFilter: IyaFilter; const ASQL: TStrings; const AParams: TParams);
var
  LFilterString: string;
begin
  if not Assigned(AFilter) then
    Exit;
  if not Assigned(ASQL) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddFilterConditions: SQL not assigned.');
  if not Assigned(AParams) then
    raise EyaORMException.Create('TyaAbstractORM<T>.AddFilterConditions: Params not assigned.');

  LFilterString := AFilter.AsString;
  if not LFilterString.IsEmpty then
    ASQL.Add(Format('WHERE %s', [LFilterString]));

  PrepareFilterParams(AFilter, AParams);
end;

procedure TyaAbstractORM<T>.PrepareKeyValuesParams(const AKeyValues: TVariantArray; const AParams: TParams);
var
  LIndex: integer;
begin
  if not Assigned(AParams) then
    raise EyaORMException.Create('TyaAbstractORM<T>.PrepareKeyValuesParams: Params not assigned.');

  for LIndex := Low(AKeyValues) to High(AKeyValues) do
    AParams[LIndex].Value := AKeyValues[LIndex];
end;

procedure TyaAbstractORM<T>.PrepareFilterParams(const AFilter: IyaFilter; const AParams: TParams);
var
  LFilterString: string;
begin
  if not Assigned(AFilter) then
    Exit;

  if not Assigned(AParams) then
    raise EyaORMException.Create('TyaAbstractORM<T>.PrepareFilterParams: Params not assigned.');

  LFilterString := AFilter.AsString;
  if not LFilterString.IsEmpty then
    AFilter.SetQueryParams(AParams);
end;

function TyaAbstractORM<T>.Concat(const AStringArray: TStringArray; const ASeparator: string): string;
var
  LKey: string;
begin
  result := '';
  for LKey in AStringArray do
  begin
    if not result.IsEmpty then
      result := result + ASeparator;
    result := result + LKey;
  end;
end;

function TyaAbstractORM<T>.Concat(const AStringArray: TStringArray; const ASeparator: string; const APrefix: string): string;
var
  LKey: string;
begin
  result := '';
  for LKey in AStringArray do
  begin
    if not result.IsEmpty then
      result := result + ASeparator;
    result := result + APrefix + LKey;
  end;
end;

function TyaAbstractORM<T>.ConvertFieldKeyArrayToFieldKeyStr: string;
begin
  if FFieldKeyFieldsStr.IsEmpty then
    FFieldKeyFieldsStr := Concat(FFieldKeyFields, ';');
  Exit(FFieldKeyFieldsStr);
end;

function TyaAbstractORM<T>.GetKeyValues(const AInstance: T): TVariantArray;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('yaORM.GetKeyValues: Instance not assigned.');

  result := GetFieldValues(FPropertyKeyFields, AInstance);
end;

function TyaAbstractORM<T>.GetObject(const AFields: TFields): T;
begin
  if not Assigned(AFields) then
    raise EyaORMException.Create('yaORM.GetObject: Fields not assigned.');

  result := New;
  CopyFieldsToInstance(AFields, result);
end;

procedure TyaAbstractORM<T>.GetObjects(const ADataset: TDataset; out OCollection: TORMCollection<T>);
var
  LObject: T;
begin
  if not Assigned(ADataset) then
    raise EyaORMException.Create('yaORM.GetObjects: Dataset not assigned.');

  OCollection := TORMCollection<T>.Create;

  ADataset.First;
  while not ADataset.EOF do
  begin
    LObject := GetObject(ADataset.Fields);
    LObject.Collection := OCollection;
    ADataset.Next;
  end;
end;

procedure TyaAbstractORM<T>.SetObjects(const ACollection: TORMCollection<T>; const ADataset: TDataset);
var
  LInstance: TCollectionItem;
  LFound: boolean;
begin
  if not Assigned(ADataset) then
    raise EyaORMException.Create('yaORM.SetObjects: Dataset not assigned.');
  if not Assigned(ACollection) then
    raise EyaORMException.Create('yaORM.SetObjects: Collection not assigned.');

  ADataset.First;
  while not ADataset.EOF do
  begin
    LFound := false;
    for LInstance in ACollection do
      LFound := LFound or HasSameKeys(T(LInstance), ADataset.Fields);
    if LFound then
      ADataset.Next
    else
      ADataset.Delete;
  end;

  for LInstance in ACollection do
    SetObject(T(LInstance), ADataset);
end;

procedure TyaAbstractORM<T>.SetObject(const AInstance: T; const ADataset: TDataset);
begin
  if not Assigned(ADataset) then
    raise EyaORMException.Create('yaORM.SetObject: Dataset not assigned.');
  if not Assigned(AInstance) then
    raise EyaORMException.Create('yaORM.SetObject: Instance not assigned.');

  if ADataset.Locate(ConvertFieldKeyArrayToFieldKeyStr, VarArrayOf(GetKeyValues(AInstance)), []) then
    ADataset.Edit
  else
    ADataset.Insert;

  CopyInstanceToFields(AInstance, ADataset.Fields);

  ADataset.Post;
end;

function TyaAbstractORM<T>.New: T;
begin
  result := FFactoryFunc();
end;

function TyaAbstractORM<T>.Clone(const AInstance: T): T;
var
  LPropertyNames: TStringArray;
  LPropertyName: string;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('yaORM.Clone: Instance not assigned.');

  result := New;
  LPropertyNames := GetPropertyNames(result);
  for LPropertyName in LPropertyNames do
    SetPropValue(result, LPropertyName, GetPropValue(AInstance, LPropertyName));
end;

function TyaAbstractORM<T>.NewFilter: IyaFilter;
begin
  result := TyaFilter<T>.Create(self);
end;

function TyaAbstractORM<T>.GetPropertyKeyFields: TStringArray;
begin
  result := FPropertyKeyFields;
end;

function TyaAbstractORM<T>.GetFieldValues(const AFieldNames: TStringArray; const AInstance: T): TVariantArray;
var
  LKeyIndex: integer;
  LPropertyName: string;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('yaORM.GetFieldValues: Instance not assigned.');

  SetLength(result, Length(AFieldNames));
  for LKeyIndex := 0 to High(AFieldNames) do
  begin
    LPropertyName := AFieldNames[LKeyIndex];
    result[LKeyIndex] := ConvertToFieldValue(LPropertyName, GetPropValue(AInstance, LPropertyName));
  end;
end;

function TyaAbstractORM<T>.Load(const AKeyValues: TVariantArray; out OInstance: T): boolean;
begin
  result := false;
  if Length(AKeyValues) <> Length(FPropertyKeyFields) then
    raise EyaORMException.Create('yaORM.Load: Number of KeyValues is incorrect.');
end;

procedure TyaAbstractORM<T>.Delete(const AKeyValues: TVariantArray);
begin
  if Length(AKeyValues) <> Length(FPropertyKeyFields) then
    raise EyaORMException.Create('yaORM.Delete: Number of KeyValues is incorrect.');
end;

{ TyaFilter }

constructor TyaFilter<T>.Create(const AORM: IyaORM<T>);
begin
  if not Assigned(AORM) then
    raise EyaORMException.Create('TyaFilter.Create: ORM is not assigned.');
  FList := TList<TyaFilterCondition>.Create;
  FORMPointer := AORM;
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

procedure TyaFilter<T>.AddCondition(const APropertyName: string; const AFilterType: TFilterType; const AValue: variant);
var
  LCondition: TyaFilterCondition;
  LFieldName: string;
begin
  LFieldName := IyaORM<T>(FORMPointer).GetFieldName(APropertyName);

  if LFieldName.IsEmpty then
    raise EyaORMException.CreateFmt('TyaFilter.AddCondition: Property "%s" does not exist.', [APropertyName]);

  LCondition.FieldName := LFieldName;
  LCondition.FilterType := AFilterType;
  LCondition.Value := IyaORM<T>(FORMPointer).ConvertToFieldValue(APropertyName, AValue);
  FList.Add({%H-}LCondition);
end;

procedure TyaFilter<T>.AddAnd;
var
  LCondition: TyaFilterCondition;
begin
  LCondition.FilterType := ftAnd;
  FList.Add({%H-}LCondition);
end;

procedure TyaFilter<T>.AddOr;
var
  LCondition: TyaFilterCondition;
begin
  LCondition.FilterType := ftOr;
  FList.Add({%H-}LCondition);
end;

procedure TyaFilter<T>.AddNot;
var
  LCondition: TyaFilterCondition;
begin
  LCondition.FilterType := ftNot;
  FList.Add({%H-}LCondition);
end;

procedure TyaFilter<T>.AddOpenBracket;
var
  LCondition: TyaFilterCondition;
begin
  LCondition.FilterType := ftOpenedBracket;
  FList.Add({%H-}LCondition);
end;

procedure TyaFilter<T>.AddClosedBracket;
var
  LCondition: TyaFilterCondition;
begin
  LCondition.FilterType := ftClosedBracket;
  FList.Add({%H-}LCondition);
end;

function TyaFilter<T>.AsString: string;
begin
  result := '';
  with FList.GetEnumerator do
  begin
    while MoveNext do
    begin
      case Current.FilterType of
        ftEqual,
        ftUnequal,
        ftLessThan,
        ftLessThanOrEqual,
        ftMoreThan,
        ftMoreThanOrEqual: result := result + ' ' + Format(FilterStrings[Current.FilterType], [Current.FieldName, Current.FieldName]);
        ftIsNull,
        ftIsNotNull: result := result + ' ' + Format(FilterStrings[Current.FilterType], [Current.FieldName]);
        ftContains,
        ftStartsWith,
        ftEndsWith: result := result + ' ' + Format(FilterStrings[Current.FilterType], [Current.FieldName, Current.Value]);
        ftAnd,
        ftOr,
        ftNot,
        ftOpenedBracket,
        ftClosedBracket: result := result + ' ' + FilterStrings[Current.FilterType];
      end;
    end;
    Free;
  end;
end;

procedure TyaFilter<T>.SetQueryParams(const AParams: TParams);
begin
  if not Assigned(AParams) then
    raise EyaORMException.Create('TyaFilter<T>.SetQueryParams: Params not assigned.');

  with FList.GetEnumerator do
  begin
    while MoveNext do
    begin
      case Current.FilterType of
        ftEqual,
        ftUnequal,
        ftLessThan,
        ftLessThanOrEqual,
        ftMoreThan,
        ftMoreThanOrEqual: AParams.ParamValues[Current.FieldName] := Current.Value;
      end;
    end;
    Free;
  end;
end;

end.

