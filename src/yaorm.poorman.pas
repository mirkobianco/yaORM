(*
  yet another ORM - for FreePascal and Delphi
  Poor man (TDataset support only) ORM classes

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.PoorMan;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  yaORM,
  yaORM.Types;

type
  { TyaPoorManORM }

  TyaPoorManORM<T: TObject> = class(TyaAbstractORM<T>)
  public
    //IyaORM
    function Load(const KeyValues: TVariantArray; out Instance: T): boolean; override;
    function LoadList(const SQL: string; out List: TObjectList<T>): boolean; overload; override;
    function LoadList(const Filter: IyaFilter; out List: TObjectList<T>): boolean; overload; override;
    function LoadList(const KeyValues: TVariantArray; out List: TObjectList<T>): boolean; overload; override;
    procedure Insert(const Instance: T); override;
    procedure Update(const Instance: T); override;
    procedure Delete(const Instance: T); overload; override;
    procedure Delete(const KeyValues: TVariantArray); overload; override;
    procedure Delete(const Filter: IyaFilter); overload; override;
  end;

implementation

{ TyaPoorManORM }

function TyaPoorManORM<T>.Load(const KeyValues: TVariantArray; out Instance: T): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Load: Operation non supported.');
end;

function TyaPoorManORM<T>.LoadList(const SQL: string; out List: TObjectList<T>): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.LoadList: Operation non supported.');
end;

function TyaPoorManORM<T>.LoadList(const Filter: IyaFilter; out List: TObjectList<T>): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.LoadList: Operation non supported.');
end;

function TyaPoorManORM<T>.LoadList(const KeyValues: TVariantArray; out List: TObjectList<T>): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.LoadList: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Insert(const Instance: T);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Insert: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Update(const Instance: T);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Update: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Delete(const Instance: T);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Delete: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Delete(const KeyValues: TVariantArray);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Delete: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Delete(const Filter: IyaFilter);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Delete: Operation non supported.');
end;

end.

