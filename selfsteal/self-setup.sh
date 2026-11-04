#!/bin/bash
set -eu

[ "$(id -u)" -eq 0 ] || { echo "Запустите от root"; exit 1; }

D="${1:-}"; THEME="${2:-}"

if [ -z "$D" ]; then
  read -rp "Домен ноды (например ni-1.example.com): " D </dev/tty
fi
D="${D,,}"
[[ "$D" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}$ ]] || { echo "Неверный домен: $D"; exit 1; }

if [ -z "$THEME" ]; then
  echo "Тема сайта:"
  echo "  1) Rust (игровое сообщество)"
  echo "  2) Борщ (кухня борща)"
  echo "  3) Пекарня (хлеб на закваске)"
  read -rp "Номер: " N </dev/tty
  case "$N" in 1) THEME=rust;; 2) THEME=borsch;; 3) THEME=bakery;; *) echo "Неверный выбор"; exit 1;; esac
fi
case "$THEME" in rust|borsch|bakery) ;; *) echo "Темы: rust, borsch, bakery"; exit 1;; esac

echo "== Домен: $D, тема: $THEME =="

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y dnsutils curl >/dev/null

MYIP=$(curl -4 -s ifconfig.me)
DNSIP=$(dig +short A "$D" @1.1.1.1 | tail -1)
echo "IP сервера: $MYIP | DNS $D: ${DNSIP:-пусто}"
if [ "$MYIP" != "$DNSIP" ] && [ "${FORCE:-0}" != "1" ]; then
  echo "ОШИБКА: A-запись $D должна указывать на $MYIP (серая тучка в Cloudflare)."
  echo "Создайте запись, подождите и запустите снова."
  exit 1
fi

port_busy() { ss -tlnH "sport = :$1" | grep -q .; }

if port_busy 80; then
  if ! { command -v nginx >/dev/null && systemctl is-active --quiet nginx; }; then
    echo "ОШИБКА: порт 80 занят не системным nginx (возможно, nginx в Docker)."
    echo "Автоматическая установка здесь небезопасна, настройте вручную."
    exit 1
  fi
fi

apt-get install -y nginx certbot >/dev/null
rm -f /etc/nginx/sites-enabled/default
mkdir -p /var/www/acme /var/www/site

if ! nginx -T 2>/dev/null | grep -Eq '^\s*server_tokens\s+off'; then
  echo 'server_tokens off;' > /etc/nginx/conf.d/00-tokens.conf
fi

if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp >/dev/null
fi

OLD=$(ls /etc/nginx/conf.d/stub*.conf 2>/dev/null | head -1 || true)
PORT=""
if [ -n "$OLD" ]; then
  PORT=$(grep -oP 'listen 127\.0\.0\.1:\K[0-9]+' "$OLD" | head -1 || true)
  rm -f /etc/nginx/conf.d/stub*.conf
fi
if [ -z "$PORT" ]; then
  for p in 8443 9443 10443 11443; do
    if ! port_busy "$p"; then PORT=$p; break; fi
  done
fi
[ -n "$PORT" ] || { echo "Не нашёл свободный порт для заглушки"; exit 1; }
echo "Порт заглушки: 127.0.0.1:$PORT"

cat > /etc/nginx/conf.d/redirect80.conf <<EOF
server {
    listen 80;
    server_name $D;
    location /.well-known/acme-challenge/ { root /var/www/acme; }
    location / { return 301 https://\$host\$request_uri; }
}
EOF
nginx -t
systemctl enable --now nginx
systemctl reload nginx

if [ ! -f "/etc/letsencrypt/live/$D/fullchain.pem" ]; then
  certbot certonly --webroot -w /var/www/acme -d "$D" --cert-name "$D" \
    --agree-tos --register-unsafely-without-email --non-interactive
fi
openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$D/fullchain.pem"

mkdir -p /etc/letsencrypt/renewal-hooks/deploy
printf '#!/bin/sh\nsystemctl reload nginx\n' > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
systemctl enable --now certbot.timer 2>/dev/null || true

NGV=$(nginx -v 2>&1 | grep -o '[0-9.]*$')
if [ "$(printf '%s\n1.25.1\n' "$NGV" | sort -V | head -1)" = "1.25.1" ]; then
  H2L="ssl"; H2D="http2 on;"
else
  H2L="ssl http2"; H2D=""
fi

cat > /etc/nginx/conf.d/stub-selfsteal.conf <<EOF
server {
    listen 127.0.0.1:$PORT $H2L;
    $H2D
    server_name $D;
    ssl_certificate     /etc/letsencrypt/live/$D/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$D/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    root /var/www/site;
    index index.html;
    error_page 404 /404.html;
    location / { try_files \$uri \$uri/ =404; }
}
EOF
nginx -t
systemctl reload nginx

MAIL="hello@$D"

case "$THEME" in
rust)
  BRAND='Rusty<span>Hollow</span>'; TITLE='Rusty Hollow'
  DESC='Rusty Hollow — сообщество игроков в Rust: вайпы по расписанию, понятные правила.'
  FOOT='Неофициальный фан-проект, не связан с Facepunch Studios'
  NAV='<a href="/rules.html">Правила</a><a href="/wipes.html">Вайпы</a><a href="/contacts.html">Контакты</a>'
  BG='#f4f1ec'; FG='#241f1a'; MUTED='#6f655a'; CARD='#ffffff'; LINE='#e0d9cd'; ACCENT='#c2410c'; SOFT='#ebe5da'
  DBG='#14110f'; DFG='#ece6dc'; DMUTED='#a69b8d'; DCARD='#1c1815'; DLINE='#322b25'; DACCENT='#ea6a2a'; DSOFT='#201b17'
  BODYFONT='system-ui,-apple-system,"Segoe UI",Roboto,sans-serif'
  HEADFONT='"Arial Narrow","Roboto Condensed",Impact,system-ui,sans-serif'
  HTRANS='text-transform:uppercase;letter-spacing:.04em'
  ;;
borsch)
  BRAND='Красная <span>ложка</span>'; TITLE='Красная ложка'
  DESC='Красная ложка — небольшая кухня борща: домашние борщи, пампушки, доставка.'
  FOOT='Кухня борща'
  NAV='<a href="/menu.html">Меню</a><a href="/delivery.html">Доставка</a><a href="/contacts.html">Контакты</a>'
  BG='#fbf4f1'; FG='#2a1519'; MUTED='#7a5a60'; CARD='#ffffff'; LINE='#ecd9d8'; ACCENT='#a4161a'; SOFT='#f5e4e1'
  DBG='#170c0e'; DFG='#f3e3e1'; DMUTED='#b79a9e'; DCARD='#211215'; DLINE='#3a1f24'; DACCENT='#e0494f'; DSOFT='#1d1013'
  BODYFONT='Georgia,"Times New Roman",serif'
  HEADFONT='system-ui,-apple-system,"Segoe UI",Roboto,sans-serif'
  HTRANS='letter-spacing:-.01em'
  ;;
bakery)
  BRAND='Заква<span>ска</span>'; TITLE='Закваска'
  DESC='Закваска — небольшая пекарня: хлеб на живой закваске, выпечка, кофе.'
  FOOT='Пекарня'
  NAV='<a href="/menu.html">Ассортимент</a><a href="/about.html">О пекарне</a><a href="/contacts.html">Контакты</a>'
  BG='#fbf7ee'; FG='#2c2417'; MUTED='#7d6f58'; CARD='#ffffff'; LINE='#ece3cf'; ACCENT='#b7791f'; SOFT='#f6edd8'
  DBG='#16130d'; DFG='#f4ecda'; DMUTED='#b3a589'; DCARD='#1e1a12'; DLINE='#342d1e'; DACCENT='#e0a645'; DSOFT='#272014'
  BODYFONT='Georgia,"Times New Roman",serif'
  HEADFONT='system-ui,-apple-system,"Segoe UI",Roboto,sans-serif'
  HTRANS='letter-spacing:-.01em'
  ;;
esac

FAV="%23${ACCENT#\#}"
cd /var/www/site
rm -f ./*.html style.css robots.txt

cat > style.css <<EOF
:root{--bg:$BG;--fg:$FG;--muted:$MUTED;--card:$CARD;--line:$LINE;--accent:$ACCENT;--soft:$SOFT}
@media (prefers-color-scheme:dark){:root{--bg:$DBG;--fg:$DFG;--muted:$DMUTED;--card:$DCARD;--line:$DLINE;--accent:$DACCENT;--soft:$DSOFT}}
*{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth}
body{font:17px/1.7 $BODYFONT;background:var(--bg);color:var(--fg)}
h1,h2,h3,.logo,nav,.btn,.price,.tag{font-family:$HEADFONT;$HTRANS}
a{color:var(--accent)}
.wrap{max-width:1040px;margin:0 auto;padding:0 24px}
header{border-bottom:1px solid var(--line);position:sticky;top:0;background:var(--bg);z-index:5}
header .wrap{display:flex;justify-content:space-between;align-items:center;min-height:64px;flex-wrap:wrap;gap:8px}
.logo{font-weight:800;font-size:21px;color:var(--fg);text-decoration:none}
.logo span{color:var(--accent)}
nav a{color:var(--muted);text-decoration:none;margin-left:20px;font-size:15px}
nav a:hover{color:var(--accent)}
.hero{padding:84px 0 56px}
.hero h1{font-size:clamp(34px,6vw,58px);line-height:1.08;max-width:760px}
.hero p{color:var(--muted);font-size:19px;max-width:600px;margin:20px 0 32px}
.page-title{padding:56px 0 24px}
.page-title h1{font-size:clamp(28px,5vw,40px)}
.page-title p{color:var(--muted);margin-top:10px;max-width:620px}
.btn{display:inline-block;background:var(--accent);color:#fff;text-decoration:none;padding:12px 26px;border-radius:6px;font-weight:700}
.btn.ghost{background:transparent;color:var(--fg);border:1px solid var(--line);margin-left:10px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px;padding-bottom:56px}
.card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:24px}
.card h3{margin-bottom:6px;font-size:18px}
.card p{color:var(--muted);font-size:15px;line-height:1.6}
.price,.tag{display:inline-block;margin-top:12px;font-weight:700;color:var(--accent)}
.band{background:var(--soft);border-top:1px solid var(--line);border-bottom:1px solid var(--line);padding:44px 0}
.band h2{font-size:26px;margin-bottom:10px}
.band p{color:var(--muted);max-width:640px}
.text{padding:8px 0 56px;max-width:700px}
.text p{margin-bottom:16px;color:var(--muted)}
.text h2{font-size:22px;margin:28px 0 10px}
.text ol{margin:0 0 16px 22px;color:var(--muted)}
.text li{margin-bottom:10px}
.rows{max-width:640px;padding-bottom:48px}
.rows div{display:flex;justify-content:space-between;gap:16px;border-bottom:1px solid var(--line);padding:12px 0}
.rows span:last-child{color:var(--muted);text-align:right}
footer{border-top:1px solid var(--line);padding:28px 0;color:var(--muted);font-size:14px;font-family:system-ui,sans-serif}
footer .wrap{display:flex;justify-content:space-between;flex-wrap:wrap;gap:8px}
EOF

layout() {
  local f="$1" t="$2" body
  body="$(cat)"
  body="${body//@@MAIL@@/$MAIL}"
  cat > "$f" <<PAGE
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$t — $TITLE</title>
<meta name="description" content="$DESC">
<link rel="stylesheet" href="/style.css">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='$FAV'/%3E%3Ccircle cx='16' cy='16' r='7' fill='%23fff'/%3E%3C/svg%3E">
</head>
<body>
<header><div class="wrap">
  <a class="logo" href="/">$BRAND</a>
  <nav>$NAV</nav>
</div></header>
<main>
$body
</main>
<footer><div class="wrap"><span>© 2026 $TITLE. $FOOT</span><span>$MAIL</span></div></footer>
</body>
</html>
PAGE
}

if [ "$THEME" = "rust" ]; then

layout index.html "Сообщество игроков в Rust" <<'EOF'
<section class="hero wrap">
  <h1>Выживай. Строй. Не доверяй никому.</h1>
  <p>Небольшое сообщество игроков в Rust. Честные вайпы по расписанию, адекватная администрация и люди, с которыми можно собраться в клан.</p>
  <a class="btn" href="/wipes.html">Расписание вайпов</a><a class="btn ghost" href="/rules.html">Правила</a>
</section>
<section class="wrap grid">
  <div class="card"><h3>Вайпы по графику</h3><p>Карта обновляется раз в две недели, большой вайп с чертежами раз в месяц.</p><span class="tag">Без сюрпризов</span></div>
  <div class="card"><h3>Честная игра</h3><p>Античит, логи и живые модераторы. Спорные случаи разбираем по записям.</p><span class="tag">Fair play</span></div>
  <div class="card"><h3>Кланы до 6 человек</h3><p>Лимит команды не даёт крупным кланам задавить одиночек.</p><span class="tag">Баланс</span></div>
</section>
<section class="band"><div class="wrap">
  <h2>Новичкам тут рады</h2>
  <p>Первый час в Rust — это боль. В чате сообщества подскажут, где взять первые ресурсы и как не потерять всё в первую же ночь.</p>
</div></section>
EOF

layout rules.html "Правила" <<'EOF'
<section class="wrap page-title"><h1>Правила сообщества</h1><p>Коротко и без юридического языка.</p></section>
<section class="wrap text">
  <ol>
    <li>Читы, макросы и использование багов карты запрещены. Бан без предупреждения.</li>
    <li>Размер команды не больше шести человек, включая союзников на рейдах.</li>
    <li>Без оскорблений, дискриминации и спама в чате и голосовом.</li>
    <li>Реклама сторонних серверов и продажа внутриигровых вещей за деньги запрещены.</li>
    <li>Рейд базы — часть игры. Травля конкретных игроков — нет.</li>
    <li>Решения администрации можно оспорить письмом с записью или скриншотами.</li>
  </ol>
</section>
EOF

layout wipes.html "Вайпы" <<'EOF'
<section class="wrap page-title"><h1>Расписание вайпов</h1><p>Время указано по Москве.</p></section>
<section class="wrap rows">
  <div><span>Малый вайп (карта)</span><span>каждый чётный четверг, 15:00</span></div>
  <div><span>Большой вайп (чертежи)</span><span>первый четверг месяца, 15:00</span></div>
  <div><span>Размер карты</span><span>3500</span></div>
  <div><span>Скорость сбора</span><span>x2</span></div>
  <div><span>Лимит команды</span><span>6 человек</span></div>
</section>
EOF

layout contacts.html "Контакты" <<'EOF'
<section class="wrap page-title"><h1>Контакты</h1><p>По вопросам игры, банов и сотрудничества.</p></section>
<section class="wrap rows">
  <div><span>Почта администрации</span><span>@@MAIL@@</span></div>
  <div><span>Ответ в течение</span><span>48 часов</span></div>
</section>
EOF

layout 404.html "Страница не найдена" <<'EOF'
<section class="hero wrap"><h1>Эту базу уже зарейдили</h1><p>Страница не найдена.</p><a class="btn" href="/">На главную</a></section>
EOF

elif [ "$THEME" = "borsch" ]; then

layout index.html "Домашний борщ" <<'EOF'
<section class="hero wrap">
  <h1>Борщ, как варили дома</h1>
  <p>Наваристый борщ на косточке, пампушки с чесноком и густая сметана. Варим каждое утро, в котле не больше двадцати порций.</p>
  <a class="btn" href="/menu.html">Смотреть меню</a><a class="btn ghost" href="/delivery.html">Доставка</a>
</section>
<section class="wrap grid">
  <div class="card"><h3>Борщ классический</h3><p>Говяжья косточка, свёкла, капуста и томлёный лук.</p><div class="price">290 ₽</div></div>
  <div class="card"><h3>Борщ зелёный</h3><p>Щавель, яйцо и молодой картофель.</p><div class="price">260 ₽</div></div>
  <div class="card"><h3>Пампушки с чесноком</h3><p>Тёплые, с маслом и укропом.</p><div class="price">150 ₽</div></div>
</section>
<section class="band"><div class="wrap">
  <h2>Вкуснее на второй день</h2>
  <p>Борщ хранится в холодильнике до трёх суток. Многие берут сразу литр-два и подогревают дома.</p>
</div></section>
EOF

layout menu.html "Меню" <<'EOF'
<section class="wrap page-title"><h1>Меню</h1><p>Порция борща 400 мл.</p></section>
<section class="wrap rows">
  <div><span>Борщ классический</span><span>290 ₽</span></div>
  <div><span>Борщ с копчёной грудинкой</span><span>340 ₽</span></div>
  <div><span>Борщ зелёный со щавелем</span><span>260 ₽</span></div>
  <div><span>Борщ постный с фасолью</span><span>240 ₽</span></div>
  <div><span>Пампушки с чесноком, 4 шт.</span><span>150 ₽</span></div>
  <div><span>Сметана деревенская</span><span>60 ₽</span></div>
  <div><span>Морс клюквенный, 300 мл</span><span>110 ₽</span></div>
</section>
EOF

layout delivery.html "Доставка" <<'EOF'
<section class="wrap page-title"><h1>Доставка</h1><p>Привозим горячим в термосумке.</p></section>
<section class="wrap rows">
  <div><span>Время доставки</span><span>с 11:00 до 20:00</span></div>
  <div><span>Срок</span><span>от 45 минут</span></div>
  <div><span>Стоимость</span><span>от 150 ₽</span></div>
  <div><span>Бесплатно при заказе</span><span>от 1 200 ₽</span></div>
</section>
<section class="wrap text"><p>Напишите на почту, что нужно, на какое время и по какому адресу. Ответим в течение часа.</p></section>
EOF

layout contacts.html "Контакты" <<'EOF'
<section class="wrap page-title"><h1>Контакты</h1><p>Заходите на борщ или заказывайте по почте.</p></section>
<section class="wrap rows">
  <div><span>Адрес</span><span>ул. Садовая, 12</span></div>
  <div><span>Пн–Пт</span><span>11:00–20:00</span></div>
  <div><span>Сб–Вс</span><span>12:00–21:00</span></div>
  <div><span>Почта</span><span>@@MAIL@@</span></div>
</section>
EOF

layout 404.html "Страница не найдена" <<'EOF'
<section class="hero wrap"><h1>Страница не найдена</h1><p>Такой страницы нет.</p><a class="btn" href="/">На главную</a></section>
EOF

elif [ "$THEME" = "bakery" ]; then

layout index.html "Хлеб на закваске" <<'EOF'
<section class="hero wrap">
  <h1>Хлеб с характером и долгой ферментацией</h1>
  <p>Печём хлеб на живой закваске: хрустящая корочка, воздушный мякиш и простой состав.</p>
  <a class="btn" href="/menu.html">Ассортимент</a><a class="btn ghost" href="/about.html">О пекарне</a>
</section>
<section class="wrap grid">
  <div class="card"><h3>Ремесленный хлеб</h3><p>Длительная ферментация и натуральные ингредиенты.</p><span class="tag">На закваске</span></div>
  <div class="card"><h3>Свежая выпечка</h3><p>Булочки и сезонная выпечка небольшими партиями.</p><span class="tag">Каждое утро</span></div>
  <div class="card"><h3>Простой состав</h3><p>Мука, вода, соль и время — ничего лишнего.</p><span class="tag">Без спешки</span></div>
</section>
<section class="band"><div class="wrap">
  <h2>Хлебу нужно время</h2>
  <p>Мы используем естественную ферментацию, чтобы раскрыть вкус зерна и получить выразительную текстуру.</p>
</div></section>
EOF

layout menu.html "Ассортимент" <<'EOF'
<section class="wrap page-title"><h1>Ассортимент</h1><p>Выпекаем небольшими партиями.</p></section>
<section class="wrap rows">
  <div><span>Пшеничный хлеб на закваске</span><span>450 ₽</span></div>
  <div><span>Ржаной хлеб</span><span>390 ₽</span></div>
  <div><span>Деревенский хлеб</span><span>490 ₽</span></div>
  <div><span>Фокачча</span><span>320 ₽</span></div>
  <div><span>Булочка с корицей</span><span>160 ₽</span></div>
</section>
EOF

layout about.html "О пекарне" <<'EOF'
<section class="wrap page-title"><h1>О пекарне</h1><p>Небольшая пекарня с уважением к ремеслу.</p></section>
<section class="wrap text">
  <p>Мы печём хлеб на натуральной закваске и не торопим тесто. Длительная ферментация помогает сформировать вкус, аромат и структуру мякиша.</p>
  <h2>Наш подход</h2>
  <p>Небольшие партии, понятные ингредиенты и свежая выпечка. Ассортимент может меняться в зависимости от сезона.</p>
</section>
EOF

layout contacts.html "Контакты" <<'EOF'
<section class="wrap page-title"><h1>Контакты</h1><p>Заказы и вопросы по ассортименту.</p></section>
<section class="wrap rows">
  <div><span>Почта</span><span>@@MAIL@@</span></div>
  <div><span>Часы работы</span><span>Пн–Сб, 09:00–19:00</span></div>
  <div><span>Заказы</span><span>Желательно за день</span></div>
</section>
EOF

layout 404.html "Страница не найдена" <<'EOF'
<section class="hero wrap"><h1>Крошки вместо страницы</h1><p>Такой страницы нет.</p><a class="btn" href="/">На главную</a></section>
EOF

fi

cat > robots.txt <<'EOF'
User-agent: *
Allow: /
EOF

echo
echo "Готово!"
echo "Домен: https://$D"
echo "Заглушка: 127.0.0.1:$PORT"
echo "Сайт: /var/www/site"
