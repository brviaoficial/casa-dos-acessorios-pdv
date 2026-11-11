-- PROPOSTA PARA REVISÃO: NÃO EXECUTAR NO BANCO REAL SEM CONFERIR SCHEMA,
-- políticas RLS, assinatura de eh_administrador() e tipos de produtos.id.
-- Operação limitada aos produtos existentes. Cadastro assistido virá depois.
BEGIN;
CREATE TABLE IF NOT EXISTS public.xml_entradas_teste (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 chave_nfe text NOT NULL UNIQUE CHECK (chave_nfe ~ '^[0-9]{44}$'),
 usuario_id uuid NOT NULL,
 criada_em timestamptz NOT NULL DEFAULT now(),
 itens jsonb NOT NULL,
 CONSTRAINT xml_entradas_teste_itens_array CHECK(jsonb_typeof(itens) = 'array')
);
ALTER TABLE public.xml_entradas_teste ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.xml_entradas_teste FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.registrar_entrada_xml_teste(
 p_chave_nfe text, p_itens jsonb
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
 v_id uuid;
 v_item jsonb;
 v_produto uuid;
 v_quantidade integer;
 v_count integer := 0;
 v_seen uuid[] := ARRAY[]::uuid[];
BEGIN
 IF auth.uid() IS NULL OR NOT public.eh_administrador() THEN
  RAISE EXCEPTION 'Acesso restrito ao administrador';
 END IF;
 IF p_chave_nfe IS NULL OR p_chave_nfe !~ '^[0-9]{44}$' THEN
  RAISE EXCEPTION 'Chave de NF-e inválida';
 END IF;
 IF jsonb_typeof(p_itens) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_itens) NOT BETWEEN 1 AND 500 THEN
  RAISE EXCEPTION 'Lista de itens inválida';
 END IF;
 -- Registro exclusivo por chave; se houver erro, toda a transação reverte.
 INSERT INTO public.xml_entradas_teste(chave_nfe, usuario_id, itens)
 VALUES (p_chave_nfe, auth.uid(), p_itens) RETURNING id INTO v_id;
 FOR v_item IN SELECT value FROM jsonb_array_elements(p_itens)
 LOOP
  IF jsonb_typeof(v_item) <> 'object'
     OR (v_item->>'produto_id') IS NULL
     OR (v_item->>'quantidade') !~ '^[1-9][0-9]{0,6}$' THEN
   RAISE EXCEPTION 'Item inválido; exige produto cadastrado e quantidade inteira positiva';
  END IF;
  BEGIN
   v_produto := (v_item->>'produto_id')::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
   RAISE EXCEPTION 'Identificador de produto inválido';
  END;
  v_quantidade := (v_item->>'quantidade')::integer;
  IF v_produto = ANY(v_seen) THEN
   RAISE EXCEPTION 'Produto duplicado na mesma nota';
  END IF;
  v_seen := array_append(v_seen,v_produto);
  -- O incremento é atômico, sob bloqueio de linha do UPDATE.
  UPDATE public.produtos
  SET quantidade = quantidade + v_quantidade
  WHERE id = v_produto AND ativo = true;
  IF NOT FOUND THEN RAISE EXCEPTION 'Produto não encontrado ou inativo: %',v_produto; END IF;
  v_count := v_count + 1;
 END LOOP;
 IF v_count <> jsonb_array_length(p_itens) THEN RAISE EXCEPTION 'Contagem inconsistente'; END IF;
 RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.registrar_entrada_xml_teste(text,jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_entrada_xml_teste(text,jsonb) TO authenticated;
COMMIT;
-- ATENÇÃO: a função NÃO autentica o XML nem verifica se a NF-e está autorizada.
-- Exige uma validação fiscal independente antes de liberar a operação real.
