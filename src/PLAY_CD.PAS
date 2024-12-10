{$a-}
{$x+}
program Lecture_CD_Audio;
uses
    crt,
    u_code_clavier,
    cddev,
    cdutil;

var
  fin : boolean;
  TI         : MSCDEX_TnoInfo;
  DI         : MSCDEX_DiskInfo;
  DS         : MSCDEX_DevStat;
  i : byte;
  lecteurs : array [1..26] of byte;
  nb_lect : integer;
  first_letter : integer;
  c : char;
  iDrive : integer;
  upc : mscdex_upcode;
  s : string;

begin
  if not MSCDEX_Installed then
    Begin
      Writeln( 'Impossible de trouver MSCDEX!' );
      Halt( 0 );
  End;

  iVersion := MSCDEX200_GetVersion;
  Writeln('MSCDEX V', HI( iVersion ), '.', LO( iVersion ):2,' d‚tect‚');

  if iVersion < $200
  then
    begin
      writeln ('Version de MSCDEX trop ancienne...');
      halt(1);
    end;
  {endif}

  MSCDEX_GetNumberOfDriveLetters (nb_lect, first_letter);
{  MSCDEX200_GetCDRomDriveLetters (@lecteurs);
  write ('Liste des lecteurs de CD-ROM de ce systŠme:');
  for i := 1 to nb_lect do
    write (' ', lecteurs [i], '=', chr (ord ('A')+lecteurs [i]), ':');
  {endfor}
{  writeln;
  write ('Lequel voulez-vous lire ?');
  readln (iDrive);}
  iDrive := first_letter;
  clrscr;

  if not MSCDEX200_CDRomDriveCheck( iDrive ) then
    Begin
      Writeln( 'Ce n''est pas un lecteur CD !' );
      Halt( 0 );
    End;
  {endif}

  cd_GetDevStat( iDrive, DS );
  if ( DS.lDeviceStatus and DS_NO_DISC_IN_DRIVE ) <> 0 then
    Begin
      Writeln( 'Pas de CD dans le lecteur!' );
      Halt( 0 );
    End;
  {endif}
  if ( DS.lDeviceStatus and DS_AUDIO_VIDEO ) = 0 then
    Begin
      Writeln( 'Le lecteur ne supporte pas la sortie audio!' );
      Halt( 0 );
    End;
  {endif}
  if ( DS.lDeviceStatus and DS_DOOR_OPEN ) <> 0 then
    cd_CloseTray( iDrive );
  {endif}

  cd_PrintDiskTracks (iDrive);

  writeln;
  cd_GetAudioDiskInfo( iDrive, DI );
  fin := false;
  i := DI.bLowestTrack;
  while not (fin or (i > DI.bHighestTrack)) do
    begin
      cd_GetAudioTrackInfo( iDrive, i, TI );
      if cd_IsDataTrack( TI )
      then
        { Ceci n'est pas une piste audio... }
      else
        if not cd_IsError ( cd_PlayAudio( iDrive, REDBOOK, TI.lStartingPoint,
                            cd_GetTrackLen( iDrive, i) ) )
        then
          Begin
            repeat
              if (keypressed)
              then
                case readkey of
                  touche_escape : fin := true;
                  'N', 'n' :
                    begin
                      repeat
                        if (i < DI.bHighestTrack)
                        then
                          inc (i)
                        else
                          i := DI.bLowestTrack;
                        {endif}
                        cd_GetAudioTrackInfo (iDrive, i, TI );
                      until not (cd_IsDataTrack (TI));
                      cd_StopAudio (iDrive);
                      cd_PlayAudio (iDrive, REDBOOK, TI.lStartingPoint, cd_GetTrackLen (iDrive, i));
                    end;
                  'P', 'p' :
                    begin
                      repeat
                        if (i > DI.bLowestTrack)
                        then
                          dec (i)
                        else
                          i := DI.bHighestTrack;
                        {endif}
                        cd_GetAudioTrackInfo (iDrive, i, TI );
                      until not (cd_IsDataTrack (TI));
                      cd_StopAudio (iDrive);
                      cd_PlayAudio (iDrive, REDBOOK, TI.lStartingPoint, cd_GetTrackLen (iDrive, i));
                    end;
                end;
              {endif}
            until (not cd_PrintActPlay (iDrive)) or fin;
          End
        else
          writeln ('Erreur de lecture');
        {endif}
      {endif}
      if (i < DI.bHighestTrack)
      then
        inc (i)
      else
        i := DI.bLowestTrack;
      {endif}
    end;
  {endwhile}
  writeln;
  cd_StopAudio( iDrive );
end.
