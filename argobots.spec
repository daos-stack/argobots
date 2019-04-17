Name: argobots
Version: 1.0rc1
Release: 1%{?dist}
Summary: Lightweight, low-level threading and tasking framework
Group: System Environment/Libraries
License: GPLv2 or BSD
Url: http://www.argobots.org/
#Source: https://api.github.com/repos/pmodels/$(NAME)/tarball/31703b1
Source: https://github.com/pmodels/%{name}/releases/download/v%{version}/%{name}-%{version}.tar.gz
Patch1: %{name}-9d48af0840.patch

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
%autosetup -p1

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
* Wed Apr 17 2019 Brian J. Murrell <brian.murrell@intel.com> - 1.0rc-1
- Update to 1.0rc1
- Add patch to bring up to 9d48af08

* Wed Apr 03 2019 Brian J. Murrell <brian.murrell@intel.com> - 0.99-1
- Initial package
