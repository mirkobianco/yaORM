(*
  yet another ORM - for FreePascal
  ORM Containers

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Collections;

{$mode delphi}

interface

uses
  Classes,
  SysUtils;

type
  { TORMCollection<T> }

  TORMCollection<T: TCollectionItem> = class(TCollection)
  private
    function GetItem(const AIndex: Integer): T;
    procedure SetItem(const AIndex: Integer; const AValue: T);
  public
    constructor Create;
    function Add: T; overload;
    property Items[Index: Integer]: T read GetItem write SetItem;

  end;

implementation

{ TCollection }

function TORMCollection<T>.GetItem(const AIndex: Integer): T;
begin
  result := inherited Items[AIndex] as T;
end;

procedure TORMCollection<T>.SetItem(const AIndex: Integer; const AValue: T);
begin
   inherited Items[AIndex] := AValue;
end;

constructor TORMCollection<T>.Create;
begin
  inherited Create(T);
end;

function TORMCollection<T>.Add: T;
begin
  result := inherited Add() as T;
end;

end.

