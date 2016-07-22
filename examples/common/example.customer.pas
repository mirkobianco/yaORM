unit Example.Customer;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  Variants,
  yaORM,
  yaORM.Types,
  yaORM.Relationships,
  Example.Address;

type

  { TCustomer }

  TCustomer = class(TPersistent)
  strict private
  var
    FCustomerId: integer;
    FName: string;
    FNotes: TNullableString;
    FAddressId: TNullableInteger;
    FCustomerToAddressRelationship: TyaOneToOneRelationship<TCustomer, TAddress>;

    procedure NotifyObservers(const AAction: TFPObservedOperation);
  strict protected
    procedure SetCustomerId(const ACustomerId: integer);
    procedure SetName(const AName: string);
    procedure Setnotes(const ANotes: TNullableString);
    procedure SetAddressId(const AAddressId: TNullableInteger);

    function GetAddress: TAddress;
    procedure SetAddress(const AAddress: TAddress);
  public
    constructor Create(const ACustomerORM: IyaORM<TCustomer>; const AAddressORM: IAddressORM); reintroduce;
    destructor Destroy; override;

    property Address: TAddress read GetAddress write SetAddress;
  published
    property CustomerId: integer read FCustomerId write SetCustomerId;
    property Name: string read FName write SetName;
    property Notes: TNullableString read FNotes write SetNotes;
    property AddressId: TNullableInteger read FAddressId write SetAddressId;
  end;

  ICustomerORM = IyaORM<TCustomer>;

implementation

{ TCustomer }

procedure TCustomer.NotifyObservers(const AAction: TFPObservedOperation);
begin
  FPONotifyObservers(self, AAction, nil);
end;

procedure TCustomer.SetCustomerId(const ACustomerId: integer);
begin
  if ACustomerId = FCustomerId then
    Exit;
  FCustomerId := ACustomerId;
  NotifyObservers(ooChange);
end;

procedure TCustomer.SetName(const AName: string);
begin
  if SameText(AName, FName) then
    Exit;
  FName := AName;
  NotifyObservers(ooChange);
end;

procedure TCustomer.Setnotes(const ANotes: TNullableString);
begin
  if SameVariantValue(FNotes, ANotes) then
    Exit;
  FNotes := ANotes;
  NotifyObservers(ooChange);
end;

procedure TCustomer.SetAddressId(const AAddressId: TNullableInteger);
begin
  if SameVariantValue(FAddressId, AAddressId) then
    Exit;
  FAddressId := AAddressId;
  if Assigned(FCustomerToAddressRelationship) then
    FCustomerToAddressRelationship.CheckLinkedObject;
  NotifyObservers(ooChange);
end;

function TCustomer.GetAddress: TAddress;
begin
  result := nil;
  if Assigned(FCustomerToAddressRelationship) then
    result := FCustomerToAddressRelationship.LinkedObject;
end;

procedure TCustomer.SetAddress(const AAddress: TAddress);
begin
  if Assigned(FCustomerToAddressRelationship) then
    FCustomerToAddressRelationship.LinkedObject := AAddress
  else
    SetAddressId(AAddress.AddressId);
end;

constructor TCustomer.Create(const ACustomerORM: ICustomerORM; const AAddressORM: IAddressORM);
begin
  inherited Create;
  FCustomerToAddressRelationship := TyaOneToOneRelationship<TCustomer, TAddress>.Create(self, TORMStringArray.Create('AddressId'), ACustomerORM, AAddressORM);
end;

destructor TCustomer.Destroy;
begin
  FreeAndNil(FCustomerToAddressRelationship);
  NotifyObservers(ooFree);
  inherited Destroy;
end;

end.

