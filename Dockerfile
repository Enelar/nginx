FROM scratch as build
ADD rootfs.tar /

COPY opkg.conf /etc/
COPY opkg-install /usr/bin/
COPY functions.sh /lib/

RUN opkg-install http://archive.openwrt.org/snapshots/trunk/x86/64/packages/base/libc_1.1.16-1_x86_64.ipk
RUN opkg-install nginx
RUN mkdir -p /usr/share/nginx/html /var/log/nginx/ /var/lib/nginx/body /var/run
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stdout /var/log/nginx/error.log

FROM scratch as squash

COPY --from=build /usr/share/nginx/html /usr/share/nginx/html
COPY --from=build /var/log/nginx/ /var/log/nginx/
COPY --from=build /var/lib/nginx/body /var/lib/nginx/body
COPY --from=build /var/run/nginx /var/run/nginx

COPY --from=nginx:alpine /etc/passwd /etc/shadow /etc/group /etc/
COPY --from=nginx:alpine /etc/nginx /etc/nginx

COPY --from=build /lib/ld64* /lib/ld-musl* /lib/libc* /lib/libgcc* /lib/
COPY --from=build /usr/lib/libpcre* /usr/lib/libz* /usr/lib/
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx

COPY --from=build /dev /dev


FROM scratch

STOPSIGNAL SIGTERM
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

COPY --from=squash / /
