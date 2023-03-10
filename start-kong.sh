docker rm -f kong-gateway-xml-request-handling

docker run -d --name kong-gateway-xml-request-handling \
--network=kong-net \
--link kong-database-xml-request-handling:kong-database-xml-request-handling \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-xml-request-handling/plugins,destination=/usr/local/kong/python/ \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database-xml-request-handling" \
-e "KONG_PG_USER=kong" \
-e "KONG_PG_PASSWORD=kongpass" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_PLUGINS=bundled,xml-request-handling" \
-e "KONG_PLUGINSERVER_NAMES=python-plugin" \
-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_SOCKET=/usr/local/kong/python_pluginserver.sock" \
-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_START_CMD=/usr/bin/kong-python-pluginserver --no-lua-style --plugins-directory /usr/local/kong/python/" \
-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_QUERY_CMD=/usr/bin/kong-python-pluginserver --no-lua-style --plugins-directory /usr/local/kong/python/ --dump-all-plugins" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
-e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
-e KONG_LICENSE_DATA \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8002:8002 \
-p 8444:8444 \
kong-gateway-xml-request-handling

# ALPINE
#-e "KONG_PLUGINS=bundled,xml-request-handling" \
#-e "KONG_PLUGINSERVER_NAMES=python-plugin" \
#-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_SOCKET=/usr/local/kong/python_pluginserver.sock" \
#-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_START_CMD=/usr/bin/kong-python-pluginserver --plugins-directory /usr/local/kong/python/" \
#-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_QUERY_CMD=/usr/bin/kong-python-pluginserver --plugins-directory /usr/local/kong/python/ --dump-all-plugins" \

# DEBIAN
#-e "KONG_PLUGINS=bundled,xml-request-handling" \
#-e "KONG_PLUGINSERVER_NAMES=python-plugin" \
#-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_SOCKET=/usr/local/kong/python_pluginserver.sock" \
#-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_START_CMD=/usr/local/bin/kong-python-pluginserver --plugins-directory /usr/local/kong/python/" \
#-e "KONG_PLUGINSERVER_PYTHON_PLUGIN_QUERY_CMD=/usr/local/bin/kong-python-pluginserver --plugins-directory /usr/local/kong/python/ --dump-all-plugins" \


echo "see logs 'docker logs kong-gateway-xml-request-handling -f'"