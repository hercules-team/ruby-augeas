# -*- coding: utf-8 -*-
##
#  augeas.rb: Ruby wrapper for augeas
#
#  Copyright (C) 2008 Red Hat Inc.
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
# Authors: Ionuț Arțăriși <iartarisi@suse.cz>
#          Bryan Kearney <bkearney@redhat.com>
#          Artem Sheremet <dot.doom@gmail.com>
##

# Do not require this file explicitly; instead require "augeas"

# Wrapper class for the augeas[http://augeas.net] library.
class Augeas::Facade
  private_class_method :new

  def self.create(opts={}, &block)
    # aug_flags is a bitmask in the underlying library, we add all the
    # values of the flags which were set to true to the default value
    # Augeas::NONE (which is 0)
    aug_flags = defined?(Augeas::NO_ERR_CLOSE) ? Augeas::NO_ERR_CLOSE : Augeas::NONE

    flags = {
      :type_check => Augeas::TYPE_CHECK,
      :no_stdinc => Augeas::NO_STDINC,
      :no_load => Augeas::NO_LOAD,
      :no_modl_autoload => Augeas::NO_MODL_AUTOLOAD,
      :enable_span => Augeas::ENABLE_SPAN
    }
    save_modes = {
      :backup => Augeas::SAVE_BACKUP,
      :newfile => Augeas::SAVE_NEWFILE,
      :noop => Augeas::SAVE_NOOP
    }
    opts.each_key do |key|
      if flags.key? key
        aug_flags |= flags[key]
      elsif key == :save_mode
        if save_modes[opts[:save_mode]]
          aug_flags |= save_modes[opts[:save_mode]]
        else
          raise ArgumentError, "Invalid save mode #{opts[:save_mode]}."
        end
      elsif key != :root && key != :loadpath
        raise ArgumentError, "Unknown argument #{key}."
      end
    end

    aug = Augeas::Facade::open3(opts[:root], opts[:loadpath], aug_flags)

    begin
      aug.send(:raise_last_error)
    rescue
      aug.close
      raise
    end

    if block_given?
      begin
        yield aug
      ensure
        aug.close
      end
    else
      return aug
    end
  end

  # Get the value associated with +path+.
  def get(path)
    run_command :augeas_get, path
  end

  # Return true if there is an entry for this path, false otherwise
  def exists(path)
    run_command :augeas_exists, path
  end

  # Set one or multiple elements to path.
  # Multiple elements are mainly sensible with a path like
  # .../array[last()+1], since this will append all elements.
  def set(path, *values)
    values.flatten.each { |v| run_command :augeas_set, path, v }
  end

  # Set multiple nodes in one operation.  Find or create a node matching SUB
  # by interpreting SUB as a  path expression relative to each node matching
  # BASE. If SUB is '.', the nodes matching BASE will be modified.

  # +base+    the base node
  # +sub+     the subtree relative to the base
  # +value+   the value for the nodes
  def setm(base, sub, value)
    run_command :augeas_setm, base, sub, value
  end

  # Remove all nodes matching path expression +path+ and all their
  # children.
  # Raises an <tt>Augeas::InvalidPathError</tt> when the +path+ is invalid.
  def rm(path)
    run_command :augeas_rm, path
  end

  # Return an Array of all the paths that match the path expression +path+
  #
  # Returns an empty Array if no paths were found.
  # Raises an <tt>Augeas::InvalidPathError</tt> when the +path+ is invalid.
  def match(path)
    run_command :augeas_match, path
  end

  # Create the +path+ with empty value if it doesn't exist
  def touch(path)
    set(path, nil) if match(path).empty?
  end

  # Evaluate +expr+ and set the variable +name+ to the resulting
  # nodeset. The variable can be used in path expressions as $name.
  # Note that +expr+ is evaluated when the variable is defined, not when
  # it is used.
  def defvar(name, expr)
    run_command :augeas_defvar, name, expr
  end

  # Define the variable +name+ to the result of evaluating +expr+, which
  # must be a nodeset.  If no node matching +expr+ exists yet, one is
  # created and +name+ will refer to it.  When a node is created and
  # +value+ is given, the new node's value is set to +value+.
  def defnode(name, expr, value=nil)
    run_command :augeas_defnode, name, expr, value
  end

  # Clear the +path+, i.e. make its value +nil+
  def clear(path)
    augeas_set(path, nil)
  end

  # Add a transform under <tt>/augeas/load</tt>
  #
  # The HASH can contain the following entries
  # * <tt>:lens</tt> - the name of the lens to use
  # * <tt>:name</tt> - a unique name; use the module name of the LENS
  # when omitted
  # * <tt>:incl</tt> - a list of glob patterns for the files to transform
  # * <tt>:excl</tt> - a list of the glob patterns to remove from the
  # list that matches <tt>:incl</tt>
  def transform(hash)
    lens = hash[:lens]
    name = hash[:name]
    incl = hash[:incl]
    excl = hash[:excl]
    raise ArgumentError, "No lens specified" unless lens
    raise ArgumentError, "No files to include" unless incl
    name = lens.split(".")[0].sub("@", "") unless name

    xfm = "/augeas/load/#{name}/"
    set(xfm + "lens", lens)
    set(xfm + "incl[last()+1]", incl)
    set(xfm + "excl[last()+1]", excl) if excl
  end

  # Clear all transforms under <tt>/augeas/load</tt>. If +load+
  # is called right after this, there will be no files
  # under +/files+
  def clear_transforms
    rm("/augeas/load/*")
  end

  # Write all pending changes to disk.
  # Raises <tt>Augeas::CommandExecutionError</tt> if saving fails.
  def save
    begin
      run_command :augeas_save
    rescue Augeas::CommandExecutionError => e
      raise e, 'Saving failed. Search the augeas tree in /augeas//error ' <<
        'for the actual errors.'
    end

    nil
  end

  def clearm(path, sub)
    setm(path, sub, nil)
  end

  # Load files according to the transforms in /augeas/load or those
  # defined via <tt>transform</tt>.  A transform Foo is represented
  # with a subtree /augeas/load/Foo.  Underneath /augeas/load/Foo, one
  # node labeled 'lens' must exist, whose value is the fully
  # qualified name of a lens, for example 'Foo.lns', and multiple
  # nodes 'incl' and 'excl' whose values are globs that determine
  # which files are transformed by that lens. It is an error if one
  # file can be processed by multiple transforms.
  def load
    begin
      run_command :augeas_load
    rescue Augeas::CommandExecutionError => e
      raise e, "Loading failed. Search the augeas tree in /augeas//error"+
        "for the actual errors."
    end

    nil
  end

  # Move node +src+ to +dst+. +src+ must match exactly one node in
  # the tree. +dst+ must either match exactly one node in the tree,
  # or may not exist yet. If +dst+ exists already, it and all its
  # descendants are deleted. If +dst+ does not exist yet, it and all
  # its missing ancestors are created.
  #
  # Raises <tt>Augeas::NoMatchError</tt> if the +src+ node does not exist
  # Raises <tt>Augeas::MultipleMatchesError</tt> if there were
  # multiple matches in +src+
  # Raises <tt>Augeas::DescendantError</tt> if the +dst+ node is a
  # descendant of the +src+ node.
  def mv(src, dst)
    run_command :augeas_mv, src, dst
  end

  # Get the filename, label and value position in the text of this node
  #
  # Raises <tt>Augeas::NoMatchError</tt> if the node could not be found
  # Raises <tt>Augeas::NoSpanInfo</tt> if the node associated with
  # +path+ doesn't belong to a file or doesn't exist
  def span(path)
    run_command :augeas_span, path
  end

  # Run one or more newline-separated commands specified by +text+,
  # returns an array of [successful_commands_number, output] or
  # [-2, output] in case 'quit' command has been encountered.
  # Raises <tt>Augeas::CommandExecutionError</tt> if gets an invalid command
  def srun(text)
    run_command(:augeas_srun, text)
  end

  # Lookup the label associated with +path+
  # Raises <tt>Augeas::NoMatchError</tt> if the +path+ node does not exist
  def label(path)
    run_command :augeas_label, path
  end

  # Rename the label of all nodes matching +path+ to +label+
  # Raises <tt>Augeas::NoMatchError</tt> if the +path+ node does not exist
  # Raises <tt>Augeas::InvalidLabelError</tt> if +label+ is invalid
  def rename(path, label)
    run_command :augeas_rename, path, label
  end

  # Use the value of node +node+ as a string and transform it into a tree
  # using the lens +lens+ and store it in the tree at +path+,
  # which will be overwritten. +path+ and +node+ are path expressions.
  def text_store(lens, node, path)
    run_command :augeas_text_store, lens, node, path
  end

  # Transform the tree at +path+ into a string lens +lens+ and store it
  # in the node +node_out+, assuming the tree was initially generated using
  # the value of node +node_in+. +path+, +node_in+ and +node_out+ are path expressions.
  def text_retrieve(lens, node_in, path, node_out)
    run_command :augeas_text_retrieve, lens, node_in, path, node_out
  end

  # Make +label+ a sibling of +path+ by inserting it directly before
  # or after +path+.
  # The boolean +before+ determines if +label+ is inserted before or
  # after +path+.
  def insert(path, label, before)
    run_command :augeas_insert, path, label, before
  end

  # Set path expression context to +path+ (in /augeas/context)
  def context=(path)
    set('/augeas/context', path)
  end

  # Get path expression context (from /augeas/context)
  def context
    get('/augeas/context')
  end

  private

  # Run a command and raise any errors that happen due to execution.
  #
  # +cmd+ name of the Augeas command to run
  # +params+ parameters with which +cmd+ will be called
  #
  # Returns whatever the original +cmd+ returns
  def run_command(cmd, *params)
    result = self.send cmd, *params

    raise_last_error

    if result.kind_of? Integer and result < 0
      # we raise CommandExecutionError here, because this is the error that
      # augtool raises in this case as well
      raise Augeas::CommandExecutionError, "Command failed. Return code was #{result}."
    end

    return result
  end

  def raise_last_error
    error_cache = error
    unless error_cache[:code].zero?
      raise Augeas::ERRORS_HASH[error_cache[:code]], "#{error_cache[:message]} #{error_cache[:details]}"
    end
  end
end
