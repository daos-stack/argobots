Name: argobots

%global major 1
%global minor 1
#%%global prerelease
%global tag %{major}.%{minor}%{?prerelease}

Version: %{major}.%{minor}%{?prerelease:~%{prerelease}}
Release: 3%{?dist}
Summary: Lightweight, low-level threading and tasking framework
Group: System Environment/Libraries
License: UChicago Argonne, LLC -- Argobots License
Url: http://www.argobots.org/
#Source: https://api.github.com/repos/pmodels/$(NAME)/tarball/31703b1
Source: https://github.com/pmodels/%{name}/releases/download/v%{tag}/%{name}-%{tag}.tar.gz

BuildRequires: pkgconfig

# to be able to generate configure if not present
BuildRequires: autoconf, automake, libtool

# need libunwind if configuring symbolic ULTs stack dumps feature
BuildRequires: libunwind-devel

# need valgrind if enabling Valgrind instrumenting
BuildRequires: valgrind-devel

%description
Argobots is a lightweight, low-level threading and tasking framework.
This release is an experimental version of Argobots that contains
features related to user-level threads, tasklets, and some schedulers.

%if (0%{?suse_version} >= 1315)
%package -n libabt0
Summary: Development files for the argobots library
Group: System Environment/Libraries
Obsoletes: %{name} < %{version}-%{release}
Provides: argobots = %{version}-%{release}

%description -n libabt0
Argobots is a lightweight, low-level threading and tasking framework.
This release is an experimental version of Argobots that contains
features related to user-level threads, tasklets, and some schedulers.

%package -n libabt-devel
Summary: Development files for the argobots library
Group: System Environment/Libraries
Requires: libabt0%{?_isa} = %{version}-%{release}

%description -n libabt-devel
%else
%package devel
Summary: Development files for the argobots library
Group: System Environment/Libraries
Requires: %{name}%{?_isa} = %{version}-%{release}

%description devel
%endif
Development files for the argobots library.

%if (0%{?suse_version} > 0)
%global __debug_package 1
%global _debuginfo_subpackages 1
%debug_package
%endif

%prep
%autosetup -p1 -n %{name}-%{tag}

%build
# need to force autogen.sh since we have patches that touch a Makefile.am
if true || [ ! -f configure ]; then
    ./autogen.sh
fi
# defaults: with-dlopen can be over-rode:
%configure --enable-valgrind --enable-stack-unwind
make %{?_smp_mflags} V=1

%install
%make_install
# remove unpackaged files from the buildroot
rm -f %{buildroot}%{_libdir}/*.{l,}a

%if (0%{?suse_version} >= 1315)
%post -n libabt0 -p /sbin/ldconfig
%postun -n libabt0 -p /sbin/ldconfig
%else
%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig
%endif

%if (0%{?suse_version} >= 1315)
%files -n libabt0
%else
%files
%endif
%{_libdir}/*.so.*
%license COPYRIGHT
%doc README

%if (0%{?suse_version} >= 1315)
%files -n libabt-devel
%else
%files devel
%endif
%{_libdir}/*.so
%{_libdir}/pkgconfig/*
%{_includedir}/*
%doc README

%changelog
* Tue Jun 06 2023 Brian J. Murrell <brian.murrell@intel.com> - 1.1-3
- Update to build on EL9

* Wed Oct 19 2022 Brian J. Murrell <brian.murrell@intel.com> - 1.1-2
- Create debuginfo packages for SUSE
- Fix up some issues found by rpmlint

* Thu Apr 01 2021 Brian J. Murrell <brian.murrell@intel.com> - 1.1-1
- Update to 1.1

* Wed Mar 17 2021 Brian J. Murrell <brian.murrell@intel.com> - 1.1~rc1-1
- Update to 1.1rc1

* Tue Feb 23 2021 B.Faccini <bruno.faccini@intel.com> - 1.1~b1-1
- Update to 1.1b1
- Build with unwinding enabled

* Mon Aug 17 2020 Brian J. Murrell <brian.murrell@intel.com> - 1.0-1
- Update to 1.0 final

* Mon Jun 22 2020 Brian J. Murrell <brian.murrell@intel.com> - 1.0rc-5
- Update License:

* Sat Sep 21 2019 Brian J. Murrell <brian.murrell@intel.com> - 1.0rc-4
- Add BR: pkgconfig

* Sat Sep 21 2019 Brian J. Murrell <brian.murrell@intel.com> - 1.0rc-3
- Revert libabt0 packaging for EL7; RH just doesn't do that

* Fri Sep 20 2019 Brian J. Murrell <brian.murrell@intel.com> - 1.0rc-2
- Add patch to bring up to 89507c1f8c
- Create a libabt0 subpackage
- Force autogen.sh since we add a patch that modifies a Makefile.am

* Wed Apr 17 2019 Brian J. Murrell <brian.murrell@intel.com> - 1.0rc-1
- Update to 1.0rc1
- Add patch to bring up to 9d48af08

* Wed Apr 03 2019 Brian J. Murrell <brian.murrell@intel.com> - 0.99-1
- Initial package
