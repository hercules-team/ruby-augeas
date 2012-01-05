##
#  augeas.rb: Ruby wrapper for augeas
#
#  Copyright (C) 2011 SUSE LINUX Products GmbH, Nuernberg, Germany.
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
# Author: Ionuț Arțăriși <iartarisi@suse.cz>
##

require "_augeas"
require "augeas_old"


# Wrapper class for the augeas[http://augeas.net] library.
class Augeas
  private_class_method :new

  class Error                   < RuntimeError; end
  class NoMemoryError           < Error; end
  class InternalError           < Error; end
  class InvalidPathError        < Error; end
  class NoMatchError            < Error; end
  class MultipleMatchesError    < Error; end
  class LensSyntaxError         < Error; end
  class LensNotFoundError       < Error; end
  class MultipleTransformsError < Error; end
  class NoSpanInfoError         < Error; end
  class DescendantError         < Error; end
  class CmdExecError            < Error; end
  @@error_hash = {
    # the cryptic error names come from the C library, we just make
    # them more ruby and more human
    ENOMEM    => NoMemoryError,
    EINTERNAL => InternalError,
    EPATHX    => InvalidPathError,
    ENOMATCH  => NoMatchError,
    EMMATCH   => MultipleMatchesError,
    ESYNTAX   => LensSyntaxError,
    ENOLENS   => LensNotFoundError,
    EMXFM     => MultipleTransformsError,
    ENOSPAN   => NoSpanInfoError,
    EMVDESC   => DescendantError,
    ECMDRUN   => CmdExecError }


  # DEPRECATED. Create a new Augeas instance and return it.
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
  def self.open(root=nil, loadpath=nil, flags=Augeas::NONE, &block)
    return AugeasOld.open(root, loadpath, flags)
  end

  def self.create(root=nil, loadpath=nil, flags=Augeas::NONE, &block)
    return Augeas.open3(nil, nil, Augeas::NONE)
  end
end
