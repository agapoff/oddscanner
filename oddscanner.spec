# if you make changes, the it is advised to increment this number, and provide 
# a descriptive suffix to identify who owns or what the change represents
# e.g. release_version 2.MSW
%define release_version 6

# if you wish to compile an rpm without ibverbs support, compile like this...
# rpmbuild -ta glusterfs-1.3.8pre1.tar.gz --without ibverbs
%define with_ibverbs %{?_without_ibverbs:0}%{?!_without_ibverbs:1}

%define _unpackaged_files_terminate_build 0

Summary: HTTP-to-SMTP gateway
Name: qtx-hellespont
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
HTTP-to-SMTP gateway

%prep
# then -n argument says that the unzipped version is NOT %name-%version
#%setup -n %name-%version
%setup -n %name 

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} install DESTDIR=$RPM_BUILD_ROOT

%files

%attr(644, root, root) /etc/logrotate.d/hellespont
%attr(644, root, root) /usr/lib/systemd/system/hellespont.service
%attr(755, hellespont, hellespont) /opt/hellespont/
%attr(755, hellespont, hellespont) /var/log/hellespont/
%attr(755, hellespont, hellespont) /opt/hellespont/hellespont.pl
%attr(644, hellespont, hellespont) /opt/hellespont/hellespont.pm
%config(noreplace) %attr(644, hellespont, hellespont) /opt/hellespont/config.ini


%pre

/usr/bin/getent group hellespont > /dev/null || /usr/sbin/groupadd -r hellespont
/usr/bin/getent passwd hellespont > /dev/null || /usr/sbin/useradd -r -g hellespont hellespont

%changelog
* Thu Aug 13 2015 Vitaly Agapov <v.agapov@quotix.com> - 1.0-6
- Added graphite endpoint

* Wed May 13 2015 Vitaly Agapov <v.agapov@quotix.com> - 1.0-5
- Fixed logrotate conf

* Wed May 06 2015 Vitaly Agapov <v.agapov@quotix.com> - 1.0-4
- Added checking for private networks

* Wed May 06 2015 Vitaly Agapov <v.agapov@quotix.com> - 1.0-3
- Removed numbers from fields in emails

* Wed May 06 2015 Vitaly Agapov <v.agapov@quotix.com> - 1.0-2
- Some fixes

* Wed May 06 2015 Vitaly Agapov <v.agapov@quotix.com> - 1.0-1
- Initial build
