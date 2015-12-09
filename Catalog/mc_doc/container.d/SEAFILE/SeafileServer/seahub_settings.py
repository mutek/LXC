SECRET_KEY = "2!)iavxz!1ygcz1y_mm$lk4g3v2ji9h*hl#v*rtj3@r#nqq&03"
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
    }
}
FILE_SERVER_ROOT = 'https://nomos.robotica.it/seafhttp'
SITE_BASE = 'https://nomos.robotica.it/docs/'
SITE_NAME = 'Nomos Docs'
SITE_ROOT = '/docs/'
USE_PDFJS = True
ENABLE_SIGNUP = False

