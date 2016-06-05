unit demo.businesslogic;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  Variants,
  yaORM,
  yaORM.Types,
  yaORM.Relationships;

type

  { TAddress }

  TAddress = class
  strict private
    FAddressId: integer;
    FDescription: string;
  strict protected
    procedure SetAddressId(const AddressId: integer);
    procedure SetDescription(const Description: string);
  published
    property AddressId: integer read FAddressId write SetAddressId;
    property Description: string read FDescription write SetDescription;
  end;

  TAddresses = TObjectList<TAddress>;

  IAddressORM = IyaORM<TAddress>;

  TCustomer = class;

  ICustomerORM = IyaORM<TCustomer>;

  { TCustomer }

  TCustomer = class
  strict private
  var
    FCustomerId: integer;
    FName: string;
    FNotes: TNullableString;
    FAddressId: TNullableInteger;
    FCustomerToAddressRelationship: TyaOneToOneRelationship<TCustomer, TAddress>;
  strict protected
    procedure SetCustomerId(const CustomerId: integer);
    procedure SetName(const Name: string);
    procedure Setnotes(const Notes: TNullableString);
    procedure SetAddressId(const AddressId: TNullableInteger);

    function GetAddress: TAddress;
    procedure SetAddress(const Address: TAddress);
  public
    constructor Create(const CustomerORM: ICustomerORM; const AddressORM: IAddressORM); reintroduce;
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

{ TAddress }

procedure TAddress.SetAddressId(const AddressId: integer);
begin
  if AddressId = FAddressId then
    Exit;
  FAddressId := AddressId;
end;

procedure TAddress.SetDescription(const Description: string);
begin
  if Description = FDescription then
    Exit;
  FDescription := Description;
end;

{ TCustomer }

procedure TCustomer.SetCustomerId(const CustomerId: integer);
begin
  if CustomerId = FCustomerId then
    Exit;
  FCustomerId := CustomerId;
end;

procedure TCustomer.SetName(const Name: string);
begin
  if SameText(Name, FName) then
    Exit;
  FName := Name;
end;

procedure TCustomer.Setnotes(const Notes: TNullableString);
begin
  if SameVariantValue(FNotes, Notes) then
    Exit;
  FNotes := Notes;
end;

procedure TCustomer.SetAddressId(const AddressId: TNullableInteger);
begin
  if SameVariantValue(FAddressId, AddressId) then
    Exit;
  FAddressId := AddressId;
  FCustomerToAddressRelationship.CheckLinkedObject;
end;

function TCustomer.GetAddress: TAddress;
begin
  result := FCustomerToAddressRelationship.LinkedObject;
end;

procedure TCustomer.SetAddress(const Address: TAddress);
begin
  FCustomerToAddressRelationship.LinkedObject := Address;
end;

constructor TCustomer.Create(const CustomerORM: ICustomerORM; const AddressORM: IAddressORM);
begin
  FCustomerToAddressRelationship := TyaOneToOneRelationship<TCustomer, TAddress>.Create(self, TStringArray.Create('AddressId'), CustomerORM, AddressORM);
end;

destructor TCustomer.Destroy;
begin
  FreeAndNil(FCustomerToAddressRelationship);
  inherited Destroy;
end;

end.

