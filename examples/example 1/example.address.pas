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
    procedure SetAddressId(const AAddressId: integer);
    procedure SetDescription(const ADescription: string);
  published
    property AddressId: integer read FAddressId write SetAddressId;
    property Description: string read FDescription write SetDescription;
  end;

  TAddresses = TObjectList<TAddress>;

  IAddressORM = IyaORM<TAddress>;

implementation

{ TAddress }

procedure TAddress.SetAddressId(const AAddressId: integer);
begin
  if AAddressId = FAddressId then
    Exit;
  FAddressId := AAddressId;
end;

procedure TAddress.SetDescription(const ADescription: string);
begin
  if ADescription = FDescription then
    Exit;
  FDescription := ADescription;
end;

end.

