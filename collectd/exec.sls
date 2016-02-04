{% from "collectd/map.jinja" import collectd_settings with context %}

include:
  - collectd

{{ collectd_settings.plugindirconfig }}/exec.conf:
  file.managed:
    - source: salt://collectd/files/exec.conf
    - user: {{ collectd_settings.user }}
    - group: {{ collectd_settings.group }}
    - mode: 644
    - template: jinja
    - watch_in:
      - service: collectd-service


{% for program in collectd_settings.plugins.exec.programs %}
/var/lib/{{ collectd_settings.plugins.exec.user }}/scripts/{{ program }}:
  file.managed:
    - name: /var/lib/{{ collectd_settings.plugins.exec.user }}/scripts/{{ program }}
    - source: salt://collectd/files/scripts/{{ program }}
    - user: {{ collectd_settings.plugins.exec.user }}
    - group: {{ collectd_settings.plugins.exec.group }}
    - mode: 744
    - makedirs: True
    - watch_in:
      - service: collectd-service
    - require_in:
        - cmd: {{ collectd_settings.plugindirconfig }}/exec.conf
    - require:
        - user: {{ collectd_settings.plugins.exec.user }}
{% endfor %}

/etc/sudoers.d/{{ collectd_settings.plugins.exec.user }}_sudoers:
  file.managed:
    - name: /etc/sudoers.d/{{ collectd_settings.plugins.exec.user }}_sudoers
    - source: salt://collectd/files/sudoers
    - user: root
    - group: root
    - mode: 0440
    - template: jinja

exec_user_{{ collectd_settings.plugins.exec.user }}:
  user.present:
    - name: {{ collectd_settings.plugins.exec.user }}
    - shell: /usr/sbin/nologin
    - home: /var/lib/{{ collectd_settings.plugins.exec.user }}
    - system: True
    - groups:
      - {{ collectd_settings.plugins.exec.group }}
      - sudo
    - require:
        - group: {{ collectd_settings.plugins.exec.group }}

exec_group_{{ collectd_settings.plugins.exec.group }}:
  group.present:
    - name: {{ collectd_settings.plugins.exec.group }}
    - system: True

