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

    function JSONDataFromString(const JSON: TJSONStringType): TJSONData;
    procedure DBJSONToObject(const JSONObject: TJSONObject; out Instance: T);
  public
    constructor Create(const ORM: IyaORM<T>); reintroduce;

    function LoadFields(const JSON: TJSONStringType; out Instance: T): boolean;
    function LoadProperties(const JSON: TJSONStringType; out Instance: T): boolean;
    function SaveProperties(const Instance: T): TJSONStringType;
  end;

implementation

{ yaORMJSON }

function TyaORMToJSONConverter<T>.JSONDataFromString(const JSON: TJSONStringType): TJSONData;
begin
  with TJSONParser.Create(JSON, [joUTF8,joStrict,joComments,joIgnoreTrailingComma]) do
    try
      result := Parse;
    finally
      Free;
    end;
end;

procedure TyaORMToJSONConverter<T>.DBJSONToObject(const JSONObject: TJSONObject; out Instance: T);
Var
  Index,
  PropIndex: Integer;
  PropInfoList: TPropInfoList;
  FieldName: string;
begin
  Instance := FORM.New;
  PropInfoList := TPropInfoList.Create(Instance, tkProperties);
  try
    for Index := 0 to PropInfoList.Count - 1 do
    begin
      FieldName := FORM.GetFieldName(PropInfoList.Items[Index]^.Name);
      PropIndex := JSONObject.IndexOfName(FieldName);
      if PropIndex <> -1 then
        FORM.SetPropertyValue(Instance, PropInfoList.Items[Index]^.Name, FORM.ConvertToPropertyValue(FieldName, JSONObject.Items[PropIndex].Value));
    end;
  finally
    FreeAndNil(PropInfoList);
  end;
end;

constructor TyaORMToJSONConverter<T>.Create(const ORM: IyaORM<T>);
begin
  FORM := ORM;
end;

function TyaORMToJSONConverter<T>.LoadProperties(const JSON: TJSONStringType; out Instance: T): boolean;
var
  DeStreamer: TJSONDeStreamer;
begin
  Instance := FORM.New;
  DeStreamer := TJSONDeStreamer.Create(nil);
  try
    try
      DeStreamer.JSONToObject(JSON, Instance);
    except
      result := false;
    end;
  finally
    FreeAndNil(DeStreamer);
  end;
end;

function TyaORMToJSONConverter<T>.LoadFields(const JSON: TJSONStringType; out Instance: T): boolean;
var
  JSONData: TJSONData;
begin
  try
    try
      JSONData := JSONDataFromString(JSON);
      if JSONData.JSONType = jtObject then
        DBJSONToObject(JSONData as TJSONObject, Instance)
      else
        result := false;
    except
      result := false;
    end;
  finally
    FreeAndNil(JSONData);
  end;
end;

function TyaORMToJSONConverter<T>.SaveProperties(const Instance: T): TJSONStringType;
var
  Streamer: TJSONStreamer;
begin
  if not Assigned(Instancce) then
    raise EyaORMException.Create('TyaORMToJSONConverter<T>.SaveProperties: Instance not assigned.');

  Streamer := TJSONStreamer.Create(nil);
  try
    Streamer.Options := Streamer.Options + [jsoCheckEmptyDateTime, jsoEnumeratedAsInteger, jsoSetAsString];
    result := Streamer.ObjectToJSONString(Instance);
  finally
    FreeAndNil(Streamer);
  end;
end;

end.

