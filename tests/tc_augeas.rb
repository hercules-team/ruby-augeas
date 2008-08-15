require 'test/unit'

$:.unshift(File::join(File::dirname(__FILE__), "..", "lib"))
$:.unshift(File::join(File::dirname(__FILE__), "..", "ext", "augeas"))
require 'augeas'

class TestAugeas < Test::Unit::TestCase
    def test_basics
        aug = Augeas::open("/tmp", nil, Augeas::SAVE_NEWFILE)
        assert_equal("newfile", aug.get("/augeas/save"))
        assert_equal("/tmp/", aug.get("/augeas/root"))

        assert(aug.exists("/augeas/root"))
        assert_not_nil(aug.get("/augeas/root"))
        assert_nothing_raised {
            aug.set("/ruby/test/node", "value")
        }
        assert_equal("value", aug.get("/ruby/test/node"))
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
end
