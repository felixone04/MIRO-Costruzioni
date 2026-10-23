/* =====================================================================
   Pagine pubbliche: Home, Progetti, Progetto, Servizi, Azienda, Contatti.
   ===================================================================== */
'use strict';

(() => {
  const { boot, esc, ms, $, $$, pad2, clamp, ph, parallax, rt, reveal, phoneDigits, mapsUrl, api, toast } = MIRO;
  const C = () => boot.content;

  // ------------------------------------------------------------ dati
  const coverUrl = (p) => (p.cover || '').trim() || (p.photos?.[0]?.url ?? '');
  const featured = () => {
    const f = boot.projects.filter((p) => p.featured);
    return f.length ? f : boot.projects.slice(0, 4);
  };
  const heroProjects = () => featured().filter((p) => coverUrl(p)).slice(0, 6);
  /** Categorie con almeno un progetto, nell'ordine scelto nel gestionale. */
  function usedCategories() {
    const used = new Set(boot.projects.map((p) => (p.category || '').trim()).filter(Boolean));
    const out = (C().categories || []).filter((c) => used.delete(c));
    return [...out, ...used];
  }
  const statusLabel = (s) => (s === 'inCorso' ? 'In corso' : 'Completato');

  // ------------------------------------------------------------ pezzi comuni
  const kicker = (t, dark = false) => (t ? `<span class="kicker ${dark ? 'dark' : ''}">${esc(t)}</span>` : '');

  /** Intestazione di sezione: etichetta, titolo e testo affiancati su schermi larghi. */
  function sh({ kicker: k = '', title, text = '', trailing = '', dark = false }) {
    return `<div class="sh ${dark ? 'dark' : ''}"><div class="head">${k ? reveal(kicker(k, dark)) : ''}${rt(title)}</div>
      ${text || trailing ? `<div class="side">${text ? reveal(`<p>${esc(text)}</p>`, 200) : ''}${trailing ? reveal(trailing, 300) : ''}</div>` : ''}</div>`;
  }
  MIRO.sh = sh;

  /** Inizio delle pagine interne. */
  function pageHeader({ kicker: k = '', title, text = '', bottom = '' }) {
    return `<header class="page-header"><div class="wrap">${k ? reveal(kicker(k)) : ''}${rt(title, { tag: 'h1', delay: 80 })}
      ${text ? reveal(`<p class="lead">${esc(text)}</p>`, 300) : ''}${bottom ? reveal(`<div class="bottom">${bottom}</div>`, 400) : ''}</div></header>`;
  }
  MIRO.pageHeader = pageHeader;

  /** Filtri discreti: parole in fila, quella scelta sottolineata. */
  const quietFilters = (options, selected, attr = 'data-f') =>
    `<div class="qfilters" role="tablist">${options.map((o, i) => `<button class="hl ${i === selected ? 'active' : ''}" ${attr}="${i}" role="tab"
      aria-selected="${i === selected}"><span>${esc(o)}</span></button>`).join('')}</div>`;
  MIRO.quietFilters = quietFilters;

  const hl = (text, href, { arrow = false, cls = '', style = '' } = {}) =>
    `<a class="hl ${cls}" href="${esc(href)}" style="${style}"><span>${esc(text)}${arrow ? ms('arrow_forward') : ''}</span></a>`;
  MIRO.hl = hl;

  const btn = (text, href, { kind = '', big = false, icon = 'arrow_forward' } = {}) =>
    `<a class="btn ${kind} ${big ? 'big' : ''}" href="${esc(href)}">${esc(text)}${ms(icon)}</a>`;
  MIRO.btn = btn;

  // ------------------------------------------------------------ scheda progetto
  function projectCard(p, { summary = false } = {}) {
    const meta = [p.location, p.year].filter((x) => (x || '').trim()).join(' · ');
    return `<a class="pcard zoom" href="${MIRO.projectLink(p)}" aria-label="Progetto ${esc(p.title)}">
      <div class="img rounded">${ph(coverUrl(p), { alt: p.title })}
        <div class="pills">${p.category ? `<span class="pill white">${esc(p.category)}</span>` : ''}${p.status === 'inCorso' ? '<span class="pill acc">In corso</span>' : ''}</div>
        <span class="go">${ms('arrow_outward')}</span></div>
      <div class="t">${esc(p.title)}</div><div class="m">${esc(meta)}</div>
      ${summary && p.summary ? `<div class="s">${esc(p.summary)}</div>` : ''}</a>`;
  }
  function projectGrid(list, opts) {
    const cols = innerWidth >= 1000 ? 3 : innerWidth >= 600 ? 2 : 1;
    return `<div class="pgrid">${list.map((p, i) => reveal(projectCard(p, opts), 100 * (i % cols))).join('')}</div>`;
  }

  // ================================================================ HOME

  function hero() {
    const c = C();
    const slides = heroProjects();
    const gap = MIRO.switcherVisible ? '64px' : '0px';
    return `<section class="hero" id="hero" style="--sw-gap:${gap}">
      <div class="slides">${slides.map((p, i) => `<div class="slide ${i === 0 ? 'on' : ''}">${ph(coverUrl(p), { dark: true, eager: i === 0, alt: p.title })}</div>`).join('')}</div>
      <div class="shade"></div>
      <div class="content"><div class="inner">
        ${reveal(kicker(c.heroKicker, true))}
        ${rt(c.heroTitle, { tag: 'h1', delay: 100, accentColor: 'color-mix(in srgb, var(--accent) 65%, white)' })}
        ${reveal(`<p class="sub">${esc(c.heroSubtitle)}</p>`, 450)}
        ${reveal(`<div class="cta">${btn('Guarda i progetti', 'progetti', { big: true })}</div>`, 600)}
        ${slides.length ? reveal('<div class="info"><a class="lab"></a><div class="dots"></div></div>', 700) : ''}
      </div></div></section>`;
  }

  function mountHero(root) {
    const el = $('#hero', root);
    if (!el) return;
    const slides = heroProjects();
    const SLIDE = 7000;
    let i = 0;
    const draw = () => {
      $$('.slide', el).forEach((s, n) => s.classList.toggle('on', n === i));
      const p = slides[i];
      const lab = $('.lab', el);
      if (lab && p) {
        lab.style.opacity = '0';
        setTimeout(() => {
          lab.href = MIRO.projectLink(p);
          lab.innerHTML = `<span class="t">${esc(p.title)}</span><span class="l">${esc(p.location)}</span>${ms('arrow_outward')}`;
          lab.style.opacity = '1';
        }, i === 0 && !draw.done ? 0 : 300);
      }
      draw.done = true;
      const dots = $('.dots', el);
      if (dots) {
        dots.innerHTML = slides.map((_, n) => `<span class="dot ${n === i ? 'on' : ''}" data-n="${n}" style="--dur:${SLIDE}ms"><i></i></span>`).join('');
      }
    };
    let timer = setInterval(() => { i = (i + 1) % slides.length; draw(); }, SLIDE);
    el.addEventListener('click', (e) => {
      const d = e.target.closest('.dot');
      if (!d) return;
      i = +d.dataset.n;
      draw();
      clearInterval(timer);
      timer = setInterval(() => { i = (i + 1) % slides.length; draw(); }, SLIDE);
    });
    draw();
    // Scorrendo, la foto rallenta e il testo sfuma verso l'alto.
    const slidesEl = $('.slides', el);
    const inner = $('.inner', el);
    const onScroll = () => {
      const h = MIRO.screenH();
      const y = scrollY;
      slidesEl.style.transform = `translate3d(0, ${(Math.min(y, h) * 0.4).toFixed(1)}px, 0)`;
      inner.style.opacity = clamp(1 - y / (h * 0.7), 0, 1);
      inner.style.transform = `translate3d(0, ${(-y * 0.15).toFixed(1)}px, 0)`;
    };
    addEventListener('scroll', onScroll, { passive: true });
    MIRO.onCleanup(() => { clearInterval(timer); removeEventListener('scroll', onScroll); });
  }

  function intro() {
    const c = C();
    return `<section class="section"><div class="wrap intro">
      <div class="txt">${reveal(kicker(c.introKicker))}${rt(c.introTitle)}
        ${reveal(`<p>${esc(c.introText)}</p>`, 200)}${reveal(hl('La nostra storia', 'azienda', { arrow: true }), 300)}</div>
      <div class="stats">${(c.stats || []).map((s, i) => reveal(`<div class="stat"><div class="n" data-count="${esc(s.title)}">${esc(s.title)}</div>
        <div class="d">${esc(s.text)}</div></div>`, 120 * i)).join('')}</div></div></section>`;
  }

  function ticker() {
    const items = C().ticker || [];
    if (!items.length) return '';
    const set = `<div class="set" aria-hidden="true">${items.map((w, i) => `<span class="w ${i % 2 ? 'i' : ''}">${esc(w)}</span><span class="dot"></span>`).join('')}</div>`;
    return `<div class="ticker" aria-label="${esc(items.join(', '))}"><div class="track">${set}${set}${set}${set}</div></div>`;
  }
  MIRO.ticker = ticker;

  function recentProjects() {
    const c = C();
    // Righe sempre piene: 3 su tre colonne, 4 su due, 3 su una.
    const n = innerWidth >= 1000 ? 3 : innerWidth >= 600 ? 4 : 3;
    const list = featured().slice(0, n);
    if (!list.length) return '';
    return `<section class="section"><div class="wrap">${sh({ kicker: c.projectsKicker, title: c.projectsTitle, text: c.projectsText,
      trailing: btn('Tutti i progetti', 'progetti', { kind: 'outline' }) })}
      <div class="mt-l">${projectGrid(list)}</div></div></section>`;
  }

  function contactLine(icon, label, value, href, ext = false) {
    return `<a class="cline" href="${esc(href)}"${ext ? ' target="_blank" rel="noopener"' : ''}><span class="ic">${ms(icon)}</span>
      <span><span class="lb">${esc(label)}</span><br><span class="vl">${esc(value)}</span></span></a>`;
  }
  MIRO.contactLine = contactLine;

  function contactStrip() {
    const k = C().contacts || {};
    return `<section class="section t0"><div class="wrap">${reveal(`<div class="cstrip"><div>${rt('Parliamo del\ntuo progetto.')}</div><div>
      ${k.phone ? contactLine('call', 'Telefono', k.phone, 'tel:' + phoneDigits(k.phone)) : ''}
      ${k.email ? contactLine('mail', 'Email', k.email, 'mailto:' + k.email) : ''}
      ${k.address ? contactLine('place', 'Sede', k.address, mapsUrl(k.address), true) : ''}
      <div class="mt-s">${hl('Scrivici dal modulo', 'contatti', { arrow: true, style: 'color:var(--accent-deep);font-weight:600' })}</div></div></div>`)}</div></section>`;
  }

  MIRO.route('/', () => MIRO.page('/', hero() + intro() + ticker() + recentProjects() + contactStrip(), { overHero: true, mount: mountHero }));

  // ============================================================ PROGETTI

  MIRO.route('/progetti', (_, q) => {
    const c = C();
    const cats = usedCategories();
    const options = ['Tutti', ...cats];
    let sel = Math.max(0, options.indexOf(q.get('categoria') || ''));
    const grid = () => {
      const cat = sel === 0 ? null : options[sel];
      const list = boot.projects.filter((p) => !cat || p.category === cat);
      return list.length ? projectGrid(list, { summary: true })
        : `<p class="muted" style="padding:60px 0">Nessun progetto in questa categoria, per ora.</p>`;
    };
    MIRO.page('/progetti', pageHeader({ kicker: c.projectsKicker, title: c.projectsTitle, text: c.projectsText, bottom: quietFilters(options, sel) })
      + `<section class="section t0"><div class="wrap" id="pg-grid">${grid()}</div></section>`, {
      mount(root) {
        root.addEventListener('click', (e) => {
          const b = e.target.closest('[data-f]');
          if (!b) return;
          sel = +b.dataset.f;
          $$('[data-f]', root).forEach((x, i) => { x.classList.toggle('active', i === sel); x.setAttribute('aria-selected', i === sel); });
          const g = $('#pg-grid', root);
          g.innerHTML = `<div class="fade-swap">${grid()}</div>`;
          MIRO.watchReveals(g);
        });
      },
    });
  });

  // ------------------------------------------------------------ prima/dopo
  function compare(before, after) {
    return reveal(`<div class="compare" style="--t:.5;aspect-ratio:${innerWidth < 600 ? '4/3.4' : '16/9'}">
      ${ph(after)}${ph(before, { cls: 'before' })}
      <span class="lab l">Prima</span><span class="lab r">Dopo</span><span class="bar"></span>
      <span class="knob">${ms('chevron_left')}${ms('chevron_right')}</span></div>`);
  }
  function mountCompare(root) {
    for (const el of $$('.compare', root)) {
      let t = 0.5;
      let touched = false;
      const set = (v) => {
        t = clamp(v, 0, 1);
        el.style.setProperty('--t', t);
        $('.lab.l', el).style.opacity = t > 0.12 ? 1 : 0;
        $('.lab.r', el).style.opacity = t < 0.88 ? 1 : 0;
      };
      const at = (e) => { const r = el.getBoundingClientRect(); set((e.clientX - r.left) / r.width); };
      let drag = false;
      el.addEventListener('pointerdown', (e) => { touched = true; drag = true; el.setPointerCapture(e.pointerId); at(e); });
      el.addEventListener('pointermove', (e) => { if (drag) at(e); });
      el.addEventListener('pointerup', () => { drag = false; });
      // Un piccolo movimento d'invito finché nessuno tocca la maniglia.
      const t0 = performance.now() + 2200;
      const hint = (now) => {
        if (touched || !el.isConnected) return;
        const k = (now - t0) / 2600;
        if (k >= 0 && k <= 1) set(0.5 + 0.12 * Math.sin(2 * Math.PI * k));
        if (k <= 1) requestAnimationFrame(hint);
      };
      requestAnimationFrame(hint);
    }
  }
  MIRO.compare = compare;
  MIRO.mountCompare = mountCompare;

  /** Galleria a ritmo alternato: una foto grande, poi due affiancate. */
  function gallery(photos) {
    const phone = innerWidth < 600;
    const tile = (i, aspect) => reveal(`<div class="gtile" data-g="${i}">${ph(photos[i].url, { attrs: `style="aspect-ratio:${aspect}"`, alt: photos[i].caption })}
      ${photos[i].caption ? `<div class="cap">${esc(photos[i].caption)}</div>` : ''}</div>`, (i % 2) * 120);
    const rows = [];
    let i = 0;
    while (i < photos.length) {
      if (phone || i % 3 === 0 || i === photos.length - 1) { rows.push(tile(i, phone ? '4/3' : '16/8')); i++; }
      else { rows.push(`<div class="row">${tile(i, '4/3')}${tile(i + 1, '4/3')}</div>`); i += 2; }
    }
    return `<div class="gal">${rows.join('')}</div>`;
  }

  MIRO.route('/progetti/:id', ([id]) => {
    const list = boot.projects;
    const p = list.find((x) => MIRO.projectSlug(x) === id) || list.find((x) => x.id === id);
    if (!p) {
      return MIRO.page('/progetti', pageHeader({ kicker: 'Progetti', title: "Questo progetto\nnon c'è più.",
        bottom: btn('Tutti i progetti', 'progetti', { kind: 'outline' }) }));
    }
    // Un vecchio link con l'id diventa l'indirizzo con il nome del progetto.
    if (id !== MIRO.projectSlug(p)) history.replaceState(null, '', MIRO.BASE + MIRO.projectLink(p));
    const next = list.length > 1 ? list[(list.indexOf(p) + 1) % list.length] : null;
    const facts = [['Luogo', p.location], ['Anno', p.year], ['Committente', p.client], ['Superficie', p.area], ['Durata', p.duration],
      ['Stato', statusLabel(p.status)]].filter(([, v]) => (v || '').trim());
    const story = (p.description || '').split('\n\n').filter((x) => x.trim()).map((x) => reveal(`<p>${esc(x.trim())}</p>`)).join('');
    const side = facts.map(([k, v]) => reveal(`<div class="fact"><span class="k">${esc(k)}</span><span class="v">${esc(v)}</span></div>`)).join('')
      + (p.works?.length ? reveal('<div class="muted mt-s" style="font-size:.906rem;margin-bottom:.625rem">Cosa abbiamo fatto</div>')
        + reveal(`<div class="chips">${p.works.map((w) => `<span class="chip">${esc(w)}</span>`).join('')}</div>`) : '')
      + reveal(`<div class="mt-m">${btn('Vorrei un lavoro simile', 'contatti?progetto=' + encodeURIComponent(MIRO.projectSlug(p)), { kind: 'outline' })}</div>`);
    const html = pageHeader({ kicker: [p.category, p.location].filter(Boolean).join(' · '), title: p.title, text: p.summary,
      bottom: hl('Tutti i progetti', 'progetti', { style: 'color:var(--muted);font-weight:600;font-size:.906rem' }) })
      + `<section class="section t0" style="padding-bottom:clamp(2.5rem, calc(2.5rem + (100vw - 22.5rem) * .0242), 4.375rem)"><div class="wrap">
        ${reveal(`<div class="cover rounded">${parallax(coverUrl(p), { extent: 0.25, cls: 'fill' })}</div>`)}</div></section>`
      + `<section class="section t0"><div class="wrap pdetail"><div class="story">${story}</div><div>${side}</div></div></section>`
      + (p.before ? `<section class="section t0"><div class="wrap">${sh({ kicker: 'Prima e dopo', title: 'Trascina\nper confrontare.' })}
        <div class="mt-l">${compare(p.before, (p.after || '').trim() || coverUrl(p))}</div></div></section>` : '')
      + (p.photos?.length ? `<section class="section t0"><div class="wrap">${sh({ kicker: 'Fotografie', title: 'Il lavoro\nda vicino.' })}
        <div class="mt-l">${gallery(p.photos)}</div></div></section>` : '')
      + (next ? `<section class="section t0"><div class="wrap">${reveal(`<a class="next" href="${MIRO.projectLink(next)}">
        ${ph(coverUrl(next), { dark: true })}<span class="veil"></span><span class="in"><small>Progetto successivo</small>
        <span class="t">${esc(next.title)}</span>${ms('arrow_forward')}</span></a>`)}</div></section>` : '');
    MIRO.page('/progetti', html, {
      title: p.title,
      mount(root) {
        mountCompare(root);
        root.addEventListener('click', (e) => {
          const g = e.target.closest('[data-g]');
          if (g) MIRO.lightbox(p.photos, +g.dataset.g);
        });
      },
    });
  });

  // ============================================================= SERVIZI

  function serviceView(s) {
    const projects = boot.projects.filter((p) => (s.categories || []).includes(p.category));
    const photos = [];
    for (const p of projects) {
      for (const f of (p.photos || []).slice(0, 2)) {
        photos.push({ url: f.url, caption: [p.title, f.caption].filter(Boolean).join(' · ') });
      }
    }
    const shown = photos.slice(0, 6);
    const text = `<div><h2>${esc(s.title)}</h2><p class="tx">${esc(s.text)}</p>
      ${s.points?.length ? `<div class="chips mt-m">${s.points.map((x) => `<span class="chip">${esc(x)}</span>`).join('')}</div>` : ''}
      ${projects.length ? `<div class="muted" style="margin-top:1.625rem;font-size:.875rem">Lavori di questo tipo</div>
        <div class="links">${projects.slice(0, 4).map((p) => hl(p.title, MIRO.projectLink(p), { arrow: true })).join('')}</div>` : ''}</div>`;
    return `<div class="fade-swap"><div class="sview">${text}${ph(s.image, { cls: 'img', alt: s.title })}</div>
      ${shown.length ? `<div class="thumbs">${shown.map((f, n) => reveal(`<div class="thumb" data-th="${n}">${ph(f.url)}<span class="cap">${esc(f.caption)}</span></div>`, 90 * (n % 3))).join('')}</div>` : ''}</div>`;
  }

  MIRO.route('/servizi', (_, q) => {
    const c = C();
    const list = boot.services;
    let sel = Math.max(0, list.findIndex((s) => s.id === q.get('s')));
    MIRO.page('/servizi', pageHeader({ kicker: c.servicesKicker, title: c.servicesTitle, text: c.servicesText,
      bottom: list.length ? quietFilters(list.map((s) => s.title), sel) : '' })
      + (list.length ? `<section class="section t0"><div class="wrap" id="sv">${serviceView(list[sel])}</div></section>` : ''), {
      mount(root) {
        root.addEventListener('click', (e) => {
          const b = e.target.closest('[data-f]');
          if (b) {
            sel = +b.dataset.f;
            $$('[data-f]', root).forEach((x, i) => { x.classList.toggle('active', i === sel); x.setAttribute('aria-selected', i === sel); });
            const v = $('#sv', root);
            v.innerHTML = serviceView(list[sel]);
            MIRO.watchReveals(v);
            return;
          }
          const th = e.target.closest('[data-th]');
          if (th) {
            const s = list[sel];
            const photos = [];
            for (const p of boot.projects.filter((p) => (s.categories || []).includes(p.category))) {
              for (const f of (p.photos || []).slice(0, 2)) photos.push({ url: f.url, caption: [p.title, f.caption].filter(Boolean).join(' · ') });
            }
            MIRO.lightbox(photos.slice(0, 6), +th.dataset.th);
          }
        });
      },
    });
  });

  // ============================================================= AZIENDA

  MIRO.route('/azienda', () => {
    const c = C();
    const story = `<section class="section t0"><div class="wrap story">
      <div class="collage">${reveal(parallax(c.aboutImage, { cls: 'rounded fill' }), 0, 'class="a"')}
        ${reveal(`<div class="b">${ph(c.aboutImage2)}</div>`, 250, 'style="position:absolute;right:0;bottom:0"')}</div>
      <div class="txt">${(c.aboutText || '').split('\n\n').filter((x) => x.trim()).map((x) => reveal(`<p>${esc(x.trim())}</p>`)).join('')}
        ${c.certifications?.length ? reveal(`<div class="chips mt-s">${c.certifications.map((x) => `<span class="chip ol">${esc(x)}</span>`).join('')}</div>`) : ''}</div>
      </div></section>`;
    const cols = innerWidth >= 1000 ? 4 : innerWidth >= 540 ? 2 : 1;
    const values = c.values?.length ? `<section class="section" style="background:var(--concrete)"><div class="wrap">
      ${sh({ kicker: 'Il nome', title: 'Quattro parole\nche ci tengono insieme.' })}
      <div class="values mt-l">${c.values.map((v, i) => reveal(`<div class="vcard"><div class="big">${esc((v.title || ' ')[0].toUpperCase())}</div>
        <h3>${esc(v.title)}</h3><p>${esc(v.text)}</p></div>`, 110 * (i % cols))).join('')}</div></div></section>` : '';
    const timeline = c.timeline?.length ? `<section class="section"><div class="wrap">${sh({ kicker: 'La storia', title: "Un cantiere\ndopo l'altro." })}
      <div class="mt-l">${c.timeline.map((m) => reveal(`<div class="tl"><span class="y">${esc(m.year)}</span><h3>${esc(m.title)}</h3><p>${esc(m.text)}</p></div>`, 80)).join('')}</div>
      </div></section>` : '';
    const tcols = innerWidth >= 1000 ? 4 : innerWidth >= 500 ? 2 : 1;
    const team = c.team?.length ? `<section class="section t0"><div class="wrap">${sh({ kicker: 'Le persone', title: 'Chi trovi\nin cantiere.' })}
      <div class="team mt-l">${c.team.map((m, i) => reveal(`<div class="person">${ph(m.photo, { alt: m.name })}<h3>${esc(m.name)}</h3><p>${esc(m.role)}</p></div>`, 100 * (i % tcols))).join('')}</div>
      </div></section>` : '';
    const ts = boot.testimonials;
    const quotes = ts.length ? `<section class="section t0"><div class="wrap">${reveal(`<div class="quotebox" id="qb">${kicker('Dicono di noi')}
      <div id="qt"></div>${ts.length > 1 ? `<div class="qdots">${ts.map((_, n) => `<i data-q="${n}"></i>`).join('')}</div>` : ''}</div>`)}</div></section>` : '';
    MIRO.page('/azienda', pageHeader({ kicker: c.aboutKicker, title: c.aboutTitle, text: c.aboutIntro }) + story + values + timeline + team + quotes, {
      mount(root) {
        const qb = $('#qb', root);
        if (!qb) return;
        let i = 0;
        const draw = () => {
          const t = ts[i % ts.length];
          $('#qt', qb).innerHTML = `<div class="fade-swap"><p class="q">«${esc(t.text)}»</p><p class="who">${esc([t.name, t.role].filter(Boolean).join(' · '))}</p></div>`;
          $$('[data-q]', qb).forEach((d, n) => d.classList.toggle('on', n === i % ts.length));
        };
        draw();
        const timer = setInterval(() => { i++; draw(); }, 8000);
        qb.addEventListener('click', (e) => { const d = e.target.closest('[data-q]'); if (d) { i = +d.dataset.q; draw(); } });
        MIRO.onCleanup(() => clearInterval(timer));
      },
    });
  });

  // ============================================================ CONTATTI

  function infoBox() {
    const k = C().contacts || {};
    const items = [
      k.phone && ['call', 'Telefono', k.phone, 'tel:' + phoneDigits(k.phone)],
      k.whatsapp && ['chat', 'WhatsApp', k.whatsapp, 'https://wa.me/' + phoneDigits(k.whatsapp).replace('+', ''), true],
      k.email && ['mail', 'Email', k.email, 'mailto:' + k.email],
      k.pec && ['verified', 'PEC', k.pec, 'mailto:' + k.pec],
      k.address && ['place', 'Sede', k.address, mapsUrl(k.address), true],
    ].filter(Boolean);
    return `<div class="box info">${items.map(([ic, l, v, h, ext], i) => reveal(contactLine(ic, l, v, h, ext), 70 * i)).join('')}
      ${k.hours ? reveal(`<div class="cline" style="cursor:default"><span class="ic">${ms('schedule')}</span><span><span class="lb">Orari ufficio</span><br>
        <span class="vl">${esc(k.hours)}</span></span></div>`, 70 * items.length) : ''}</div>`;
  }

  const field = (name, label, { type = 'text', area = false, auto = '', cls = '' } = {}) =>
    `<label class="field ${cls}">${area ? `<textarea name="${name}" placeholder=" " rows="4"></textarea>`
      : `<input name="${name}" type="${type}" placeholder=" "${auto ? ` autocomplete="${auto}"` : ''}>`}<span>${esc(label)}</span><small class="err"></small></label>`;
  MIRO.field = field;

  // ------------------------------------------------------------ richiesta di preventivo a passi
  const AREAS = [['fino a 50', 'Fino a 50 m²'], ['50–100', '50–100 m²'], ['100–200', '100–200 m²'], ['oltre 200', 'Oltre 200 m²'], ['', 'Non lo so']];
  const STEPS = ['Il lavoro', 'Qualche dettaglio', "Foto dell'immobile", 'I tuoi contatti'];
  const MAX_PHOTOS = 6;

  /** Foto ridotta nel browser (lato lungo 1600 px): l'invio è leggero anche dal telefono. */
  async function shrink(file) {
    const img = await createImageBitmap(file).catch(() => null);
    if (!img) return null;
    const k = Math.min(1, 1600 / Math.max(img.width, img.height));
    const cv = document.createElement('canvas');
    cv.width = Math.round(img.width * k);
    cv.height = Math.round(img.height * k);
    cv.getContext('2d').drawImage(img, 0, 0, cv.width, cv.height);
    return new Promise((r) => cv.toBlob(r, 'image/jpeg', 0.82));
  }

  /** Quattro passi: tipo di lavoro, dettagli, foto, contatti. ref = progetto da cui si arriva. */
  function quoteWizard(host, ref = '') {
    const c = C();
    const d = { type: '', city: '', area: null, timing: '', message: '', photos: [], name: '', phone: '', email: '', privacy: false };
    let step = 0;
    const chips = (list, cur, attr) => `<div class="row-wrap" style="gap:.5rem">${list.map(([v, l]) =>
      `<button type="button" class="choice ${cur === v ? 'on' : ''}" ${attr}="${esc(v)}">${esc(l)}</button>`).join('')}</div>`;
    const body = () => {
      if (step === 0) {
        return `<p class="q">Di cosa si tratta?</p>${ref ? `<p class="ref">${ms('apartment')}Come il progetto «${esc(ref)}»</p>` : ''}
          ${chips((c.requestTypes || []).map((t) => [t, t]), d.type, 'data-type')}<p class="formerr mt-s" id="werr"></p>`;
      }
      if (step === 1) {
        return `<p class="q">Qualche dettaglio</p>${field('city', "Comune dell'immobile")}
          <p class="sub">Superficie indicativa</p>${chips(AREAS, d.area, 'data-area')}
          ${(c.timings || []).length ? `<p class="sub">Quando vorresti iniziare?</p>${chips(c.timings.map((t) => [t, t]), d.timing, 'data-timing')}` : ''}
          <div class="mt-m">${field('message', 'Raccontaci cosa hai in mente', { area: true })}</div>`;
      }
      if (step === 2) {
        return `<p class="q">Hai qualche foto?</p><p class="muted">Facoltative, fino a ${MAX_PHOTOS}: ci aiutano a capire il lavoro già prima del sopralluogo.</p>
          <div class="wphotos">${d.photos.map((p, i) => `<div class="wph"><img src="${p.url}" alt="Foto ${i + 1}">
            <button type="button" data-rmp="${i}" aria-label="Togli la foto">${ms('close')}</button></div>`).join('')}
          ${d.photos.length < MAX_PHOTOS ? `<label class="wph add">${ms('add_a_photo')}<span>Aggiungi</span>
            <input type="file" accept="image/*" multiple id="wfile" style="display:none"></label>` : ''}</div>`;
      }
      return `<p class="q">Come ti ricontattiamo?</p><div style="display:grid;gap:.875rem">
          <div class="f2">${field('name', 'Nome e cognome *', { auto: 'name' })}${field('phone', 'Telefono *', { type: 'tel', auto: 'tel' })}</div>
          ${field('email', 'Email *', { type: 'email', auto: 'email' })}
          <input name="website" tabindex="-1" autocomplete="off" style="position:absolute;left:-9999px" aria-hidden="true"></div>
        <label class="check mt-s"><input type="checkbox" name="privacy" ${d.privacy ? 'checked' : ''}><span>Ho letto l'<a class="ul" href="privacy" target="_blank">informativa
          sulla privacy</a> e acconsento al trattamento dei dati per essere ricontattato. *<br><span class="formerr" id="perr"></span></span></label>`;
    };
    const draw = () => {
      host.innerHTML = `<form class="wizard box" novalidate><div class="whead"><span>Passo ${step + 1} di ${STEPS.length} · ${STEPS[step]}</span>
          <div class="wbar"><i style="width:${((step + 1) / STEPS.length) * 100}%"></i></div></div>
        <div class="fade-swap">${body()}</div>
        <div class="wnav">${step ? `<button type="button" class="btn outline" data-back>Indietro</button>` : '<span></span>'}
          <button type="submit" class="btn">${step < STEPS.length - 1 ? 'Avanti' + ms('arrow_forward') : 'Invia la richiesta' + ms('send')}</button></div></form>`;
      const f = $('form', host);
      for (const n of ['city', 'message', 'name', 'phone', 'email']) if (f.elements[n]) f.elements[n].value = d[n];
      const top = host.getBoundingClientRect().top;
      if (top < 0) scrollBy({ top: top - 100, behavior: 'smooth' });
    };
    const pick = (attr, key, el) => {
      d[key] = d[key] === el.getAttribute(attr) ? (key === 'area' ? null : '') : el.getAttribute(attr);
      $$(`[${attr}]`, host).forEach((b) => b.classList.toggle('on', b.getAttribute(attr) === d[key]));
    };
    host.onclick = (e) => {
      const t = e.target;
      if (t.closest('[data-type]')) { pick('data-type', 'type', t.closest('[data-type]')); $('#werr', host).textContent = ''; }
      else if (t.closest('[data-area]')) pick('data-area', 'area', t.closest('[data-area]'));
      else if (t.closest('[data-timing]')) pick('data-timing', 'timing', t.closest('[data-timing]'));
      else if (t.closest('[data-back]')) { step--; draw(); }
      else if (t.closest('[data-rmp]')) {
        const [p] = d.photos.splice(+t.closest('[data-rmp]').dataset.rmp, 1);
        URL.revokeObjectURL(p.url);
        draw();
      }
    };
    host.oninput = (e) => {
      const el = e.target;
      if (el.name === 'privacy') d.privacy = el.checked;
      else if (el.name in d && el.type !== 'file') d[el.name] = el.value;
    };
    host.onchange = async (e) => {
      if (e.target.id !== 'wfile') return;
      for (const file of [...e.target.files].slice(0, MAX_PHOTOS - d.photos.length)) {
        const blob = await shrink(file);
        if (blob) d.photos.push({ blob, url: URL.createObjectURL(blob) });
        else toast(`"${file.name}" non è una foto che il browser sa leggere (prova JPG o PNG).`, true);
      }
      draw();
    };
    host.onsubmit = async (e) => {
      e.preventDefault();
      const f = e.target;
      if (step === 0 && (c.requestTypes || []).length && !d.type) { $('#werr', f).textContent = 'Scegli il tipo di lavoro per continuare.'; return; }
      if (step < STEPS.length - 1) { step++; draw(); return; }
      const v = (n) => f.elements[n].value.trim();
      const err = (n, m) => { const el = f.elements[n].closest('.field'); el.classList.toggle('bad', !!m); $('.err', el).textContent = m || ''; return !m; };
      let ok = err('name', v('name') ? '' : 'Campo obbligatorio');
      ok = err('phone', !v('phone') ? 'Campo obbligatorio' : phoneDigits(v('phone')).replace('+', '').length < 6 ? 'Numero non valido' : '') && ok;
      ok = err('email', !v('email') ? 'Campo obbligatorio' : /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v('email')) ? '' : 'Email non valida') && ok;
      $('#perr', f).textContent = d.privacy ? '' : 'Serve il consenso per inviare la richiesta.';
      if (!ok || !d.privacy) return;
      const b = $('button[type=submit]', f);
      b.classList.add('loading');
      b.innerHTML = 'Invio<span class="spin"></span>';
      const fd = new FormData();
      Object.entries({ type: d.type, city: d.city, area: d.area || '', timing: d.timing, message: d.message, name: v('name'), phone: v('phone'),
        email: v('email'), privacy: '1', website: f.elements.website.value, projectRef: ref }).forEach(([k, x]) => fd.append(k, x));
      d.photos.forEach((p, i) => fd.append('photos[]', p.blob, `foto-${i + 1}.jpg`));
      try {
        await api('contact', fd);
        await new Promise((r) => setTimeout(r, 600));
        const first = v('name').split(' ')[0];
        host.innerHTML = `<div class="box fade-swap" style="padding:clamp(1.75rem, calc(1.75rem + (100vw - 22.5rem) * .0194), 3.25rem)">
          <div class="thanks-ic">${ms('check')}</div><h2 class="serif" style="margin-top:1.5rem;font-size:clamp(2.125rem, calc(2.125rem + (100vw - 22.5rem) * .0145), 3.25rem)">Richiesta inviata</h2>
          <p class="muted" style="margin-top:.75rem;font-size:1.0625rem">Grazie ${esc(first)}, ti richiamiamo entro due giorni lavorativi.</p>
          <div class="row-wrap mt-l">${btn('Guarda i progetti', 'progetti')}<button class="btn outline" id="again">Nuova richiesta${ms('refresh')}</button></div></div>`;
        d.photos.forEach((p) => URL.revokeObjectURL(p.url));
        $('#again', host).onclick = () => quoteWizard(host);
      } catch (x) {
        toast(x.message, true);
        b.classList.remove('loading');
        b.innerHTML = 'Invia la richiesta' + ms('send');
      }
    };
    draw();
  }

  MIRO.route('/contatti', (_, q) => {
    const c = C();
    const from = boot.projects.find((p) => MIRO.projectSlug(p) === q.get('progetto'));
    MIRO.page('/contatti', pageHeader({ kicker: 'Contatti', title: c.contactTitle, text: c.contactText })
      + `<section class="section t0"><div class="wrap cgrid">${infoBox()}${reveal('<div id="fhost"></div>', 200)}</div></section>`, {
      mount(root) { quoteWizard($('#fhost', root), from?.title || ''); },
    });
  });

  // ============================================================ PRIVACY E COOKIE

  /** Testi di base, compilati con i dati dell'impresa: dal gestionale si possono riscrivere. */
  function legalDefault(kind, c = C()) {
    const k = c.contacts || {};
    const who = [c.companyName, k.address, k.vat].filter(Boolean).join(', ');
    const mail = [k.email, k.pec && `PEC ${k.pec}`].filter(Boolean).join(' oppure ');
    if (kind === 'cookie') {
      return `## Cookie tecnici
Questo sito usa un solo cookie, tecnico: tiene aperto l'accesso all'area clienti e all'area riservata dopo l'ingresso con email e password. Senza questo cookie l'accesso non funzionerebbe; non serve a profilare né a fare pubblicità, e per questo non richiede il consenso.

## Nessun cookie di terze parti
Il sito non usa strumenti di statistica, pubblicità o social network che installano cookie. I caratteri tipografici sono caricati dal sito stesso.

## Link esterni
Il pulsante WhatsApp e i link ai social portano su siti di altre aziende, che hanno le proprie regole su cookie e privacy.

## Come gestire i cookie
Puoi cancellare i cookie dalle impostazioni del browser in qualsiasi momento: dovrai solo rientrare nell'area clienti.`;
    }
    return `## Titolare del trattamento
${who}. Per qualsiasi domanda sui tuoi dati scrivi a ${mail || "l'indirizzo indicato nella pagina Contatti"}.

## Quali dati raccogliamo
Con il modulo di richiesta: nome, telefono, email, comune, informazioni sul lavoro e le foto dell'immobile che decidi di allegare.
Nell'area clienti: i dati dell'account creato dall'impresa, i documenti del cantiere, i messaggi e le approvazioni.

## Perché li usiamo
Per risponderti e preparare un preventivo (misure precontrattuali richieste da te), per gestire il cantiere e il rapporto con i clienti (esecuzione del contratto) e per rispettare gli obblighi di legge, anche fiscali.

## Per quanto tempo
Le richieste che non diventano un lavoro sono cancellate entro 24 mesi dall'ultimo contatto. I dati legati a un lavoro si conservano per la durata del rapporto e per il tempo previsto dalla legge per i documenti contabili e fiscali.

## Chi li vede
Solo il personale dell'impresa e il fornitore che ospita il sito, nominato responsabile del trattamento. I dati non vengono venduti né diffusi.

## I tuoi diritti
Puoi chiedere di vedere, correggere o cancellare i tuoi dati, limitarne l'uso, opporti al trattamento o riceverli in un formato leggibile, scrivendo ai recapiti sopra. Puoi anche presentare reclamo al Garante per la protezione dei dati personali (garanteprivacy.it).`;
  }

  /** Testo semplice: righe "## " come titoletti, righe vuote come paragrafi. */
  const legalHtml = (text) => text.split(/\n\s*\n|\n(?=## )/).map((b) => b.trim()).filter(Boolean)
    .map((b) => (b.startsWith('## ') ? `<h2>${esc(b.slice(3).split('\n')[0])}</h2>${b.includes('\n') ? `<p>${esc(b.slice(b.indexOf('\n') + 1))}</p>` : ''}`
      : `<p>${esc(b)}</p>`)).join('');

  for (const [path, key, title, kicker] of [['/privacy', 'privacyText', 'Informativa\nsulla privacy.', 'Privacy'], ['/cookie', 'cookieText', 'Informativa\nsui cookie.', 'Cookie']]) {
    MIRO.route(path, () => {
      const text = (C()[key] || '').trim() || legalDefault(key === 'cookieText' ? 'cookie' : 'privacy');
      MIRO.page(path, pageHeader({ kicker, title }) + `<section class="section t0"><div class="wrap">${reveal(`<div class="legal-text">${legalHtml(text)}</div>`)}</div></section>`);
    });
  }
  MIRO.legalDefault = legalDefault;

  // Gestionale: si carica solo quando serve.
  let adminLoading = null;
  MIRO.route('/admin', () => MIRO.loadAdmin().then(() => MIRO_ADMIN.render(null, new URLSearchParams())));
  MIRO.route('/admin/:section', ([s], q) => MIRO.loadAdmin().then(() => MIRO_ADMIN.render(s, q)));
  MIRO.loadAdmin = () => {
    if (window.MIRO_ADMIN?.render) return Promise.resolve();
    adminLoading ??= new Promise((resolve, reject) => {
      const l = document.createElement('link');
      l.rel = 'stylesheet';
      l.href = window.MIRO_ADMIN.css;
      document.head.appendChild(l);
      const files = window.MIRO_ADMIN.js;
      const next = (i) => {
        if (i >= files.length) return resolve();
        const s = document.createElement('script');
        s.src = files[i];
        s.onload = () => next(i + 1);
        s.onerror = reject;
        document.body.appendChild(s);
      };
      next(0);
    });
    return adminLoading;
  };

  MIRO.coverUrl = coverUrl;
  MIRO.usedCategories = usedCategories;
  MIRO.statusLabel = statusLabel;
  MIRO.kicker = kicker;
})();
