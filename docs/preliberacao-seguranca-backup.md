# Pre-liberação do PDV — segurança e backup

**Estado atual (13/11/2026):** versão principal do PDV ainda identificada como **AMBIENTE DE TESTES — NÃO UTILIZAR PARA VENDAS REAIS**, e a frente de caixa utiliza RPCs de venda com sufixo `_teste`. **Não retirar o aviso nem liberar operações reais até homologar um ambiente de produção.**

## Etapa 1 — Auditoria sem alterar dados
Execute o arquivo `sql/auditoria-preliberacao-somente-leitura.sql` no Supabase SQL Editor. Revise:
- Quais tabelas críticas têm RLS ativado e se as políticas realmente restringem as operações por função/usuário.
- Quais grants diretos as funções `anon` e `authenticated` possuem.
- Quais RPCs de teste continuam disponíveis e quais são `SECURITY DEFINER`. **Não revogue automaticamente RPCs**, pois isso pode quebrar os testes existentes.
- O teste de RLS deverá ser repetido com uma conta de funcionário sem privilégios, e não somente pelo SQL Editor (que pode ter privilégios elevados).

## Etapa 2 — Backup e recuperação, antes da operação
- Identificar no painel do Supabase o projeto/banco de desenvolvimento e o projeto/banco destinado a **produção**.
- Planejar backup consistente de esquema + dados, incluindo `auth`/relacionamentos e objetos necessários, por método suportado pelo projeto/plano.
- Armazenar cópia de backup em local protegido com acesso restrito; nunca enviar dump com dados reais para GitHub.
- Fazer **teste de restauração em ambiente separado**, validar contagens e integridade (produtos, vendas, itens, caixa, pagamentos e fiado). Só um backup sem restauração comprovada não basta.
- Registrar responsável, frequência, retenção, data e resultado da restauração.
- Manter variáveis e segredos apenas nos ambientes apropriados; nunca copiar `service_role` para o navegador, HTML ou repositório.
- Separar os dados fictícios (p. ex. `TESTE002`, `CALOTA-ARO14`, `PRESILHA-TESTE`) do catálogo comercial. Não apagar dados de teste antes de confirmar plano de segregação/backup.

## Etapa 3 — Fluxo mínimo de produção
- Planejar migração controlada do esquema para ambiente limpo, com versão do código congelada.
- Validar venda única, pagamento dividido, baixa de estoque, caixa, fechamento, devoluções, fiado e impressões com dados fictícios em **homologação**.
- Testar idempotência sob falha de conexão/duplo clique e permissões de usuário.
- Definir solução fiscal regular para venda de mercadorias antes de operar com clientes. Importação XML real e emissão fiscal são assuntos separados.
- Somente após evidências de aprovação, construir e liberar as RPCs de produção; não renomear simplesmente funções `_teste` nem suprimir avisos.

## Estado da execução
Este PR adiciona somente SQL **SELECT** e documentação. Não executa SQL no Supabase, não cria backups e não altera o aplicativo nem o estoque. O checklist operacional complementar está em PR #17.
