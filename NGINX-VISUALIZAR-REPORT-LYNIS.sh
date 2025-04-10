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
sudo chown -R /etc/nginx/
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
    server_name www.oreacle9-1-lynisreport.com;

    root /var/www/html;
    index index.html;

    location / {
        autoindex on;
        try_files $uri $uri/ =404;
    }
    location /lynis-reports/ {
    autoindex on;
    try_files $uri $uri/ =404;
    types {
        text/plain dat;
    }
    default_type text/plain;
    add_header Content-Type text/plain;
}
}
EOF

echo "🧾 Criando index.html para visualização dos .dat..."
cat <<'HTML' | sudo tee /var/www/html/index.html > /dev/null
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <title>Relatórios Lynis (.dat)</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background: #f9f9f9;
            color: #333;
            padding: 20px;
            margin: 0;
        }

        h1 {
            margin-bottom: 20px;
            color: #2c3e50;
        }

        #container {
            display: flex;
            gap: 20px;
        }

        ul {
            list-style: none;
            padding: 0;
            width: 250px;
            border-right: 1px solid #ccc;
            max-height: 600px;
            overflow-y: auto;
        }

        li {
            margin-bottom: 5px;
        }

        a {
            display: block;
            padding: 8px;
            border-radius: 5px;
            text-decoration: none;
            color: #2980b9;
            background: #ecf0f1;
            transition: background 0.3s;
        }

        a:hover {
            background: #d0e4f1;
        }

        pre {
            flex: 1;
            background: #fff;
            padding: 15px;
            border: 1px solid #ccc;
            max-height: 600px;
            overflow-y: auto;
            white-space: pre-wrap;
            word-break: break-word;
        }

        .highlight {
            background-color: #ff0000;
            font-weight: bold;
            color: #ffffff;
        }

        .error {
            color: red;
            font-weight: bold;
        }

        .loading {
            font-style: italic;
            color: #888;
        }
    </style>
</head>
<body>
    <h1>Relatórios do Lynis (.dat)</h1>
    <div id="container">
        <ul id="lista"></ul>
        <pre id="conteudo" class="loading">Carregando lista de relatórios...</pre>
    </div>

    <script>
        const lista = document.getElementById('lista');
        const conteudo = document.getElementById('conteudo');

        function highlightHardeningIndex(text) {
            return text.replace(
                /^.*hardening_index=\d+.*$/gmi,
                match => `<span class="highlight">${match}</span>`
            );
        }

        fetch('/lynis-reports/')
            .then(res => res.text())
            .then(html => {
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');

                const links = Array.from(doc.querySelectorAll('a'))
                    .filter(a => a.href.endsWith('.dat') && a.href.startsWith(location.origin));

                if (links.length === 0) {
                    conteudo.classList.remove('loading');
                    conteudo.innerHTML = '<span class="error">Nenhum relatório encontrado.</span>';
                    return;
                }

                conteudo.classList.remove('loading');
                conteudo.textContent = 'Selecione um relatório para visualizar.';

                links.forEach(link => {
                    const nome = link.href.split('/').pop();
                    const li = document.createElement('li');
                    const a = document.createElement('a');
                    a.textContent = nome;
                    a.href = '#';

                    a.onclick = (e) => {
                        e.preventDefault();
                        conteudo.classList.add('loading');
                        conteudo.textContent = 'Carregando conteúdo...';

                        fetch(`/lynis-reports/${nome}`)
                            .then(resp => resp.text())
                            .then(data => {
                                conteudo.classList.remove('loading');
                                conteudo.innerHTML = highlightHardeningIndex(
                                    data.replace(/[&<>"']/g, function (m) {
                                        return {
                                            '&': '&amp;',
                                            '<': '&lt;',
                                            '>': '&gt;',
                                            '"': '&quot;',
                                            "'": '&#39;'
                                        }[m];
                                    })
                                );
                            })
                            .catch(err => {
                                conteudo.classList.remove('loading');
                                conteudo.innerHTML = '<span class="error">Erro ao carregar o arquivo.</span>';
                                console.error(err);
                            });
                    };

                    li.appendChild(a);
                    lista.appendChild(li);
                });
            })
            .catch(err => {
                conteudo.classList.remove('loading');
                conteudo.innerHTML = '<span class="error">Erro ao carregar a lista de relatórios.</span>';
                console.error(err);
            });
    </script>
    <footer style="margin-top: 40px; font-size: 0.9em; color: #555; border-top: 1px solid #ccc; padding-top: 10px;">
        <p>
            Para gerar um novo relatório manualmente, execute:
            <code>
                sudo lynis audit system --auditor "Renato" --report-file "/var/www/html/lynis-reports/lynis-report-$(date +%F).dat"; chown -R nginx:nginx /var/www/html/lynis-reports/
            </code>
        </p>
    </footer>    
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
