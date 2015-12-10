SECRET_KEY = "GENERATA AL SETUP DI SEAFILE"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'seahub-db',
        'USER': 'UTENTE DB MYSQL',
        'PASSWORD': 'INSERIRE LA PASSWORD DI MYSQL',
        'HOST': '127.0.0.1',
        'PORT': '3306',
        'OPTIONS': {
            'init_command': 'SET storage_engine=INNODB',
        }
    }
}

FILE_SERVER_ROOT = 'https://cname.dominio.tld/seafhttp'

SERVE_STATIC = True
MEDIA_URL = '/seafmedia/'
SITE_ROOT = '/archivio/'
COMPRESS_URL = MEDIA_URL
STATIC_URL = MEDIA_URL + 'assets/'
# workaround momentaneo valido almeno per la 4.x (5.x da testare)
DEBUG = True


LANGUAGE_CODE = 'it-IT'

# show or hide library 'download' button
SHOW_REPO_DOWNLOAD_BUTTON = True

# enable 'upload folder' or not
ENABLE_UPLOAD_FOLDER = True

# enable resumable fileupload or not
ENABLE_RESUMABLE_FILEUPLOAD = True

# browser tab title
SITE_TITLE = 'Archivio ACME'

# Path to the Logo Imagefile (relative to the media path)
#LOGO_PATH = 'img/seafile_logo.png'


CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
    }
}

