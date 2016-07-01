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
  LSQL: string;
begin
  ORMS.Connection.Open;

  LSQL := 'CREATE TABLE CUSTOMER(' + #13#10 +
         'CustomerId INTEGER PRIMARY KEY,' + #13#10 +
         'AddressId INTEGER,' + #13#10 +
         'Name TEXT,' + #13#10 +
         'Notes TEXT)';

  ORMS.Connection.ExecuteDirect(LSQL);

  LSQL := 'CREATE TABLE ADDRESS(' + #13#10 +
         'AddressId INTEGER PRIMARY KEY,' + #13#10 +
         'Description TEXT)';

  ORMS.Connection.ExecuteDirect(LSQL);
end;

procedure TyaORMExample.Example;
var
  LCustomer: TCustomer;
  LCustomers: TCustomers;
  LAddress: TAddress;
  LFilter: IyaFilter;
begin
  LCustomer := ORMS.CustomerORM.New;
  LAddress := ORMS.AddressORM.New;

  try
    LCustomer.CustomerId := 1;
    LCustomer.Name := 'Mirko Bianco';

    LAddress.AddressId := 1;
    LAddress.Description := 'Mirko Bianco''s Address';
    ORMS.AddressORM.Insert(LAddress);
    LCustomer.Address := LAddress; //LAddress is assigned to the LCustomer, please check TyaOneToOneRelationship for objects ownership
    if Assigned(LCustomer.Address) then
      Writeln(LCustomer.Address.Description);

    ORMS.CustomerORM.Insert(LCustomer);
  finally
    FreeAndNil(LCustomer);
    //LCustomer takes care of the LAddress
  end;

  LCustomer := ORMS.CustomerORM.New;
  try
    LCustomer.CustomerId := 2;
    LCustomer.Name := 'Someone Else';
    LCustomer.AddressId := 1;
    if Assigned(LCustomer.Address) then
        Writeln(LCustomer.Address.Description);
    ORMS.CustomerORM.Insert(LCustomer);
  finally
    FreeAndNil(LCustomer);
  end;

  LCustomer := ORMS.CustomerORM.New;
  try
    LCustomer.CustomerId := 3;
    LCustomer.Name := 'Another Bianco';
    LCustomer.Notes := 'Test';
    ORMS.CustomerORM.Insert(LCustomer);
  finally
    FreeAndNil(LCustomer);
  end;

  if ORMS.CustomerORM.LoadList('SELECT * FROM CUSTOMER', LCustomers) then
    Writeln(IntToStr(LCustomers.Count))
  else
    Writeln('Not Found');
  FreeAndNil(LCustomers);

  LFilter := ORMS.CustomerORM.NewFilter;
  LFilter.AddCondition('Name', ftEndsWith, 'Bianco');
  if ORMS.CustomerORM.LoadList(LFilter, LCustomers) then
    Writeln(IntToStr(LCustomers.Count))
  else
    Writeln('Not Found');
  FreeAndNil(LCustomers);
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

