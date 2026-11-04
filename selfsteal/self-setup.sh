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
