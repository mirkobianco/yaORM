(*
  yet another ORM - for FreePascal
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
  { IyaORMToJSONConverter }

  IyaORMToJSONConverter<T: TPersistent> = interface(IInterface)
    ['{42E56C93-8547-E611-9DEE-080027BF4002}']
    function LoadProperties(const AJSON: TJSONStringType; out OInstance: T): boolean;
    function SaveProperties(const AInstance: T): TJSONStringType;
  end;

  { TyaORMToJSONConverter }

  TyaORMToJSONConverter<T: TPersistent> = class(TInterfacedObject, IyaORMToJSONConverter<T>)
  strict private
  var
    FORM: IyaORM<T>;
  public
    constructor Create(const AORM: IyaORM<T>); reintroduce;
    //IyaORMToJSONConverter<T>
    function LoadProperties(const AJSON: TJSONStringType; out OInstance: T): boolean;
    function SaveProperties(const AInstance: T): TJSONStringType;
  end;

implementation

{ TyaORMToJSONConverter }
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

function TyaORMToJSONConverter<T>.SaveProperties(const AInstance: T): TJSONStringType;
var
  LStreamer: TJSONStreamer;
begin
  if not Assigned(AInstance) then
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

