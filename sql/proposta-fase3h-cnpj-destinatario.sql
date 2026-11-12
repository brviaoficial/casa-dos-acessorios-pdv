-- FASE 3H — PROPOSTA DE CONFIGURAÇÃO SEGURA DE DESTINATÁRIO
-- NÃO EXECUTAR SEM REVISÃO. NÃO IMPORTA XML NEM MODIFICA ESTOQUE.
-- A configuração armazena o CNPJ da empresa em tabela de acesso direto revogado.
-- Não informe CNPJ em commits, URLs, mensagens ou JavaScript publicado.

CREATE TABLE IF NOT EXISTS public.xml_empresa_destinataria_config (
    config_id smallint PRIMARY KEY DEFAULT 1 CHECK (config_id=1),
    cnpj text NOT NULL CHECK (cnpj ~ '^[0-9]{14}$'),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.xml_empresa_destinataria_config ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.xml_empresa_destinataria_config FROM PUBLIC, anon, authenticated;

-- A RPC abaixo é somente leitura: devolve APENAS status da comparação.
-- Aceita CNPJ extraído no cliente, mas não valida autenticidade do XML;
-- logo, jamais deve autorizar sozinho importação fiscal ou estoque.
CREATE OR REPLACE FUNCTION public.conferir_destinatario_xml_previa(
    p_cnpj_destinatario text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_cnpj_config text;
    v_cnpj_xml text;
BEGIN
    IF auth.uid() IS NULL OR NOT public.eh_administrador() THEN
        RAISE EXCEPTION 'Acesso não autorizado';
    END IF;
    v_cnpj_xml := COALESCE(p_cnpj_destinatario,'');
    IF v_cnpj_xml !~ '^[0-9]{14}$' THEN
        RETURN jsonb_build_object('status','cnpj_xml_invalido','confere',false);
    END IF;

    SELECT cnpj INTO v_cnpj_config
    FROM public.xml_empresa_destinataria_config
    WHERE config_id=1;

    IF v_cnpj_config IS NULL THEN
        RETURN jsonb_build_object('status','empresa_nao_configurada','confere',false);
    END IF;

    IF v_cnpj_xml <> v_cnpj_config THEN
        RETURN jsonb_build_object('status','destinatario_divergente','confere',false);
    END IF;

    RETURN jsonb_build_object('status','cnpj_igual_ao_configurado',
                             'confere',true);
END;
$$;
REVOKE ALL ON FUNCTION public.conferir_destinatario_xml_previa(text)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.conferir_destinatario_xml_previa(text)
    TO authenticated;

-- CONFIGURAÇÃO FUTURA (manual e privada no SQL Editor após revisão da fonte fiscal):
-- Use SQL privado, fora do GitHub, para cadastrar o CNPJ correto da empresa.
-- Não publicar nenhum valor real de CNPJ no repositório.
-- O CPF do destinatário não é aceito nesta RPC de prévia para empresa.
