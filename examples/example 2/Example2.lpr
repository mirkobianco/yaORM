program Example2;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils,
  Interfaces, // this includes the LCL widgetset
  Forms,
  frmMain, yaORM.Collections,
  lz_rtticontrols
  { you can add units after this };

{$R *.res}

begin
  //if FileExists('heap.trc') then
  //  DeleteFile('heap.trc');
  //SetHeapTraceOutput('heap.trc');

  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

