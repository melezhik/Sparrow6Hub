use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Hub;
use Misc;

my $application = route {


    get -> 'search', Str :$q {

      my @results = plugin-search($q||"all");

      template 'templates/search.crotmp', %( 
        results => @results,
        plg-cnt => @results.elems,
        q => $q
      )
    }

    get -> 'plugin', Str $name, Str $version {
        my %plg = plugin-deploy($name,$version);
        #%plg<html-doc> = html-doc(%plg<doc-file>); 
        template 'templates/plugin.crotmp', %plg; 
    }

    get -> {
      template 'templates/main.crotmp', %( 
        plg-cnt => plugins-cnt
      )
    }

    get -> 'repo', *@path {
        cache-control :public, :max-age(300);
        static 'repo', @path;
    }
    
}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}

