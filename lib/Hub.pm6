use v6;

unit module Hub;


sub plugins-cnt () is export {

  "{%*ENV<HOME>}/sparrow6/index".IO.lines.elems

}
