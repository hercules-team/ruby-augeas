require 'test/unit'

unless defined?(TOPDIR)
  TOPDIR = File::expand_path(File::join(File::dirname(__FILE__), ".."))
end

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

    def test_defnode
        aug = aug_open
        assert aug.defnode("x", "/files/etc/hosts/*[ipaddr = '127.0.0.1']", nil)
        assert_equal(["/files/etc/hosts/1"], aug.match("$x"))
    end

    def test_save!
        aug = aug_open
        aug.set("/files/etc/hosts/1/garbage", "trash")
        assert_raises(Augeas::Error) { aug.save! }
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
