##
#  Augeas tests
#
#  Copyright (C) 2011 Red Hat Inc.
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
# Authors: David Lutterkort <dlutter@redhat.com>
#          Ionuț Arțăriși <iartarisi@suse.cz>
##

require 'test/unit'

TOPDIR = File::expand_path(File::join(File::dirname(__FILE__), ".."))

$:.unshift(File::join(TOPDIR, "lib"))
$:.unshift(File::join(TOPDIR, "ext", "augeas"))

require 'augeas'
require 'fileutils'

class TestAugeas < Test::Unit::TestCase

  SRC_ROOT = File::expand_path(File::join(TOPDIR, "tests", "root")) + "/."
  TST_ROOT = File::expand_path(File::join(TOPDIR, "build", "root")) + "/"

  def test_basics
    aug = aug_create(:save_mode => :newfile)
    assert_equal("newfile", aug.get("/augeas/save"))
    assert_equal(TST_ROOT, aug.get("/augeas/root"))

    assert(aug.exists("/augeas/root"))
    assert_not_nil(aug.get("/augeas/root"))
    node = "/ruby/test/node"
    assert_nothing_raised {
      aug.set(node, "value")
    }
    assert_equal("value", aug.get(node))
    assert_nothing_raised {
      aug.clear(node)
    }
    assert_equal(nil, aug.get(node))
    m = aug.match("/*")
    ["/augeas", "/ruby"].each do |p|
      assert(m.include?(p))
      assert(aug.exists(p))
    end
  end

  def test_no_new
    assert_raise NoMethodError do
      Augeas.new
    end
  end

  def test_create_unknown_argument
    assert_raise ArgumentError do
      Augeas::create(:bogus => false)
    end
  end

  def test_create_invalid_save_mode
    assert_raise ArgumentError do
      Augeas::create(:save_mode => :bogus)
    end
  end

  def test_create_block
    foo = nil
    Augeas::create do |aug|
      aug.set('/foo', 'bar')
      foo = aug.get('/foo')
    end
    assert_equal(foo, 'bar')
  end

    def test_load
        aug = aug_open(Augeas::NO_LOAD)
        assert_equal([], aug.match("/files/etc/*"))
        aug.rm("/augeas/load/*");
        assert_nothing_raised {
            aug.load
        }
        assert_equal([], aug.match("/files/etc/*"))
    end

    def test_transform
        aug = aug_open(Augeas::NO_LOAD)
        aug.clear_transforms
        aug.transform(:lens => "Hosts.lns",
                      :incl => "/etc/hosts")
        assert_raise(ArgumentError) {
            aug.transform(:name => "Fstab",
                          :incl => [ "/etc/fstab" ],
                          :excl => [ "*~", "*.rpmnew" ])
        }
        aug.transform(:lens => "Inittab",
                      :incl => "/etc/inittab")
        aug.transform(:lens => "Fstab.lns",
                      :incl => "/etc/fstab*",
                      :excl => "*~")
        assert_equal(["/augeas/load/Fstab", "/augeas/load/Fstab/excl",
                      "/augeas/load/Fstab/incl", "/augeas/load/Fstab/lens",
                      "/augeas/load/Hosts", "/augeas/load/Hosts/incl",
                      "/augeas/load/Hosts/lens", "/augeas/load/Inittab",
                      "/augeas/load/Inittab/incl",
                      "/augeas/load/Inittab/lens"],
                     aug.match("/augeas/load//*").sort)
        aug.load
        assert_equal(["/files/etc/hosts", "/files/etc/inittab"],
                     aug.match("/files/etc/*").sort)
    end

    def test_defvar
        Augeas::open("/dev/null") do |aug|
            aug.set("/a/b", "bval")
            aug.set("/a/c", "cval")
            assert aug.defvar("var", "/a/b")
            assert_equal(["/a/b"], aug.match("$var"))
            assert aug.defvar("var", nil)
            assert_raises(SystemCallError) {
                aug.match("$var")
            }
            assert ! aug.defvar("var", "/foo/")
        end
  end

  def test_close
    aug = Augeas::create(:root => "/tmp", :save_mode => :newfile)
    assert_equal("newfile", aug.get("/augeas/save"))
    aug.close

    assert_raise(SystemCallError) {
      aug.get("/augeas/save")
    }

    assert_raise(SystemCallError) {
      aug.close
    }
  end

  def test_mv
    Augeas::create(:root => "/dev/null") do |aug|
      aug.set("/a/b", "value")
      aug.mv("/a/b", "/x/y")
      assert_equal("value", aug.get("/x/y"))
    end
  end

  def test_mv_descendent_error
    aug = aug_create
    aug.set("/foo", "bar")
    assert_raises(Augeas::DescendantError) {aug.mv("/foo", "/foo/bar/baz")}
  end

  def test_mv_multiple_matches_error
    aug = aug_create
    aug.set("/foo/bar", "bar")
    aug.set("/foo/baz", "baz")
    assert_raises(Augeas::MultipleMatchesError) {aug.mv("/foo/*", "/qux")}
  end

  def test_mv_invalid_path_error
    aug = aug_create
    assert_raises(Augeas::InvalidPathError) {aug.mv("/foo", "[]")}
  end

  def test_mv_no_match_error
    aug = aug_create
    assert_raises(Augeas::NoMatchError) {aug.mv("/nonexistent", "/")}
  end

  def test_mv_mutiple_dest_error
    aug = aug_create
    aug.set("/foo", "bar")
    assert_raises(Augeas::CommandExecutionError) {aug.mv("/foo", "/bar/baz/*")}
  end

  def test_load
    aug = aug_create(:no_load => true)
    assert_equal([], aug.match("/files/etc/*"))
    aug.rm("/augeas/load/*");
    assert_nothing_raised {
      aug.load
    }
    assert_equal([], aug.match("/files/etc/*"))
  end

  def test_load_bad_lens
    aug = aug_create(:no_load => true)
    aug.transform(:lens => "bad_lens", :incl => "irrelevant")
    assert_raises(Augeas::LensNotFoundError) { aug.load }
    assert_equal aug.error[:details], "Can not find lens bad_lens"
  end

  def test_transform
    aug = aug_create(:no_load => true)
    aug.clear_transforms
    aug.transform(:lens => "Hosts.lns",
                  :incl => "/etc/hosts")
    assert_raise(ArgumentError) {
      aug.transform(:name => "Fstab",
                    :incl => [ "/etc/fstab" ],
                    :excl => [ "*~", "*.rpmnew" ])
    }
    aug.transform(:lens => "Inittab.lns",
                  :incl => "/etc/inittab")
    aug.transform(:lens => "Fstab.lns",
                  :incl => "/etc/fstab*",
                  :excl => "*~")
    assert_equal(["/augeas/load/Fstab", "/augeas/load/Fstab/excl",
                  "/augeas/load/Fstab/incl", "/augeas/load/Fstab/lens",
                  "/augeas/load/Hosts", "/augeas/load/Hosts/incl",
                  "/augeas/load/Hosts/lens", "/augeas/load/Inittab",
                  "/augeas/load/Inittab/incl",
                  "/augeas/load/Inittab/lens"],
                 aug.match("/augeas/load//*").sort)
    aug.load
    assert_equal(["/files/etc/hosts", "/files/etc/inittab"],
                 aug.match("/files/etc/*").sort)
  end

  def test_transform_invalid_path
    aug = aug_create
    assert_raises (Augeas::InvalidPathError) {
      aug.transform :lens => '//', :incl => 'foo' }
  end

  def test_clear_transforms
    aug = aug_create
    assert_not_equal [], aug.match("/augeas/load/*")
    aug.clear_transforms
    assert_equal [], aug.match("/augeas/load/*")
  end

  def test_clear
    aug = aug_create
    aug.set("/foo/bar", "baz")
    aug.clear("/foo/bar")
    assert_equal aug.get("/foo/bar"), nil
  end

  def test_rm
    aug = aug_create
    aug.set("/foo/bar", "baz")
    assert aug.get("/foo/bar")
    assert_equal 2, aug.rm("/foo")
    assert_nil aug.get("/foo")
  end

  def test_rm_invalid_path
    aug = aug_create
    assert_raises(Augeas::InvalidPathError) { aug.rm('//') }
  end

  def test_defvar
    Augeas::create(:root => "/dev/null") do |aug|
      aug.set("/a/b", "bval")
      aug.set("/a/c", "cval")
      assert aug.defvar("var", "/a/b")
      assert_equal(["/a/b"], aug.match("$var"))
      assert aug.defvar("var", nil)
      assert_raises(SystemCallError) {
        aug.match("$var")
      }
      assert ! aug.defvar("var", "/foo/")
    end
  end

  def test_defnode
    aug = aug_create
    assert aug.defnode("x", "/files/etc/hosts/*[ipaddr = '127.0.0.1']", nil)
    assert_equal(["/files/etc/hosts/1"], aug.match("$x"))
  end

  def test_insert_before
    aug = aug_create
    aug.set("/parent/child", "foo")
    aug.insert("/parent/child", "sibling", true)
    assert_equal ["/parent/sibling", "/parent/child"], aug.match("/parent/*")
  end

  def test_insert_after
    aug = aug_create
    aug.set("/parent/child", "foo")
    aug.insert("/parent/child", "sibling", false)
    assert_equal ["/parent/child", "/parent/sibling"], aug.match("/parent/*")
  end

  def test_insert_no_match
    aug = aug_create
    assert_raises (Augeas::NoMatchError) { aug.insert "foo", "bar", "baz" }
  end

  def test_insert_invalid_path
    aug = aug_create
    assert_raises (Augeas::InvalidPathError) { aug.insert "//", "bar", "baz" }
  end

  def test_insert_too_many_matches
    aug = aug_create
    assert_raises (Augeas::MultipleMatchesError) { aug.insert "/*", "a", "b" }
  end

  def test_match
    aug = aug_create
    aug.set("/foo/bar", "baz")
    aug.set("/foo/baz", "qux")
    aug.set("/foo/qux", "bar")

    assert_equal(["/foo/bar", "/foo/baz", "/foo/qux"], aug.match("/foo/*"))
  end

  def test_match_empty_list
    aug = aug_create
    assert_equal([], aug.match("/nonexistent"))
  end

  def test_match_invalid_path
    aug = aug_create
    assert_raises(Augeas::InvalidPathError) { aug.match('//') }
  end

  def test_save
    aug = aug_create
    aug.set("/files/etc/hosts/1/garbage", "trash")
    assert_raises(Augeas::CommandExecutionError) { aug.save }
  end

  def test_save_tree_error
    aug = aug_create(:no_load => true)
    aug.set("/files/etc/sysconfig/iptables", "bad")
    assert_raises(Augeas::CommandExecutionError) {aug.save}
    assert aug.get("/augeas/files/etc/sysconfig/iptables/error")
    assert_equal("No such file or directory",
                 aug.get("/augeas/files/etc/sysconfig/iptables/error/message"))
  end

  def test_set_invalid_path
    aug = aug_create
    assert_raises(Augeas::InvalidPathError) { aug.set("files/etc//", nil) }
  end

  def test_set_multiple_matches_error
    aug = aug_create
    assert_raises(Augeas::MultipleMatchesError) { aug.set("files/etc/*", nil) }
  end

  def test_set
    aug = aug_create
    aug.set("/files/etc/group/disk/user[last()+1]",["user1","user2"])
    assert_equal(aug.get("/files/etc/group/disk/user[1]"), "root")
    assert_equal(aug.get("/files/etc/group/disk/user[2]"), "user1")
    assert_equal(aug.get("/files/etc/group/disk/user[3]"), "user2")

    aug.set("/files/etc/group/new_group/user[last()+1]",
            "nuser1",["nuser2","nuser3"])
    assert_equal(aug.get("/files/etc/group/new_group/user[1]"), "nuser1")
    assert_equal(aug.get("/files/etc/group/new_group/user[2]"), "nuser2")
    assert_equal(aug.get("/files/etc/group/new_group/user[3]"), "nuser3")

    aug.rm("/files/etc/group/disk/user")
    aug.set("/files/etc/group/disk/user[last()+1]", "testuser")
    assert_equal(aug.get("/files/etc/group/disk/user"), "testuser")

    aug.rm("/files/etc/group/disk/user")
    aug.set("/files/etc/group/disk/user[last()+1]", nil)
    assert_equal(aug.get("/files/etc/group/disk/user"), nil)
  end

  def test_setm
    aug = aug_create

    aug.setm("/files/etc/group/*[label() =~ regexp(\"rpc.*\")]",
             "users", "testuser1")
    assert_equal(aug.get("/files/etc/group/rpc/users"), "testuser1")
    assert_equal(aug.get("/files/etc/group/rpcuser/users"), "testuser1")

    aug.setm("/files/etc/group/*[label() =~ regexp(\"rpc.*\")]/users",
             nil, "testuser2")
    assert_equal(aug.get("/files/etc/group/rpc/users"), "testuser2")
    assert_equal(aug.get("/files/etc/group/rpcuser/users"), "testuser2")
  end

  def test_setm_invalid_path
    aug = aug_create
    assert_raises (Augeas::InvalidPathError) { aug.setm("[]", "bar", "baz") }
  end

  def test_exists
    aug = aug_create
    assert_equal false, aug.exists("/foo")
    aug.set("/foo", "bar")
    assert aug.exists("/foo")
  end

  def test_exists_invalid_path_error
    aug = aug_create
    assert_raises(Augeas::InvalidPathError) {aug.exists("[]")}
  end
  
  def test_get_multiple_matches_error
    aug = aug_create

    # Cause an error
    assert_raises (Augeas::MultipleMatchesError) { 
      aug.get("/files/etc/hosts/*") }
    
    err = aug.error
    assert_equal(Augeas::EMMATCH, err[:code])
    assert err[:message]
    assert err[:details]
    assert err[:minor].nil?
  end

  def test_get_invalid_path
    aug = aug_create
    assert_raises (Augeas::InvalidPathError) { aug.get("//") }

    err = aug.error
    assert_equal(Augeas::EPATHX, err[:code])
    assert err[:message]
    assert err[:details]
  end

  def test_defvar
    Augeas::create(:root => "/dev/null") do |aug|
      aug.set("/a/b", "bval")
      aug.set("/a/c", "cval")
      assert aug.defvar("var", "/a/b")
      assert_equal(["/a/b"], aug.match("$var"))
      assert aug.defvar("var", nil)
    end
  end

  def test_defvar_invalid_path
    aug = aug_create
    assert_raises(Augeas::InvalidPathError) { aug.defvar('var', 'F#@!$#@') }
  end

  def test_defnode
    aug = aug_create
    assert aug.defnode("x", "/files/etc/hosts/*[ipaddr = '127.0.0.1']", nil)
    assert_equal(["/files/etc/hosts/1"], aug.match("$x"))
  end

  def test_defnode_invalid_path
    aug = aug_create
    assert_raises (Augeas::InvalidPathError) { aug.defnode('x', '//', nil)}
  end

  def test_span
    aug = aug_create

    aug.set("/augeas/span", "enable")
    aug.rm("/files/etc")
    aug.load

    span = aug.span("/files/etc/ssh/sshd_config/Protocol")
    assert_not_nil(span[:filename])
    assert_equal(29..37, span[:label])
    assert_equal(38..39, span[:value])
    assert_equal(29..40, span[:span])
  end

  def test_span_no_span_info
    aug = aug_create
    # this error should be raised because we haven't enabled the span
    assert_raises(Augeas::NoSpanInfoError) {
      aug.span("/files/etc/ssh/sshd_config/Protocol") }
  end

  def test_span_no_matches
    aug = aug_create
    assert_raises(Augeas::NoMatchError) { aug.span("bogus") }
  end

  def test_flag_save_noop
    aug = aug_create(:save_mode => :noop)
    assert_equal("noop", aug.get("/augeas/save"))
  end

  def test_flag_no_load
    aug = aug_create(:no_load => true)
    assert_equal([], aug.match("/files/*"))
  end

  def test_flag_no_modl_autoload
    aug = aug_create(:no_modl_autoload => true)
    assert_equal([], aug.match("/files/*"))
  end

  def test_flag_enable_span
    aug = aug_create(:enable_span => true)
    assert_equal("enable", aug.get("/augeas/span"))
  end

  private

  def aug_create(flags={})
    if File::directory?(TST_ROOT)
      FileUtils::rm_rf(TST_ROOT)
    end
    FileUtils::mkdir_p(TST_ROOT)
    FileUtils::cp_r(SRC_ROOT, TST_ROOT)

    Augeas::create({:root => TST_ROOT, :loadpath => nil}.merge(flags))
  end

    def test_set!
        aug = aug_open
        assert_raises(Augeas::Error) { aug.set!("files/etc/hosts/*", nil) }
    end

    def test_set
       aug = aug_open
       aug.set("/files/etc/group/disk/user[last()+1]",["user1","user2"])
       assert_equal( aug.get("/files/etc/group/disk/user[1]"),"root" )
       assert_equal( aug.get("/files/etc/group/disk/user[2]"),"user1" )
       assert_equal( aug.get("/files/etc/group/disk/user[3]"),"user2" )

       aug.set("/files/etc/group/new_group/user[last()+1]",
	       "nuser1",["nuser2","nuser3"])
       assert_equal( aug.get("/files/etc/group/new_group/user[1]"),"nuser1")
       assert_equal( aug.get("/files/etc/group/new_group/user[2]"),"nuser2" )
       assert_equal( aug.get("/files/etc/group/new_group/user[3]"),"nuser3" )

       aug.rm("/files/etc/group/disk/user")
       aug.set("/files/etc/group/disk/user[last()+1]","testuser")
       assert_equal( aug.get("/files/etc/group/disk/user"),"testuser")

       aug.rm("/files/etc/group/disk/user")
       aug.set("/files/etc/group/disk/user[last()+1]", nil)
       assert_equal( aug.get("/files/etc/group/disk/user"), nil)
    end

    def test_setm
        aug = aug_open

        aug.setm("/files/etc/group/*[label() =~ regexp(\"rpc.*\")]","users", "testuser1")
        assert_equal( aug.get("/files/etc/group/rpc/users"), "testuser1")
        assert_equal( aug.get("/files/etc/group/rpcuser/users"), "testuser1")

        aug.setm("/files/etc/group/*[label() =~ regexp(\"rpc.*\")]/users",nil, "testuser2")
        assert_equal( aug.get("/files/etc/group/rpc/users"), "testuser2")
        assert_equal( aug.get("/files/etc/group/rpcuser/users"), "testuser2")
    end

    def test_error
        aug = aug_open

        # Cause an error
        aug.get("/files/etc/hosts/*")
        err = aug.error
        assert_equal(Augeas::EMMATCH, err[:code])
        assert err[:message]
        assert err[:details]
        assert err[:minor].nil?
    end

    def test_span
        aug = aug_open

        span = aug.span("/files/etc/ssh/sshd_config/Protocol")
        assert_equal({}, span)

        aug.set("/augeas/span", "enable")
        aug.rm("/files/etc")
        aug.load

        span = aug.span("/files/etc/ssh/sshd_config/Protocol")
        assert_not_nil(span[:filename])
        assert_equal(29..37, span[:label])
        assert_equal(38..39, span[:value])
        assert_equal(29..40, span[:span])
    end

    def test_srun
        aug = aug_open

        path = "/files/etc/hosts/*[canonical='localhost.localdomain']/ipaddr"
        r, out = aug.srun("get #{path}\n")
        assert_equal(1, r)
        assert_equal("#{path} = 127.0.0.1\n", out)

        assert_equal(0, aug.srun(" ")[0])
        assert_equal(-1, aug.srun("foo")[0])
        assert_equal(-1, aug.srun("set")[0])
        assert_equal(-2, aug.srun("quit")[0])
    end

    def test_label
        Augeas::open("/dev/null") do |aug|
            assert_equal 'augeas', aug.label('/augeas')
            assert_equal 'files', aug.label('/files')
        end
    end

    def test_rename
        Augeas::open("/dev/null") do |aug|
            assert_equal false, aug.rename('/files', 'invalid/label')
            assert_equal 0, aug.rename('/nonexistent', 'label')
            assert_equal ['/files'], aug.match('/files')
            assert_equal 1, aug.rename('/files', 'label')
        end
    end

    def test_text_store_retrieve
        Augeas::open("/dev/null") do |aug|
            # text_store errors
            assert_equal false, aug.text_store('Simplelines.lns', '/input', '/store')

            # text_store
            aug.set('/input', "line1\nline2\n")
            assert aug.text_store('Simplelines.lns', '/input', '/store')
            assert_equal 'line2', aug.get('/store/2')

            # text_retrieve errors
            assert_equal false, aug.text_retrieve('Simplelines.lns', '/unknown', '/store', '/output')

            # text_retrieve
            aug.set('/store/3', 'line3')
            assert aug.text_retrieve('Simplelines.lns', '/input', '/store', '/output')
            assert_equal "line1\nline2\nline3\n", aug.get('/output')
        end
    end

    def test_context
        Augeas::open("/dev/null") do |aug|
            aug.context = '/augeas'
            assert_equal '/augeas', aug.get('/augeas/context')
            assert_equal '/augeas', aug.get('context')
            assert_equal '/augeas', aug.context
        end
    end

    def test_touch
        Augeas::open("/dev/null") do |aug|
            assert_equal [], aug.match('/foo')
            aug.touch '/foo'
            assert_equal ['/foo'], aug.match('/foo')

            aug.set '/foo', 'bar'
            aug.touch '/foo'
            assert_equal 'bar', aug.get('/foo')
        end
    end

    def test_clearm
        Augeas::open("/dev/null") do |aug|
            aug.set('/foo/a', '1')
            aug.set('/foo/b', '2')
            aug.clearm('/foo', '*')
            assert_nil aug.get('/foo/a')
            assert_nil aug.get('/foo/b')
        end
    end

    private
    def aug_open(flags = Augeas::NONE)
        if File::directory?(TST_ROOT)
            FileUtils::rm_rf(TST_ROOT)
        end
        FileUtils::mkdir_p(TST_ROOT)
        FileUtils::cp_r(SRC_ROOT, TST_ROOT)

        Augeas::open(TST_ROOT, nil, flags)
    end
end
