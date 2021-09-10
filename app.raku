use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Hub;
use Misc;
use Cro::HTTP::Client;

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

    get -> 'repo', *@path {
        my $allow = False;
        for request.headers {
            $allow = True if .name eq "User-Agent" and .value ~~ /^^ 'curl' \S*/;
        }
        unless $allow {
          warn "not allowed";
          return bad-request();
        }
        cache-control :public, :max-age(300);
        static 'repo', @path;
    }

    get -> 'js', *@path {
        cache-control :public, :max-age(300);
        static 'js', @path;
    }

    get -> 'login', {

      redirect :permanent, "https://github.com/login/oauth/authorize?client_id={%*ENV<OAUTH_CLIENT_ID>}&state={%*ENV<OAUTH_STATE>}"

    }


    get -> 'oauth2', :$state, :$code {

      my $resp = await Cro::HTTP::Client.get: 'https://github.com/login/oauth/access_token',
        query => { 
          redirect_uri => "https://sparrowhub.io/oauth2",
          client_id => %*ENV<OAUTH_CLIENT_ID>,
          client_secret => %*ENV<OAUTH_CLIENT_SECRET>,
          code => $code,
          state => $state,    
        };

      my $data = await $resp.body-text();
      template 'templates/oauth2.crotmp', %( 
        resp => "authenticated ok",
      );
      
    } 
}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<localhost>, :port<5000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}

