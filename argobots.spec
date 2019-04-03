Name: argobots
Version: 0.99
Release: 1%{?dist}
Summary: Lightweight, low-level threading and tasking framework
Group: System Environment/Libraries
License: GPLv2 or BSD
Url: http://www.argobots.org/
#Source: https://api.github.com/repos/pmodels/$(NAME)/tarball/31703b1
Source: https://api.github.com/repos/pmodels/$(NAME)/tarball/argobots-%{version}.tar.gz

# to be able to generate configure if not present
BuildRequires: autoconf, automake, libtool

%ifarch x86_64
%global configopts --enable-sockets --enable-verbs --enable-usnic --disable-static --enable-psm --enable-psm2
%else
%global configopts --enable-sockets --enable-verbs --enable-usnic --disable-static
%endif

%description
Argobots is a lightweight, low-level threading and tasking framework.
This release is an experimental version of Argobots that contains
features related to user-level threads, tasklets, and some schedulers.

%package devel
Summary: Development files for the argobots library
Group: System Environment/Libraries
Requires: %{name}%{?_isa} = %{version}-%{release}

%description devel
Development files for the argobots library.

%prep
%setup -q -n pmodels-argobots-31703b1

%build
if [ ! -f configure ]; then
    ./autogen.sh
fi
# defaults: with-dlopen can be over-rode:
%configure 
make %{?_smp_mflags} V=1

%install
%make_install
# remove unpackaged files from the buildroot
rm -f %{buildroot}%{_libdir}/*.la

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files
%{_libdir}/*.so.*
%{_libdir}/pkgconfig/%{name}.pc
%license COPYRIGHT
%doc README

%files devel
%{_libdir}/*.so
%{_libdir}/*.a
%{_libdir}/pkgconfig/*
%{_includedir}/*

%changelog
* Wed Apr  3 2019 Brian J. Murrell <brian.murrell@intel.com> - 0.99-1
- Initial package
