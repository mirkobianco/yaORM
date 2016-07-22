unit Example.ORM;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  sqldb,
  sqlite3conn,
  yaORM,
  yaORM.SQL,
  yaORM.JSON,
  Example.Address,
  Example.Customer;

type

  { TORMS }

  TORMS = class
  strict private
    FSQLConnection: TSQLite3Connection;
    FSQLTransaction: TSQLTransaction;

    FCustomerORM: ICustomerORM;
    FAddressORM: IAddressORM;

    FCustomerJSON: IyaORMToJSONConverter<TCustomer>;
    FAddressJSON: IyaORMToJSONConverter<TAddress>;

    function GetNewCustomer: TCustomer;
    function GetNewAddress: TAddress;

    function GetCustomerORM: ICustomerORM;
    Function GetAddressORM: IAddressORM;

    function GetCustomerJSON: IyaORMToJSONConverter<TCustomer>;
    Function GetAddressJSON: IyaORMToJSONConverter<TAddress>;
  public
    constructor Create;
    destructor Destroy; override;

    property Connection: TSQLite3Connection read FSQLConnection;
    property Transaction: TSQLTransaction read FSQLTransaction;

    property CustomerORM: ICustomerORM read GetCustomerORM;
    property AddressORM: IAddressORM read GetAddressORM;

    property CustomerJSON: IyaORMToJSONConverter<TCustomer> read GetCustomerJSON;
    property AddressJSON: IyaORMToJSONConverter<TAddress> read GetAddressJSON;
  end;

var
  ORMS: TORMS;

implementation

{ TORMS }

function TORMS.GetNewCustomer: TCustomer;
begin
  result := TCustomer.Create(CustomerORM, AddressORM);
end;

function TORMS.GetNewAddress: TAddress;
begin
  result := TAddress.Create;
end;

constructor TORMS.Create;
begin
  inherited;

  FSQLTransaction := TSQLTransaction.Create(nil);

  FSQLConnection := TSQLite3Connection.Create(nil);
  FSQLConnection.DatabaseName := ':MEMORY:';
  FSQLConnection.Transaction := FSQLTransaction;
end;

destructor TORMS.Destroy;
begin
  FreeAndNil(FSQLConnection);
  FreeAndNil(FSQLTransaction);

  inherited Destroy;
end;

function TORMS.GetCustomerORM: ICustomerORM;
begin
  if not Assigned(FCustomerORM) then
    FCustomerORM := TyaSQLORM<TCustomer>.Create(GetNewCustomer,
                                                'CUSTOMER',
                                                TStringArray.Create('CustomerId'),
                                                FSQLConnection,
                                                FSQLTransaction);
  result := FCustomerORM;
end;

function TORMS.GetAddressORM: IAddressORM;
var
  LArray: TStringArray;
begin
  if not Assigned(FAddressORM) then
  begin
    LArray := TStringArray.Create('AddressId');
    FAddressORM := TyaSQLORM<TAddress>.Create(GetNewAddress,
                                              'ADDRESS',
                                              LArray,
                                              FSQLConnection,
                                              FSQLTransaction);
  end;
  result := FAddressORM;
end;

function TORMS.GetCustomerJSON: IyaORMToJSONConverter<TCustomer>;
begin
  if not Assigned(FCustomerJSON) then
    FCustomerJSON := TyaORMToJSONConverter<TCustomer>.Create(GetCustomerORM);
  result := FCustomerJSON;
end;

function TORMS.GetAddressJSON: IyaORMToJSONConverter<TAddress>;
begin
  if not Assigned(FAddressJSON) then
    FAddressJSON := TyaORMToJSONConverter<TAddress>.Create(GetAddressORM);
  result := FAddressJSON;
end;

initialization

ORMS := TORMS.Create;

finalization

FreeAndNil(ORMS);

end.

