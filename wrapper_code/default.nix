{
  lib,
  stdenv,
}:

stdenv.mkDerivation rec {
  pname = "mysync";
  version = "1.0.0";

  src = ./.;

  buildPhase = "gcc -Ofast -mtune=native  mysync.c -o mysync" ;
  installPhase = "mkdir -pv -- $out/bin ; cp mysync $out/bin/mysync" ;

  meta = with lib; {
    homepage = "http://www.google.com";
    description = "rsync wrapper";
    platforms = platforms.unix;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ruuda ];
    mainProgram = "mysync";
  };
}
