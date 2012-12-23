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

    class Error < RuntimeError; end

    # Create a new Augeas instance and return it.
    #
    # Use +root+ as the filesystem root. If +root+ is +nil+, use the value
    # of the environment variable +AUGEAS_ROOT+. If that doesn't exist
    # either, use "/".
    #
    # +loadpath+ is a colon-spearated list of directories that modules
    # should be searched in. This is in addition to the standard load path
    # and the directories in +AUGEAS_LENS_LIB+
    #
    # +flags+ is a bitmask (see <tt>enum aug_flags</tt>)
    #
    # When a block is given, the Augeas instance is passed as the only
    # argument into the block and closed when the block exits. In that
    # case, the return value of the block is the return value of
    # +open+. With no block, the Augeas instance is returned.
    def self.open(root = nil, loadpath = nil, flags = NONE, &block)
        aug = open3(root, loadpath, flags)
        if block_given?
            begin
                rv = yield aug
                return rv
            ensure
                aug.close
            end
        else
            return aug
        end
    end

    # Set one or multiple elemens to path.
    # Multiple elements are mainly sensible with a path like
    # .../array[last()+1], since this will append all elements.
    def set(path, *values)
        values.flatten.each { |v| set_internal(path, v) }
    end

    # The same as +set+, but raises <tt>Augeas::Error</tt> if setting fails
    def set!(path, *values)
        values.flatten.each do |v|
            raise Augeas::Error unless set_internal(path, v)
        end
    end

    # Clear the +path+, i.e. make its value +nil+
    def clear(path)
        set_internal(path, nil)
    end

    # Clear multiple nodes values in one operation. Find or create a node matching +sub+
    # by interpreting +sub+ as a path expression relative to each node matching
    # +base+. If +sub+ is '.', the nodes matching +base+ will be modified.
    def clearm(base, sub)
        setm(base, sub, nil)
    end

    # Create the +path+ with empty value if it doesn't exist
    def touch(path)
        set_internal(path, nil) if match(path).empty?
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
        excl = hash[:excl]
        raise ArgumentError, "No lens specified" unless lens
        raise ArgumentError, "No files to include" unless incl
        lens = "#{lens}.lns" unless lens.include? '.'
        name = lens.split(".")[0].sub("@", "") unless name

        xfm = "/augeas/load/#{name}/"
        set(xfm + "lens", lens)
        set(xfm + "incl[last()+1]", incl)
        set(xfm + "excl[last()+1]", excl) if excl
    end

    # The same as +save+, but raises <tt>Augeas::Error</tt> if saving fails
    def save!
        raise Augeas::Error unless save
    end

    # The same as +load+, but raises <tt>Augeas::Error</tt> if loading fails
    def load!
        raise Augeas::Error unless load
    end

    # Set path expression context to +path+ (in /augeas/context)
    def context=(path)
      set_internal('/augeas/context', path)
    end

    # Get path expression context (from /augeas/context)
    def context
      get('/augeas/context')
    end

end
