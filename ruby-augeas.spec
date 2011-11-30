%{!?ruby_sitelib: %define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")}
%{!?ruby_sitearch: %define ruby_sitearch %(ruby -rrbconfig -e "puts Config::CONFIG['sitearchdir']")}

Name:           ruby-augeas
Version:        @VERSION@
Release:        1%{?dist}
Summary:        Ruby bindings for Augeas
Group:          Development/Languages

License:        LGPLv2+
URL:            http://augeas.net
Source0:        http://augeas.net/download/ruby/ruby-augeas-%{version}.tgz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  ruby ruby-devel rubygem(rake)
BuildRequires:  augeas-devel >= 0.8.0
BuildRequires:  libxml2-devel
BuildRequires:  pkgconfig
Requires:       ruby(abi) = 1.8
Requires:       augeas-libs >= 0.8.0
Provides:       ruby(augeas) = %{version}

%description
Ruby bindings for augeas.

%prep
%setup -q


%build
export CFLAGS="$RPM_OPT_FLAGS"
rake build

%install
rm -rf %{buildroot}
install -d -m0755 %{buildroot}%{ruby_sitelib}
install -d -m0755 %{buildroot}%{ruby_sitearch}
install -p -m0644 lib/augeas.rb %{buildroot}%{ruby_sitelib}
install -p -m0755 ext/augeas/_augeas.so %{buildroot}%{ruby_sitearch}

%check
rake test

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%doc COPYING README.rdoc NEWS
%{ruby_sitelib}/augeas.rb
%{ruby_sitearch}/_augeas.so


%changelog
* Fri Mar 25 2011 David Lutterkort <lutter@redhat.com> - 0.4.0-1
- Now requires augeas-0.8.0

* Wed Aug 12 2009 David Lutterkort <lutter@redhat.com> - 0.3.0-1
- New version

* Tue Aug 26 2008 David Lutterkort <dlutter@redhat.com> - 0.2.0-1
- New version

* Fri May  9 2008 David Lutterkort <dlutter@redhat.com> - 0.1.0-1
- Fixed up in accordance with Fedora guidelines

* Mon Mar 3 2008 Bryan Kearney <bkearney@redhat.com> - 0.0.1-1
- Initial specfile
