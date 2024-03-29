#!/usr/bin/env bash

################################################################################
##  help
################################################################################

SCRIP_VERSION="0.1.1"

HELP="\
scrip - file creation utility

Usage:
    scrip <filename> [<filetype>] [flags]
    scrip -h, --help
    scrip --version

Filetypes
    c, c++, gv, hs, html/css, idr, md, nix, py, rs, sh, tex, texi

General flags
    -f          force overwrite of existing files
    -q          quiet mode: don't list files created
    -e          open file(s) for editing

Filetype-specific flags

c, c++
    -H          create a header file
    -i          include standard library i/o headers
    -m [args]   create a source file with main function and
                    no header inclusion if filename==main
                    args is either 'void' or 'args'
    -s          create a source file
    -t          create named struct
    -u          create pair of files for a compilation unit

hs
    -i          import System.Environment
    -m          create a main function within file
    -M          declare module
    -r          include a runhaskell shebang

html
    -t          formatted title from filename
    -l          link element for local style.css

idr
    -m          create a main function within file
    -M          declare module

md
    -n          no file extension
    -l          link element for local style.css
    -R          template software requirement specification document

rs
    -m          create a main function within file

sh
    -x          create file with xtrace set (set -x)
    -X          create file with automatic non-zero exits set (set -e)
    -b [shell]  specify a different shell (default bash)
    -n          no file extension

tex
    -c          table of contents
    -d          include date in title
    -t          title from filename

texi
"

################################################################################
##  create_c_header ()
################################################################################

create_c_header () {

    # Create a new header with inclusion guards

    if [[ $# != 6 ]] ; then
        echo "error: create_c_header() requires 6 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5
    struct=$6

    filename=$3$'.'$2
    fullpath=$directory'/'$filename

    name_upper=$(echo $name | tr [:lower:] [:upper:])
    ext_upper=$(echo $extension | tr [:lower:] [:upper:])

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo "\
#pragma once"\
    > $fullpath

    if [[ !(-e $fullpath) ]] ; then
        echo "error: file not created"
        return 1
    fi


    if $struct ; then

        head -n -1 $fullpath > $fullpath'.tmp'
        cat $fullpath'.tmp' > $fullpath
        rm $fullpath'.tmp'

        echo "\
struct $name;

struct $name
{

};"\
        >> $fullpath

    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_c_src ()
################################################################################

create_c_src () {

    # Create a new source file with corresponding header inclusion

    if [[ $# != 10 ]] ; then
        echo "error: create_c_src() requires 10 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    header_ext=$3
    name=$4
    overwrite=$5
    quiet=$6
    no_header=$7
    main=$8
    main_args=$9
    include_io=${10}

    filename=$4$'.'$2
    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo -n > $fullpath

    if [[ !(-e $fullpath) ]] ; then
        echo "error: file not created"
        return 1
    fi

    if $include_io ; then

        case $extension in

            c)
                echo "\
#include <stdio.h>"\
                >> $fullpath
            ;;

            cc|cpp)
                echo "\
#include <cstdio>"\
                >> $fullpath
            ;;

            *)
                echo "error: create_c_header() unrecognized filetype"
                return 1
            ;;

        esac
    fi

    if ! $no_header ; then
        echo "\
#include \"$name.$header_ext\""\
        >> $fullpath
    fi

    if $main ; then

        if ! $no_header || $include_io ; then
            echo "" >> $fullpath
        fi

        case $main_args in

            v|vo|voi|void)
                echo "\
int main() {"\
                >> $fullpath
            ;;

            a|ar|arg|args)
                echo "\
int main (int argc, char *argv[]) {"\
                >> $fullpath
            ;;

            *)
                echo "error: create_c_src() \$main_args not valid"
                return 1
            ;;

        esac

        # body

        if $include_io ; then
            case $extension in

                c|cc|cpp)
                    echo "\
  puts (\"main...\");
  puts (\"...main\");"\
                    >> $fullpath
                ;;

#               cc|cpp)
#                   echo "\
# std::cout << \"main...\\n\";
# std::cout << \"...main\\n\";"\
#                   >> $fullpath
#               ;;

                *)
                    echo "error: create_c_src() extension not recognized"
                    return 1
                ;;

            esac
        fi

        echo "\
}"\
        >> $fullpath

    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_graphviz ()
################################################################################

create_graphviz () {

    # Create a new html file with optional title

    if [[ $# != 5 ]] ; then
        echo "error: create_graphviz() requires 5 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5

    filename=$3$'.'$2

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo "\
digraph G {
  "A";
  "B";
  "C";
  "A" -> "B";
  "B" -> "C";
  "A" -> "C";
}
"\
    > $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_haskell_source ()
################################################################################

create_haskell_source () {

    # Create a new .hs file with optional main function

    nargs=8
    if [[ $# != $nargs ]] ; then
        echo "error: create_haskell_source() requires $nargs arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5
    main=$6
    module=$7
    shebang=$8

    filename=$3$'.'$2

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    header="\
{-------------------------------------------------------------------------------
    $filename
-------------------------------------------------------------------------------}"
    if $shebang ; then
      echo "\
#!/usr/bin/env runhaskell

$header"\
      > $fullpath
      chmod +x $fullpath
    else
      echo "$header" > $fullpath
    fi


    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if $module ; then
        name_upper=$(echo "${name[@]^}")

        echo "\

module $name_upper where"\
        >> $fullpath
    else
        name_upper="Main"
    fi

    if $main ; then
        echo "\

--------------------------------------------------------------------------------
--  main
--------------------------------------------------------------------------------

main :: IO ()
main = do
  putStrLn \"main...\"
  putStrLn \"...main\""\
        >> $fullpath
    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_html ()
################################################################################

create_html () {

    # Create a new html file with optional title

    if [[ $# != 7 ]] ; then
        echo "error: create_html() requires 7 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5
    title_from_filename=$6
    link_stylecss=$7

    filename=$3$'.'$2

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    string_out=
    if $title_from_filename ; then

        make_title $name

    fi
    title=$string_out   # string out from make_title()

    echo "\
<!DOCTYPE html>
<html>
  <head>
    <meta charset=\"utf-8\" />
    <title>$title</title>
"\
    > $fullpath

    if $link_stylecss ; then
        echo "    <link rel=\"stylesheet\" href=\"style.css\" />"\
         >> $fullpath
    fi

    echo "\
  </head>

  <body>
  </body>
</html>
"\
    >> $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_idris_source ()
################################################################################

create_idris_source () {

    # Create a new .idr file with optional main function

    if [[ $# != 7 ]] ; then
        echo "error: create_idris_source() requires 7 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5
    main=$6
    module=$7

    filename=$3$'.'$2

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo "\
{-------------------------------------------------------------------------------
    $filename
-------------------------------------------------------------------------------}"\
    > $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if [[ $name == "main" || $name == "Main" ]] ; then
        module_name="Main"
    else
        module_name=$name
    fi

    if $module ; then

        echo "\

module $module_name"\
        >> $fullpath
    else
        module_name="Main"
    fi

    if $main ; then
        echo "\

--------------------------------------------------------------------------------
--  main
--------------------------------------------------------------------------------

main : IO ()
main = do
  putStrLn \"$module_name main...\""\
        >> $fullpath
    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_latex ()
################################################################################

create_latex () {

    # Create a new latex file with title and optional table of contents

    if [[ $# != 8 ]] ; then
        echo "error: create_latex() requires 8 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5
    toc=$6
    title=$7
    show_date=$8

    filename=$3$'.'$2

    fullpath=$directory'/'$filename

    date=""

    if $show_date ; then
        date="\\today"
    fi

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo "\
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\\documentclass{article}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\\begin{document}
"\
    > $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if $title ; then

        string_out=

        make_title $name

        title=$string_out   # string out from make_title()

        echo "\
% ------------------------------------------------------------------------------

\\title{$title}
\\date{$date}
\\maketitle
"\
        >> $fullpath

    fi

    if $toc ; then
        echo "\
% ------------------------------------------------------------------------------

\\tableofcontents
"\
        >> $fullpath
    fi

    echo "\
% ------------------------------------------------------------------------------

\\end{document}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"\
    >> $fullpath

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_markdown ()
################################################################################

create_markdown () {

    # Create a new markdown file with title

    if [[ $# != 8 ]] ; then
        echo "error: create_markdown() requires 8 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5
    no_ext=$6
    link_stylecss=$7
    requirements=$8

    if $no_ext ; then
        filename=$3
    else
        filename=$3$'.'$2
    fi

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    string_out=

    make_title $name

    title=$string_out   # string out from make_title()

    title_len=${#title}

    spacer_size=$[65-$title_len]
    spacer=

    for i in $(seq 1 $spacer_size) ; do
        spacer="$spacer "
    done

    echo "\
% $title
%
%
"\
    > $fullpath

    if $link_stylecss ; then
        echo "\
<link rel=\"stylesheet\" href=\"style.css\" />
"\
        >> $fullpath
    fi

    if $requirements ; then

        echo "\
********************************************************************************
********************************************************************************
#   Outline

********************************************************************************
********************************************************************************

- Customer
- Architecture
- Structural
- Behavioral
- Non-functional
- Performance
- Design
- Derived
- Allocated



********************************************************************************
********************************************************************************
#   Introduction

********************************************************************************
********************************************************************************

********************************************************************************
##  Purpose

********************************************************************************

********************************************************************************
##  Definitions

********************************************************************************

********************************************************************************
##  System overview

********************************************************************************

********************************************************************************
##  References

********************************************************************************



********************************************************************************
********************************************************************************
#   Overall description

********************************************************************************
********************************************************************************



********************************************************************************
********************************************************************************
#   Specific requirements

********************************************************************************
********************************************************************************"\
        >> $fullpath

    else

        echo "\
********************************************************************************
********************************************************************************
#   $title

********************************************************************************
********************************************************************************
"\
        >> $fullpath
    fi

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_nix_derivation ()
################################################################################

create_nix_derivation () {
  if [[ $# != 5 ]] ; then
      echo "error: create_nix_derivation() requires 5 arguments"
      return 1
  fi

  directory=$1
  extension=$2
  name=$3
  overwrite=$4
  quiet=$5

  filename=$3$'.'$2

  fullpath=$directory'/'$filename

  if [[ -e $fullpath ]] && ! $overwrite ; then
      echo "error: $fullpath already exists, use -f to overwrite"
      return 1
  fi

  echo "\
with import <nixpkgs> {};"\
> $fullpath

  if [[ $name == "shell" ]] ; then
    echo "\
mkShell {
  buildInputs = [ ];
}"\
>> $fullpath
  else
    pname=""
    if [[ $name == "default" ]] ; then
      pname=$(basename $(pwd))
    else
      pname=$name
    fi
    echo "\
stdenv.mkDerivation {
  name = \"$pname\";
  src = lib.cleanSource ./.;
  installPhase = ''
    mkdir -p \$out
  '';
}"\
>> $fullpath
  fi

  if [[ !(-e $fullpath) ]]
  then
      echo "error: file not created"
      return 1
  fi

  if ! $quiet ; then
      echo "created file $fullpath"
  fi

  return
}

################################################################################
##  create_py_script ()
################################################################################

create_py_script () {
    if [[ $# != 5 ]] ; then
        echo "error: create_py_script() requires 5 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5

    filename=$3$'.'$2

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo "\
#!/usr/bin/env python3

print (\"hello world\")"\
 > $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    chmod +x $fullpath

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_rust_source ()
################################################################################

create_rust_source () {

    # Create a new .rs file with optional main function

    if [[ $# != 6 ]] ; then
        echo "error: create_rust_source() requires 6 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5
    main=$6

    filename=$3$'.'$2

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo "\
/******************************************************************************/
//! \`$filename\`
/******************************************************************************/"\
    > $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if $main ; then
      if [[ $name == "main" ]] ; then
        echo "\

fn main() {
  println! (\"main...\");
}"\
        >> $fullpath
      else
        echo "\

fn main() {
  println! (\"$name main...\");
}"\
        >> $fullpath
      fi
    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_sh_script ()
################################################################################

create_sh_script () {

    # Create a new .sh file with shebang and execute permission.

    if [[ $# != 9 ]] ; then
        echo "error: create_sh_script() requires 9 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    shell=$3
    name=$4
    overwrite=$5
    quiet=$6
    xtrace=$7
    nonzero_exit=$8
    no_ext=$9

    if $no_ext ; then
        filename=$4
    else
        filename=$4$'.'$2
    fi

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    echo "\
#!/usr/bin/env $shell"\
    > $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if $xtrace ; then
        echo "\
set -x"\
        >> $fullpath
    fi

    if $nonzero_exit ; then
        echo "\
set -e"\
        >> $fullpath
    fi

    echo "\

exit 0"\
    >> $fullpath

    chmod +x $fullpath

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  create_texinfo ()
################################################################################

create_texinfo () {

    if [[ $# != 5 ]] ; then
        echo "error: create_texinfo() requires 5 arguments"
        return 1
    fi

    directory=$1
    extension=$2
    name=$3
    overwrite=$4
    quiet=$5

    fullpath=$directory'/'$filename

    if [[ -e $fullpath ]] && ! $overwrite ; then
        echo "error: $fullpath already exists, use -f to overwrite"
        return 1
    fi

    string_out=

    make_title $name

    title=$string_out   # string out from make_title()

    echo "\
@c -----------------------------------------------------------------------------
@c -----------------------------------------------------------------------------
@c
@c  $title
@c
@c -----------------------------------------------------------------------------
@c -----------------------------------------------------------------------------



@c -----------------------------------------------------------------------------
@c  Header
@c -----------------------------------------------------------------------------

\input texinfo
@setfilename $name.info
@settitle $title



@c -----------------------------------------------------------------------------
@c  Summary & Copyright
@c -----------------------------------------------------------------------------

@copying

@c summary here

@copyright{} @c copyright here
@end copying



@c -----------------------------------------------------------------------------
@c  Titlepage, Contents, Copyright
@c -----------------------------------------------------------------------------

@titlepage
@title $title

@page
@vskip 0pt plus 1filll
@insertcopying
@end titlepage

@contents



@c -----------------------------------------------------------------------------
@c  \`Top\` Node & Master Menu
@c -----------------------------------------------------------------------------

@ifnottex
@node Top
@top $title Top Node

@c node description here
@end ifnottex

@menu
Main Menu

@c main menu entries here

* Index::    $title Index
@end menu



@c -----------------------------------------------------------------------------
@c  Body
@c -----------------------------------------------------------------------------



@c -----------------------------------------------------------------------------
@c  End
@c -----------------------------------------------------------------------------

@c -----------------------------------------------------------------------------
@node Index
@unnumbered Index
@c -----------------------------------------------------------------------------

@printindex cp

@c -----------------------------------------------------------------------------

@bye"\
    > $fullpath

    if [[ !(-e $fullpath) ]]
    then
        echo "error: file not created"
        return 1
    fi

    if ! $quiet ; then
        echo "created file $fullpath"
    fi

    return
}



################################################################################
##  make_title ()
################################################################################

make_title () {

    # converts characters following whitespace or separators from
    # lowercase to uppercase and replaces separators with whitespace
    # separators are '-' and '_'

    # return variable: string_out

    string_in=$1

    string_in_len=${#string_in}

    last_char=
    read_char=

    string_out=

    for i in $(seq 0 ${string_in_len-1}) ; do
        read_char=${string_in:i:1}

        case $last_char in

            " "|""|-|_)
                this_char="${read_char^}"
            ;;

            *)
                this_char=$read_char
            ;;

        esac

        case $this_char in

            -|_)
                this_char=" "
            ;;

            *)
            ;;

        esac

        string_out=$string_out$this_char

        last_char=$this_char
    done

    return
}



################################################################################
##  main
################################################################################

if [[ $# < 1 ]] ; then
    echo "error: syntax is 'scrip <filename> [<filetype>] [flags]' or 'scrip -h' for help"
    exit 1

fi

case $1 in

    -h|--help)
        echo "$HELP"
        exit 0
    ;;

    --version)
        echo "scrip $SCRIP_VERSION"
        exit 0
    ;;

    *)
    ;;

esac

# options

cflags='Him:stu'
genflags='efhq'
gvflags=
hsflags='imMr'
htmlflags='tl'
idrflags='mM'
mdflags='csnlR'
nixflags=
pyflags=
rsflags='m'
shflags='xXb:sn'
texflags='cdt'
texiflags=

specflags=

# file output flags

graphviz=false
haskell=false
header=false
html=false
idris=false
latex=false
markdown=false
nix=false
python=false
rust=false
script=false
src=false
texinfo=false

# option flags flags

hs_main=false
html_title=false
idr_main=false
rs_main=false
include_io=false
latex_date=false
latex_title=false
link_stylecss=false
main=false
module=false
no_ext=false
open_editor=false
overwrite=false
quiet=false
requirements=false
struct=false
table_of_contents=false
xtrace=false
nonzero_exit=false
shebang=false

# option arguments

shell="bash"
main_args="void"

# filenames

filename=$1
filetype=$2

directory=$(dirname "$filename")
filename=$(basename "$filename")
extension="${filename##*.}"
name="${filename%.*}"

# no-extension check

if [[ $extension == $filename ]] ; then
    extension=
fi

gv_ext=
haskell_ext=
header_ext=
html_ext=
idris_ext=
latex_ext=
markdown_ext=
nix_ext=
python_ext=
rust_ext=
script_ext=
src_ext=
texinfo_ext=

gv_filename=
haskell_filename=
header_filename=
html_filename=
idris_filename=
latex_filename=
markdown_filename=
nix_filename=
python_filename=
rust_filename=
script_filename=
src_filename=
texinfo_filename=

# check filetype

known_filetype=false

case $filetype in

    c|c++|cc|cpp|gv|hs|htm|html|idr|md|nix|py|rs|sh|tex|texi)
        known_filetype=true
    ;;

    *)
    ;;

esac

# extension

case $extension in

    # c

    c)
        src_ext='c'
        src=true
    ;;&

    h)
        header_ext='h'
        header=true
    ;;&

    c|h)
        if ! $known_filetype ; then
            filetype='c'
        fi
    ;;

    # c++

    cc)
        header_ext='hh'
        src_ext='cc'
    ;;&

    cpp)
        header_ext='hpp'
        src_ext='cpp'
    ;;&

    cc|cpp)
        src=true
    ;;&

    hh)
        header_ext='hh'
        src_ext='cc'
    ;;&

    hpp)
        header_ext='hpp'
        src_ext='cpp'
    ;;&

    hh|hpp)
        header=true
    ;;&

    cc|hh)
        if ! $known_filetype ; then
            filetype='cc'
        fi
    ;;&

    cpp|hpp)
        if ! $known_filetype ; then
            filetype='cpp'
        fi
    ;;

    # gv

    dot)
        if ! $known_filetype ; then
            filetype='gv'
        fi
    ;;

    # hs

    hs)
        if ! $known_filetype ; then
            filetype='hs'
        fi
    ;;

    # html
    htm|html)
        if ! $known_filetype ; then
            filetype='html'
        fi
    ;;

    # idr

    idr)
        if ! $known_filetype ; then
            filetype='idr'
        fi
    ;;

    # md

    md)
        markdown=true
        if ! $known_filetype ; then
            filetype='md'
        fi
    ;;

    # nix

    nix)
        if ! $known_filetype ; then
            filetype='nix'
        fi
    ;;

    # py

    py)
        if ! $known_filetype ; then
            filetype='py'
        fi
    ;;

    # rs

    rs)
        if ! $known_filetype ; then
            filetype='rs'
        fi
    ;;

    # sh

    sh)
        script=true
        if ! $known_filetype ; then
            filetype='sh'
        fi
    ;;

    # tex

    tex)
        latex=true
        if ! $known_filetype ; then
            filetype='tex'
        fi
    ;;

    # texi

    texi)
        texinfo=true
        if ! $known_filetype ; then
            filetype='texi'
        fi
    ;;

    *)
    ;;

esac

# filetype

case $filetype in

    c)
        header_ext='h'
        src_ext='c'
    ;;&

    cc)
        if [[ $header_ext == '' || $extension == $src_ext ]] ; then
            header_ext='hh'
        else
            header_ext=$extension
        fi
        if [[ $src_ext == '' ]] ; then
            src_ext='cc'
        fi
    ;;&

    c++|cpp)
        if [[ $header_ext == '' || $extension == $src_ext ]] ; then
            header_ext='hpp'
        else
            header_ext=$extension
        fi
        if [[ $src_ext == '' ]] ; then
            src_ext='cpp'
        fi
    ;;&

    c|c++|cc|cpp)
        specflags=$cflags
    ;;

    gv)
        specflags=$gvflags
        graphviz=true
        graphviz_ext='dot'
    ;;

    hs)
        specflags=$hsflags
        haskell=true
        haskell_ext='hs'
    ;;

    htm|html)
        filetype='html' # filetype checks will be extension agnostic from here
        specflags=$htmlflags
        html=true
        if [[ $extension == '' ]] ; then
            html_ext='html'
        else
            html_ext=$extension
        fi
    ;;

    idr)
        specflags=$idrflags
        idris=true
        idris_ext='idr'
    ;;

    md)
        specflags=$mdflags
        markdown=true
        markdown_ext='md'
    ;;

    nix)
        specflags=$nixflags
        nix=true
        nix_ext='nix'
    ;;

    py)
        specflags=$pyflags
        python=true
        python_ext='py'
    ;;

    rs)
        specflags=$rsflags
        rust=true
        rust_ext='rs'
    ;;

    sh)
        specflags=$shflags
        script=true
        script_ext='sh'
    ;;

    tex)
        specflags=$texflags
        latex=true
        latex_ext='tex'
    ;;

    texi)
        specflags=$texiflags
        texinfo=true
        texinfo_ext='texi'
    ;;

    *)
        echo "error: could not determine filetype"
        exit 1
    ;;

esac

# filenames

graphviz_filename=$name'.'$graphviz_ext
haskell_filename=$name'.'$haskell_ext
header_filename=$name'.'$header_ext
html_filename=$name'.'$html_ext
idris_filename=$name'.'$idris_ext
latex_filename=$name'.'$latex_ext
markdown_filename=$name'.'$markdown_ext
nix_filename=$name'.'$nix_ext
python_filename=$name'.'$python_ext
rust_filename=$name'.'$rust_ext
script_filename=$name'.'$script_ext
src_filename=$name'.'$src_ext

graphviz_fullpath=$directory'/'$graphviz_filename
haskell_fullpath=$directory'/'$haskell_filename
header_fullpath=$directory'/'$header_filename
html_fullpath=$directory'/'$html_filename
idris_fullpath=$directory'/'$idris_filename
latex_fullpath=$directory'/'$latex_filename
markdown_fullpath=$directory'/'$markdown_filename
nix_fullpath=$directory'/'$nix_filename
python_fullpath=$directory'/'$python_filename
rust_fullpath=$directory'/'$rust_filename
script_fullpath=$directory'/'$script_filename
src_fullpath=$directory'/'$src_filename

# process flags

flags_found=false

no_header_flag=true

while (($OPTIND <= $#)) ; do

    while getopts $genflags$specflags o ; do

        flags_found=true

        case $o in

            b)
                shell=$OPTARG
            ;;

            c)
                table_of_contents=true
            ;;

            d)
                latex_date=true
            ;;

            e)
                open_editor=true
            ;;

            f)
                overwrite=true
            ;;

            H)
                no_header_flag=false
                header=true
            ;;

            i)
                include_io=true
            ;;

            l)
                link_stylecss=true
            ;;

            m)
                case $filetype in
                    c|c++|cc|cpp)
                        main=true
                        main_args=$OPTARG

                        if [[ $main_args == '' ]] ; then
                            main_args="void"
                        fi
                    ;;

                    hs)
                        hs_main=true
                    ;;

                    idr)
                        idr_main=true
                    ;;

                    rs)
                        rs_main=true
                    ;;

                    *)
                        echo "error: option 'm' invalid for filetype"
                        exit 1
                    ;;
                esac
            ;;

            M)
                module=true
            ;;

            n)
                no_ext=true
            ;;

            q)
                quiet=true
            ;;

            r)
                shebang=true
            ;;

            R)
                requirements=true
            ;;

            s)
                src=true
            ;;

            t)
                case $filetype in
                    c|c++|cc|cpp)
                        struct=true
                    ;;
                    html)
                        html_title=true
                    ;;
                    tex)
                        latex_title=true
                    ;;
                    *)
                        echo "error: option 't' invalid for filetype"
                        exit 1
                    ;;
                esac
            ;;

            u)
                no_header_flag=false
                header=true
                src=true
                unit=true
            ;;

            x)
                xtrace=true
            ;;

            X)
                nonzero_exit=true
            ;;

            h)
                echo "\
ignoring -h: use -H for headers
help syntax: scrip -h, scrip --help"
            ;;

        esac

    done

    OPTIND=$((OPTIND+1))

done

# catch main

if [[ $name == "main" || $name == "Main" ]] ; then
    hs_main=true
    idr_main=true
    rs_main=true
    main=true
    include_io=true
fi

# if no flag or extension was provided, set defaults

if ! $header && ! $src && ! $script && ! $graphviz && ! $haskell && ! $idris\
  && ! $nix && ! $python && ! $rust; then
    case $filetype in

        c++|c|cc|cpp)   # default c family: create compilation unit

            if [[ $name != "main" ]] ; then
                header=true
            fi

            if [[ $name == "main" ]] ; then
                include_io=true
            fi

            src=true
        ;;

        gv)         # default graphviz
            graphviz=true
        ;;

        hs)         # default haskell: create file with main
            hs_main=true
        ;;

        idr)        # default idris: create file with main
            idr_main=true
        ;;

        nix)         # default nix: create nix derivation
            nix=true
        ;;

        py)         # default python: create python script
            python=true
        ;;

        rs)         # default rust: create file with main
            rs_main=true
        ;;

        sh)         # default shell: create shell script
            script=true
        ;;

    esac
fi

# messages for invalid options

if ! $src && ! $haskell && ! $idris && ! $rust && ! $latex && $include_io ; then
    echo "warning: include io specified but no source file created"
fi

if ! $src && ! $haskell && ! $idris && ! $rust && ! $latex && $main ; then
    echo "warning: main specified but no source file created"
fi

if ! $header && $struct ; then
    echo "ignoring -t struct: no header file created"
fi

if $latex && ! $latex_title && $latex_date ; then
    echo "ignoring -d date: title not specified"
fi

# file creation

header_created=

if $header ; then
    create_c_header $directory $header_ext $name $overwrite $quiet $struct

    header_created=$directory'/'$name'.'$header_ext
fi

if $src ; then
    create_c_src $directory $src_ext $header_ext $name $overwrite $quiet $no_header_flag $main $main_args $include_io

    src_created=$directory'/'$name'.'$src_ext
fi

if $graphviz ; then
    create_graphviz $directory $graphviz_ext $name $overwrite $quiet

    graphviz_created=$directory'/'$name'.'$graphviz_ext
fi

if $haskell ; then
    create_haskell_source $directory $haskell_ext $name $overwrite $quiet $hs_main $module $shebang

    haskell_created=$directory'/'$name'.'$haskell_ext
fi

if $html ; then
    create_html $directory $html_ext $name $overwrite $quiet $html_title $link_stylecss

    html_created=$directory'/'$name'.'$html_ext
fi

if $idris ; then
    create_idris_source $directory $idris_ext $name $overwrite $quiet $idr_main $module

    idris_created=$directory'/'$name'.'$idris_ext
fi

if $markdown ; then

    create_markdown $directory $markdown_ext $name $overwrite $quiet $no_ext $link_stylecss $requirements

    if $no_ext ; then
        markdown_created=$directory'/'$name
    else
        markdown_created=$directory'/'$name'.'$markdown_ext
    fi

fi

if $nix ; then

    create_nix_derivation $directory $nix_ext $name $overwrite $quiet

    nix_created=$directory'/'$name'.'$nix_ext
fi

if $python ; then

    create_py_script $directory $python_ext $name $overwrite $quiet

    python_created=$directory'/'$name'.'$python_ext
fi

if $rust ; then

    create_rust_source $directory $rust_ext $name $overwrite $quiet $rs_main

    rust_created=$directory'/'$name'.'$rust_ext
fi

if $script ; then

    create_sh_script $directory $script_ext $shell $name $overwrite $quiet $xtrace $nonzero_exit $no_ext

    if $no_ext ; then
        script_created=$directory'/'$name
    else
        script_created=$directory'/'$name'.'$script_ext
    fi

fi

if $latex ; then

    create_latex $directory $latex_ext $name $overwrite $quiet $table_of_contents $latex_title $latex_date

    latex_created=$directory'/'$name'.'$latex_ext

fi

if $texinfo ; then

    create_texinfo $directory $texinfo_ext $name $overwrite $quiet

    texinfo_created=$directory'/'$name'.'$texinfo_ext

fi

if $open_editor; then
    vim $header_created $src_created $script_created $markdown_created \
      $graphviz_created $haskell_created $idris_created $latex_created \
      $nix_created $python_created $rust_created
fi

# exit

exit 0
