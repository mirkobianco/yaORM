unit frmMain;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  FileUtil,
  RTTIGrids,
  RTTICtrls,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  StdCtrls, ExtCtrls, Spin, Grids,
  TypInfo,

  yaORM.Types,
  yaORM.Collections,
  yaORM.Mediators.Lists,
  yaORM.Mediators.GUI.Properties,
  yaORM.Mediators.GUI.Properties.Delegated,
  yaORM.Mediators.GUI.Comboboxes,
  yaORM.Mediators.GUI.Listboxes,
  Example.Address,
  Example.Customer,
  Example.ORM
  ;


type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    ComboBox1: TComboBox;
    DrawGrid1: TDrawGrid;
    Edit1: TEdit;
    Edit2: TEdit;
    ListBox1: TListBox;
    SpinEdit1: TSpinEdit;
    procedure Button1Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    { private declarations }
    FCustomer: TCustomer;
    FCustomers: TObjectList<TCustomer>;
    FAddress: TAddress;

    FCustomersMediator: TListMediator<TCustomer>;
    FCustomerNameMediator: TGUIPropertyMediator<TCustomer, TEdit>;
    FCustomerAddressIdMediator: TGUIPropertyMediator<TCustomer, TSpinEdit>;
    FCustomerAddressMediator: TGUIDelegatedPropertyMediator<TCustomer, TAddress, TEdit>;
    FCustomersListboxMediator: TGUIListMediator<TCustomer, TListBox>;
    FCustomersComboboxMediator: TGUIComboBoxMediator<TCustomer, TComboBox>;

    procedure CreateDatabase;
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.CreateDatabase;
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

function CustomerDescFunc(const ACustomer: TCustomer): string;
begin
  result := ACustomer.Name;
end;

function GetAddressFromCustomer(const ASourceInstance: TCustomer): TAddress;
begin
  result := ASourceInstance.Address;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  CreateDatabase;

  FCustomer := ORMS.CustomerORM.New;
  FAddress := ORMS.AddressORM.New;

  FCustomer.CustomerId := 1;
  FCustomer.Name := 'Mirko Bianco';

  FAddress.AddressId := 1;
  FAddress.Description := 'Mirko Bianco''s address';
  ORMS.AddressORM.Insert(FAddress);

  FCustomer.Address := FAddress; //LAddress is assigned to the LCustomer, please check TyaOneToOneRelationship for objects ownership

  ORMS.CustomerORM.Insert(FCustomer);

  FCustomer := ORMS.CustomerORM.New;
  FCustomer.CustomerId := 2;
  FCustomer.Name := 'Ye auld wife';
  ORMS.CustomerORM.Insert(FCustomer);

  FCustomer := ORMS.CustomerORM.New;
  FCustomer.CustomerId := 3;
  FCustomer.Name := 'ye young daughter';
  ORMS.CustomerORM.Insert(FCustomer);

  ORMS.CustomerORM.LoadList(ORMS.CustomerORM.NewFilter, FCustomers);

  FCustomer := FCustomers.Items[0];

  FCustomerNameMediator := TGUIPropertyMediator<TCustomer, TEdit>.Create(Edit1, 'Text', FCustomer, 'Name');
  FCustomerAddressIdMediator := TGUIPropertyMediator<TCustomer, TSpinEdit>.Create(SpinEdit1, 'Value', FCustomer, 'AddressId');
  FCustomerAddressMediator := TGUIDelegatedPropertyMediator<TCustomer, TAddress, TEdit>.Create(Edit2, 'Text', FCustomer, GetAddressFromCustomer, 'Description');
  FCustomersMediator := TListMediator<TCustomer>.Create(FCustomers);
  FCustomersMediator.AttachPropertyMediator(FCustomerNameMediator);
  FCustomersMediator.AttachPropertyMediator(FCustomerAddressIdMediator);
  FCustomersMediator.AttachPropertyMediator(FCustomerAddressMediator);
  FCustomersListboxMediator := TGUIListMediator<TCustomer, TListBox>.Create(ListBox1, FCustomersMediator, CustomerDescFunc, nil);
  FCustomersComboboxMediator := TGUIComboBoxMediator<TCustomer, TComboBox>.Create(ComboBox1, FCustomersMediator, CustomerDescFunc, nil);
end;

procedure TForm1.FormClick(Sender: TObject);
begin

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  FCustomer := ORMS.CustomerORM.New;
  FCustomer.CustomerId := 4;
  FCustomer.Name := 'Arya';
  ORMS.CustomerORM.Insert(FCustomer);
  FCustomers.Add(FCustomer);
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin

end;

procedure TForm1.ComboBox1Select(Sender: TObject);
begin
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCustomerAddressMediator);
  FreeAndNil(FCustomerNameMediator);
  FreeAndNil(FCustomerAddressIdMediator);
  FreeAndNil(FCustomersListboxMediator);
  FreeAndNil(FCustomersComboboxMediator);
  FreeAndNil(FCustomersMediator);
  with FCustomers.GetEnumerator do
    while MoveNext do
      GetCurrent.Free;
  FreeAndNil(FCustomers);
end;

procedure TForm1.ListBox1Click(Sender: TObject);
begin
end;

end.

