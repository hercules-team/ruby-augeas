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
        aug = Augeas::open("/dev/null", nil, 0)
        aug.set("/a/b", "value")
        aug.mv("/a/b", "/x/y")
        assert_equal("value", aug.get("/x/y"))
        aug.close
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

    def test_defvar
        aug = Augeas::open("/dev/null", nil, 0)
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
