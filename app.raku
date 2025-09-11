use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Hub;
use Misc;
use Cro::HTTP::Client;
use JSON::Tiny;

my $application = route {

    my %conf = get-webui-conf();
  
    my $theme;
  
    if %conf<ui> && %conf<ui><theme> {
      $theme = %conf<ui><theme>
    } else {
      $theme = "lumen";
    };

    say "ui theme: <$theme> ...";

    get -> 'search', Str :$q {

      my @results = plugin-search($q||"all");

      template 'templates/search.crotmp', %( 
        results => @results,
        plg-cnt => @results.elems,
        q => $q,
        theme => $theme
      )
    }

    get -> 'plugin', Str $name, Str $version {
        my %plg = plugin-deploy($name,$version);
        #%plg<html-doc> = html-doc(%plg<doc-file>);
        %plg<theme> = $theme; 
        template 'templates/plugin.crotmp', %plg; 
    }

    get -> {
      template 'templates/main.crotmp', %( 
        plg-cnt => plugins-cnt,
        theme => $theme
      )
    }

    get -> 'examples' {
      template 'templates/examples.crotmp', %( 
        theme => $theme,
        plg-cnt => plugins-cnt,
      )
    }

    get -> 'repo', *@path {

        my $allow = False;

        for request.headers {
            $allow = True if .name eq "User-Agent" and .value ~~ /^^ 'curl' \S*/;
            $allow = True if .name eq "User-Agent" and .value ~~ m:i/^^ 'wget' \S*/;
        }

        if $allow {
          cache-control :public, :max-age(300);
          static 'repo', @path;

        } else { 

          #return bad-request();
          warn "not allowed";
          redirect :permanent, "/";

        }

    }

    get -> 'js', *@path {
        cache-control :public, :max-age(5);
        static 'js', @path;
    }

    get -> 'logos', *@path {

      cache-control :public, :max-age(3000);
      static 'logos', @path;

    }
}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host(%*ENV<SPH_HOST> || "localhost"), :port(%*ENV<SPH_PORT> || 5000), :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}

