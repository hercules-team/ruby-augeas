# -*- ruby -*-
# Rakefile: build ruby auges bindings
#
# Copyright (C) 2008 Red Hat, Inc.
#
# Distributed under the GNU Lesser General Public License v2.1 or later.
# See COPYING for details
#
# Bryan Kearney <bkearney@redhat.com>

require 'fileutils'
require 'rake/clean'
require 'rake/extensiontask'
require 'rdoc/task'
require 'rubygems/package'
require 'rubygems/package_task'
require 'zlib'

CLEAN.include [
  'pkg/*/',
  'ports/',
  'tmp/',
]
CLOBBER.include [
  'doc/',
  'lenses/',
  'lib/augeas/_augeas.so',
  'pkg/*.gem',
]

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_dir = 'doc/site/api'
  rdoc.rdoc_files.include('README.md', 'ext/augeas/*.[ch]', 'lib/**/*.rb')
end

spec = Gem::Specification.new do |spec|
  spec.name        = 'ruby-augeas'
  spec.version     = '0.5.0'
  spec.summary     = 'Ruby bindings for augeas'
  spec.description = 'Provides bindings for augeas.'
  spec.authors     = ['Bryan Kearney', 'David Lutterkort']
  spec.email       = 'augeas-devel@redhat.com'
  spec.homepage    = 'http://augeas.net/'

  spec.required_ruby_version = '>= 2.0'

  spec.files = Dir[
    'ext/augeas/*.[ch]',
    'lenses/*.aug',
    'lib/**/*.rb',
  ]
  spec.extensions = ['ext/augeas/extconf.rb']
end
task gem: ['lenses']

pkg_task = Gem::PackageTask.new(spec) do |pkg|
end

desc 'Extract augeas lenses from source archive'
directory 'lenses' => [augeas_tgz = 'ports/archives/augeas-1.8.1.tar.gz'] do
  Gem::Package::TarReader.new(Zlib::GzipReader.open(augeas_tgz)) do |tar|
    FileUtils.mkdir_p('lenses')
    lenses = []

    tar.each do |entry|
      next unless File.fnmatch?('augeas-*/lenses/*.aug', entry.full_name, File::FNM_PATHNAME)

      dest = File.join('lenses', File.basename(entry.full_name))
      puts "Copying #{entry.full_name} to #{dest}"
      File.open(dest, 'wb') { |file| file.write(entry.read) }
      lenses << dest
    end

    # We need to add the lenses to the gemspec as `Dir.glob` is evaluated
    # before the `lenses/` directory exists.
    spec.files += lenses
    pkg_task.package_files += lenses
  end
end

file 'ports/archives/augeas-1.8.1.tar.gz' => 'compile:_augeas'

Rake::ExtensionTask.new('_augeas', spec) do |ext|
  ext.ext_dir        = 'ext/augeas'
  ext.lib_dir        = 'lib/augeas'
  ext.cross_compile  = true
  ext.cross_platform = ['x86-linux', 'x86_64-linux']
end

desc 'Build the native gem file under rake_compiler_dock'
task 'gem:native' do
  require 'rake_compiler_dock'

  RakeCompilerDock.sh [
    'sudo apt-get --quiet --quiet --yes install libreadline-dev:amd64 libreadline-dev:i386 zlib1g-dev:amd64 zlib1g-dev:i386',
    'bundle install --quiet',
    'rake cross native gem',
  ].join(' && ')
end
