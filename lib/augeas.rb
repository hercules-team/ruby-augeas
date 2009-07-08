##
#  augeas.rb: Ruby wrapper for augeas
#
#  Copyright (C) 2008 Red Hat Inc.
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

require "_augeas"

# Wrapper class for the augeas[http://augeas.net] library.
class Augeas
    private_class_method :new

    # Clear the +path+, i.e. make its value +nil+
    def clear(path)
        set(path, nil)
    end

    # Clear all transforms under <tt>/augeas/load</tt>. If +load+
    # is called right after this, there will be no files
    # under +/files+
    def clear_transforms
        rm("/augeas/load/*")
    end

    # Add a transform under <tt>/augeas/load</tt>
    #
    # The HASH can contain the following entries
    # * <tt>:lens</tt> - the name of the lens to use
    # * <tt>:name</tt> - a unique name; use the module name of the LENS when omitted
    # * <tt>:incl</tt> - a list of glob patterns for the files to transform
    # * <tt>:excl</tt> - a list of the glob patterns to remove from the list that matches <tt>:INCL</tt>
    def transform(hash)
        lens = hash[:lens]
        name = hash[:name]
        incl = hash[:incl]
        excl = hash[:excl] || ""
        raise ArgumentError, "No lens specified" unless lens
        raise ArgumentError, "No files to include" unless incl
        name = lens.split(".")[0].sub("@", "") unless name
        incl = [ incl ] unless incl.is_a?(Array)
        excl = [ excl ] unless incl.is_a?(Array)

        xfm = "/augeas/load/#{name}/"
        set(xfm + "lens", lens)
        incl.each { |inc| set(xfm + "incl[last()+1]", inc) }
        excl.each { |exc| set(xfm + "excl[last()+1]", exc) }
    end
end
