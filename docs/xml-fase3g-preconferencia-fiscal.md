# Fase 3G — Pré-conferência fiscal local (read-only)

Esta entrega acrescenta uma seção de diagnóstico à tela de conferência de XML já existente. Não altera produtos nem estoque e não habilita importação real.

## O que verifica localmente
- Chave de acesso de 44 dígitos no Id de infNFe e dígito verificador.
- Formato e dígitos verificadores do CNPJ do emitente e do destinatário, se CNPJ.
- Modelo 55, indicador de ambiente e tipo de operação.
- Presença de protNFe/infProt e compatibilidade entre a chave do protocolo e a chave informada na NF-e.
- Exibe claramente se cStat 100/150 **declara** autorização no arquivo, sem tratá-la como autorização confirmada.

## Limites e próximas exigências
- Não verifica assinatura XML, certificados, eventos de cancelamento/inutilização nem disponibilidade ou situação na SEFAZ.
- Não compara o CNPJ destinatário com o CNPJ real da Casa dos Acessórios, que precisa ser configurado com segurança para a empresa.
- A existência de protNFe não prova autenticidade nem validade fiscal atual.
- Para importação de mercadorias reais, validar a nota e situação atual por serviço fiscal confiável do lado do servidor; confirmar emitente/destinatário e CFOP; revisar unidades de compra, EAN e mapeamento fornecedor→SKU; exigir conferência física; registrar documento e itens em transação única com idempotência por chave de acesso (além de eventuais NF-e já importadas).
- Não usar o protótipo de Fase 3F para notas reais; ele é fixo em duas peças fictícias.

## Plano de testes
1. Abrir XML fictício antigo: pré-conferência indica pendências estruturais, mas a tela de comparação continua funcionando normalmente.
2. Abrir XML malformado: erro e nenhuma alteração no banco.
3. Abrir XML válido com chave e protocolo: informações exibidas como declaração não autenticada; não há botão de importação real.
4. Conferir que carregar novo arquivo/limpar esconde a prévia anterior.
5. Conferir que todos os fluxos de testes fictícios anteriores permanecem isolados.
