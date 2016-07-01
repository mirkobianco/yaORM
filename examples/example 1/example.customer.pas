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

  TCustomer = class;

  ICustomerORM = IyaORM<TCustomer>;

  TCustomer = class
  strict private
  var
    FCustomerId: integer;
    FName: string;
    FNotes: TNullableString;
    FAddressId: TNullableInteger;
    FCustomerToAddressRelationship: TyaOneToOneRelationship<TCustomer, TAddress>;
  strict protected
    procedure SetCustomerId(const ACustomerId: integer);
    procedure SetName(const AName: string);
    procedure Setnotes(const ANotes: TNullableString);
    procedure SetAddressId(const AAddressId: TNullableInteger);

    function GetAddress: TAddress;
    procedure SetAddress(const AAddress: TAddress);
  public
    constructor Create(const ACustomerORM: ICustomerORM; const AAddressORM: IAddressORM); reintroduce;
    destructor Destroy; override;

    property Address: TAddress read GetAddress write SetAddress;
  published
    property CustomerId: integer read FCustomerId write SetCustomerId;
    property Name: string read FName write SetName;
    property Notes: TNullableString read FNotes write SetNotes;
    property AddressId: TNullableInteger read FAddressId write SetAddressId;
  end;

  TCustomers = TObjectList<TCustomer>;

implementation

{ TCustomer }

procedure TCustomer.SetCustomerId(const ACustomerId: integer);
begin
  if ACustomerId = FCustomerId then
    Exit;
  FCustomerId := ACustomerId;
end;

procedure TCustomer.SetName(const AName: string);
begin
  if SameText(AName, FName) then
    Exit;
  FName := AName;
end;

procedure TCustomer.Setnotes(const ANotes: TNullableString);
begin
  if SameVariantValue(FNotes, ANotes) then
    Exit;
  FNotes := ANotes;
end;

procedure TCustomer.SetAddressId(const AAddressId: TNullableInteger);
begin
  if SameVariantValue(FAddressId, AAddressId) then
    Exit;
  FAddressId := AAddressId;
  FCustomerToAddressRelationship.CheckLinkedObject;
end;

function TCustomer.GetAddress: TAddress;
begin
  result := FCustomerToAddressRelationship.LinkedObject;
end;

procedure TCustomer.SetAddress(const AAddress: TAddress);
begin
  FCustomerToAddressRelationship.LinkedObject := AAddress;
end;

constructor TCustomer.Create(const ACustomerORM: ICustomerORM; const AAddressORM: IAddressORM);
begin
  FCustomerToAddressRelationship := TyaOneToOneRelationship<TCustomer, TAddress>.Create(self, TStringArray.Create('AddressId'), ACustomerORM, AAddressORM);
end;

destructor TCustomer.Destroy;
begin
  FreeAndNil(FCustomerToAddressRelationship);
  inherited Destroy;
end;

end.

