unit Unit1;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, FileUtil, LazFileUtils, Forms, Controls, Graphics,
    Dialogs, StdCtrls, Menus, SyncUtils;

type

    { TForm1 }

    TForm1 = class(TForm)
			Button1: TButton;
        ButtSyncExisting: TButton;
		ButJoinNew: TButton;
		CheckBoxTestRun: TCheckBox;
		EditConfig: TEdit;
		EditNotes: TEdit;
		EditSync: TEdit;
		Label1: TLabel;
		LabelNotes: TLabel;
		LabelConfig: TLabel;
        LabelSync: TLabel;
        Memo1: TMemo;
        SelectDirectoryDialog1: TSelectDirectoryDialog;
		procedure Button1Click(Sender: TObject);
        procedure ButtSyncExistingClick(Sender: TObject);
		procedure ButJoinNewClick(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure FormShow(Sender: TObject);
    private
	    procedure DisplaySync();
    public
        function Proceed(const ClashRec : TClashRecord) : TSyncAction;
    end;


var
    Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }
uses Sync, TB_SDiff;

var
    ASync : TSync;

procedure TForm1.DisplaySync();
var
    UpNew, UpEdit, Down, DelLoc, DelRem, Clash, DoNothing : integer;
begin
    ASync.ReportMetaData(UpNew, UpEdit, Down, DelLoc, DelRem, Clash, DoNothing);
    Memo1.Append('New Uploads    ' + inttostr(UpNew));
    Memo1.Append('Edit Uploads   ' + inttostr(UpEdit));
    Memo1.Append('Downloads      ' + inttostr(Down));
    Memo1.Append('Local Deletes  ' + inttostr(DelLoc));
    Memo1.Append('Remote Deletes ' + inttostr(DelRem));
    Memo1.Append('Clashes        ' + inttostr(Clash));
    Memo1.Append('Do Nothing     ' + inttostr(DoNothing));
end;

procedure TForm1.ButtSyncExistingClick(Sender: TObject);
// var
//    SyncState : TSyncAvailable;
begin
    Memo1.clear;
  {if SelectDirectoryDialog1.Execute then begin
       LabelSync.Caption := TrimFilename(SelectDirectoryDialog1.FileName + PathDelim);    }
    try
	    //ASync := TSync.Create('/home/dbannon/.local/share/tomboy-ng/', '/home/dbannon/.config/', SpinEdit1.Value);
	    ASync := TSync.Create();
	    ASync.DebugMode:=True;
	    ASync.TestRun := CheckBoxTestRun.Checked;
	    ASync.ProceedFunction:=@Proceed;
	    ASync.NotesDir:= EditNotes.Text;
	    ASync.ConfigDir := EditConfig.Text;
	    ASync.SyncAddress := EditSync.Text;
	    //ASync.CurrRev:=SpinEdit1.Value;
	    Async.SetMode(True);
	       // SyncState := ASync.testConnection;
	       {case SyncState of
	               Syncready : Async.StartSync();
	               SyncNoLocal : begin
	                                if ASync.JoinSync() then begin
	                                    DisplaySync();
	                                    ASync.StartSync()
								    end
								    else showmessage('Failed to join sync repo')
				                end;
		       end;  }
        if SyncReady <> ASync.TestConnection() then begin
	        Memo1.Append('Failed to find an existing connection. ' + ASync.ErrorString);
	    end else begin
	            // If to here, sync should be enabled and know about remote files it might need.
	        ASync.StartSync();
	        DisplaySync();
	    end;
    finally
	    ASync.Free;
    end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
    MR : integer;
begin
    MR := QuestionDlg('Window Title', 'My question', mtConfirmation, [mrYes, mrNo], 'Blar');
    if Mr = mrYes  then showmessage('YES')
    else if MR = mrNo then showmessage('no');
end;

// Join (possibly forcing a (new) join) connection or, if its not there
// initialise that connection.

procedure TForm1.ButJoinNewClick(Sender: TObject);
var
    SyncState : TSyncAvailable;
    MR : integer;
    //UseLocalManifest : boolean = True;
begin
    Memo1.Clear;
	try
	    ASync := TSync.Create();
	    ASync.DebugMode:=True;
	    ASync.TestRun := CheckBoxTestRun.Checked;
	    ASync.ProceedFunction:=@Proceed;
	    ASync.NotesDir:= EditNotes.Text;
	    ASync.ConfigDir := EditConfig.Text;
	    ASync.SyncAddress := EditSync.Text;
	    Async.SetMode(True);         // Ie, Filesync
        if ASync.ErrorString <> '' then begin
            showmessage('ASync initial parameter error - ' + ASync.ErrorString);
            exit;
		end;
        ASync.IgnoreLocalManifest := True;          // because we asked to 'JOIN' !
	    SyncState := Async.TestConnection();
        while SyncState <> SyncReady do
	    case SyncState of
        // Ask user if we should proceed if we are SyncMisMatch, SyncNoRemoteRepo
        // quietlty proceed if NoLocal (but log to debug)
        // We cannot handle SyncXMLError, SyncBadRemote, SyncNoRemoteWrite
	        SyncNoLocal : begin
                showmessage('No Local Manifest, Thats OK');
                ASync.IgnoreLocalManifest := True;
                SyncState := ASync.TestConnection();
                end;
	        SyncNoRemoteRepo : begin ;
                    MR := QuestionDlg('Warning', 'Create a new Reop ?', mtConfirmation, [mrYes, mrNo], 'Blar');
                    if MR = mrYes then begin
                        ASync.NewRepo:=True;
                        SyncState := ASync.TestConnection();    // will try and create repo.
                        if SyncState = SyncNoRemoteRepo then
                            showmessage('ERROR ' + Async.ErrorString);
					end else exit;
                end;
            SyncMisMatch : begin
                    MR := QuestionDlg('Warning', 'Force Join of this Repo ?', mtConfirmation, [mrYes, mrNo], 'Blar');
                    if MR = mrYes then begin
                        ASync.IgnoreLocalManifest := True;
                        SyncState := ASync.TestConnection();
                    end;
				end;
	        SyncXMLError, SyncNoRemoteDir, SyncBadRemote, SyncNoRemoteWrite : begin
                        showmessage(ASync.ErrorString);
                        exit;
                    end;
	    end;    // end of case statement
	    if SyncState = SyncReady then begin
	        ASync.StartSync();
	        DisplaySync();
		end else showmessage('Cancelling operation');
    finally
        ASync.Free;
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.FormShow(Sender: TObject);
begin
	    EditConfig.Text := 'config';
	    EditSync.Text := 'sync';
	    EditNotes.Text := 'notes';
	    CheckBoxtestRun.Checked := True;
end;

function TForm1.Proceed(const ClashRec : TClashRecord) : TSyncAction;
var
    SDiff : TFormSDiff;
    Res : integer;
begin
    result := SyDownload;
    SDiff := TFormSDiff.Create(self);
    SDiff.RemoteFilename := ClashRec.ServerFileName;
    SDiff.LocalFilename := ClashRec.LocalFileName;
    Res := SDiff.ShowModal;
    case Res of
            mrYes : Result := SyDownLoad;
            mrNo  : Result := SyUpLoadEdit;
    end;
    SDiff.Free;
end;

end.
