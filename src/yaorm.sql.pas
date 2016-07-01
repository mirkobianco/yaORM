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
    constructor Create(const AFactoryFunc: TFactoryFunc;
                       const ATableName: string;
                       const APropertyKeyFields: TStringArray;
                       const ASQLConnection: TSQLConnection;
                       const ASQLTransaction: TSQLTransaction = nil;
                       const AFieldToPropertyMap: TDictionary<string, string> = nil;
                       const AFieldToPropertyConversionFunc: TConversionFunc = nil;
                       const APropertytoFieldConversionFunc: TConversionFunc = nil); reintroduce;
    destructor Destroy; override;

    //IyaORM
    function Load(const AKeyValues: TVariantArray; out OInstance: T): boolean; override;
    function LoadList(const ASQL: string; out OList: TObjectList<T>): boolean; overload; override;
    function LoadList(const AFilter: IyaFilter; out OList: TObjectList<T>): boolean; overload; override;
    function LoadList(const AKeyValues: TVariantArray; out OList: TObjectList<T>): boolean; overload; override;
    procedure Insert(const AInstance: T); override;
    procedure Update(const AInstance: T); override;
    procedure Delete(const AInstance: T); overload; override;
    procedure Delete(const AKeyValues: TVariantArray); overload; override;
    procedure Delete(const AFilter: IyaFilter); overload; override;
  end;

implementation

{ TyaSQLIyaORM }

constructor TyaSQLORM<T>.Create(const AFactoryFunc: TFactoryFunc;
                                const ATableName: string;
                                const APropertyKeyFields: TStringArray;
                                const ASQLConnection: TSQLConnection;
                                const ASQLTransaction: TSQLTransaction;
                                const AFieldToPropertyMap: TDictionary<string, string>;
                                const AFieldToPropertyConversionFunc: TConversionFunc;
                                const APropertytoFieldConversionFunc: TConversionFunc);
begin
  inherited Create(AFactoryFunc, ATableName, APropertyKeyFields, AFieldToPropertyMap, AFieldToPropertyConversionFunc, APropertytoFieldConversionFunc);
  FSQLConnection := ASQLConnection;
  FSQLTransaction := ASQLTransaction;
  FOwnedTransaction := false;
  if not Assigned(FSQLTransaction) then
  begin
    FSQLTransaction := TSQLTransaction.Create(nil);
    FSQLTransaction.SQLConnection := ASQLConnection;
    FOwnedTransaction := true;
  end;
end;

destructor TyaSQLORM<T>.Destroy;
begin
  if FOwnedTransaction then
    FreeAndNil(FSQLTransaction);
  inherited Destroy;
end;

function TyaSQLORM<T>.Load(const AKeyValues: TVariantArray; out OInstance: T): boolean;
var
  LQuery: TSQLQuery;
begin
  inherited;
  result := false;
  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      OInstance := New;

      CreateSelectSQL(OInstance, LQuery.SQL);
      AddKeyValuesConditions(AKeyValues, LQuery.SQL, LQuery.Params);
      LQuery.Open;

      result := not LQuery.IsEmpty;
      if not result then
        Exit;

      CopyFieldsToInstance(LQuery.Fields, OInstance);
    except
      on E: Exception do
      begin
        FreeAndNil(OInstance);
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

function TyaSQLORM<T>.LoadList(const ASQL: string; out OList: TObjectList<T>): boolean;
var
  LQuery: TSQLQuery;
begin
  result := false;
  OList := nil;
  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      LQuery.SQL.Add(ASQL);
      LQuery.Open;

      result := not LQuery.IsEmpty;
      if not result then
        Exit;

      GetObjects(LQuery, OList);
    except
      on E: Exception do
      begin
        FreeAndNil(OList);
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

function TyaSQLORM<T>.LoadList(const AFilter: IyaFilter; out OList: TObjectList<T>): boolean;
var
  LQuery: TSQLQuery;
  LInstance: T;
begin
  result := false;
  OList := nil;
  LQuery := TSQLQuery.Create(nil);
  LInstance := New;
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      CreateSelectSQL(LInstance, LQuery.SQL);
      AddFilterConditions(AFilter, LQuery.SQL, LQuery.Params);
      LQuery.Open;

      result := not LQuery.IsEmpty;
      if not result then
        Exit;

      GetObjects(LQuery, OList);
    except
      on E: Exception do
      begin
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
    FreeAndNil(LInstance);
  end;
end;

function TyaSQLORM<T>.LoadList(const AKeyValues: TVariantArray; out OList: TObjectList<T>): boolean;
var
  LQuery: TSQLQuery;
  LInstance: T;
begin
  result := false;
  OList := nil;
  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      LInstance := New;

      CreateSelectSQL(LInstance, LQuery.SQL);
      AddKeyValuesConditions(AKeyValues, LQuery.SQL, LQuery.Params);
      LQuery.Open;

      result := not LQuery.IsEmpty;
      if not result then
        Exit;

      GetObjects(LQuery, OList);
    except
      on E: Exception do
      begin
        FreeAndNil(OList);
        FreeAndNil(LInstance);
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Load: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

procedure TyaSQLORM<T>.Insert(const AInstance: T);
var
  LQuery: TSQLQuery;
  LManageTransactions: boolean;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaSQLORM<T>.Insert: Instance not assigned.');

  LManageTransactions := not FSQLTransaction.Active;

  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      if LManageTransactions then
        FSQLTransaction.StartTransaction;;

      CreateInsertSQL(AInstance, LQuery.SQL);
      CopyInstanceToParams(AInstance, LQuery.Params);
      LQuery.ExecSQL;

      if LManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if LManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Insert: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

procedure TyaSQLORM<T>.Update(const AInstance: T);
var
  LQuery: TSQLQuery;
  LManageTransactions: boolean;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaSQLORM<T>.Update: Instance not assigned.');

  LManageTransactions := not FSQLTransaction.Active;

  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      if LManageTransactions then
        FSQLTransaction.StartTransaction;;

      CreateUpdateSQL(AInstance, LQuery.SQL);
      CopyInstanceToParams(AInstance, LQuery.Params);

      LQuery.ExecSQL;

      if LManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if LManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Update: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

procedure TyaSQLORM<T>.Delete(const AInstance: T);
var
  LQuery: TSQLQuery;
  LManageTransactions: boolean;
  LKeyValues: TVariantArray;
begin
  if not Assigned(AInstance) then
    raise EyaORMException.Create('TyaSQLORM<T>.Delete: Instance not assigned.');

  LManageTransactions := not FSQLTransaction.Active;

  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      if LManageTransactions then
        FSQLTransaction.StartTransaction;

      LKeyValues := GetKeyValues(AInstance);
      CreateDeleteSQL(LQuery.SQL);
      AddKeyValuesConditions(LKeyValues, LQuery.SQL, LQuery.Params);
      LQuery.ExecSQL;

      if LManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if LManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Delete: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

procedure TyaSQLORM<T>.Delete(const AKeyValues: TVariantArray);
var
  LManageTransactions: boolean;
  LQuery: TSQLQuery;
begin
  inherited;
  LManageTransactions := not FSQLTransaction.Active;

  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      if LManageTransactions then
        FSQLTransaction.StartTransaction;

      CreateDeleteSQL(LQuery.SQL);
      AddKeyValuesConditions(AKeyValues, LQuery.SQL, LQuery.Params);
      LQuery.ExecSQL;

      if LManageTransactions then
        FSQLTransaction.Commit;

    except
      on E: Exception do
      begin
        if LManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Delete: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

procedure TyaSQLORM<T>.Delete(const AFilter: IyaFilter);
var
  LQuery: TSQLQuery;
  LManageTransactions: boolean;
begin
  LManageTransactions := not FSQLTransaction.Active;

  LQuery := TSQLQuery.Create(nil);
  try
    LQuery.SQLConnection := FSQLConnection;
    LQuery.Transaction := FSQLTransaction;
    try
      if LManageTransactions then
        FSQLTransaction.StartTransaction;

      CreateDeleteSQL(LQuery.SQL);
      AddFilterConditions(AFilter, LQuery.SQL, LQuery.Params);
      LQuery.ExecSQL;

      if LManageTransactions then
        FSQLTransaction.Commit;
    except
      on E: Exception do
      begin
        if LManageTransactions then
          FSQLTransaction.Rollback;
        raise EyaORMException.CreateFmt('TyaSQLORM<T>.Delete: %s', [E.Message]);
      end;
    end;
  finally
    FreeAndNil(LQuery);
  end;
end;

end.

