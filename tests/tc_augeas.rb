# These tests are run against the old deprecated module which is
# instantiated by Augeas::open

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
    aug = aug_open(Augeas::SAVE_NEWFILE)
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

  def test_create_block
    foo = nil
    Augeas::create do |aug|
      aug.set('/foo', 'bar')
      foo = aug.get('/foo')
    end
    assert_equal(foo, 'bar')
  end

  def test_close
    aug = Augeas::open("/tmp", nil, Augeas::SAVE_NEWFILE)
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
    Augeas::open("/dev/null") do |aug|
      aug.set("/a/b", "value")
      aug.mv("/a/b", "/x/y")
      assert_equal("value", aug.get("/x/y"))
    end
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

  def test_rm
    aug = aug_open
    aug.set("/foo/bar", "baz")
    assert aug.get("/foo/bar")
    assert_equal 2, aug.rm("/foo")
    assert_nil aug.get("/foo")
  end

  def test_rm_invalid_path
    aug = aug_open
    assert_raises(Augeas::InvalidPathError) { aug.rm('//') }
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

  def test_defnode
    aug = aug_open
    assert aug.defnode("x", "/files/etc/hosts/*[ipaddr = '127.0.0.1']", nil)
    assert_equal(["/files/etc/hosts/1"], aug.match("$x"))
  end

  def test_match
    aug = aug_open
    aug.set("/foo/bar", "baz")
    aug.set("/foo/baz", "qux")
    aug.set("/foo/qux", "bar")

    assert_equal(["/foo/bar", "/foo/baz", "/foo/qux"], aug.match("/foo/*"))
  end

  def test_match_empty_list
    aug = aug_open
    assert_equal([], aug.match("/nonexistent"))
  end

  def test_match_invalid_path
    aug = aug_open
    assert_raises(Augeas::InvalidPathError) { aug.match('//') }
  end

  def test_save
    aug = aug_open
    aug.set("/files/etc/hosts/1/garbage", "trash")
    assert_raises(Augeas::CommandExecutionError) { aug.save }
  end

  def test_save_tree_error
    aug = aug_open(Augeas::NO_LOAD)
    aug.set("/files/etc/sysconfig/iptables", "bad")
    assert_raises(Augeas::CommandExecutionError) {aug.save}
    assert aug.get("/augeas/files/etc/sysconfig/iptables/error")
    assert_equal("No such file or directory",
                 aug.get("/augeas/files/etc/sysconfig/iptables/error/message"))
  end

  def test_set_invalid_path
    aug = aug_open
    assert_raises(Augeas::InvalidPathError) { aug.set("files/etc//", nil) }
  end

  def test_set_multiple_matches_error
    aug = aug_open
    assert_raises(Augeas::MultipleMatchesError) { aug.set("files/etc/*", nil) }
  end

  def test_set
    aug = aug_open
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
    aug = aug_open

    aug.setm("/files/etc/group/*[label() =~ regexp(\"rpc.*\")]",
             "users", "testuser1")
    assert_equal(aug.get("/files/etc/group/rpc/users"), "testuser1")
    assert_equal(aug.get("/files/etc/group/rpcuser/users"), "testuser1")

    aug.setm("/files/etc/group/*[label() =~ regexp(\"rpc.*\")]/users",
             nil, "testuser2")
    assert_equal(aug.get("/files/etc/group/rpc/users"), "testuser2")
    assert_equal(aug.get("/files/etc/group/rpcuser/users"), "testuser2")
  end

  def test_get_multiple_matches_error
    aug = aug_open

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
    aug = aug_open
    assert_raises (Augeas::InvalidPathError) { aug.get("//") }

    err = aug.error
    assert_equal(Augeas::EPATHX, err[:code])
    assert err[:message]
    assert err[:details]
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

  private
  def aug_open(flags = Augeas::NONE)
    if File::directory?(TST_ROOT)
      FileUtils::rm_rf(TST_ROOT)
    end
    FileUtils::mkdir_p(TST_ROOT)
    FileUtils::cp_r(SRC_ROOT, TST_ROOT)

    Augeas::create(TST_ROOT, nil, flags)
  end
end
