##
#  extconf.rb: Ruby extension configuration
#
#  Copyright (C) 200 Red Hat Inc.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# Author: Bryan Kearney <bkearney@redhat.com>
##

require 'fileutils'
require 'mini_portile2'
require 'mkmf'

# Bundler doesn't enforce gem version constraints at install-time (only at run-time).
require 'rubygems'
gem 'mini_portile2'

# A wrapper around MiniPortile to cut down on boilerplate code.
def process_recipe(name, version)
  MiniPortile.new(name, version).tap do |recipe|
    recipe.target = File.expand_path('../../ports', File.dirname(__FILE__))
    recipe.host = RbConfig::CONFIG['host_alias'].empty? ? RbConfig::CONFIG['host'] : RbConfig::CONFIG['host_alias']

    yield recipe

    # Extract environment variables from the `configure` options.
    env = {}
    recipe.configure_options.delete_if do |option|
      case option
      when /\A(\w+)=(.*)\z/
        env[$1] = $2
        true
      else
        false
      end
    end

    recipe.configure_options += [
      '--disable-shared',
      '--enable-static',
    ]
    env['CFLAGS'] = '-fPIC'

    # Convert the `env` hash back into `configure` options.
    recipe.configure_options += env.map do |key, value|
      "#{key}=#{value}"
    end

    unless File.exist?("#{recipe.target}/#{recipe.host}/#{recipe.name}/#{recipe.version}")
      recipe.cook
    end

    recipe.activate

    pkg_config_path = (env['PKG_CONFIG_PATH'] || '').split(':').unshift("#{recipe.path}/lib/pkgconfig")
    pkg_config_cmd = "PKG_CONFIG_PATH=#{pkg_config_path.join(':')} pkg-config #{recipe.name}"

    # Add module's `CFLAGS` to our own `CFLAGS`.
    $CPPFLAGS = `#{pkg_config_cmd} --cflags`.strip << ' ' << $CPPFLAGS

    # Add module's libs to our own `$libs` and `$LIBPATH`.
    $libs = $libs.shellsplit.tap do |libs|
      `#{pkg_config_cmd} --libs`.strip.shellsplit.each do |arg|
        case arg
        when /\A-L(.+)\z/
          $LIBPATH = [$1] | $LIBPATH
        when /\A-l./
          libs.unshift(arg)
        else
          $LDFLAGS << ' ' << arg.shellescape
        end
      end
    end.shelljoin
  end
end

libxml_recipe = process_recipe('libxml-2.0', '2.9.4') do |recipe|
  recipe.files = [{
    url: "http://xmlsoft.org/sources/libxml2-#{recipe.version}.tar.gz",
    sha256: 'ffb911191e509b966deb55de705387f14156e1a56b21824357cdf0053233633c',
  }]

  # Disable most of the optional components, because we don't need them.
  recipe.configure_options += [
    '--without-c14n',
    '--without-catalog',
    '--without-debug',
    '--without-docbook',
    '--without-ftp',
    '--without-html',
    '--without-http',
    '--without-iconv',
    '--without-icu',
    '--without-iso8859x',
    '--without-legacy',
    '--without-pattern',
    '--without-push',
    '--without-python',
    '--without-reader',
    '--without-readline',
    '--without-regexps',
    '--without-sax1',
    '--without-schemas',
    '--without-schematron',
    '--without-valid',
    '--without-writer',
    '--without-xinclude',
    '--without-xpath',
    '--without-xptr',
    '--without-modules',
  ]
end

augeas_recipe = process_recipe('augeas', '1.8.1') do |recipe|
  recipe.files = [{
    url: "http://download.augeas.net/augeas-#{recipe.version}.tar.gz",
    sha256: '65cf75b5a573fee2a5c6c6e3c95cad05f0101e70d3f9db10d53f6cc5b11bc9f9',
  }]
  recipe.configure_options += [
    "PKG_CONFIG_PATH=#{libxml_recipe.path}/lib/pkgconfig",
  ]

  $libs = append_library($libs, 'fa')
end

create_makefile('_augeas')
