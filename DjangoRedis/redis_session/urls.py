
from django.urls import re_path
from redis_session import views

urlpatterns = [
    re_path(r'^set_session$', views.set_session),
    re_path(r'^get_session$', views.get_session),
]
