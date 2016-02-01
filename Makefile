install:
	install -d -m 755 ${DESTDIR}/opt/oddscanner
	install -d -m 755 ${DESTDIR}/var/log/oddscanner
	install -d -m 755 ${DESTDIR}/etc/logrotate.d
	install -d -m 755 ${DESTDIR}/usr/lib/systemd/system/
	install -m 755 src/oddscanner*  ${DESTDIR}/opt/oddscanner/
	install -m 755 src/config.ini  ${DESTDIR}/opt/oddscanner/
	install -m 755 logrotate.d/oddscanner  ${DESTDIR}/etc/logrotate.d/
	install -m 755 systemd/oddscanner.service ${DESTDIR}/usr/lib/systemd/system/
