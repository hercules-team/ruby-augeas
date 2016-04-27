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
require 'mkmf'

extension_name = '_augeas'

# On Darwin compile for x86_64 only and link with augeas library to avoid dyld errors. 
if RbConfig::CONFIG['target_os'] =~ /darwin/
  $CFLAGS = $CFLAGS.gsub(/\-arch\ i386/, '')
  $LDFLAGS = $LDFLAGS.gsub(/\-arch\ i386/, '')
  $LDSHARED = RbConfig::MAKEFILE_CONFIG['LDSHARED']
  RbConfig::MAKEFILE_CONFIG['LDSHARED'] = $LDSHARED.gsub(/\-arch\ i386/, '')
  $LIBS += "-laugeas"
end

# Use have_library rather than pkg_config
unless have_library("augeas")
  raise "libaugeas is not installed"
end

pkg_config('augeas')

unless have_library("xml2")
  raise "libxml2 is not installed"
end

pkg_config('libxml-2.0')

create_makefile(extension_name)
