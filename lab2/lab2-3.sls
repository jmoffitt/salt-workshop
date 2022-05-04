nginx_content_present:
  file.managed:
    - name: /usr/share/nginx/html/index.html
    - source: salt://nginx/index.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx_installed