# Switcher

Меню-бар приложение для macOS (Apple Silicon), которое переключает раскладку клавиатуры по **Shift+Alt** — как в Windows.

## Возможности

- Иконка в строке меню (трей)
- Горячая клавиша **⇧⌥ (Shift+Option/Alt)** — циклическое переключение раскладок
- Автозапуск при входе в систему
- Работает в фоне без иконки в Dock (`LSUIElement`)

## Требования

- macOS 13 Ventura или новее
- Apple Silicon (arm64)
- Две или больше раскладок в **Системные настройки → Клавиатура → Источники ввода**

## Сборка

```bash
chmod +x Scripts/build.sh
./Scripts/build.sh
```

Готовое приложение: `build/Switcher.app` (Hardened Runtime, ad-hoc подпись).

### Developer ID + notarization (опционально)

```bash
export SWITCHER_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./Scripts/build.sh
xcrun notarytool submit build/Switcher.app --keychain-profile "notary" --wait
xcrun stapler staple build/Switcher.app
```

## Установка

```bash
cp -R build/Switcher.app /Applications/
open /Applications/Switcher.app
```

## Первый запуск — разрешения

### 1. Accessibility (обязательно)

При первом запуске macOS попросит доступ. Без него глобальная горячая клавиша не работает.

**Системные настройки → Конфиденциальность и безопасность → Универсальный доступ** → включите **Switcher**.

Или выберите пункт «Выдать доступ Accessibility…» в меню приложения.

После выдачи доступа перезапустите приложение.

### 2. Автозапуск

В меню приложения включите **«Запускать при входе в систему»**.

Приложение должно лежать в `/Applications` (или быть зарегистрировано как обычное .app), иначе `SMAppService` может отказать.

## Использование

1. Зажмите **Shift** и **Alt (Option)**
2. Отпустите — раскладка переключится на следующую
3. Если вместе с ⇧⌥ нажать обычную клавишу (спецсимвол), переключения не будет

## Удаление

```bash
# выключите автозапуск в меню приложения, затем:
rm -rf /Applications/Switcher.app
```
