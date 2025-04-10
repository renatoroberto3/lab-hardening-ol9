#!/bin/bash
#################################################################
#############VISUALIZAÇÃO DE REPORTS DO LYNIS####################
#################################################################

# Nome do auditor (ajuste se quiser)
AUDITOR_NAME="Renato"

echo "🔧 Instalando NGINX e ferramentas..."
sudo dnf install -y nginx policycoreutils-python-utils firewalld

echo "🚀 Habilitando e iniciando serviços..."
sudo systemctl enable --now nginx firewalld

echo "🔥 Liberando NGINX no Firewalld..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

echo "📁 Criando diretórios para os relatórios..."
sudo mkdir -p /var/www/html/lynis-reports

echo "🔐 Ajustando permissões e contextos..."
sudo chown -R nginx:nginx /var/www/html
sudo chmod -R 755 /var/www/html
sudo chcon -Rt httpd_sys_content_t /var/www/html 2>/dev/null

echo "🛡️ Verificando e aplicando política SELinux (se necessário)..."
if command -v semanage &> /dev/null; then
    sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
    sudo restorecon -Rv /var/www/html
else
    echo "⚠️ 'semanage' não encontrado. Pulando configuração SELinux..."
fi

echo "📝 Criando arquivo de configuração do NGINX..."
cat <<EOF | sudo tee /etc/nginx/conf.d/lynis-reports.conf > /dev/null
server {
    listen 80;
    server_name localhost;

    root /var/www/html;
    index index.html;

    location / {
        autoindex on;
        try_files \$uri \$uri/ =404;
    }
    location /lynis-reports/ {
    autoindex on;
    try_files $uri $uri/ =404;
    types { 
        text/plain dat;
    }
    default_type text/plain;
}
}
EOF

echo "🧾 Criando index.html para visualização dos .dat..."
cat <<'HTML' | sudo tee /var/www/html/index.html > /dev/null
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Relatórios Lynis (.dat)</title>
</head>
<body>
    <h1>Relatórios do Lynis (.dat)</h1>
    <ul id="lista"></ul>

    <script>
        fetch('/lynis-reports/')
            .then(res => res.text())
            .then(html => {
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');
                const links = Array.from(doc.querySelectorAll('a'))
                    .filter(a => a.href.endsWith('.dat'));

                const lista = document.getElementById('lista');
                links.forEach(link => {
                    const li = document.createElement('li');
                    const nome = link.href.split('/').pop();
                    li.innerHTML = `<a href="${link.href}">${nome}</a>`;
                    lista.appendChild(li);
                });
            })
            .catch(err => {
                document.body.innerHTML += '<p>Erro ao carregar os relatórios.</p>';
                console.error(err);
            });
    </script>
</body>
</html>
HTML

echo "🔄 Garantir permissionamento pro user do NGINX..."
sudo chown -R nginx:nginx /var/www/

echo "🔄 Testando e recarregando o NGINX..."
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Gerando relatório de exemplo do Lynis..."
sudo lynis audit system --auditor "$AUDITOR_NAME" \
  --report-file "/var/www/html/lynis-reports/lynis-report-$(date +%F).dat"

IP=$(hostname -I | awk '{print $1}')
echo -e "\n🌐 Acesse via navegador: http://$IP/\n"

echo "🎉 Pronto!"

#################################################################
############### CRIADO PARA ORACLE LINUX 9 ######################
#################################################################
