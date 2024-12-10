{$a-}
{$x+}
program Lecture_CD_Audio;
uses
    dos,
    crt,
    u_code_clavier,
    cddev,
    cdutil;

var
  fin : boolean;
  TI         : MSCDEX_TnoInfo;
  DI         : MSCDEX_DiskInfo;
  DS         : MSCDEX_DevStat;
  i, j : integer;
  lecteurs : array [1..26] of byte;
  nb_lect : integer;
  first_letter : integer;
  c : char;
  iDrive : integer;
  upc : mscdex_upcode;
  s : string;
  param_heure, param_minute,
  param_first_track,
  hh, mm, ss, ss100 : word;

begin
  if (paramcount <> 3)
  then
    begin
      writeln ('REVEIL HH MM TRACK');
      writeln;
      writeln ('Avec HH = Heure de 0 Ö 23');
      writeln ('et MM = Minutes de 0 Ö 59');
      writeln;
      writeln ('TRACK correspond Ö la premiäre piste lue sur le CD');
      halt (1);
    end;
  {endif}

  {$r-}
  val (paramstr(1), i, j);
  {$r+}
  if ((j <> 0) or (i < 0) or (i > 23))
  then
    begin
      writeln ('Paramätre HH incorrect...');
      halt(1);
    end
  else
    param_heure := i;
  {endif}

  {$r-}
  val (paramstr(2), i, j);
  {$r+}
  if ((j <> 0) or (i < 0) or (i > 59))
  then
    begin
      writeln ('Paramätre MM incorrect...');
      halt(1);
    end
  else
    param_minute := i;
  {endif}

  {$r-}
  val (paramstr(3), i, j);
  {$r+}
  if ((j <> 0) or (i < 1) or (i > 99))
  then
    begin
      writeln ('Paramätre Track incorrect...');
      halt(1);
    end
  else
    param_first_track := i;
  {endif}

  if not MSCDEX_Installed then
    Begin
      Writeln( 'Impossible de trouver MSCDEX!' );
      Halt( 0 );
  End;

  iVersion := MSCDEX200_GetVersion;
  Writeln('MSCDEX V', HI( iVersion ), '.', LO( iVersion ):2,' dÇtectÇ');

  if iVersion < $200
  then
    begin
      writeln ('Version de MSCDEX trop ancienne...');
      halt(1);
    end;
  {endif}

  MSCDEX_GetNumberOfDriveLetters (nb_lect, first_letter);
{  MSCDEX200_GetCDRomDriveLetters (@lecteurs);
  write ('Liste des lecteurs de CD-ROM de ce systäme:');
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

  repeat
    delay (60000);
    gettime (hh, mm, ss, ss100);
  until ((hh = param_heure) and (mm = param_minute));

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
  if ((param_first_track >= DI.bLowestTrack) and (param_first_track <= DI.bHighestTrack))
  then
    i := param_first_track
  else
    i := DI.bLowestTrack;
  {endif}
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
