from django.conf.urls.defaults import *

from views import *

urlpatterns = patterns("",
    url(r'^save/$', save_options, name='options_save'),
    url(r'^enable_sub_lib/$', sub_lib_enable_set, name='sub_lib_enable_set'),
)
