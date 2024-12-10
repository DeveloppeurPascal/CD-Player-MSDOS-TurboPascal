{********************************************************************}
{                       C D R O M . P A S                            }
{*------------------------------------------------------------------*}
{ Fonction        : D‚montre la programmation de MSCDEX.              }
{                   Utilise CDUTIL                                   }
{*------------------------------------------------------------------*}
{ Auteurs          : Michael Tischer / Bruno Jennrich                }
{ D‚velopp‚ le : 08.04.1994                                          }
{ DerniŠre MAJ :  8.10.1994                                          }
{********************************************************************}

{$A-}                         { Pas de Word Alignment des structures }
{$X+}    { Syntaxe ‚tendue, ‚valuation facultative des r‚sultats fct }

Uses ARGS,CDDEV,CDUTIL,DOS;

Var
  DS         : MSCDEX_DevStat;
  MC         : MSCDEX_MedChng;
  Di         : MSCDEX_DiskInfo;
  TI         : MSCDEX_TnoInfo;
  UPC        : MSCDEX_UPCode;
  i,j,
  iVersion,
  iresult,
  iIsHsg,
  iSize      : Integer;
  arg        : String;
  lpFileName : String;
  lSektor    : Longint;
  Sektor     : Array[0..2047] of Byte;
  cSektor    : Array[0..2351] of Char;
  DirEntry   : DIR_ENTRY ;

Const
  iDrive    : Integer = 0;
  iNumTrack : Integer = 5;


{********************************************************************}
{--  P R O G R A M M E  P R I N C I P A L                          --}
{********************************************************************}
Begin
  if ParamCount = 0 then
  Begin
    Writeln( 'Parameter:');
    Writeln( 'A-Z:            Lettre du lecteur');
    Writeln( ' -DEVSTAT       Montre l''‚tat du p‚riph‚rique');
    Writeln( ' -VTOC          Montre Volume Table Of Contents');
    Writeln( ' -UPC           Montre Universal Product Code');
    Writeln( ' -CONTENTS      Montre les pistes');
    Writeln( ' -SHOW:X        Montre secteur num‚ro X [avec -RAW en Raw-Data]');
    Writeln( ' -PLAY:X        Joue piste track num‚ro X');
    Writeln( '                [-WAIT provoque l''affichage des infos d''‚tat]');
    Write  ( ' -ENTRY:name    Montre l''entr‚e de r‚pertoire du');
    Writeln( ' fichier sp‚cifi‚');
    Halt(0);
  End;

  iDrive := -1;
  for i := 1 to ParamCount do
    for j := 0 to  25 do
      begin
        arg := ParamStr(i);
        if( ( upcase( arg[1] ) = char ( j + ord( 'A' ) ) ) and
            ( arg[ 2 ] = ':' ) and
            ( length(arg) = 2 ) ) then iDrive := j;
      end;

  if iDrive < 0 then
    Begin
      Writeln( 'Indication de lecteur incorrecte!' );
      Halt( 0 );
  End;

  if not MSCDEX_Installed then
    Begin
      Writeln( 'Impossible de trouver MSCDEX!' );
      Halt( 0 );
  End;

  iVersion := MSCDEX200_GetVersion;
  Writeln('MSCDEX V', HI( iVersion ), '.', LO( iVersion ):2,' d‚tect‚');

  if iVersion > $200 then
    if not MSCDEX200_CDRomDriveCheck( iDrive ) then
      Begin
        Writeln( 'Ce n''est pas un lecteur CD-ROM!' );
        Halt( 0 );
      End;

  {- V‚rifier d'‚ventuels changements de CD ---------------}
  cd_GetMediaChanged( iDrive, MC );
  cd_GetDevStat( iDrive, DS );
  if GetArg( '-DEVSTAT', _none, NIL, 0 ) <> 0 then
    cd_PrintDevStat( DS )
  else
    if ( DS.lDeviceStatus and DS_NO_DISC_IN_DRIVE ) <> 0 then
      Begin
        Writeln( 'Pas de CD dans le lecteur!' );
        Halt( 0 );
      End;

  {- Afficher Volume Table Of Contents -------------------------------}
  if GetArg( '-VTOC', _none, NIL, 0 ) <> 0 then
  Begin
    i := 0;
    repeat
      iResult := MSCDEX_ReadVTOC( iDrive, @Sektor, i );
      if ( iResult ) <> 0 then
        cd_PrintSektor( @Sektor, 2048, 16, 24 );
      Inc(i);
    Until iResult = 0;
  End;

  {- Afficher Universal Product Code --------------------------------}
  if GetArg( '-UPC', _none, NIL, 0 ) <> 0 then
  Begin
    cd_GetUPCode( iDrive, UPC );
    cd_PrintUPCode( UPC );
  End;

  {- Afficher table des matiŠres (titre) ---------------------------}
  if GetArg( '-CONTENTS', _none, NIL, 0 ) <> 0 then
    cd_PrintDiskTracks( iDrive );

  {- Afficher contenu de secteur ------------------------------------------}
  lSektor := 0;
  if GetArg( '-SHOW:', _long, @lSektor, 1 ) <> 0 then
    Begin                                          { RAW accept‚ }
      iSize := 2048; i := COOKED;
      if GetArg( '-RAW', _none, NIL, 1 ) <> 0 then
        Begin
          iSize := 2352;
          i := RAW;
        End;
              { Attention! CD audio non lus … cause du Copyight! }
    if not cd_IsError( cd_ReadLong( iDrive, HSG, lSektor, 1, @cSektor, i ) ) then
      cd_PrintSektor( @cSektor, iSize, 16, 24 )
    else
      Writeln( 'Impossible de lire le secteur! (CD audio?)' );
  End;

  {- Afficher entr‚e de r‚pertoire ------------------------------------}
  if GetArg( '-ENTRY:', _string, @lpFileName, 1 ) <> 0 then
    Begin
      if MSCDEX200_GetDirectoryEntry( iDrive, STRUCT_COPY,
                                      lpFileName, @DirEntry, iIsHsg ) then
        cd_PrintDirEntry( DirEntry )
      else
         Writeln( 'Error: ', DOSERROR );
    End;

  {- Jouer titre ------------------------------------------------}
  iNumTrack := 0;
  if GetArg( '-PLAY:', _int, @iNumTrack, 1 ) <> 0 then
    Begin
      if ( DS.lDeviceStatus and DS_AUDIO_VIDEO ) = 0 then
        Begin
          Writeln( 'Le lecteur ne supporte pas la sortie audio!' );
          Halt( 0 );
        End;
      if ( DS.lDeviceStatus and DS_DOOR_OPEN ) <> 0 then
        cd_CloseTray( iDrive );
      cd_GetAudioDiskInfo( iDrive, DI );
      if ( ( iNumTrack < DI.bLowestTrack ) or
           ( iNumTrack > DI.bHighestTrack ) ) then
        Begin
          Writeln( 'Num‚ro de chanson incorrect' );
          Halt(0);
        End;
      cd_GetAudioTrackInfo( iDrive, iNumTrack, TI );
      if cd_IsDataTrack( TI ) then
        Begin
          Writeln('Ce n''est pas une piste audio !');
          Halt(0);
        End;
       cd_StopAudio( iDrive );
       if not cd_IsError ( cd_PlayAudio( iDrive, REDBOOK, TI.lStartingPoint,
                           cd_GetTrackLen( iDrive, iNumTrack ) ) ) then
         Begin
           if GetArg( '-WAIT', _none, NIL, 0 ) <> 0 then
             Begin
               Repeat Until not ( cd_PrintActPlay( iDrive ) );
               writeln;
             End;
           Writeln( 'Play - OK' );
         End;
    End;
End.
