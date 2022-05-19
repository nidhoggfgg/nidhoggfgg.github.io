sudo docker run \
    --name jupyter-pub \
    -m 4G \
    --cpus=4 \
    -idt \
    -p 7777:8888 \
    --user root \
    -e NB_USER="jupyter" \
    -e CHOWN_HOME=yes \
    -w "/home/${NB_USER}" \
    -v /etc/caddy/tls:/etc/ssl/notebook \
    jupyter/datascience-notebook \
    start-notebook.sh --NotebookApp.password='argon2:$argon2id$v=19$m=10240,t=10,p=8$6U/WlNzSOfYLUyN1Bs/VLA$BdzarauYwJyXvIqr/XqiPT4j+MWasCfbKFNWhz5ZrA8' \
    --NotebookApp.keyfile=/etc/ssl/notebook/server.nidhoggfgg.fun.key \
    --NotebookApp.certfile=/etc/ssl/notebook/server.nidhoggfgg.fun_bundle.crt