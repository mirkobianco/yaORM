(*
  yet another ORM - for FreePascal
  ORM GUI abstract Mediator

  Copyright (C) 2016 Mirko Bianco
  See the file LICENSE, included in this distribution,
  for details about the copyright.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)
unit yaORM.Mediators.GUI;

{$mode Delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Controls,
  TypInfo,
  yaORM.Types;

type
  TGUIMediator<TItem: TPersistent> = class abstract (TCollectionItem)
  public
    procedure ChangeInstance(const AInstance: TItem); virtual; abstract;
  end;

implementation

end.
