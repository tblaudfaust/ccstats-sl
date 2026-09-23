FROM odoo:18.0
USER root
COPY addons /mnt/extra-addons
RUN find /mnt/extra-addons -maxdepth 2 -name requirements.txt -print0 \
    | xargs -0 -r -n1 pip3 install --break-system-packages --no-cache-dir -r \
 && chown -R odoo:odoo /mnt/extra-addons
USER odoo
