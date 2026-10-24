# Instalação em Dispositivos (Android e iPhone)

Guia para gerar o app e instalá-lo no próprio celular. Este build é o modo
demonstração: os dados ficam apenas em memória e, ao fechar o app, o cenário
de demonstração é recriado. Para o teste real com vários celulares e dados
compartilhados, veja `12_SUPABASE.md`.

| Plataforma | Situação | Precisa de |
|---|---|---|
| Android | Suportado (alvo secundário) | Windows/macOS/Linux + Android SDK |
| iPhone | Fora do escopo do MVP; possível com Mac | macOS + Xcode + Apple ID |
| iPhone sem Mac | Usar a versão Web no Safari | PC e iPhone na mesma rede Wi‑Fi |

---

## Android

### 1. Pré-requisitos

- Flutter instalado (ex.: `C:\src\flutter`). Confira com `flutter doctor`.
- Android Studio instalado (fornece o Android SDK e um Java compatível).
- Licenças do SDK aceitas:

```bash
flutter doctor --android-licenses
```

Se `flutter` não for reconhecido no terminal, adicione-o ao PATH da sessão
(PowerShell):

```powershell
$env:Path = "C:\src\flutter\bin;$env:Path"
```

### 2. Problemas conhecidos no Windows

**Java muito novo.** Se `JAVA_HOME` apontar para um JDK recente demais (ex.: 27),
o Gradle falha com `Unable to establish loopback connection`. Use o Java do
Android Studio apenas na sessão do terminal:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
```

**Pasta TEMP com nome curto (`ROBERT~1.NAS`).** Também pode causar o erro de
loopback. Use uma pasta temporária simples:

```powershell
New-Item -ItemType Directory -Force C:\tmp | Out-Null
$env:TEMP = "C:\tmp"; $env:TMP = "C:\tmp"
```

**Projeto dentro do OneDrive.** O OneDrive trava arquivos da pasta `build`
(`Unable to delete directory ...`) e pode criar cópias com nomes hexadecimais
(ex.: `res/drawable/b9139cf0`) que quebram o build Android. Gere o build a
partir de uma cópia fora do OneDrive, ou mova o projeto para `C:\src\MinduRun`.

### 3. Gerar o APK

Na pasta do projeto, em PowerShell (copia o projeto para `C:\src\mindurun-build`
e gera o APK lá):

```powershell
$env:TEMP="C:\tmp"; $env:TMP="C:\tmp"
$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
$env:Path="C:\src\flutter\bin;$env:JAVA_HOME\bin;$env:Path"
robocopy . C:\src\mindurun-build /MIR /XD build .dart_tool .git android\.gradle android\.kotlin /NFL /NDL /NJH /NP
cd C:\src\mindurun-build
flutter build apk --release
```

Se o projeto já estiver fora do OneDrive, basta `flutter build apk --release`.

O APK fica em:

```text
build\app\outputs\flutter-apk\app-release.apk
```

O primeiro build demora alguns minutos (baixa NDK/CMake). O APK é assinado com
a chave de debug: serve para instalar no próprio celular, não para a Play Store.

### 4. Instalar no celular

**Opção A — copiando o arquivo**

1. Envie `app-release.apk` para o celular (cabo USB, Google Drive, WhatsApp...).
2. Abra o arquivo no celular.
3. Quando solicitado, permita **Instalar apps desconhecidos** para o app que
   abriu o arquivo e confirme a instalação.

**Opção B — pelo terminal (cabo USB)**

1. No celular: **Configurações → Sobre o telefone** → toque 7 vezes em
   **Número da versão** para liberar as Opções do desenvolvedor.
2. Em **Opções do desenvolvedor**, ative **Depuração USB**.
3. Conecte o cabo e aceite **Permitir depuração USB?** no celular.
4. Confira se o aparelho aparece como `device`:

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" devices
```

5. Instale (o `-r` substitui uma versão anterior):

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" install -r C:\src\mindurun-build\build\app\outputs\flutter-apk\app-release.apk
```

Ao aparecer `Success`, o MinduRun estará na lista de apps.

**Opção C — modo desenvolvimento**

Com o celular conectado como na opção B, `flutter run` instala e abre o app com
hot reload:

```bash
flutter run
```

### 5. Atualizar após mudanças no código

Repita os passos 3 e 4. Sempre gere um novo APK antes de reinstalar.

---

## iPhone

O build para iOS **exige um Mac com Xcode**; não é possível gerar o app para
iPhone a partir do Windows. O repositório ainda não possui a pasta `ios/`,
porque iOS está fora do escopo imediato do MVP.

### Opção 1 — Mac com Xcode (app instalado)

1. No Mac, instale Xcode (App Store) e Flutter; rode `flutter doctor`.
2. Instale o CocoaPods se o `flutter doctor` pedir:

```bash
sudo gem install cocoapods
```

3. Na pasta do projeto, gere a plataforma iOS:

```bash
flutter create --platforms=ios .
```

4. Abra `ios/Runner.xcworkspace` no Xcode.
5. Em **Runner → Signing & Capabilities**, marque **Automatically manage
   signing**, selecione seu **Team** (um Apple ID gratuito funciona) e, se
   necessário, troque o **Bundle Identifier** por um único
   (ex.: `br.edu.mindurun.seunome`).
6. Conecte o iPhone por cabo e confie no computador.
7. No iPhone, ative **Ajustes → Privacidade e Segurança → Modo de
   Desenvolvedor** (o iPhone reinicia).
8. Instale e rode:

```bash
flutter run --release
```

9. Na primeira abertura, autorize o desenvolvedor em **Ajustes → Geral → VPN e
   Gerenciamento de Dispositivo**.

Com Apple ID gratuito, o app instalado expira em **7 dias**; basta repetir o
passo 8. Distribuir via TestFlight/App Store exige conta paga do Apple Developer
Program.

### Opção 2 — Sem Mac: versão Web no Safari

O alvo principal do MVP é Web, então o iPhone pode usar o app pelo navegador.

1. Conecte PC e iPhone na **mesma rede Wi‑Fi**.
2. No PC, descubra o IP local (`ipconfig`, campo **Endereço IPv4**, ex.:
   `192.168.0.15`).
3. Na pasta do projeto, rode o servidor aceitando conexões da rede:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8787
```

4. No Safari do iPhone, abra `http://192.168.0.15:8787` (use o seu IP).
5. Opcional: **Compartilhar → Adicionar à Tela de Início** para abrir como app.

Se não carregar, libere a porta 8787 no Firewall do Windows quando solicitado.
Redes corporativas ou de faculdade podem bloquear conexões entre aparelhos;
nesse caso, use o roteador do celular (hotspot) para conectar o PC.

O mesmo procedimento funciona em Android pelo Chrome, sem instalar APK.
