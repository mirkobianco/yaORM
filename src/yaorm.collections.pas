(*
  yet another ORM - for FreePascal
  ORM Containers

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Collections;

{$mode delphi}

interface

uses
  Classes,
  SysUtils,

  fgl;

type
  { TObjectListEnumerator<T> }

  TObjectListEnumerator<T> = class(TObject)
  protected
    FList: TFPSList;
    FPosition: Integer;
    function GetCurrent: T;
  public
    constructor Create(AList: TFPSList);
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  { TObjectList<T> }

  TObjectList<T: TPersistent> = class(TPersistent)
  private
  type
    TFPGItemListEnumerator = TObjectListEnumerator<T>;
    TCompareFunc = function(const Item1, Item2: T): Integer;
  var
    FList: TFPGObjectList<T>;

    function GetFirst: T;
    procedure SetFirst(const AItem: T);
    function GetLast: T;
    procedure SetLast(const AItem: T);

    function  Get(Index: Integer): T;
    procedure Put(Index: Integer; const Item: T);

    function GetCapacity: integer;
    procedure SetCapacity(const ACapacity: integer);
    function GetCount: integer;
    procedure SetCount(const ACount: integer);
    function GetItemSize: integer;
  public
    constructor Create(const AFreeObjects: Boolean = true);
    destructor Destroy; override;
    function Add(const Item: T): Integer;
    function Extract(const Item: T): T;
    function GetEnumerator: TFPGItemListEnumerator;
    function IndexOf(const Item: T): Integer;
    function Remove(const Item: T): Integer;
    procedure Sort(Compare: TCompareFunc);
    procedure Insert(Index: Integer; const Item: T);

    procedure Clear;
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function Expand: TFPSList;
    procedure Move(CurIndex, NewIndex: Integer);
    procedure Pack;

    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property ItemSize: Integer read GetItemSize;
    property Last: T read GetLast write SetLast;
    property First: T read GetFirst write SetFirst;
    property Items[Index: Integer]: T read Get write Put; default;
  end;

implementation

{ TObjectList }

constructor TObjectList<T>.Create(const AFreeObjects: Boolean);
begin
  FList := TFPGObjectList<T>.Create(AFreeObjects);
end;

destructor TObjectList<T>.Destroy;
begin
  FPONotifyObservers(Self, ooFree, nil);
  FreeAndNil(FList);
  inherited Destroy;
end;

function TObjectList<T>.GetFirst: T;
begin
  result := FList.GetFirst;
end;

procedure TObjectList<T>.SetFirst(const AItem: T);
begin
  if FList.First = AItem then
    Exit;

  FPONotifyObservers(Self, ooDeleteItem, Pointer(FList.First));
  FPONotifyObservers(Self, ooAddItem, Pointer(AItem));

  FList.First := AItem;
end;

function TObjectList<T>.GetLast: T;
begin
  result := FList.Last;
end;

procedure TObjectList<T>.SetLast(const AItem: T);
begin
  if FList.Last = AItem then
    Exit;

  FPONotifyObservers(Self, ooDeleteItem, Pointer(FList.Last));
  FPONotifyObservers(Self, ooAddItem, Pointer(AItem));

  FList.Last := AItem;
end;

function TObjectList<T>.Get(Index: Integer): T;
begin
  result := FList.Items[Index];
end;

procedure TObjectList<T>.Put(Index: Integer; const Item: T);
begin
  if FList.Items[Index] = Item then
    Exit;

  FPONotifyObservers(Self, ooDeleteItem, Pointer(FList.Items[Index]));
  FPONotifyObservers(Self, ooAddItem, Pointer(Item));

  FList.Items[Index] := Item;
end;

function TObjectList<T>.Add(const Item: T): Integer;
begin
  result := FList.Add(Item);

  FPONotifyObservers(Self, ooAddItem, Pointer(Item));
end;

function TObjectList<T>.Extract(const Item: T): T;
begin
  result := FList.Extract(Item);

  FPONotifyObservers(Self, ooDeleteItem, Pointer(Item));
end;

function TObjectList<T>.GetEnumerator: TFPGItemListEnumerator;
begin
  result := TFPGItemListEnumerator.Create(FList);
end;

function TObjectList<T>.IndexOf(const Item: T): Integer;
begin
  result := FList.IndexOf(Item);
end;

function TObjectList<T>.Remove(const Item: T): Integer;
begin
  result := FList.Remove(Item);
  FPONotifyObservers(Self, ooDeleteItem, Pointer(Item));
end;

procedure TObjectList<T>.Sort(Compare: TCompareFunc);
begin
  FList.Sort(Compare);
  FPONotifyObservers(Self, ooChange, nil);
end;

procedure TObjectList<T>.Insert(Index: Integer; const Item: T);
begin
  FList.Insert(Index, Item);
  FPONotifyObservers(Self, ooAddItem, nil);
end;

function TObjectList<T>.GetCapacity: integer;
begin
  result := FList.Capacity;
end;

procedure TObjectList<T>.SetCapacity(const ACapacity: integer);
begin
  FList.Capacity := ACapacity;
end;

function TObjectList<T>.GetCount: integer;
begin
  result := FList.Count;
end;

procedure TObjectList<T>.SetCount(const ACount: integer);
begin
  FList.Count := ACount;
end;

function TObjectList<T>.GetItemSize: integer;
begin
  result := FList.ItemSize;
end;

procedure TObjectList<T>.Clear;
begin
   FList.Clear;
   FPONotifyObservers(Self, ooChange, nil);
end;

procedure TObjectList<T>.Delete(Index: Integer);
var
  LItem: T;
begin
  if FList.Count <= Index then
    Exit;

  LItem := FList.Items[Index];
  FPONotifyObservers(Self, ooDeleteItem, Pointer(LItem));
  FList.Delete(Index);
end;

procedure TObjectList<T>.Exchange(Index1, Index2: Integer);
begin
  FList.Exchange(Index1, Index2);
  FPONotifyObservers(Self, ooChange, nil);
end;

function TObjectList<T>.Expand: TFPSList;
begin
  result := FList.Expand;
end;

procedure TObjectList<T>.Move(CurIndex, NewIndex: Integer);
begin
  FList.Move(CurIndex, NewIndex);
  FPONotifyObservers(Self, ooChange, nil);
end;

procedure TObjectList<T>.Pack;
begin
  FList.Pack;
end;

{ TObjectListEnumerator<T> }

function TObjectListEnumerator<T>.GetCurrent: T;
begin
  Result := T(FList.Items[FPosition]^);
end;

constructor TObjectListEnumerator<T>.Create(AList: TFPSList);
begin
  inherited Create;
  FList := AList;
  FPosition := -1;
end;

function TObjectListEnumerator<T>.MoveNext: Boolean;
begin
  inc(FPosition);
  Result := FPosition < FList.Count;
end;

end.

