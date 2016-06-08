unit Example.Address;

{$MODE DELPHI}
{$H+}

interface

uses
  Classes,
  SysUtils,
  Variants,
  yaORM,
  yaORM.Types;

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

end.

