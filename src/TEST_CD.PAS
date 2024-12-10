{
Programme de test des API de MSCDEX (cf. Bible Pc v5 pages 1354 et suivantes)
}
uses
    crt;

type
    t_lecteurs = array [1..26] of byte;

procedure attente_fin;
var
   c : char;
begin
  writeln;
  writeln ('Veuillez pressez une touche pour continuer...');
  while keypressed do c := readkey;
  while not keypressed do;
  while keypressed do c := readkey;
end; { attente_fin }

procedure mscdex_gestionnaire_cd_rom (lecteur : word; var buffer);
var
   o, s : word;
begin
  o := ofs (buffer);
  s := seg (buffer);
  asm
    push ax
    push bx
    push cx
    push es
    mov ax, 1510h
    mov cx, lecteur
    mov bx, o
    mov es, s
    int 2fh
    pop es
    pop cx
    pop bx
    pop ax
  end;
end; { mscdex_gestionnaire_cd_rom }

procedure info_cd_rom (var nom_lect, nb_lect : word);
var
   a, b : word;
begin
  asm
    push ax
    push bx
    push cx
    mov bx, 0
    mov ax, 1500h
    int 2fh
    mov a, bx
    mov b, cx
    pop cx
    pop bx
    pop ax
  end;
  nom_lect := b;
  nb_lect := a;
end; { info_cd_rom }

function mscdex_version : word;
var
   a : word;
begin
  asm
    push ax
    push bx
    mov bx, 0;
    mov ax, 150ch
    int 2fh
    mov a, bx
    pop bx
    pop ax
  end;
  if (a = 0)
  then
    a := 100;
  {endif}
  mscdex_version := a;
end; { mscdex_version }

procedure mscdex_detail_cd_rom (var lecteurs : t_lecteurs);
var
   i : byte;
   o, s : word;
begin
  for i := 1 to 26 do lecteurs [i] := 0;
  s := seg (lecteurs);
  o := ofs (lecteurs);
  asm
    push ax
    push bx
    push es
    mov ax, 150dh
    mov bx, o
    mov es, s
    int 2fh
    pop es
    pop bx
    pop ax
  end;
end; { mscdex_detail_cd_rom }

var
   nb_lect : word;
   nom_lect : word;
   ver : word;
   i : byte;
   lecteurs : t_lecteurs;

begin
  clrscr;

  info_cd_rom (nom_lect, nb_lect);
  if (nb_lect = 0)
  then
    begin
      writeln ('Aucun lecteur de CD-ROM connect‚ ou MSCDEX non charg‚...');
      attente_fin;
      halt (1);
    end;
  {endif}
{  writeln ('Nombre de lecteurs CD-ROM: ', nb_lect);
  writeln ('1er lecteur CD-ROM: ', chr (ord ('A')+nom_lect));}

  ver := mscdex_version;
  writeln ('MSCDEX v', hi (ver), '.', lo(ver));

  mscdex_detail_cd_rom (lecteurs);
  write ('Liste des lecteurs de CD-ROM de ce systŠme:');
  for i := 1 to nb_lect do write (' ', chr (ord ('A')+lecteurs [i]), ':');
  writeln;

  if (ver < 2*256+10)
  then
    begin
      writeln ('MSCDEX trop ancien, veuillez le mettre … jour en contactant');
      writeln ('votre revendeur de CD-ROM ou Microsoft...');
      attente_fin;
      halt (2);
    end;
  {endif}

  dir


  attente_fin;
end.
