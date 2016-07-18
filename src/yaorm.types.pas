(*
  yet another ORM - for FreePascal
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
  Variants,
  TypInfo,
  PropEdits;

type
{$IFDEF FPC}
  TList<T> = class(TFPGList<T>);
  TDictionary<K, V> = class(TFPGMap<K, V>);
  TObjectDictionary<K, V> = class(TFPGMapObject<K, V>);
{$ENDIF}

  EyaORMException = class(Exception);

  TORMStringArray = array of string;
  TORMVariantArray = array of variant;

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

//TNullableStringPropertyEditor
//The default property editor for all strings and sub types (e.g. string,
//string[20], etc.).

  TVariantPropertyEditor = class(TPropertyEditor)
  public
    function AllEqual: Boolean; override;
    function GetEditLimit: Integer; override;
    function GetValue: ansistring; override;
    procedure SetValue(const NewValue: ansistring); override;
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

{ TVariantPropertyEditor }

function TVariantPropertyEditor.AllEqual: Boolean;
var
  I: Integer;
  V: Variant;
begin
  Result := false;
  if PropCount > 1 then
  begin
    V := GetVarValue;
    for I := 1 to PropCount - 1 do
      if GetVarValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TVariantPropertyEditor.GetEditLimit: Integer;
begin
  if GetPropType^.Kind = tkVariant then
    Result := GetTypeData(GetPropType)^.MaxLength
  else
    Result := $0FFF;
end;

function TVariantPropertyEditor.GetValue: ansistring;
begin
  Result := GetVarValue;
end;

procedure TVariantPropertyEditor.SetValue(const NewValue: ansistring);
begin
  SetVarValue(NewValue);
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

procedure RegisterPropertyEditors;
begin
  RegisterPropertyEditor(TypeInfo(Variant), nil, '', TVariantPropertyEditor);
end;

initialization

  RegisterPropertyEditors;

finalization

end.

