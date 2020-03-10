use v6;

unit module Hub;


sub repo-root () {

  "/usr/share/repo/plugins"

}


sub index-file () {

  "/usr/share/repo/api/v1/index"

}

sub cache-root () {

  "{%*ENV<HOME>}/.hub"

}

sub plugins-cnt () is export {

  index-file().IO.lines.elems

}


sub plugins-search ( Str $q ) is export {

  my @out;

  mkdir cache-root();

  for index-file().IO.lines -> $l {

      my @a = $l.split(/\s+/);
      my $name = @a[0];
      my $version = @a[1];

      if "{cache-root()}/$name/$version".IO !~~ :d {
        say "deploy {repo-root()}/{$name}-v{$version}.tar.gz ->  {cache-root()}/$name/$version";
        mkdir "{cache-root()}/$name/";
        mkdir "{cache-root()}/$name/$version";
        shell "tar -xzf {repo-root()}/{$name}-v{$version}.tar.gz -C {cache-root()}/$name/$version";
      }

      if $q eq 'all' {
        push @out, $l;      
      } else {
        next unless $l ~~ /<$q>/;
        push @out, $l;      
      }
  }

  return @out;
}
