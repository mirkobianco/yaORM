(*
  yet another ORM - for FreePascal and Delphi
  ORM types

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Types;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
{$IFDEF FPC}
  fgl,
{$ENDIF}
  Variants;

type
{$IFDEF FPC}
  TObjectList<T> = class(TFPGObjectList<T>);
  TList<T> = class(TFPGList<T>);
  TDictionary<K, V> = class(TFPGMap<K, V>);
{$ENDIF}

  EyaORMException = class(Exception);

  TStringArray = array of string;
  TVariantArray = array of variant;

  TConversionFunc = function(const Name: string; const Value: variant): variant;

  TNullableString = variant;
  TNullableInteger = variant;
  TNullableDouble = variant;
  TNullableDateTime = variant;

  TFilterType = (ftEqual,
                 ftUnequal,
                 ftLessThan,
                 ftLessThanOrEqual,
                 ftMoreThan,
                 ftMoreThanOrEqual,
                 ftIsNull,
                 ftIsNotNull,
                 ftContains,
                 ftStartsWith,
                 ftEndsWith,
                 ftAnd,
                 ftOr,
                 ftNot,
                 ftOpenedBracket,
                 ftClosedBracket);

  TyaFilterCondition = record
    FieldName: string;
    FilterType: TFilterType;
    Value: variant;

    class operator Equal(const Cond1, Cond2: TyaFilterCondition): Boolean;
  end;

const
  FilterStrings: array[TFilterType] of string = ('%s = :%s',
                                                 '%s <> :%s',
                                                 '%s < :%s',
                                                 '%s <= :%s',
                                                 '%s > :%s',
                                                 '%s >= :%s',
                                                 '%s IS NULL',
                                                 '%s IS NOT NULL',
                                                 '%s LIKE ''%%%s%%''',
                                                 '%s LIKE ''%s%%''',
                                                 '%s LIKE ''%%%s''',
                                                 ' AND ',
                                                 ' OR ',
                                                 ' NOT ',
                                                 ' ( ',
                                                 ' ) ');

function VariantIsEmptyOrNull(const Value: variant): boolean;
function SameVariantValue(const Value1, Value2: variant): boolean;

implementation


function VariantIsEmptyOrNull(const Value: variant): boolean;
begin
  result := VarIsEmpty(Value) or VarIsNull(Value);
end;

function SameVariantValue(const Value1, Value2: variant): boolean;
begin
  Result := false;

  if VariantIsEmptyOrNull(Value1) and
     VariantIsEmptyOrNull(Value2) then
    Exit(true);

  if (not VariantIsEmptyOrNull(Value1) or
      not VariantIsEmptyOrNull(Value2)) and
     (VarType(Value1) = VarType(Value2)) and
     (Value1 = Value2) then
    Exit(true);
end;

{ TyaFilterCondition }

class operator TyaFilterCondition.Equal(const Cond1, Cond2: TyaFilterCondition): Boolean;
var
  LCond: TyaFilterCondition;
begin
  LCond := Cond1;
  result := LCond.FieldName.Equals(Cond2.FieldName) and
            (Cond1.FilterType = Cond2.FilterType) and
            (Cond1.Value = Cond2.Value);
end;

end.

