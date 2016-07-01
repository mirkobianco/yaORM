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

  TConversionFunc = function(const AName: string; const AValue: variant): variant;

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

    class operator Equal(const ACond1, ACond2: TyaFilterCondition): Boolean;
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

function VariantIsEmptyOrNull(const AValue: variant): boolean;
function SameVariantValue(const AValue1, AValue2: variant): boolean;

implementation


function VariantIsEmptyOrNull(const AValue: variant): boolean;
begin
  result := VarIsEmpty(AValue) or VarIsNull(AValue);
end;

function SameVariantValue(const AValue1, AValue2: variant): boolean;
begin
  Result := false;

  if VariantIsEmptyOrNull(AValue1) and
     VariantIsEmptyOrNull(AValue2) then
    Exit(true);

  if (not VariantIsEmptyOrNull(AValue1) or
      not VariantIsEmptyOrNull(AValue2)) and
     (VarType(AValue1) = VarType(AValue2)) and
     (AValue1 = AValue2) then
    Exit(true);
end;

{ TyaFilterCondition }

class operator TyaFilterCondition.Equal(const ACond1, ACond2: TyaFilterCondition): Boolean;
var
  LCond: TyaFilterCondition;
begin
  LCond := ACond1;
  result := LCond.FieldName.Equals(ACond2.FieldName) and
            (ACond1.FilterType = ACond2.FilterType) and
            (ACond1.Value = ACond2.Value);
end;

end.

