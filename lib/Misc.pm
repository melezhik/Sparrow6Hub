use v6;

unit module Misc;

use Sparrow6::DSL;

sub html-doc ( Str $doc-file ) is export {
  my %state =  task-run "readme html", "text-markdown", %(
    file => $doc-file
  );
  return  %state<html> ;
}


