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

def solaris?
  RbConfig::CONFIG['target_os'] =~ /solaris/
end


if solaris?
  $CFLAGS += " -I/usr/include/libxml2"
  unless have_library("augeas")
    raise "libaugeas not installed"
  end
  unless have_library("xml2")
      raise "libxml2 not installed"
  end
else
  unless pkg_config("augeas")
    raise "augeas-devel not installed"
  end

  unless pkg_config("libxml-2.0")
    raise "libxml2-devel not installed"
  end
end

create_makefile(extension_name)
