use v6;

unit module Hub;
use JSON::Tiny;
use Misc;

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

sub plugin-deploy ( Str $name, Str $version ) is export {


  if "{cache-root()}/$name/$version".IO !~~ :d {
    say "deploy {repo-root()}/{$name}-v{$version}.tar.gz ->  {cache-root()}/$name/$version";
    mkdir "{cache-root()}/$name/";
    mkdir "{cache-root()}/$name/$version";
    shell "tar -xzf {repo-root()}/{$name}-v{$version}.tar.gz -C {cache-root()}/$name/$version";

    unless "{cache-root()}/$name/$version/README.html".IO ~~ :e {
      say "generate html doc for {cache-root()}/$name/$version/README.md";
      my $html = html-doc("{cache-root()}/$name/$version/README.md");
      spurt "{cache-root()}/$name/$version/README.html", $html;
    }

  }
  
  my %meta = from-json("{cache-root()}/$name/$version/sparrow.json".IO.slurp);

  if "{cache-root()}/$name/$version/README.md".IO ~~ :f {
    %meta<readme> = "{cache-root()}/$name/$version/README.md".IO.slurp;
    %meta<doc-file> = "{cache-root()}/$name/$version/README.md";
    %meta<readme-html> = "{cache-root()}/$name/$version/README.html".IO.slurp;
  }

  %meta<date> = DateTime.new(
    "{cache-root()}/$name/$version/sparrow.json".IO.modified,
    formatter => { 
      sprintf "%02d/%02d/%04d", .month, .day, .year
    }
  );

  return %meta;

}

sub plugin-search ( Str $q ) is export {

  my @out;

  mkdir cache-root();

  my $num = 0;

  for index-file().IO.lines -> $l {

      my @a = $l.split(/\s+/);
      my $name = @a[0];
      my $version = @a[1];

      my %plg-meta = plugin-deploy($name,$version);

      if $q eq 'all' {
        push @out, %(
          name => $name,
          version => $version,
          description => %plg-meta<description>,
          num => ++$num,
        );
        next;
      }

      if $name ~~ /<$q>/ {
        push @out, %(
          name => $name,
          version => $version,
          description => %plg-meta<description>,
          num => ++$num,
        );
        next;
      }

      if %plg-meta<description>:exists && %plg-meta<description> ~~ /<$q>/ {
        push @out, %(
          name => $name,
          version => $version,
          description => %plg-meta<description>,
          num => ++$num,
        );
        next;
      }

      if %plg-meta<category>:exists && %plg-meta<category> ~~ /<$q>/ {
        push @out, %(
          name => $name,
          version => $version,
          description => %plg-meta<description>,
          num => ++$num,
        );
        next;
      }

      if %plg-meta<url>:exists && %plg-meta<url> ~~ /<$q>/ {
        push @out, %(
          name => $name,
          version => $version,
          description => %plg-meta<description>,
          num => ++$num,
        );
        next;
      }

  }

  return @out;
}
