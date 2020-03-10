use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Hub;

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
        template 'templates/plugin.crotmp', %plg; 
    }

    get -> {
      template 'templates/main.crotmp', %( 
        plg-cnt => plugins-cnt
      )
    }


}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}

