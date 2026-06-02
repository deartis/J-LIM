# J-LIM 🧹

**Otimizador Android honesto — opensource, sem anúncios, sem enganação.**

Diferente dos apps da Play Store cheios de animações falsas e propagandas, o J-LIM só mostra o que realmente acontece no seu dispositivo e faz o que é tecnicamente possível sem root.

---

## O que o app faz (de verdade)

| Funcionalidade | Como funciona |
|---|---|
| Monitor de RAM em tempo real | `ActivityManager.MemoryInfo` |
| Uso de CPU | Leitura de `/proc/stat` a cada 3s |
| Análise de armazenamento | `StatFs` sobre `Environment.getDataDirectory()` |
| Detalhes da bateria | `BatteryManager` via `ACTION_BATTERY_CHANGED` |
| Lista de apps com tamanho | `PackageManager` + tamanho do APK |
| Abrir configurações de qualquer app | `Intent ACTION_APPLICATION_DETAILS_SETTINGS` |
| Desinstalar apps | `Intent ACTION_DELETE` |
| Atalho para limpeza do sistema | `Intent ACTION_INTERNAL_STORAGE_SETTINGS` |

---

## O que o app NÃO faz (e por quê)

- ❌ **Matar processos de outros apps** — O Android 8+ bloqueia isso para apps sem root. Qualquer app que "mata RAM" sem root está mentindo.
- ❌ **Limpar cache de outros apps** — A API `clearApplicationUserData()` exige permissão de sistema. Removida do SDK público desde o Android 6.
- ❌ **"Turbo boost" ou animações de otimização** — Teatro. Não existe.

---

## Estrutura do projeto

```
lib/
├── core/
│   ├── theme/         # JLimTheme (paleta escura + verde)
│   └── utils/
│       ├── device_channel.dart    # Bridge Flutter ↔ Kotlin
│       └── device_provider.dart   # Provider central (atualiza a cada 3s)
├── features/
│   ├── dashboard/     # Visão geral + gráficos em tempo real
│   ├── storage/       # Análise de armazenamento + pizza chart
│   └── apps/          # Lista de apps com busca e ordenação
└── main.dart          # NavigationBar com 3 abas

android/app/src/main/kotlin/com/jlim/
└── MainActivity.kt    # Todos os MethodChannels implementados
```

---

## Stack

- **Flutter** 3.x + Dart 3
- **Kotlin** (platform channels)
- **Provider** — state management
- **fl_chart** — gráficos de linha e pizza
- **Hive** — histórico local (pronto para expandir)

---

## Como rodar

```bash
flutter pub get
flutter run
```

> Testado em Android 10+ (API 29+). Recomendado Android 12+ para melhor precisão do StorageStatsManager.

---

## Roadmap v2

- [ ] Histórico de métricas salvo com Hive (gráfico por hora/dia)
- [ ] Detecção de APKs duplicados ou antigos para limpeza manual
- [ ] Aviso de temperatura crítica da bateria (notificação)
- [ ] Widget para a home screen (RAM + bateria)
- [ ] Tema claro opcional

---

## Licença

MIT — faça o que quiser, só não coloca anúncio 😄
