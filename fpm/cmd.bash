#make writable dirs writable
chmod -R a+rw storage

exec php-fpm
