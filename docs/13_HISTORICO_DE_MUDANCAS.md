# Histórico de mudanças (22 a 24/10/2026)

Este documento resume o que mudou no MinduRun desde a versão inicial do MVP
(commit `43a59d2`, 22/10) até a versão **0.4.0+5**, e por quê. Serve de ponto
de partida para quem chegar ao projeto agora. As regras completas continuam
nos documentos citados em cada seção.

## Resumo

O MVP original era uma **demonstração num único aparelho**: dados só em
memória, 5 perfis fixos e nenhuma comunicação entre celulares. Para o **teste
real de 30/10/2026**, em que cada participante instala o app no próprio
Android e entra numa sala compartilhada, o projeto passou a ter:

1. **Modo sincronizado com Supabase** (login anônimo, banco, tempo real e
   armazenamento de prints), mantendo o modo demonstração intacto.
2. **Regras reforçadas no servidor** (moderação, participação, período,
   prints duplicados).
3. **Melhorias de experiência de uso** (ritmo automático, convites,
   pendências, perfil, curtidas/comentários etc.).
4. **Nova identidade visual** (feita em paralelo, em outra conversa).

Testes automatizados: de 110 para **164**, todos passando.

## Linha do tempo

| Data | Commit | Mudança | Onde está |
|---|---|---|---|
| 23/10 | `6b9078d` | Remove arquivos duplicados criados pelo OneDrive | `main` |
| 23/10 | `47260f3` | Guia de instalação Android/iPhone (`11_INSTALACAO_DISPOSITIVOS.md`) | `main` |
| 23/10 | `7bc75d6` | 1ª identidade visual (verde + laranja) | `main` (PR #1) |
| 23/10 | `74101c9` | Modo sincronizado com Supabase | `main` (PR #2) |
| 23/10 | `51ae9bc` | Participação tardia, confirmação de envio, moderação no servidor | `main` (PR #2) |
| 23/10 | `a64e57a` | Resultado final, bloqueio de print duplicado, relógio do servidor | branch |
| 23/10 | `021d26a` | Alterar nome, consentimento, scripts de limpeza e monitoramento | branch |
| 23/10 | `9dd0dc3`, `50480ec` | Tema escuro, nova logo e ícone do Android | branch |
| 23/10 | `bf94d82` | UX: ritmo automático, convite, pendências, sincronização, regras | branch |
| 23/10 | `afa1208` | UX: perfil, excluir corrida, sair da sala, curtidas e comentários | branch |
| 23/10 | `782d02e`, `7a12378` | Versões 0.3.0+4 e 0.4.0+5 (APKs) | branch |

"branch" = `feature/supabase-backend`, ainda não mesclada na `main` quando
este documento foi escrito. Regra de trabalho combinada: **nada é feito
direto na `main`**; cada mudança vai numa branch `feature/...` e entra por PR.

## 1. Modo sincronizado (Supabase)

Por que: sem backend, a sala criada num celular não existia nos outros e os
dados sumiam ao fechar o app. A decisão está em
[`adr/0001-supabase-synced-mode.md`](adr/0001-supabase-synced-mode.md).

- **Dois modos, escolhidos no build.** Sem configuração → modo
  demonstração (igual ao original; é o que os testes e o Chrome usam). Com
  `--dart-define-from-file=config/supabase.json` → modo sincronizado.
- **Arquitetura** (`lib/core/remote/`, detalhes em `03_ARCHITECTURE.md`):
  os repositórios em memória viraram **cache local**; os repositórios
  `Synced*` gravam no cache na hora (as telas continuam síncronas) e enviam
  ao servidor por uma **fila ordenada** (`SyncEngine`). O cache é recarregado
  por inteiro em eventos de tempo real, a cada 20 s, ao voltar ao app e ao
  puxar para atualizar — nunca enquanto há envio pendente.
- **Identidade:** uma conta anônima por celular + nome digitado (tabela
  `profiles`). Não há troca de perfil nem reset de demonstração nesse modo.
- **Prints:** comprimidos no celular (`image_picker`, 1440 px, JPEG 75%) e
  enviados ao bucket `evidence` antes da corrida que os usa.
- **Confirmação real:** "Atividade publicada" só aparece depois que o
  servidor aceitou print e corrida; falhas mantêm o formulário.
- **Relógio:** o app corrige a hora do celular com a do servidor
  (`server_now`) a cada recarga.
- **IDs:** gerados aleatoriamente no aparelho (`newRemoteId`), códigos de
  convite com 6 caracteres sem ambíguos (0/O, 1/I/L).

Configuração passo a passo, roteiro do dia do teste e limitações:
[`12_SUPABASE.md`](12_SUPABASE.md).

### Banco de dados (rodar no SQL Editor, nesta ordem)

| Arquivo | Conteúdo | Apaga dados? |
|---|---|---|
| `supabase/schema.sql` | Tabelas, RLS, realtime, bucket `evidence` | **Sim**, se rodado de novo |
| `migrations/002_join_and_server_moderation.sql` | `join_competition`, `create_report`, `cast_vote`; corrida só no período (hora do servidor) | Não |
| `migrations/003_duplicates_and_clock.sql` | Coluna/índice `evidence_hash`, `server_now` | Não |
| `migrations/004_social_leave_delete.sql` | `delete_activity`, sair/remover membro, curtidas, comentários | Não |
| `supabase/monitoring.sql` | Consultas só de leitura para acompanhar o teste | Não |
| `supabase/cleanup.sql` | Apaga todos os dados e contas anônimas após o teste | **Sim** |

O app tolera um banco sem a 003/004 (abre e lê), mas as ações dessas
migrações falham ao salvar. O projeto Supabase atual já tem 002, 003 e 004.

## 2. Regras de domínio novas ou alteradas

Todas estão em [`02_DOMAIN_RULES.md`](02_DOMAIN_RULES.md) e, no modo
sincronizado, são repetidas no servidor (funções/políticas SQL). **Ao mudar
uma regra, mude o Dart e o SQL.**

| Regra | Dart | Servidor |
|---|---|---|
| Membro que entrou depois pode **participar** da competição enquanto agendada/ativa | `CompetitionRules.canJoin` | `join_competition` |
| Denúncia e voto com apuração atômica | `ModerationService` | `create_report`, `cast_vote` |
| Corrida só de participante e dentro do período | `ActivitySubmissionService` | política de insert em `activities` |
| **Resultado final**: campeão, empate dividido, pódio, "provisório" com denúncia aberta | `CompetitionResultService` | — (derivado) |
| **Print duplicado** bloqueado por competição (SHA-256) | `duplicateEvidenceError` | índice único `evidence_hash` |
| **Excluir a própria corrida**: publicada, nunca denunciada, competição ativa | `canDelete` | `delete_activity` |
| **Sair da sala** (exceto o criador) / criador remove membros; participação em competições é mantida | `RoomRules.canLeave/canRemove` | política de delete em `room_members` |
| **Curtidas** (não na própria) e **comentários** (1–280), só participantes | `SocialRules` | políticas em `activity_likes`/`activity_comments` |
| Nome de 2 a 30 caracteres | `ProfileRules` | check em `profiles` |

Pontuação, ranking, tolerância de ritmo e regras de votação **não mudaram**.

## 3. Funcionalidades de experiência de uso

| Funcionalidade | Onde no app | Código principal |
|---|---|---|
| Ritmo calculado pela distância e duração (editável) | Registrar atividade | `ActivityInput.suggestPace` |
| Compartilhar convite com mensagem pronta | Detalhes da sala | `RoomRules.inviteMessage`, `share_plus` |
| Link de convite `mindurun://open/join/CODIGO` | Android / rota `/join/:code` | `JoinInvitePage`, `PendingInvite` |
| Card "Pendências" (votações e competições para participar) | Tela inicial | `PendingActionsService` |
| Puxar para atualizar + "Atualizado há X / Sem conexão / Enviando" | Início, sala, competição | `SyncStatus`, `refreshDataProvider` |
| Contagem regressiva ("Termina em 2 dias") | Card e tela da competição | `competitionCountdown` |
| "Como funciona" (após o 1º cadastro e por link) | Tela inicial | `showHowItWorks` |
| Consentimento de privacidade obrigatório | Entrada | `privacyNotice` |
| Alterar nome | Ícone de lápis na tela inicial | `SessionController.saveProfile` |
| Meu perfil (pontos, km válidos, histórico) | Botão ">" no card do topo | `ProfileStatsService` |
| Curtir e comentar | Feed da competição | `SocialController` |
| Excluir a própria corrida | Feed (botão "Excluir") | `ActivitiesController.deleteActivity` |
| Sair da sala / remover membro | Detalhes da sala | `RoomsController` |

## 4. Visual

Feito em outra conversa, de propósito separado das funcionalidades: primeira
identidade (verde Mindu + laranja), depois **tema escuro e nova logo** vindos
de um design no Lovable, ícone do Android com a logo, pódio animado no
resultado final. Componentes compartilhados em `lib/app/theme/`
(`app_theme.dart`, `app_widgets.dart`). Mudanças de visual não alteram regras;
os textos conferidos pelos testes devem ser mantidos.

## 5. Android e distribuição

- Permissão de internet no manifesto principal, nome "MinduRun", ícone
  próprio, link `mindurun://open/...` registrado.
- APK gerado **fora do OneDrive** (cópia em `C:\src\mindurun-build`), com
  `flutter build apk --release --dart-define-from-file=config/supabase.json`
  (ver `11_INSTALACAO_DISPOSITIVOS.md` e `12_SUPABASE.md`).
- Aumente o número após o `+` em `version:` a cada APK para instalar por cima
  sem perder a conta. Gere sempre na mesma máquina (assinatura de debug).
- Para testar mudanças, prefira o **localhost** (Flutter Web em modo
  sincronizado) e gere APK só quando necessário — o build leva de 4 a 10 min.

## 6. Dependências adicionadas

| Pacote | Para quê |
|---|---|
| `supabase_flutter` | Backend do modo sincronizado |
| `image_picker` | Escolher e comprimir o print na galeria |
| `crypto` | SHA-256 do print (bloqueio de duplicados) |
| `share_plus` | Compartilhar convite |

## 7. Testes

164 testes (`flutter test`), incluindo: motor de sincronização com um
servidor falso (`test/core/sync_engine_test.dart`), conversão de linhas do
banco, regras novas (resultado, duplicados, contagem, pendências, social,
exclusão, salas) e testes de tela (entrada com consentimento, convite antes do
login, resultado final, perfil). As **funções SQL não têm teste automático**:
são verificadas no uso real e com `monitoring.sql`.

## 8. Pendências e cuidados para quem continuar

- **Fila offline persistente (adiada para depois do teste):** hoje, se o app
  for fechado com um envio pendente, esse envio se perde (a tela avisa e só
  confirma após o servidor aceitar). Resolver exige armazenamento local, o que
  o `AGENTS.md` proíbe para dados de domínio — precisa de decisão de escopo.
- **Link de convite no WhatsApp:** o WhatsApp não torna `mindurun://`
  clicável; o código continua sendo o caminho principal.
- **Prints em bucket público:** quem tiver o link vê. Apague os dados após o
  teste (`cleanup.sql` + "Empty bucket").
- **Riverpod:** um provider que observa vários providers "família" pelo mesmo
  caminho causou erro ao voltar para uma tela (`setState` durante o build).
  Providers de tela inicial/resultado observam só os controladores raiz ou se
  descartam (`autoDispose`); siga o mesmo padrão.
- **Arquivos fora do Git:** `config/supabase.json` (URL e chave do projeto;
  copie de `config/supabase.example.json`) e `.claude/launch.json`
  (configurações locais de preview).
- **iPhone:** fora do escopo; só há APK Android.
