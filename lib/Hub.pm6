use v6;

unit module Hub;


sub repo-root () {

  "/usr/share/repo/plugins"

}


sub index-file () {

  "/usr/share/repo/api/v1/index"

}

sub plugins-cnt () is export {

  index-file().IO.lines.elems

}


sub plugins-search ( Str $q ) is export {

  my @out;

  for index-file().IO.lines -> $l {
      if $q eq 'all' {
        push @out, $l;      
      } else {
        next unless $l ~~ /<$q>/;
        push @out, $l;      
      }
  }

  return @out;
}
