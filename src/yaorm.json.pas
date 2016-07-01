(*
  yet another ORM - for FreePascal and Delphi
  JSON ORM converter class

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.JSON;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  TypInfo,
  DB,
  RTTIUtils,
  fpjson,
  fpjsonrtti,
  jsonparser,
  jsonscanner,
  yaORM.Types,
  yaORM;

type

  { TyaORMToJSONConverter }

  TyaORMToJSONConverter<T: Tobject> = class
  strict private
  var
    FORM: IyaORM<T>;

    function JSONDataFromString(const AJSON: TJSONStringType): TJSONData;
    procedure DBJSONToObject(const AJSONObject: TJSONObject; out OInstance: T);
  public
    constructor Create(const AORM: IyaORM<T>); reintroduce;

    function LoadFields(const AJSON: TJSONStringType; out OInstance: T): boolean;
    function LoadProperties(const AJSON: TJSONStringType; out OInstance: T): boolean;
    function SaveProperties(const AInstance: T): TJSONStringType;
  end;

implementation

{ TyaORMToJSONConverter }

function TyaORMToJSONConverter<T>.JSONDataFromString(const AJSON: TJSONStringType): TJSONData;
begin
  with TJSONParser.Create(AJSON, [joUTF8,joStrict,joComments,joIgnoreTrailingComma]) do
    try
      result := Parse;
    finally
      Free;
    end;
end;

procedure TyaORMToJSONConverter<T>.DBJSONToObject(const AJSONObject: TJSONObject; out OInstance: T);
Var
  LIndex,
  LPropIndex: Integer;
  LPropInfoList: TPropInfoList;
  LFieldName: string;
begin
  OInstance := FORM.New;
  LPropInfoList := TPropInfoList.Create(OInstance, tkProperties);
  try
    for LIndex := 0 to LPropInfoList.Count - 1 do
    begin
      LFieldName := FORM.GetFieldName(LPropInfoList.Items[LIndex]^.Name);
      LPropIndex := AJSONObject.IndexOfName(LFieldName);
      if LPropIndex <> -1 then
        FORM.SetPropertyValue(OInstance, LPropInfoList.Items[LIndex]^.Name, FORM.ConvertToPropertyValue(LFieldName, AJSONObject.Items[LPropIndex].Value));
    end;
  finally
    FreeAndNil(LPropInfoList);
  end;
end;

constructor TyaORMToJSONConverter<T>.Create(const AORM: IyaORM<T>);
begin
  FORM := AORM;
end;

function TyaORMToJSONConverter<T>.LoadProperties(const AJSON: TJSONStringType; out OInstance: T): boolean;
var
  LDeStreamer: TJSONDeStreamer;
begin
  OInstance := FORM.New;
  LDeStreamer := TJSONDeStreamer.Create(nil);
  try
    try
      LDeStreamer.JSONToObject(AJSON, OInstance);
    except
      result := false;
    end;
  finally
    FreeAndNil(LDeStreamer);
  end;
end;

function TyaORMToJSONConverter<T>.LoadFields(const AJSON: TJSONStringType; out OInstance: T): boolean;
var
  LJSONData: TJSONData;
begin
  try
    try
      LJSONData := JSONDataFromString(AJSON);
      if LJSONData.JSONType = jtObject then
        DBJSONToObject(LJSONData as TJSONObject, OInstance)
      else
        result := false;
    except
      result := false;
    end;
  finally
    FreeAndNil(LJSONData);
  end;
end;

function TyaORMToJSONConverter<T>.SaveProperties(const AInstance: T): TJSONStringType;
var
  LStreamer: TJSONStreamer;
begin
  if not Assigned(Instancce) then
    raise EyaORMException.Create('TyaORMToJSONConverter<T>.SaveProperties: Instance not assigned.');

  LStreamer := TJSONStreamer.Create(nil);
  try
    LStreamer.Options := LStreamer.Options + [jsoCheckEmptyDateTime, jsoEnumeratedAsInteger, jsoSetAsString];
    result := LStreamer.ObjectToJSONString(AInstance);
  finally
    FreeAndNil(LStreamer);
  end;
end;

end.

