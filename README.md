# Тема Fly «Astra 1.8 Fly Dark» + автосмена день/ночь

Тёмная тема оформления **Fly** для **Astra Linux 1.8** (Special Edition / Common
Edition, X11) и автоматическая смена темы по времени суток: днём — светлая
версия этой темы (светлые панель, меню и обои, но те же тёмные рамки окон),
ночью — тёмная тема.

Обе темы используют одинаковое оформление рамок окон (`#262626`, без толстой
рамки). Это важно: если днём переключаться на штатную светлую тему с голубыми
рамками, Fly может оставить у верха окна светлую 1 px кромку от прежней темы
до перезапуска `fly-wm`.

Тема повторяет оформление рабочего стола, собранное при настройке Astra:
заголовок и кромки окон в тон окну (`#262626`), без цветной окантовки; толстая
рамка отключена (`FrameBorderWidth=0`); тёмный интерфейс (меню, панель задач,
диалоги), обои `fly-default-red.jpg`.

## Скриншоты

| День (`Astra18FlyLight`) | Ночь (`Astra18FlyDark`) |
|---|---|
| ![День](docs/screenshots/day.png) | ![Ночь](docs/screenshots/night.png) |

## Состав

- тёмная тема Fly `Astra18FlyDark` и светлая `Astra18FlyLight`
  (Id темы, `index.theme` + `theme/themerc`); у обеих — тёмные (без синих
  линий) рамки окон;
- пользовательские цветовые схемы `Astra18FlyDark.colors` и
  `Astra18FlyLight.colors` (в `[WM]`: заголовок/рамки `38,38,38`);
- `fly-theme-apply` — применить тему по Id;
- `fly-theme-switch` — демон автосмены день/ночь и CLI;
- установка в профиль (`install.sh` / `uninstall.sh`) и сборка `.deb`.

## Требования

- Astra Linux 1.8 с рабочим столом **Fly** (X11);
- пакет `fly-admin-theme` (`fly-select-theme`, `fly-wmfunc`, `fly-admin-theme`);
- `python3`, `bash`;
- композитор: в Astra Linux Fly используется `compton` (пакет `picom`);
- светлая тема входит в комплект (`Astra18FlyLight`), штатная
  `AstraProximaLight` не требуется.

## Установка в профиль пользователя (без root)

```sh
git clone https://github.com/Xivilai73/astra-1.8-fly-theme.git
cd astra-1.8-fly-theme
./install.sh
```

Скрипт:

1. копирует темы в `~/.local/share/flythemes/Astra18FlyDark` и
   `~/.local/share/flythemes/Astra18FlyLight`;
2. копирует схемы в `~/.local/share/color-schemes/` (обе);
3. ставит `~/.local/bin/fly-theme-apply` и `~/.local/bin/fly-theme-switch`;
4. создаёт конфиг `~/.config/fly-theme-switch.conf` (если его ещё нет);
5. добавляет автозапуск `~/.config/autostart/fly-theme-switch.desktop`;
6. сохраняет бэкап текущего оформления и применяет тему по текущему времени
   суток, запускает демон.

Скрипт идемпотентен: повторный запуск обновляет файлы темы/скриптов, не
перезаписывая конфиг и бэкап.

## Готовый пакет

Собранный пакет и контрольная сумма — в [GitHub Releases](https://github.com/Xivilai73/astra-1.8-fly-theme/releases/tag/v1.0.0):

- [astra-1.8-fly-theme_1.0.0-1_all.deb](https://github.com/Xivilai73/astra-1.8-fly-theme/releases/download/v1.0.0/astra-1.8-fly-theme_1.0.0-1_all.deb)
- [SHA256SUMS](https://github.com/Xivilai73/astra-1.8-fly-theme/releases/download/v1.0.0/SHA256SUMS)

```sh
sha256sum -c SHA256SUMS
sudo dpkg -i astra-1.8-fly-theme_1.0.0-1_all.deb
```

## Установка из .deb (системно)

```sh
make deb          # или ./build-deb.sh
sudo dpkg -i dist/astra-1.8-fly-theme_1.0.0-1_all.deb
sudo apt-get -f install
```

Пакет ставит тему в `/usr/share/flythemes`, схему в
`/usr/share/color-schemes`, скрипты в `/usr/bin`, демон — в
`/etc/xdg/autostart`. Тему из пакета можно выбрать в
«Параметры → Оформление → Темы» как «Astra 1.8 Fly Dark».

> Пакет ставится системно (нужен root), но применяется к пользователю при входе
> в сеанс — через демон автосмены.

## Автосмена день/ночь

Конфиг — `~/.config/fly-theme-switch.conf`:

```ini
DAY_START=08:00
NIGHT_START=20:00
DAY_THEME=Astra18FlyLight
NIGHT_THEME=Astra18FlyDark
CHECK_INTERVAL=60
```

- `DAY_START..NIGHT_START` — день; если `DAY_START > NIGHT_START`, интервал
  считается переходящим через полночь;
- `DAY_THEME` / `NIGHT_THEME` — Id тем Fly (см. `fly-theme-apply --list`);
  можно указать штатную `AstraProximaLight`, но тогда при смене на тёмную тему
  возможна светлая 1 px кромка у окна до перезапуска `fly-wm`;
- проверка — раз в `CHECK_INTERVAL` секунд.

Демон запускается автоматически при входе в сеанс (автозапуск `.desktop`).
Тема меняется только при смене фазы: ручной выбор темы в течение дня/ночи не
перебивается до следующей границы.

### Команды

```sh
fly-theme-switch --status                 # фаза, текущая тема, статус демона
fly-theme-switch --apply day|night|auto   # применить тему фазы вручную
fly-theme-switch --apply Astra18FlyDark   # применить конкретную тему
fly-theme-switch --once                   # один тик автосмены
fly-theme-switch --daemon                 # запустить демон вручную
```

Журнал — `~/.local/state/fly-theme-switch/log`, состояние — `state` в том же
каталоге. Повторный запуск демона не создаёт второй экземпляр (`flock`).

### Ручное переключение тем

```sh
fly-theme-apply --list
fly-theme-apply Astra18FlyDark
fly-theme-apply Astra18FlyLight
```

`fly-theme-apply` использует штатную утилиту Fly `fly-select-theme`: цвета,
панель задач, меню, заголовки окон и обои применяются на лету. Так как обе
темы используют одинаковые тёмные рамки окон, переключение не оставляет
светлых «кромок» от прежней темы. Если `fly-select-theme` недоступна,
используется резервный способ: запись `~/.config/fly-admin-themerc` и
`~/.fly/paletterc` плюс перезапуск `fly-wm`.

## Как это работает

- Тема Fly — каталог `flythemes/<Id>` (`index.theme` + `theme/themerc`) и
  цветовая схема (`*.colors`). `fly-select-theme` копирует параметры темы в
  `~/.fly/theme/current.themerc`, обновляет палитру и применяет оформление.
- В themerc темы путь к схеме подставляется при установке (плейсхолдер
  `@SCHEME_PATH@`): в профиле — `~/.local/share/color-schemes/`, в пакете —
  `/usr/share/color-schemes/`.
- `fly-theme-switch` считает фазу по локальному времени, сравнивает с
  сохранённым состоянием и при смене фазы вызывает `fly-theme-apply`.

## Ограничения

- **Нет широкого края для изменения размера мышью**: в теме
  `FrameBorderWidth=0` (тонкая кромка 1 px, как в текущем оформлении). Чтобы
  вернуть классическую рамку, добавьте в
  `~/.local/share/flythemes/Astra18FlyDark/theme/themerc` строку
  `FrameBorderWidth=5` и переключите тему заново.
- Смена темы через Fly кратковременно перезапускает панель задач/меню
  (несколько секунд); открытые окна не закрываются.
- Если выбрать днём штатную `AstraProximaLight` (голубые рамки окон), при
  переключении на тёмную тему Fly может оставить светлую 1 px кромку у верха
  окна до перезапуска `fly-wm` (`fly-wmfunc FLYWM_RESTART`). Поэтому в
  комплекте — светлая тема `Astra18FlyLight` с такими же тёмными рамками.
- Если нужная тема не установлена, переключение не произойдёт — запись об
  ошибке попадёт в журнал, останется текущая тема.
- Ручные изменения оформления через «Параметры» будут перезаписаны при
  следующей автосмене — для своих постоянных настроек правьте тему/конфиг.

## Удаление

```sh
./uninstall.sh
```

Скрипт останавливает демон, удаляет тему, схему, скрипты, автозапуск и конфиг,
затем восстанавливает оформление, сохранённое при установке.

## Структура репозитория

```
astra-1.8-fly-theme/
├── README.md
├── LICENSE                    # MIT
├── Makefile                   # install / uninstall / deb / clean
├── install.sh                 # установка в профиль
├── uninstall.sh
├── build-deb.sh
├── packaging/
│   ├── control
│   └── fly-theme-switch.desktop
├── src/
│   ├── themes/Astra18FlyDark/   # index.theme + theme/themerc
│   ├── themes/Astra18FlyLight/  # index.theme + theme/themerc
│   ├── colors/Astra18FlyDark.colors
│   ├── colors/Astra18FlyLight.colors
│   ├── fly-theme-apply
│   ├── fly-theme-switch
│   └── fly-theme-switch.conf
└── docs/screenshots/
```

## Лицензия

MIT, см. [LICENSE](LICENSE).
