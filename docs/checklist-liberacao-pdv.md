# Casa dos Acessórios — plano de liberação do PDV (13/11/2026)

**Objetivo:** colocar a frente de caixa em operação presencial em **um computador**, com rastreabilidade e reversão segura. Não confundir testes de desenvolvimento com homologação de produção. **Status: NÃO LIBERADO até evidências abaixo.**

## Diagnóstico do código atual (main)
- Título da página ainda informa `Menu de Caixa (TESTE)`; botões do controle de caixa dizem `Abrir caixa de TESTE` e `Fechar caixa`, com valores fictícios predefinidos.
- Existem chamadas a RPCs com sufixo `_teste` para carrinho/estoque e pagamentos divididos.
- O estoque e produtos consultam tabelas Supabase reais, mas a importação XML real **não** está habilitada; 3E/3F são exclusivamente fictícias.
- Por isso não se deve tratar o percentual informal de desenvolvimento como garantia de prontidão para vendas reais.

## Portão A — Ambiente e dados
- [ ] Identificar banco/projeto de **produção** separado dos testes (ou procedimento explícito de segregação e limpeza autorizado, com backup restaurável).
- [ ] Validar políticas RLS e permissões de administrador/funcionário usando contas separadas.
- [ ] Registrar e testar backup/restore de banco, esquema, dados e configurações; definir responsável e periodicidade.
- [ ] Preparar carga inicial do catálogo real, verificar código único, preços, custo, quantidades, endereços e amostras do inventário. Não colocar produtos fictícios disponíveis para venda.
- [ ] Confirmar conectividade no computador da loja, navegadores, rotinas para indisponibilidade e queda de internet.

## Portão B — Vendas e pagamentos
- [ ] Venda simples de produto fictício em ambiente de homologação: antes/depois de estoque, totais, usuário, carimbo de data/hora.
- [ ] Venda com múltiplos itens: impedir estoque negativo e duplo clique/duplo processamento.
- [ ] Venda com dois ou mais pagamentos: somatório exato, arredondamento em centavos, registro por forma.
- [ ] Cancelamento controlado: motivo obrigatório, estorno de estoque **uma vez**, relatório consistente.
- [ ] Teste de interrupção de rede após clicar em vender: reconciliar operação antes de tentar de novo.
- [ ] Garantir que a interface de uso real não chame RPCs de teste sem revisão e controles adequados.

## Portão C — Caixa e relatórios
- [ ] Abertura, movimentações, sangria/suprimento se aplicável, fechamento, divergência e histórico.
- [ ] Conferir venda por forma de pagamento versus fechamento e relatório diário.
- [ ] Impedir operações de caixa em estado inválido (fechado, sessão desatualizada ou usuário sem permissão).

## Portão D — Garagistas/fiado
- [ ] Venda vinculada à garagem, vencimento combinado e responsabilidade da garagem.
- [ ] Retirada por funcionário da garagem opcional, sem transferir a dívida.
- [ ] Devolução parcial, recebimento parcial, saldo e histórico sem lançamentos em dobro.
- [ ] Bloquear baixa/estorno duplicado e auditar permissões.

## Portão E — Fiscal e operação
- [ ] Definir processo fiscal **legalmente adequado** para vendas da loja (emissão pela ferramenta homologada/externa ou integração fiscal), antes de vendas reais.
- [ ] Revisar treinamento dos 3 usuários, impressora/comprovantes e procedimento de contingência.
- [ ] Importação NF-e XML real, modo offline e endereçamento avançado são fases independentes; não bloquear um piloto só se houver procedimentos manuais seguros e fluxo fiscal regular.

## Roteiro de homologação: registrar prova
Para cada teste preencher: **data, executor, ambiente, cenário, operação/ID, valor esperado, valor observado, evidência, passou/falhou, ação corretiva**.
Não utilizar dados de clientes reais ou valores financeiros reais nos ensaios.

## Critério de decisão
**GO** apenas quando Portões A–E aplicáveis ao primeiro dia estiverem aprovados, sem defeito crítico aberto, com backup/restauração testados e fluxo fiscal definido. Caso contrário, **NO-GO** e corrigir riscos primeiro.
