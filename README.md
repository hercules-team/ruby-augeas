![ruby-augeas ci build status](../../actions/workflows/ci.yml/badge.svg)

# Ruby bindings for augeas

The class Augeas provides bindings to [Augeas](https://augeas.net) library.


## Building

To build the bindings, which unfortunately includes installing them from a
gem, you need to have Augeas and its header file installed as well as
`pkg-config`.

On Fedora, you can do that simply by running
```
dnf install augeas-devel pkgconfig
```

On MacOS (OSX), you need to set up [Homebrew](https://brew.sh/) and then run
```
brew install augeas pkg-config
```

Build the ruby gem by running
```
rake build
rake test
rake gem
```
The output is pkg/ruby-augeas-VERSION.gem

Build the rpm package (optional) in the pkg/ subdirectory
```
rake rpm
```
The output is pkg/ruby-augeas-VERSION-1.DIST.src.rpm with binary packages in pkg/$(uname -m)

Create html documentation using rdoc

```
rake rdoc
```

The output is in doc/site/api/
The starting document is doc/site/api/index.html

## Usage

### Setting Data
```ruby
    Augeas::open do |aug|
      aug.set("/files/etc/sysconfig/firstboot/RUN_FIRSTBOOT", "YES")
      unless aug.save
        raise IOError, "Failed to save changes"
      end
    end
```

### Accessing Data
```ruby
    firstboot = Augeas::open { |aug| aug.get("/files/etc/sysconfig/firstboot/RUN_FIRSTBOOT") }
```

### Removing Data
```ruby
    Augeas::open do |aug|
      aug.rm("/files/etc/sysconfig/firstboot/RUN_FIRSTBOOT")
      unless aug.save
        raise IOError, "Failed to save changes"
      end
    end
```

### Minimal Setup with a Custom Root

By passing `NO_MODL_AUTOLOAD`, no files are read on startup; that allows
setting up a custom transform.

```ruby
  Augeas::open("/var/tmp/augeas-root", "/usr/local/share/mylenses",
                Augeas::NO_MODL_AUTOLOAD) do |aug|
    aug.transform(:lens => "Aliases.lns", :incl => "/etc/aliases")
    aug.load
    aug.get("/files/etc/aliases/*[name = 'postmaster']/value")
  end
```
