program yaORMExample1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes,
  SysUtils,
  CustApp
  { you can add units after this },
  yaORM,
  yaORM.Types,
  Example.Address,
  Example.Customer,
  Example.ORM;

type

  { TyaORMExample }

  TyaORMExample = class(TCustomApplication)
  strict private
    procedure CreateDatabase;
    procedure Example;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TyaORMExample }

procedure TyaORMExample.CreateDatabase;
var
  SQL: string;
begin
  ORMS.Connection.Open;

  SQL := 'CREATE TABLE CUSTOMER(' + #13#10 +
         'CustomerId INTEGER PRIMARY KEY,' + #13#10 +
         'AddressId INTEGER,' + #13#10 +
         'Name TEXT,' + #13#10 +
         'Notes TEXT)';

  ORMS.Connection.ExecuteDirect(SQL);

  SQL := 'CREATE TABLE ADDRESS(' + #13#10 +
         'AddressId INTEGER PRIMARY KEY,' + #13#10 +
         'Description TEXT)';

  ORMS.Connection.ExecuteDirect(SQL);
end;

procedure TyaORMExample.Example;
var
  Customer: TCustomer;
  Customers: TCustomers;
  Address: TAddress;
  Filter: IyaFilter;
begin
  Customer := ORMS.CustomerORM.New;
  Address := ORMS.AddressORM.New;

  try
    Customer.CustomerId := 1;
    Customer.Name := 'Mirko Bianco';

    Address.AddressId := 1;
    Address.Description := 'Mirko Bianco''s Address';
    ORMS.AddressORM.Insert(Address);
    Customer.Address := Address; //Address is assigned to the Customer, please check TyaOneToOneRelationship for objects ownership
    if Assigned(Customer.Address) then
      Writeln(Customer.Address.Description);

    ORMS.CustomerORM.Insert(Customer);
  finally
    FreeAndNil(Customer);
    //Customer takes care of the Address
  end;

  Customer := ORMS.CustomerORM.New;
  try
    Customer.CustomerId := 2;
    Customer.Name := 'Someone Else';
    Customer.AddressId := 1;
    if Assigned(Customer.Address) then
        Writeln(Customer.Address.Description);
    ORMS.CustomerORM.Insert(Customer);
  finally
    FreeAndNil(Customer);
  end;

  Customer := ORMS.CustomerORM.New;
  try
    Customer.CustomerId := 3;
    Customer.Name := 'Another Bianco';
    Customer.Notes := 'Test';
    ORMS.CustomerORM.Insert(Customer);
  finally
    FreeAndNil(Customer);
  end;

  if ORMS.CustomerORM.LoadList('SELECT * FROM CUSTOMER', Customers) then
    Writeln(IntToStr(Customers.Count))
  else
    Writeln('Not Found');
  FreeAndNil(Customers);

  Filter := ORMS.CustomerORM.NewFilter;
  Filter.AddCondition('Name', ftEndsWith, 'Bianco');
  if ORMS.CustomerORM.LoadList(Filter, Customers) then
    Writeln(IntToStr(Customers.Count))
  else
    Writeln('Not Found');
  FreeAndNil(Customers);
end;

procedure TyaORMExample.DoRun;
begin
  { add your program here }
  Example;

  // stop program loop
  Terminate;
end;

constructor TyaORMExample.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
  CreateDatabase;
end;

destructor TyaORMExample.Destroy;
begin
  inherited Destroy;
end;

procedure TyaORMExample.WriteHelp;
begin
  { add your help code here }
  writeln('No help available here...');
end;

var
  Application: TyaORMExample;
begin
  Application:=TyaORMExample.Create(nil);
  Application.Title:='ya ORM Example';
  Application.Run;
  Application.Free;
end.

