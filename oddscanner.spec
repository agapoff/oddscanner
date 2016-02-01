# if you make changes, the it is advised to increment this number, and provide 
# a descriptive suffix to identify who owns or what the change represents
# e.g. release_version 2.MSW
%define release_version 1

# if you wish to compile an rpm without ibverbs support, compile like this...
# rpmbuild -ta glusterfs-1.3.8pre1.tar.gz --without ibverbs
%define with_ibverbs %{?_without_ibverbs:0}%{?!_without_ibverbs:1}

%define _unpackaged_files_terminate_build 0

Summary: Bookmakers Parser
Name: qtx-oddscanner
Version: 1.0
Release: %release_version
License: GPL2
Group: System Environment/Base
Vendor: quotix
Packager: v.agapov@quotix.com
BuildRoot: %_tmppath/%name-root
BuildArch: noarch
Requires: perl perl-HTTP-Server-Simple perl-Data-Dumper perl-JSON
Source: %name.tar.gz

%description
Bookmakers Parser

%prep
# then -n argument says that the unzipped version is NOT %name-%version
#%setup -n %name-%version
%setup -n %name 

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} install DESTDIR=$RPM_BUILD_ROOT

%files

%attr(644, root, root) /etc/logrotate.d/oddscanner
%attr(644, root, root) /usr/lib/systemd/system/oddscanner.service
%attr(755, oddscanner, oddscanner) /opt/oddscanner/
%attr(755, oddscanner, oddscanner) /var/log/oddscanner/
%attr(755, oddscanner, oddscanner) /opt/oddscanner/oddscanner.pl
%attr(644, oddscanner, oddscanner) /opt/oddscanner/oddscanner.pm
%attr(644, oddscanner, oddscanner) /opt/oddscanner/Parser/*
%config(noreplace) %attr(644, oddscanner, oddscanner) /opt/oddscanner/config.ini


%pre

/usr/bin/getent group oddscanner > /dev/null || /usr/sbin/groupadd -r oddscanner
/usr/bin/getent passwd oddscanner > /dev/null || /usr/sbin/useradd -r -g oddscanner oddscanner

%changelog
* Mon Feb 01 2016 Vitaly Agapov <agapov.vitaly@gmail.com> - 1.0-1
- Initial build
