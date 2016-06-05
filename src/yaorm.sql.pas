(*
  yet another ORM - for FreePascal and Delphi
  SQL (sqldb) based ORM class

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.SQL;
{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  DB,
  sqldb,
  yaORM.Types,
  yaORM;

type
  { TyaSQLORM }

  TyaSQLORM<T: TObject> = class(TyaAbstractORM<T>)
  strict protected
    FSQLConnection: TSQLConnection;
    FSQLTransaction: TSQLTransaction;
    FOwnedTransaction: boolean;
  public
    constructor Create(const FactoryFunc: TFactoryFunc;
                       const TableName: string;
                       const PropertyKeyFields: TStringArray;
                       const SQLConnection: TSQLConnection;
                       const SQLTransaction: TSQLTransaction = nil;
                       const FieldToPropertyMap: TDictionary<string, string> = nil;
                       const FieldToPropertyConversionFunc: TConversionFunc = nil;
                       const PropertytoFieldConversionFunc: TConversionFunc = nil); reintroduce;
    destructor Destroy; override;

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

{ TyaSQLIyaORM }

constructor TyaSQLORM<T>.Create(const FactoryFunc: TFactoryFunc;
                                const TableName: string;
                                const PropertyKeyFields: TStringArray;
                                const SQLConnection: TSQLConnection;
                                const SQLTransaction: TSQLTransaction;
                                const FieldToPropertyMap: TDictionary<string, string>;
                                const FieldToPropertyConversionFunc: TConversionFunc;
                                const PropertytoFieldConversionFunc: TConversionFunc);
begin
  inherited Create(FactoryFunc, TableName, PropertyKeyFields, FieldToPropertyMap, FieldToPropertyConversionFunc, PropertytoFieldConversionFunc);
  FSQLConnection := SQLConnection;
  FSQLTransaction := SQLTransaction;
  FOwnedTransaction := false;
  if not Assigned(FSQLTransaction) then
  begin
    FSQLTransaction := TSQLTransaction.Create(nil);
    FSQLTransaction.SQLConnection := SQLConnection;
    FOwnedTransaction := true;
  end;
end;

destructor TyaSQLORM<T>.Destroy;
begin
  if FOwnedTransaction then
    FreeAndNil(FSQLTransaction);
  inherited Destroy;
end;

function TyaSQLORM<T>.Load(const KeyValues: TVariantArray; out Instance: T): boolean;
var
  Query: TSQLQuery;
begin
  inherited;
  result := false;
  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      Instance := New;

      CreateSelectSQL(Instance, Query.SQL);
      AddKeyValuesConditions(KeyValues, Query.SQL, Query.Params);
      Query.Open;

      result := not Query.IsEmpty;
      if not result then
        Exit;

      CopyFieldsToInstance(Query.Fields, Instance);
    except
      on E: Exception do
      begin
        FreeAndNil(Instance);
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

function TyaSQLORM<T>.LoadList(const SQL: string; out List: TObjectList<T>): boolean;
var
  Query: TSQLQuery;
begin
  result := false;
  List := nil;
  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      Query.SQL.Add(SQL);
      Query.Open;

      result := not Query.IsEmpty;
      if not result then
        Exit;

      GetObjects(Query, List);
    except
      on E: Exception do
      begin
        FreeAndNil(List);
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

function TyaSQLORM<T>.LoadList(const Filter: IyaFilter; out List: TObjectList<T>): boolean;
var
  Query: TSQLQuery;
  Instance: T;
begin
  result := false;
  List := nil;
  Query := TSQLQuery.Create(nil);
  Instance := New;
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      CreateSelectSQL(Instance, Query.SQL);
      AddFilterConditions(Filter, Query.SQL, Query.Params);
      Query.Open;

      result := not Query.IsEmpty;
      if not result then
        Exit;

      GetObjects(Query, List);
    except
      on E: Exception do
      begin
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
    FreeAndNil(Instance);
  end;
end;

function TyaSQLORM<T>.LoadList(const KeyValues: TVariantArray; out List: TObjectList<T>): boolean;
var
  Query: TSQLQuery;
  Instance: T;
begin
  result := false;
  List := nil;
  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      Instance := New;

      CreateSelectSQL(Instance, Query.SQL);
      AddKeyValuesConditions(KeyValues, Query.SQL, Query.Params);
      Query.Open;

      result := not Query.IsEmpty;
      if not result then
        Exit;

      GetObjects(Query, List);
    except
      on E: Exception do
      begin
        FreeAndNil(List);
        FreeAndNil(Instance);
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TyaSQLORM<T>.Insert(const Instance: T);
var
  Query: TSQLQuery;
  ManageTransactions: boolean;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaSQLORM<T>.Insert: Instance not assigned.');

  ManageTransactions := not FSQLTransaction.Active;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      if ManageTransactions then
        FSQLTransaction.StartTransaction;;

      CreateInsertSQL(Instance, Query.SQL);
      CopyInstanceToParams(Instance, Query.Params);
      Query.ExecSQL;

      if ManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if ManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Insert: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TyaSQLORM<T>.Update(const Instance: T);
var
  Query: TSQLQuery;
  ManageTransactions: boolean;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaSQLORM<T>.Update: Instance not assigned.');

  ManageTransactions := not FSQLTransaction.Active;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      if ManageTransactions then
        FSQLTransaction.StartTransaction;;

      CreateUpdateSQL(Instance, Query.SQL);
      CopyInstanceToParams(Instance, Query.Params);

      Query.ExecSQL;

      if ManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if ManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Update: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TyaSQLORM<T>.Delete(const Instance: T);
var
  Query: TSQLQuery;
  ManageTransactions: boolean;
  KeyValues: TVariantArray;
begin
  if not Assigned(Instance) then
    raise EyaORMException.Create('TyaSQLORM<T>.Delete: Instance not assigned.');

  ManageTransactions := not FSQLTransaction.Active;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      if ManageTransactions then
        FSQLTransaction.StartTransaction;

      KeyValues := GetKeyValues(Instance);
      CreateDeleteSQL(Query.SQL);
      AddKeyValuesConditions(KeyValues, Query.SQL, Query.Params);
      Query.ExecSQL;

      if ManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if ManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Delete: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TyaSQLORM<T>.Delete(const KeyValues: TVariantArray);
var
  ManageTransactions: boolean;
  Query: TSQLQuery;
begin
  inherited;
  ManageTransactions := not FSQLTransaction.Active;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      if ManageTransactions then
        FSQLTransaction.StartTransaction;

      CreateDeleteSQL(Query.SQL);
      AddKeyValuesConditions(KeyValues, Query.SQL, Query.Params);
      Query.ExecSQL;

      if ManageTransactions then
        FSQLTransaction.Commit;

    except
      on E: Exception do
      begin
        if ManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Delete: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TyaSQLORM<T>.Delete(const Filter: IyaFilter);
var
  Query: TSQLQuery;
  ManageTransactions: boolean;
begin
  ManageTransactions := not FSQLTransaction.Active;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FSQLConnection;
    Query.Transaction := FSQLTransaction;
    try
      if ManageTransactions then
        FSQLTransaction.StartTransaction;

      CreateDeleteSQL(Query.SQL);
      AddFilterConditions(Filter, Query.SQL, Query.Params);
      Query.ExecSQL;

      if ManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if ManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Delete: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

end.

