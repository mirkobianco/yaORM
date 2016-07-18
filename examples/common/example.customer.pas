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

  TCustomer = class(TCollectionItem)
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

procedure TCustomer.SetCustomerId(const ACustomerId: integer);
begin
  if ACustomerId = FCustomerId then
    Exit;
  FCustomerId := ACustomerId;
  FPONotifyObservers(self, ooChange, nil);
end;

procedure TCustomer.SetName(const AName: string);
begin
  if SameText(AName, FName) then
    Exit;
  FName := AName;
  FPONotifyObservers(self, ooChange, nil);
end;

procedure TCustomer.Setnotes(const ANotes: TNullableString);
begin
  if SameVariantValue(FNotes, ANotes) then
    Exit;
  FNotes := ANotes;
  FPONotifyObservers(self, ooChange, nil);
end;

procedure TCustomer.SetAddressId(const AAddressId: TNullableInteger);
begin
  if SameVariantValue(FAddressId, AAddressId) then
    Exit;
  FAddressId := AAddressId;
  FCustomerToAddressRelationship.CheckLinkedObject;
  FPONotifyObservers(self, ooChange, nil);
end;

function TCustomer.GetAddress: TAddress;
begin
  result := FCustomerToAddressRelationship.LinkedObject;
end;

procedure TCustomer.SetAddress(const AAddress: TAddress);
begin
  FCustomerToAddressRelationship.LinkedObject := AAddress;
end;

constructor TCustomer.Create(const ACustomerORM: IyaORM<TCustomer>; const AAddressORM: IAddressORM);
begin
  inherited Create(nil);
  FCustomerToAddressRelationship := TyaOneToOneRelationship<TCustomer, TAddress>.Create(self, TStringArray.Create('AddressId'), ACustomerORM, AAddressORM);
end;

destructor TCustomer.Destroy;
begin
  FPONotifyObservers(self, ooFree, nil);
  FreeAndNil(FCustomerToAddressRelationship);
  inherited Destroy;
end;

end.

