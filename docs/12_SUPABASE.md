# Modo sincronizado (Supabase) — teste real

Para o teste de 30/10, cada participante instala o APK no próprio Android e
entra numa sala compartilhada. Para isso o app tem dois modos:

| Modo | Quando | Dados |
|---|---|---|
| Demonstração | Build sem configuração (`flutter run`, testes, Chrome) | Seed local em memória, 5 perfis fixos |
| Sincronizado | Build com `--dart-define-from-file=config/supabase.json` | Supabase: compartilhado entre celulares e persistente |

Regras de domínio, telas e testes são os mesmos nos dois modos.

## Como funciona

- **Identidade:** cada celular entra com uma conta anônima do Supabase. Na
  primeira abertura a pessoa digita o nome (2 a 30 caracteres). A sessão fica
  salva no aparelho; não há "Trocar usuário" nem "Resetar demonstração".
- **Dados:** os repositórios em memória viram um cache local. Cada ação é
  aplicada no cache na hora e enviada ao servidor numa fila (em ordem). O cache
  é recarregado do servidor ao receber notificações em tempo real, a cada 20 s
  e quando o app volta ao primeiro plano.
- **Falhas:** sem internet, o app mostra um aviso e tenta de novo. Se um envio
  falhar, aparece "Não foi possível salvar no servidor" e os dados são
  recarregados do servidor.
- **Evidências:** o print é escolhido na galeria, reduzido/comprimido
  (máx. 1440 px de largura, JPEG 75%) e enviado ao bucket `evidence` antes da
  atividade que o referencia.

Código: `lib/core/remote/` (store, engine, repositórios sincronizados) e
`lib/app/bootstrap/synced_startup.dart`.

## Configurar o Supabase (uma vez)

1. Crie um projeto gratuito em <https://supabase.com> (região *South America
   (São Paulo)*).
2. **SQL Editor → New query**: cole o conteúdo de `supabase/schema.sql` e clique
   em **Run**. (Rodar de novo apaga todos os dados do MinduRun.)
3. **Authentication → Sign In / Providers**: ative **Allow anonymous sign-ins**.
4. **Project Settings → API Keys**: copie a *Project URL* e a *Publishable key*
   (ou a *anon public* legada).
5. Crie `config/supabase.json` a partir de `config/supabase.example.json` com
   esses dois valores. Esse arquivo não vai para o Git.

## Gerar o APK do teste

Igual ao `11_INSTALACAO_DISPOSITIVOS.md`, trocando o último comando por:

```powershell
flutter build apk --release --dart-define-from-file=config/supabase.json
```

Sem o `--dart-define-from-file`, o APK sai em modo demonstração.

A cada novo APK, aumente o número depois do `+` em `version:` no
`pubspec.yaml` para que ele instale por cima do anterior sem perder a conta.
Gere sempre na mesma máquina (o APK é assinado com a chave de debug dela).

## Roteiro do dia do teste

1. Todos instalam o APK e digitam o nome.
2. O organizador cria a sala e compartilha o código de convite.
3. **Todos entram na sala antes de criar a competição.** Os participantes são
   uma foto dos membros no momento da criação; quem entrar depois não participa
   daquela competição.
4. O dono da sala cria a competição.
5. Corridas, prints, denúncias e votos aparecem nos outros celulares em poucos
   segundos.

## Limitações conhecidas

- Quem desinstalar o app ou limpar os dados perde a conta anônima e precisa
  entrar de novo com outro nome.
- Prints ficam num bucket público (qualquer pessoa com o link vê). Apague o
  projeto ou os dados após o teste.
- A resolução de votação é feita no celular de quem dá o voto decisivo; o banco
  impede votos duplicados e votos em denúncias já encerradas.
- Login anônimo do Supabase tem limite por IP (padrão 30/h): muitos celulares
  na mesma rede Wi‑Fi instalando ao mesmo tempo podem precisar esperar.
