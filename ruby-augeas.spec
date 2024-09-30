Name:           ruby-augeas
Version:        @VERSION@
Release:        1%{?dist}
Summary:        Ruby bindings for Augeas

License:        LGPLv2+
URL:            http://augeas.net
Source0:        https://github.com/hercules-team/ruby-augeas/releases/download/release-%{version}/ruby-augeas-%{version}.tgz

BuildRequires:  ruby rubygem(rake)
%if 0%{?rhel} != 7
# RedHat/CentOS 7 use Ruby 2.0 where test-unit is not a seperate package
BuildRequires:  rubygem(test-unit)
%endif
BuildRequires:  ruby rubygem(rdoc)
BuildRequires:  ruby-devel
BuildRequires:  augeas-devel >= 1.0.0
BuildRequires:  pkgconfig
BuildRequires:  gcc
Requires:       ruby(release)
Requires:       augeas-libs >= 1.0.0
Provides:       ruby(augeas) = %{version}

%description
Ruby bindings for augeas.

%prep
%setup -q


%build
export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
rake build

%install
rm -rf %{buildroot}
install -d -m0755 %{buildroot}%{ruby_vendorlibdir}
install -d -m0755 %{buildroot}%{ruby_vendorarchdir}
install -p -m0644 lib/augeas.rb %{buildroot}%{ruby_vendorlibdir}
install -p -m0755 ext/augeas/_augeas.so %{buildroot}%{ruby_vendorarchdir}

%check
rake test


%files
%doc COPYING README.md NEWS
%{ruby_vendorlibdir}/augeas.rb
%{ruby_vendorarchdir}/_augeas.so

%changelog
* Thu Aug  1 2024 - George Hansper <george@hansper.id.au>
- Copied latest ruby-augeas.spec from Fedora 39 src rpm
  Added %if for building under rhel 7
  Updated Source0 to github URL
