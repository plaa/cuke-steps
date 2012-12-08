cuke-steps
==========

Cucumber step documentation.

This is a small script that reads Cucumber/Gherkin step definition files and outputs pretty-printed documentation of those steps.  It is meant as a tool for developers to easily see what step definitions already exist.

Currently the only output format supported is the format for a Confluence wiki.  The documentation can be pushed into a wiki using the [Confluence Publisher Plugin] [cpp] for Jenkins.  An HTML outputter should be easy to implement.

  [cpp]: https://wiki.jenkins-ci.org/display/JENKINS/Confluence+Publisher+Plugin

Usage
-----

  ruby cuke-steps.rb &lt;directories...&gt;

This will scan the provided directories for step definition files (*.rb) and output a file named 'steps.cf'.
