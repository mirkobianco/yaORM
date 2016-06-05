unit DEMO.ORM;

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
  DEMO.BusinessLogic;

type

  { TORMS }

  TORMS = class
  strict private
    FSQLConnection: TSQLite3Connection;
    FSQLTransaction: TSQLTransaction;

    FCustomerORM: ICustomerORM;
    FAddressORM: IAddressORM;

    function GetNewCustomer: TCustomer;
    Function GetNewAddress: TAddress;
  public
    constructor Create;
    destructor Destroy; override;

    property Connection: TSQLite3Connection read FSQLConnection;
    property Transaction: TSQLTransaction read FSQLTransaction;

    property CustomerORM: ICustomerORM read FCustomerORM;
    property AddressORM: IAddressORM read FAddressORM;
  end;

var
  ORMS: TORMS;

implementation

{ TORMS }

constructor TORMS.Create;
begin
  inherited;

  FSQLTransaction := TSQLTransaction.Create(nil);

  FSQLConnection := TSQLite3Connection.Create(nil);
  FSQLConnection.DatabaseName := ':MEMORY:';
  FSQLConnection.Transaction := FSQLTransaction;

  FCustomerORM := TyaSQLORM<TCustomer>.Create(GetNewCustomer,
                                              'CUSTOMER',
                                              TStringArray.Create('CustomerId'),
                                              FSQLConnection,
                                              FSQLTransaction);

  FAddressORM := TyaSQLORM<TAddress>.Create(GetNewAddress,
                                            'ADDRESS',
                                            TStringArray.Create('AddressId'),
                                            FSQLConnection,
                                            FSQLTransaction);
end;

destructor TORMS.Destroy;
begin
  FreeAndNil(FSQLConnection);
  FreeAndNil(FSQLTransaction);
  inherited Destroy;
end;

function TORMS.GetNewCustomer: TCustomer;
begin
  result := TCustomer.Create(FCustomerORM, FAddressORM);
end;

function TORMS.GetNewAddress: TAddress;
begin
  result := TAddress.Create;
end;

initialization

ORMS := TORMS.Create;

finalization

FreeAndNil(ORMS);

end.

