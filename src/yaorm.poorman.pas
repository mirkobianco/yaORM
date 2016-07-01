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
    function Load(const AKeyValues: TVariantArray; out OInstance: T): boolean; override;
    function LoadList(const ASQL: string; out OList: TObjectList<T>): boolean; overload; override;
    function LoadList(const AFilter: IyaFilter; out LList: TObjectList<T>): boolean; overload; override;
    function LoadList(const AKeyValues: TVariantArray; out OList: TObjectList<T>): boolean; overload; override;
    procedure Insert(const AInstance: T); override;
    procedure Update(const AInstance: T); override;
    procedure Delete(const AInstance: T); overload; override;
    procedure Delete(const AKeyValues: TVariantArray); overload; override;
    procedure Delete(const AFilter: IyaFilter); overload; override;
  end;

implementation

{ TyaPoorManORM }

function TyaPoorManORM<T>.Load(const AKeyValues: TVariantArray; out OInstance: T): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Load: Operation non supported.');
end;

function TyaPoorManORM<T>.LoadList(const ASQL: string; out OList: TObjectList<T>): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.LoadList: Operation non supported.');
end;

function TyaPoorManORM<T>.LoadList(const AFilter: IyaFilter; out OList: TObjectList<T>): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.LoadList: Operation non supported.');
end;

function TyaPoorManORM<T>.LoadList(const AKeyValues: TVariantArray; out OList: TObjectList<T>): boolean;
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.LoadList: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Insert(const AInstance: T);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Insert: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Update(const AInstance: T);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Update: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Delete(const AInstance: T);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Delete: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Delete(const AKeyValues: TVariantArray);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Delete: Operation non supported.');
end;

procedure TyaPoorManORM<T>.Delete(const AFilter: IyaFilter);
begin
  raise EyaORMException.Create('TyaPoorManORM<T>.Delete: Operation non supported.');
end;

end.

