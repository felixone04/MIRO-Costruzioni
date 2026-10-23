/* =====================================================================
   Gestionale: Clienti, Cantieri, Progetti, Servizi, Testimonianze,
   Stile e colori, Pagina Home, Azienda, Identità e contatti.
   ===================================================================== */
'use strict';

(() => {
  const A = ADM;
  const { esc, ms, $, $$, ph } = MIRO;
  const newId = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  const WSTATUS = { preparazione: 'In preparazione', inCorso: 'Lavori in corso', sospeso: 'Sospeso', completato: 'Completato' };

  /** Password leggibile da dettare o mandare (niente caratteri ambigui). */
  const genPassword = () => {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const r = crypto.getRandomValues(new Uint32Array(10));
    return [...r].map((n) => chars[n % chars.length]).join('');
  };

  // ================================================================= CLIENTI

  function credentials(c, password) {
    const text = `Ciao ${c.name.split(' ')[0]}, ecco l'accesso alla tua area clienti di ${MIRO.boot.content.companyName}, dove puoi seguire i lavori e scaricare i documenti.\n\n`
      + `Indirizzo: ${A.siteLink('/area-clienti')}\nEmail: ${c.email}\nPassword: ${password}\n\nDopo il primo accesso puoi cambiare la password.`;
    A.dialog({ title: 'Credenziali del cliente', width: 520,
      body: `<p class="muted-a">Copia il messaggio e mandalo al cliente (email o WhatsApp). La password non si potrà più rivedere: se la perde, generane una nuova.</p>
        <div class="codebox" style="margin-top:.875rem">${esc(text)}</div>`,
      actions: [{ label: 'Chiudi' }, { html: ms('content_copy') + 'Copia messaggio', kind: 'fill', onClick: () => A.copy(text, 'Messaggio copiato.') }] });
  }

  function clientDialog(existing, onDone) {
    const e = existing;
    const d = A.dialog({ title: e ? 'Modifica cliente' : 'Nuovo cliente', width: 560,
      body: `<div class="stack">${A.field({ label: 'Nome e cognome o ragione sociale *', name: 'name', value: e?.name || '' })}
        <div class="frow-a">${A.field({ label: 'Email (per entrare) *', name: 'email', type: 'email', value: e?.email || '' })}${A.field({ label: 'Telefono', name: 'phone', value: e?.phone || '' })}</div>
        ${e ? '' : `<label class="af"><input name="pw" value="${esc(genPassword())}"><span class="l">Password iniziale *</span>
          <button type="button" class="ib suffix" id="regen" title="Genera un'altra">${ms('casino')}</button>
          <small class="help">Generata a caso: puoi cambiarla. Il cliente potrà sceglierne una sua.</small><small class="err"></small></label>`}
        ${A.field({ label: 'Appunti interni (il cliente non li vede)', name: 'notes', area: true, rows: 2, value: e?.notes || '' })}
        ${e ? A.sw('Accesso attivo', e.active, { sub: 'Se lo spegni il cliente non può più entrare.', attrs: 'name="active"' })
          + `<div class="achips"><button type="button" class="b out" id="newpw">${ms('key')}Nuova password</button>
            <button type="button" class="b text danger" id="delc">${ms('delete')}Elimina cliente</button></div>` : ''}</div>`,
      actions: [{ label: 'Annulla' }, { label: e ? 'Salva' : 'Crea account', kind: 'fill', onClick: async (close, b) => {
        const f = (n) => $(`[name="${n}"]`, d.el);
        let ok = A.setError(f('name'), f('name').value.trim() ? '' : 'Campo obbligatorio');
        const email = f('email').value.trim().toLowerCase();
        ok = A.setError(f('email'), !email ? 'Campo obbligatorio' : !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) ? 'Email non valida'
          : A.D.clients.some((c) => c.email === email && c.id !== e?.id) ? 'Email già usata da un altro cliente' : '') && ok;
        if (!e) ok = A.setError(f('pw'), f('pw').value.length < 8 ? 'Almeno 8 caratteri' : '') && ok;
        if (!ok) return;
        b.disabled = true;
        const value = { id: e?.id || '', name: f('name').value.trim(), email, phone: f('phone').value.trim(), notes: f('notes').value.trim(),
          active: e ? f('active').checked : true };
        try {
          const r = await A.call('admin.client', { value, password: e ? '' : f('pw').value });
          const i = A.D.clients.findIndex((c) => c.id === r.client.id);
          if (i >= 0) A.D.clients[i] = r.client; else A.D.clients.push(r.client);
          close();
          onDone();
          if (!e) credentials(r.client, f('pw').value);
          else A.toast('Cliente aggiornato.');
        } catch (x) { A.toast(x.message, true); b.disabled = false; }
      } }] });
    $('#regen', d.el)?.addEventListener('click', () => { $('[name="pw"]', d.el).value = genPassword(); });
    $('#newpw', d.el)?.addEventListener('click', async () => {
      if (!(await A.confirm(`Generare una nuova password per ${e.name}? Quella attuale smetterà di funzionare.`, { confirm: 'Genera', title: 'Nuova password', danger: false }))) return;
      const pw = genPassword();
      await A.call('admin.client', { value: e, password: pw });
      d.close();
      credentials(e, pw);
    });
    $('#delc', d.el)?.addEventListener('click', async () => {
      if (!(await A.confirm(`Eliminare ${e.name} e tutti i suoi cantieri, documenti e messaggi?`))) return;
      await A.call('admin.client.delete', { id: e.id });
      A.D.clients = A.D.clients.filter((c) => c.id !== e.id);
      A.D.worksites = A.D.worksites.filter((w) => w.clientId !== e.id);
      d.close();
      onDone();
    });
  }

  A.pages.clienti = () => {
    const rows = () => A.D.clients.map((c) => {
      const n = A.D.worksites.filter((w) => w.clientId === c.id).length;
      const meta = [c.email, `${n} ${n === 1 ? 'cantiere' : 'cantieri'}`, c.lastLogin ? 'ultimo accesso ' + A.fmtD(c.lastLogin) : 'mai entrato'].join(' · ');
      return `<div class="lrow" data-c="${esc(c.id)}"><span class="avatar">${esc((c.name || '?')[0].toUpperCase())}</span><div class="bd">
        <div class="tt"><span>${esc(c.name)}</span>${c.active ? '' : '<span style="color:#B3382A;font-size:.75rem;font-weight:400">sospeso</span>'}</div>
        <div class="ss">${esc(meta)}</div></div><span class="ib dim">${ms('chevron_right')}</span></div>`;
    }).join('');
    const draw = (root) => {
      $('#cl', root).innerHTML = A.D.clients.length ? `<div class="card" style="overflow:hidden">${rows()}</div>`
        : `<div class="card">${A.empty('group', 'Nessun cliente ancora. Crea il primo account.')}</div>`;
    };
    return {
      html: A.header('Clienti', "Gli account dell'area clienti. Solo tu puoi crearli: dal sito non ci si può registrare. Ogni cliente vede soltanto i propri cantieri.",
        A.btn('Nuovo cliente', { icon: 'person_add', attrs: 'data-newc' })) + '<div id="cl"></div>',
      mount(root) {
        draw(root);
        root.addEventListener('click', (e) => {
          if (e.target.closest('[data-newc]')) return clientDialog(null, () => draw(root));
          const r = e.target.closest('[data-c]');
          if (r) clientDialog(A.D.clients.find((c) => c.id === r.dataset.c), () => draw(root));
        });
      },
    };
  };

  // ================================================================ CANTIERI

  const setWorksite = (w) => {
    const i = A.D.worksites.findIndex((x) => x.id === w.id);
    if (i >= 0) A.D.worksites[i] = w; else A.D.worksites.unshift(w);
  };

  A.pages.cantieri = (q) => {
    const open = A.D.worksites.find((w) => w.id === q.get('id'));
    if (open) return worksiteEditor(open);
    const row = (w) => {
      const cn = A.D.clients.find((c) => c.id === w.clientId)?.name || '—';
      const unread = w.messages.filter((m) => m.fromClient && !m.read).length;
      return `<a class="lrow" href="#/admin/cantieri?id=${encodeURIComponent(w.id)}"><div class="thumb-a" style="width:5.25rem;height:3.75rem">${ph(w.cover)}</div>
        <div class="bd"><div class="tt"><span>${esc(w.title)}</span></div><div class="ss">${esc(cn)} · ${esc(WSTATUS[w.status] || '')}</div>
        <div class="lin"><i style="width:${w.progress}%"></i></div></div><b style="font-size:.875rem">${w.progress}%</b>
        ${unread ? `<span class="nbadge" title="Messaggi nuovi dal cliente">${unread}</span>` : ''}</a>`;
    };
    return {
      html: A.header('Cantieri', "Quello che ogni cliente vede nella sua area: avanzamento, fasi, aggiornamenti con foto, documenti e messaggi.",
        A.btn('Nuovo cantiere', { icon: 'add', attrs: 'data-neww' }))
        + (A.D.worksites.length ? `<div class="card" style="overflow:hidden">${A.D.worksites.map(row).join('')}</div>`
          : `<div class="card">${A.empty('foundation', 'Nessun cantiere. Creane uno e collegalo a un cliente.')}</div>`),
      mount(root) {
        root.addEventListener('click', async (e) => {
          if (!e.target.closest('[data-neww]')) return;
          if (!A.D.clients.length) { A.toast("Crea prima l'account del cliente."); location.hash = '#/admin/clienti'; return; }
          const w = { id: newId(), clientId: A.D.clients[0].id, title: 'Nuovo cantiere', address: '', start: '', end: '', status: 'preparazione', progress: 0,
            phase: '', description: '', cover: '', steps: [], updates: [] };
          try {
            const r = await A.call('admin.worksite', { value: w });
            setWorksite(r.worksite);
            location.hash = '#/admin/cantieri?id=' + encodeURIComponent(w.id);
          } catch (x) { A.toast(x.message, true); }
        });
      },
    };
  };

  function worksiteEditor(w) {
    const dataFields = ['clientId', 'title', 'address', 'start', 'end', 'status', 'progress', 'phase', 'description', 'cover', 'steps'];
    const pick = () => structuredClone(Object.fromEntries(dataFields.map((k) => [k, w[k] ?? (k === 'steps' ? [] : '')])));
    let draft = pick();
    const saveWhole = async () => {
      const r = await A.call('admin.worksite', { value: { ...w, files: undefined, messages: undefined } });
      Object.assign(w, r.worksite);
      setWorksite(w);
    };

    const stepsHtml = () => draft.steps.map((s, i) => `<div class="steprow" data-step="${i}"><input type="checkbox" title="Completata" ${s.done ? 'checked' : ''}
      data-bind="steps.${i}.done" style="width:1.25rem;height:1.25rem;accent-color:#16191C">
      <div class="t">${A.field({ label: 'Fase', value: s.title, bind: `steps.${i}.title`, dense: true })}</div>
      <div class="d">${A.field({ label: 'Quando', value: s.date, bind: `steps.${i}.date`, dense: true })}</div>
      <button type="button" class="ib" data-sup ${i ? '' : 'disabled'} title="Sposta su">${ms('arrow_upward')}</button>
      <button type="button" class="ib" data-sdel title="Togli">${ms('close')}</button></div>`).join('');

    const dataPanel = () => A.panel('Dati e avanzamento', '', `<div class="stack">
      ${A.field({ label: 'Cliente *', value: draft.clientId, bind: 'clientId', options: A.D.clients.map((c) => [c.id, `${c.name} · ${c.email}`]) })}
      ${A.field({ label: 'Titolo *', value: draft.title, bind: 'title' })}${A.field({ label: 'Indirizzo', value: draft.address, bind: 'address' })}
      <div class="frow-a">${A.field({ label: 'Inizio lavori', value: draft.start, bind: 'start' })}${A.field({ label: 'Fine prevista', value: draft.end, bind: 'end' })}</div>
      ${A.chips(Object.entries(WSTATUS), (v) => v === draft.status, 'data-wst')}
      <div><div style="font-weight:600" id="pval">Avanzamento: ${draft.progress}%</div>
        <input type="range" class="slider" min="0" max="100" step="5" value="${draft.progress}" data-bind="progress"></div>
      ${A.field({ label: 'Fase attuale', value: draft.phase, bind: 'phase', help: 'Es. "Impianti" o "Finiture".' })}
      ${A.field({ label: 'Descrizione per il cliente', value: draft.description, bind: 'description', area: true, rows: 4 })}
      ${A.imgField('Foto di copertina', draft.cover, 'cover')}
      <div class="subh">Fasi</div><div id="steps">${stepsHtml()}</div>
      <div><button type="button" class="b out" id="addstep">${ms('add')}Aggiungi fase</button></div></div>`);

    const updatesPanel = () => {
      const list = [...(w.updates || [])].sort((a, b) => b.date.localeCompare(a.date));
      return A.panel('Aggiornamenti', 'Note e foto dei progressi: il cliente le vede subito.', list.length ? list.map((u) => `<div class="li" style="cursor:default" data-u="${esc(u.id)}">
        ${u.photos?.length ? `<div style="width:3.5rem;height:2.625rem;border-radius:6px;overflow:hidden;flex:none">${ph(u.photos[0])}</div>` : `<span class="avatar">${ms('notes')}</span>`}
        <span class="bd"><div>${esc(u.title)}</div><div class="t2">${esc(A.fmtD(u.date))} · ${u.photos?.length || 0} foto</div></span>
        <button class="ib" data-umenu>${ms('more_vert')}</button></div>`).join('') : '<p class="hint">Nessun aggiornamento pubblicato.</p>',
      `<button class="b fill" id="newu">${ms('add')}Nuovo aggiornamento</button>`);
    };

    const filesPanel = () => A.panel('Documenti', 'Preventivi, contratti, planimetrie, foto: il cliente li scarica dalla sua area.',
      w.files.length ? w.files.map((f) => `<div class="li" style="cursor:default" data-f="${esc(f.id)}">${ms(MIRO.fileIcon(f.name))}
        <span class="bd"><div>${esc(f.name)}</div><div class="t2">${esc([A.fmtD(f.uploadedAt), MIRO.sizeLabel(f.size), f.note].filter(Boolean).join(' · '))}</div></span>
        <button class="ib" data-fmenu>${ms('more_vert')}</button></div>`).join('') : '<p class="hint">Nessun documento caricato.</p>',
      `<div class="achips"><button class="b fill" id="upf">${ms('upload_file')}Carica file</button><button class="b out" id="linkf">${ms('link')}Da indirizzo</button></div>`);

    const messagesPanel = () => {
      const cn = A.D.clients.find((c) => c.id === w.clientId)?.name || 'Cliente';
      const msgs = [...w.messages].sort((a, b) => a.date.localeCompare(b.date));
      return A.panel('Messaggi', 'Il canale con il cliente.', `<div class="chat">${msgs.length ? msgs.map((m) => MIRO.bubble(m, !m.fromClient, cn)).join('') : '<p class="hint" style="margin-bottom:.75rem">Nessun messaggio.</p>'}
        <form class="send" id="reply"><textarea rows="1" placeholder="Rispondi al cliente" aria-label="Risposta"></textarea>
        <button class="round-send" aria-label="Invia">${ms('send')}</button></form></div>`);
    };

    function draw(root, keepDirty = false) {
      const cn = A.D.clients.find((c) => c.id === w.clientId)?.name || '';
      root.innerHTML = `<div class="adm-scroll"><div class="adm-inner"><a class="b text" href="#/admin/cantieri" style="margin-bottom:.5rem">${ms('arrow_back')}Tutti i cantieri</a>
        ${A.header(w.title, cn, `<button class="b text danger" id="delw">${ms('delete')}Elimina cantiere</button>`)}
        <div id="dp">${dataPanel()}</div><div id="up">${updatesPanel()}</div><div id="fp">${filesPanel()}</div><div id="mp">${messagesPanel()}</div></div></div>${A.saveBar()}`;
      const bar = $('#savebar', root);
      const dirty = () => bar.classList.add('on');
      if (keepDirty) dirty();
      mountData(root, dirty);
      mountRest(root);
      $('#sb-undo', root).onclick = () => { draft = pick(); draw(root); };
      $('#sb-save', root).onclick = async (e) => {
        if (!draft.title.trim()) { A.toast('Il titolo è obbligatorio.', true); return; }
        const b = e.currentTarget;
        b.disabled = true;
        Object.assign(w, structuredClone(draft), { steps: draft.steps.filter((s) => (s.title || '').trim()) });
        try {
          await saveWhole();
          A.toast('Cantiere salvato: il cliente vede già le modifiche.');
          draft = pick();
          draw(root);
        } catch (x) { A.toast(x.message, true); b.disabled = false; }
      };
    }

    function mountData(root, dirty) {
      const dp = $('#dp', root);
      A.bind(dp, draft, (el) => { if (el.dataset.bind === 'progress') $('#pval', dp).textContent = `Avanzamento: ${draft.progress}%`; dirty(); });
      A.bindImages(dp, (k, v) => { draft[k] = v; dirty(); });
      const redrawSteps = () => { $('#steps', dp).innerHTML = stepsHtml(); A.bind($('#steps', dp), draft, dirty); dirty(); };
      $('#addstep', dp).onclick = () => { draft.steps.push({ title: '', date: '', done: false }); redrawSteps(); };
      dp.addEventListener('click', (e) => {
        const st = e.target.closest('[data-wst]');
        if (st) {
          draft.status = st.dataset.wst;
          $$('[data-wst]', dp).forEach((b) => b.classList.toggle('on', b.dataset.wst === draft.status));
          dirty();
          return;
        }
        const row = e.target.closest('[data-step]');
        if (!row) return;
        const i = +row.dataset.step;
        if (e.target.closest('[data-sup]')) { A.moveItem(draft.steps, i, i - 1); redrawSteps(); }
        if (e.target.closest('[data-sdel]')) { draft.steps.splice(i, 1); redrawSteps(); }
      });
    }

    function mountRest(root) {
      // Aprendo il cantiere i messaggi del cliente risultano letti.
      if (w.messages.some((m) => m.fromClient && !m.read)) {
        A.call('admin.read', { worksiteId: w.id }).catch(() => {});
        w.messages.forEach((m) => { if (m.fromClient) m.read = true; });
        A.refreshNav();
      }
      const up = $('#up', root);
      const redrawU = () => { up.innerHTML = updatesPanel(); };
      up.addEventListener('click', (e) => {
        if (e.target.closest('#newu')) return updateDialog(null, redrawU);
        const m = e.target.closest('[data-umenu]');
        if (!m) return;
        const u = w.updates.find((x) => x.id === m.closest('[data-u]').dataset.u);
        A.menu(m, [['Modifica', () => updateDialog(u, redrawU)], ['Elimina', async () => {
          if (!(await A.confirm(`Eliminare l'aggiornamento "${u.title}"?`))) return;
          w.updates = w.updates.filter((x) => x !== u);
          await saveWhole();
          redrawU();
        }]]);
      });
      const fp = $('#fp', root);
      const redrawF = () => { fp.innerHTML = filesPanel(); };
      fp.addEventListener('click', async (e) => {
        if (e.target.closest('#upf')) {
          const files = await A.pickFiles({ accept: '', multiple: true });
          if (!files?.length) return;
          const b = $('#upf', fp);
          b.disabled = true;
          b.innerHTML = '<span class="spin"></span>Carico…';
          const fd = new FormData();
          fd.append('worksiteId', w.id);
          [...files].forEach((f) => fd.append('files[]', f));
          try {
            const r = await A.call('admin.file.upload', fd);
            Object.assign(w, r.worksite);
            setWorksite(w);
            if (r.skipped?.length) A.toast(`Non caricati (troppo grandi): ${r.skipped.join(', ')}. Per file grandi usa "Da indirizzo" con un link (es. Google Drive).`, true);
            else A.toast('Documenti caricati.');
          } catch (x) { A.toast(x.message, true); }
          redrawF();
          return;
        }
        if (e.target.closest('#linkf')) {
          const d = A.dialog({ title: 'Documento da indirizzo', width: 480, body: `<div class="stack">${A.field({ label: 'Nome (es. Planimetria.pdf)', name: 'n' })}
            ${A.field({ label: 'Link (Google Drive, Dropbox…)', name: 'u' })}</div>`,
          actions: [{ label: 'Annulla' }, { label: 'Aggiungi', kind: 'fill', onClick: async (close) => {
            try {
              const r = await A.call('admin.file.link', { worksiteId: w.id, name: $('[name=n]', d.el).value, url: $('[name=u]', d.el).value });
              Object.assign(w, r.worksite);
              close();
              redrawF();
            } catch (x) { A.setError($('[name=u]', d.el), x.message); }
          } }] });
          return;
        }
        const m = e.target.closest('[data-fmenu]');
        if (!m) return;
        const f = w.files.find((x) => x.id === m.closest('[data-f]').dataset.f);
        A.menu(m, [
          ['Nota', () => {
            const d = A.dialog({ title: f.name, width: 460, body: A.field({ label: 'Nota per il cliente', area: true, rows: 3, value: f.note, attrs: 'id="fnote"' }),
              actions: [{ label: 'Annulla' }, { label: 'Salva', kind: 'fill', onClick: async (close) => {
                const r = await A.call('admin.file.note', { id: f.id, worksiteId: w.id, note: $('#fnote', d.el).value });
                Object.assign(w, r.worksite);
                close();
                redrawF();
              } }] });
          }],
          ['Scarica', () => window.open(f.url, '_blank')],
          ['Elimina', async () => {
            if (!(await A.confirm(`Eliminare "${f.name}"?`))) return;
            const r = await A.call('admin.file.delete', { id: f.id, worksiteId: w.id });
            Object.assign(w, r.worksite);
            redrawF();
          }],
        ]);
      });
      const mp = $('#mp', root);
      const bindReply = () => {
        const f = $('#reply', mp);
        const ta = $('textarea', f);
        ta.addEventListener('input', () => { ta.style.height = 'auto'; ta.style.height = Math.min(ta.scrollHeight, 160) + 'px'; });
        f.addEventListener('submit', async (e) => {
          e.preventDefault();
          const t = ta.value.trim();
          if (!t) return;
          try {
            const r = await A.call('admin.message', { worksiteId: w.id, text: t });
            Object.assign(w, r.worksite);
            mp.innerHTML = messagesPanel();
            bindReply();
          } catch (x) { A.toast(x.message, true); }
        });
      };
      bindReply();
    }

    function updateDialog(existing, onDone) {
      const u = existing;
      const photos = [...(u?.photos || [])];
      const thumbs = () => photos.map((p, i) => `<div class="t">${ph(p)}<button type="button" data-rp="${i}" aria-label="Togli">${ms('close')}</button></div>`).join('');
      const d = A.dialog({ title: u ? 'Modifica aggiornamento' : 'Nuovo aggiornamento', width: 600,
        body: `<div class="stack">${A.field({ label: 'Titolo *', name: 'title', value: u?.title || '', attrs: 'placeholder="Es. Finiti i massetti"' })}
          ${A.field({ label: 'Cosa è stato fatto', name: 'text', area: true, rows: 4, value: u?.text || '' })}
          <div style="display:flex;align-items:center"><b style="flex:1" id="pc">Foto (${photos.length})</b><button type="button" class="b out" id="addp">${ms('add_photo_alternate')}Aggiungi foto</button></div>
          <div class="thumbs-a" id="th">${thumbs()}</div></div>`,
        actions: [{ label: 'Annulla' }, { label: 'Pubblica', kind: 'fill', onClick: async (close, b) => {
          const t = $('[name=title]', d.el);
          if (!t.value.trim()) { A.setError(t, 'Campo obbligatorio'); return; }
          b.disabled = true;
          if (u) Object.assign(u, { title: t.value.trim(), text: $('[name=text]', d.el).value.trim(), photos });
          else (w.updates ||= []).push({ id: newId(), date: new Date().toISOString(), title: t.value.trim(), text: $('[name=text]', d.el).value.trim(), photos });
          try {
            await saveWhole();
            close();
            A.toast('Aggiornamento pubblicato.');
            onDone();
          } catch (x) { A.toast(x.message, true); b.disabled = false; }
        } }] });
      const redraw = () => { $('#th', d.el).innerHTML = thumbs(); $('#pc', d.el).textContent = `Foto (${photos.length})`; };
      $('#th', d.el).addEventListener('click', (e) => { const b = e.target.closest('[data-rp]'); if (b) { photos.splice(+b.dataset.rp, 1); redraw(); } });
      $('#addp', d.el).onclick = async (e) => {
        const b = e.currentTarget;
        const files = await A.pickFiles({ multiple: true });
        if (!files?.length) return;
        b.disabled = true;
        try { photos.push(...(await A.uploadImages(files))); redraw(); } catch (x) { A.toast(x.message, true); }
        b.disabled = false;
      };
    }

    const del = async () => {
      if (!(await A.confirm(`Eliminare il cantiere "${w.title}" con documenti e messaggi?`))) return;
      await A.call('admin.worksite.delete', { id: w.id });
      A.D.worksites = A.D.worksites.filter((x) => x.id !== w.id);
      location.hash = '#/admin/cantieri';
    };
    return { raw: true, mount(root) { draw(root); root.addEventListener('click', (e) => { if (e.target.closest('#delw')) del(); }); } };
  }

  // ================================================================ PROGETTI

  async function saveList(key, list) {
    await A.call('admin.' + key, { value: list });
    A.D[key] = list;
    MIRO.setPublic(key, structuredClone(list));
  }

  /** Pagina "elenco riordinabile + finestra di modifica" (progetti, servizi, testimonianze). */
  function listPage({ key, title, subtitle, addLabel, emptyIcon, emptyMsg, row, dialog }) {
    const draw = (root) => {
      const list = A.D[key];
      $('#lst', root).innerHTML = list.length ? `<div class="card" style="overflow:hidden" id="rows">${list.map(row).join('')}</div>`
        : `<div class="card">${A.empty(emptyIcon, emptyMsg)}</div>`;
      const rows = $('#rows', root);
      if (rows) A.sortable(rows, async (from, to) => { await saveList(key, A.moveItem([...A.D[key]], from, to)); draw(root); });
    };
    return {
      html: A.header(title, subtitle, A.btn(addLabel, { icon: 'add', attrs: 'data-new' })) + '<div id="lst"></div>',
      mount(root) {
        draw(root);
        const edit = (item) => dialog(item, async (saved) => {
          const list = [...A.D[key]];
          const i = list.findIndex((x) => x.id === saved.id);
          if (i >= 0) list[i] = saved; else if (key === 'projects') list.unshift(saved); else list.push(saved);
          await saveList(key, list);
          draw(root);
        });
        const remove = async (item, name) => {
          if (!(await A.confirm(`Eliminare ${name}?`))) return;
          await saveList(key, A.D[key].filter((x) => x.id !== item.id));
          draw(root);
        };
        root.addEventListener('click', async (e) => {
          if (e.target.closest('[data-new]')) return edit(null);
          const r = e.target.closest('[data-key]');
          if (!r || e.target.closest('.drag')) return;
          const item = A.D[key].find((x) => x.id === r.dataset.key);
          const name = `"${item.title || item.name}"`;
          const tog = e.target.closest('[data-toggle]');
          if (tog) {
            const f = tog.dataset.toggle;
            const on = (x) => (f === 'featured' ? !!x[f] : x[f] !== false);
            const list = A.D[key].map((x) => (x.id === item.id ? { ...x, [f]: !on(x) } : x));
            await saveList(key, list);
            draw(root);
            return;
          }
          if (e.target.closest('[data-del]')) return remove(item, name);
          const more = e.target.closest('[data-more]');
          if (more) return A.menu(more, [['Modifica', () => edit(item)], ['Elimina', () => remove(item, name)]]);
          edit(item);
        });
      },
    };
  }

  const eye = (on) => `<button class="ib ${on ? '' : 'dim'}" data-toggle="${'published'}" title="${on ? 'Visibile sul sito' : 'Nascosto'}">${ms(on ? 'visibility' : 'visibility_off')}</button>`;

  A.pages.progetti = () => listPage({
    key: 'projects', title: 'Progetti', addLabel: 'Nuovo progetto', emptyIcon: 'apartment', emptyMsg: 'Nessun progetto ancora. Aggiungi il primo.',
    subtitle: 'I lavori mostrati sul sito. Trascina per riordinare; la stella li mette in evidenza in Home e nella prima schermata.',
    row: (p, i) => A.listRow({ index: i, key: p.id, image: MIRO.coverUrl(p), title: p.title, dimmed: p.published === false,
      subtitle: [p.category, p.location, p.year, `${(p.photos || []).length} foto`].filter((x) => String(x).trim()).join(' · '),
      extra: p.status === 'inCorso' ? '<span class="tag">IN CORSO</span>' : '',
      trailing: `<button class="ib ${p.featured ? 'star' : 'dim'}" data-toggle="featured" title="${p.featured ? 'In evidenza' : 'Metti in evidenza'}">${ms(p.featured ? 'star' : 'star_outline')}</button>`
        + eye(p.published !== false) }),
    dialog: projectDialog,
  });

  function projectDialog(existing, onSave) {
    const p = existing ? structuredClone(existing) : { id: newId(), title: '', category: '', location: '', year: '', client: '', area: '', duration: '', status: 'completato',
      summary: '', description: '', works: [], cover: '', photos: [], before: '', after: '', featured: false, published: true };
    const cats = A.D.content.categories || [];
    const photoRows = () => p.photos.map((f, i) => `<div class="photo-row" data-ph="${i}"><span class="n">${i + 1}</span><div class="pv">${ph(f.url)}</div>
      ${A.field({ label: 'Didascalia', value: f.caption, bind: `photos.${i}.caption`, dense: true })}
      <button type="button" class="ib" data-pu ${i ? '' : 'disabled'} title="Sposta su">${ms('arrow_upward')}</button>
      <button type="button" class="ib" data-pd ${i < p.photos.length - 1 ? '' : 'disabled'} title="Sposta giù">${ms('arrow_downward')}</button>
      <button type="button" class="ib" data-px title="Togli foto">${ms('close')}</button></div>`).join('');
    const d = A.dialog({ title: existing ? 'Modifica progetto' : 'Nuovo progetto', width: 760,
      body: `<div class="stack">${A.field({ label: 'Titolo *', value: p.title, bind: 'title', help: 'Es. "Villa Le Querce" o "Residenza Aurora".' })}
        ${A.field({ label: 'Categoria', value: p.category, bind: 'category', help: 'Serve ai filtri della pagina Progetti. Le categorie si ordinano da "Identità e contatti".', attrs: 'id="pcat"' })}
        <div id="catchips">${A.chips(cats, (c) => c.toLowerCase() === p.category.trim().toLowerCase(), 'data-cat')}</div>
        <div class="frow-a">${A.field({ label: 'Luogo', value: p.location, bind: 'location' })}${A.field({ label: 'Anno', value: p.year, bind: 'year' })}</div>
        <div class="frow-a" style="--n:3">${A.field({ label: 'Committente', value: p.client, bind: 'client' })}${A.field({ label: 'Superficie (es. 420 m²)', value: p.area, bind: 'area' })}
          ${A.field({ label: 'Durata (es. 16 mesi)', value: p.duration, bind: 'duration' })}</div>
        <div class="seg" id="pstat" style="justify-self:start">${[['completato', 'Completato'], ['inCorso', 'In corso']].map(([v, l]) => `<button type="button" data-ps="${v}" class="${p.status === v ? 'on' : ''}">${l}</button>`).join('')}</div>
        ${A.field({ label: 'Descrizione breve', value: p.summary, bind: 'summary', help: 'Una frase: compare sotto il titolo e nelle schede.' })}
        ${A.field({ label: 'Racconto del progetto', value: p.description, bind: 'description', area: true, rows: 6, help: 'Lascia una riga vuota per andare a capo con un nuovo paragrafo.' })}
        <div class="subh" style="margin:0">Interventi eseguiti</div>${A.stringList('works', p.works, 'Nuovo intervento')}
        ${A.imgField('Copertina (se vuota si usa la prima foto)', p.cover, 'cover', 4 / 3)}
        <div style="display:flex;align-items:center;gap:.625rem;flex-wrap:wrap"><b style="flex:1" id="phc">Galleria (${p.photos.length} foto)</b>
          <button type="button" class="b out" id="phup">${ms('upload')}Carica dal dispositivo</button><button type="button" class="b out" id="phurl">${ms('link')}Da indirizzo</button></div>
        <div id="phs">${photoRows()}</div>
        <div class="subh" style="margin-bottom:0">Prima e dopo (facoltativo)</div>
        <p class="hint">Con la foto "prima" sulla pagina del progetto compare il confronto da trascinare.</p>
        ${A.imgField('Prima', p.before, 'before', 16 / 9)}${A.imgField('Dopo (se vuota si usa la copertina)', p.after, 'after', 16 / 9)}
        ${A.sw('In evidenza in Home', p.featured, { attrs: 'data-bind="featured"' })}${A.sw('Visibile sul sito', p.published !== false, { attrs: 'data-bind="published"' })}</div>`,
      actions: [{ label: 'Annulla' }, { label: 'Salva', kind: 'fill', onClick: async (close, b) => {
        p.photos = p.photos.filter((f) => (f.url || '').trim());
        if (!p.title.trim()) { A.setError($('[data-bind=title]', d.el), 'Campo obbligatorio'); return; }
        if (!(p.cover || '').trim() && !p.photos.length) { A.toast('Aggiungi almeno una foto o una copertina.', true); return; }
        p.category = p.category.trim();
        b.disabled = true;
        try { await onSave(p); close(); A.toast('Progetto salvato.'); } catch (x) { A.toast(x.message, true); b.disabled = false; }
      } }] });
    const root = d.el;
    A.bind(root, p);
    A.bindImages(root, (k, v) => { p[k] = v; });
    A.bindStringList(root, 'works', p.works, () => {});
    const redrawPhotos = () => { $('#phs', root).innerHTML = photoRows(); $('#phc', root).textContent = `Galleria (${p.photos.length} foto)`; A.bind($('#phs', root), p); };
    $('#pcat', root).addEventListener('input', () => $$('[data-cat]', root).forEach((c) => c.classList.toggle('on', c.dataset.cat.toLowerCase() === p.category.trim().toLowerCase())));
    root.addEventListener('click', async (e) => {
      const c = e.target.closest('[data-cat]');
      if (c) { p.category = c.dataset.cat; $('#pcat', root).value = p.category; $$('[data-cat]', root).forEach((x) => x.classList.toggle('on', x === c)); return; }
      const s = e.target.closest('[data-ps]');
      if (s) { p.status = s.dataset.ps; $$('[data-ps]', root).forEach((x) => x.classList.toggle('on', x === s)); return; }
      const row = e.target.closest('[data-ph]');
      if (row) {
        const i = +row.dataset.ph;
        if (e.target.closest('[data-pu]')) A.moveItem(p.photos, i, i - 1);
        else if (e.target.closest('[data-pd]')) A.moveItem(p.photos, i, i + 1);
        else if (e.target.closest('[data-px]')) p.photos.splice(i, 1);
        else return;
        redrawPhotos();
        return;
      }
      if (e.target.closest('#phup')) {
        const files = await A.pickFiles({ multiple: true });
        if (!files?.length) return;
        const b = $('#phup', root);
        b.disabled = true;
        b.innerHTML = '<span class="spin"></span>Carico…';
        try { (await A.uploadImages(files)).forEach((url) => p.photos.push({ url, caption: '' })); redrawPhotos(); } catch (x) { A.toast('Caricamento non riuscito: ' + x.message, true); }
        b.disabled = false;
        b.innerHTML = ms('upload') + 'Carica dal dispositivo';
        return;
      }
      if (e.target.closest('#phurl')) {
        let url = '';
        const dd = A.dialog({ title: 'Aggiungi foto', width: 480, body: A.imgField('Fotografia', '', 'u'),
          actions: [{ label: 'Annulla' }, { label: 'Aggiungi', kind: 'fill', onClick: (close) => { if (url) { p.photos.push({ url, caption: '' }); redrawPhotos(); } close(); } }] });
        A.bindImages(dd.el, (k, v) => { url = v; });
      }
    });
  }

  // ================================================================= SERVIZI

  A.pages.servizi = () => listPage({
    key: 'services', title: 'Servizi', addLabel: 'Nuovo servizio', emptyIcon: 'construction', emptyMsg: 'Nessun servizio. Aggiungi il primo.',
    subtitle: "Cosa fa l'impresa: compaiono nella pagina Servizi con i lavori collegati. Trascina per riordinare.",
    row: (s, i) => A.listRow({ index: i, key: s.id, image: s.image, title: s.title, subtitle: s.text, dimmed: s.active === false,
      trailing: `<button class="ib ${s.active === false ? 'dim' : ''}" data-toggle="active" title="${s.active === false ? 'Nascosto' : 'Visibile sul sito'}">${ms(s.active === false ? 'visibility_off' : 'visibility')}</button>` }),
    dialog(existing, onSave) {
      const s = existing ? structuredClone(existing) : { id: newId(), title: '', text: '', image: '', points: [], categories: [], active: true };
      s.categories ||= [];
      const d = A.dialog({ title: existing ? 'Modifica servizio' : 'Nuovo servizio', width: 640,
        body: `<div class="stack">${A.field({ label: 'Nome *', value: s.title, bind: 'title' })}${A.field({ label: 'Descrizione', value: s.text, bind: 'text', area: true, rows: 4 })}
          <div class="subh" style="margin:0">Punti chiave</div>${A.stringList('points', s.points, 'Nuovo punto (es. "Classe energetica A")')}
          <div class="subh" style="margin:0">Lavori da mostrare</div><p class="hint">Nella pagina Servizi compaiono le foto dei progetti di queste categorie.</p>
          ${A.chips(A.D.content.categories || [], (c) => s.categories.includes(c), 'data-sc')}
          ${A.imgField('Foto', s.image, 'image', 4 / 3)}${A.sw('Visibile sul sito', s.active !== false, { attrs: 'data-bind="active"' })}</div>`,
        actions: [{ label: 'Annulla' }, { label: 'Salva', kind: 'fill', onClick: async (close, b) => {
          if (!s.title.trim()) { A.setError($('[data-bind=title]', d.el), 'Campo obbligatorio'); return; }
          b.disabled = true;
          try { await onSave(s); close(); A.toast('Servizio salvato.'); } catch (x) { A.toast(x.message, true); b.disabled = false; }
        } }] });
      A.bind(d.el, s);
      A.bindImages(d.el, (k, v) => { s[k] = v; });
      A.bindStringList(d.el, 'points', s.points, () => {});
      d.el.addEventListener('click', (e) => {
        const c = e.target.closest('[data-sc]');
        if (!c) return;
        const v = c.dataset.sc;
        s.categories = s.categories.includes(v) ? s.categories.filter((x) => x !== v) : [...s.categories, v];
        c.classList.toggle('on', s.categories.includes(v));
      });
    },
  });

  // =========================================================== TESTIMONIANZE

  A.pages.testimonianze = () => listPage({
    key: 'testimonials', title: 'Testimonianze', addLabel: 'Nuova testimonianza', emptyIcon: 'format_quote', emptyMsg: 'Nessuna testimonianza. Aggiungi la prima.',
    subtitle: 'Le parole dei clienti che scorrono nella pagina Azienda. Trascina per riordinare.',
    row: (t, i) => A.listRow({ index: i, key: t.id, image: null, title: `“${t.text}”`, subtitle: [t.name, t.role].filter(Boolean).join(' · '),
      dimmed: t.published === false, trailing: eye(t.published !== false) }),
    dialog(existing, onSave) {
      const t = existing ? structuredClone(existing) : { id: newId(), name: '', role: '', text: '', published: true };
      const d = A.dialog({ title: existing ? 'Modifica testimonianza' : 'Nuova testimonianza', width: 560,
        body: `<div class="stack">${A.field({ label: 'Testo *', value: t.text, bind: 'text', area: true, rows: 4 })}
          <div class="frow-a">${A.field({ label: 'Nome *', value: t.name, bind: 'name' })}${A.field({ label: 'Progetto o ruolo', value: t.role, bind: 'role' })}</div>
          ${A.sw('Visibile sul sito', t.published !== false, { attrs: 'data-bind="published"' })}</div>`,
        actions: [{ label: 'Annulla' }, { label: 'Salva', kind: 'fill', onClick: async (close, b) => {
          let ok = A.setError($('[data-bind=text]', d.el), t.text.trim() ? '' : 'Campo obbligatorio');
          ok = A.setError($('[data-bind=name]', d.el), t.name.trim() ? '' : 'Campo obbligatorio') && ok;
          if (!ok) return;
          b.disabled = true;
          try { await onSave(t); close(); A.toast('Testimonianza salvata.'); } catch (x) { A.toast(x.message, true); b.disabled = false; }
        } }] });
      A.bind(d.el, t);
    },
  });

  // ========================================================== STILE E COLORI

  A.pages.stile = () => {
    const MODES = [['tutti', 'Visibile a tutti'], ['link', 'Solo con il link di prova'], ['nessuno', 'Nascosto']];
    const look = () => A.D.look;
    const save = async (change) => {
      const l = structuredClone(look());
      change(l);
      await A.call('admin.look', { value: l });
      A.D.look = l;
      MIRO.setPublic('look', structuredClone(l));
    };
    const preview = (t) => `<div class="tprev"><div class="l" style="background:${t.night}"><div style="display:flex;gap:.375rem;align-items:center">
      <i style="width:.75rem;height:.75rem;background:${t.accent}"></i><i style="width:2.125rem;height:.3125rem;background:rgba(255,255,255,.7)"></i></div>
      <span style="flex:1"></span><i style="width:5.625rem;height:.5625rem;background:#fff"></i><i style="width:4.375rem;height:.5625rem;background:${t.accent};margin-top:.3125rem"></i>
      <i style="width:1.75rem;height:.625rem;background:${t.accent};margin-top:.625rem"></i></div>
      <div class="r" style="background:${t.paper}"><i style="width:1.875rem;height:.25rem;background:${t.accentDeep}"></i><i style="width:3.5rem;height:.4375rem;background:${t.ink};margin-top:.5rem"></i>
      <i style="width:2.5rem;height:.4375rem;background:${t.ink};margin-top:.25rem"></i><span style="flex:1"></span><span style="flex:1;background:${t.concrete}"></span></div></div>`;
    const draw = (root) => {
      const l = look();
      const def = MIRO.defaultTheme().id;
      const cur = MIRO.currentTheme().id;
      $('#lk', root).innerHTML = A.panel('Pulsante "Colori" sul sito', "Il pulsante in basso a sinistra apre l'elenco delle tavolozze e le applica al volo.",
        A.chips(MODES, (m) => m === l.switcher, 'data-mode') + (l.switcher === 'link' ? `<p class="muted-a" style="margin-top:1rem">Il pulsante compare solo a chi apre il sito con questo link:</p>
          <button class="b out" data-copy="${esc(A.siteLink('/', { prova: 1 }))}" style="margin-top:.5rem">${ms('link')}Copia il link di prova</button>` : ''))
        + A.panel('Tavolozze', 'La stella indica quella con cui si apre il sito. "Prova" la applica subito a questo browser; il link apre il sito già con quei colori (utile da mandare a un cliente).',
          `<div class="tcards">${MIRO.THEMES.map((t) => {
            const isDef = t.id === def;
            const offered = !(l.hidden || []).includes(t.id) || isDef;
            return `<div class="tcard ${t.id === cur ? 'on' : ''}" style="--tc-accent:${t.accent}">${preview(t)}<div class="tt"><span>${esc(t.name)}</span>
              <button class="ib ${isDef ? 'star' : 'dim'}" data-def="${t.id}" ${isDef ? 'disabled' : ''} title="${isDef ? 'Predefinita' : 'Rendi predefinita'}">${ms(isDef ? 'star' : 'star_outline')}</button></div>
              ${A.sw('Proponi ai visitatori', offered, { attrs: `data-off="${t.id}"`, disabled: isDef })}
              <div class="ac"><button class="b text sm" data-try="${t.id}">${ms(t.id === cur ? 'check' : 'visibility')}${t.id === cur ? 'In uso' : 'Prova'}</button>
              <button class="b text sm" data-copy="${esc(A.siteLink('/', { tema: t.id }))}">${ms('link')}Copia link</button></div></div>`;
          }).join('')}</div>`);
    };
    return {
      html: A.header('Stile e colori', 'Le stesse pagine con atmosfere diverse. Scegli la tavolozza predefinita, quali proporre ai visitatori e chi vede il pulsante "Colori".') + '<div id="lk"></div>',
      mount(root) {
        draw(root);
        root.addEventListener('click', async (e) => {
          const t = e.target;
          if (t.closest('[data-mode]')) { await save((l) => { l.switcher = t.closest('[data-mode]').dataset.mode; }); draw(root); }
          else if (t.closest('[data-def]')) { const id = t.closest('[data-def]').dataset.def; await save((l) => { l.defaultTheme = id; l.hidden = (l.hidden || []).filter((x) => x !== id); }); draw(root); }
          else if (t.closest('[data-try]')) { MIRO.selectTheme(t.closest('[data-try]').dataset.try); draw(root); }
          else if (t.closest('[data-copy]')) A.copy(t.closest('[data-copy]').dataset.copy, 'Link copiato: ' + t.closest('[data-copy]').dataset.copy);
        });
        root.addEventListener('change', async (e) => {
          const off = e.target.closest('[data-off]');
          if (!off) return;
          const id = off.dataset.off;
          await save((l) => { l.hidden = off.checked ? (l.hidden || []).filter((x) => x !== id) : [...new Set([...(l.hidden || []), id])]; });
          draw(root);
        });
      },
    };
  };

  // ======================================================= TESTI DEL SITO

  const TITLE_HELP = "Vai a capo per la riga successiva: l'ultima riga appare in corsivo, colorata.";
  const f = (label, path, d, o = {}) => A.field({ label, value: A.getPath(d, path) ?? '', bind: path, ...o });

  /** Editor di coppie titolo/testo (numeri, valori). */
  const highlights = (d, key, tl, xl, add, rows = 1) => `${(A.getPath(d, key) || []).map((h, i) => `<div class="card" style="padding:.5rem .5rem 1rem 1rem;margin-bottom:.875rem;background:#FAFAF8">
    <div style="display:flex;justify-content:flex-end">${ctl(key, i, A.getPath(d, key).length)}</div>
    <div class="frow-a" style="grid-template-columns:10.625rem 1fr">${f(tl, `${key}.${i}.title`, d)}${f(xl, `${key}.${i}.text`, d, rows > 1 ? { area: true, rows } : {})}</div></div>`).join('')}
    <button type="button" class="b out" data-add="${key}" data-kind="hl">${ms('add')}${esc(add)}</button>`;
  const ctl = (key, i, n) => `<button type="button" class="ib" data-mv="${key}:${i}:-1" ${i ? '' : 'disabled'} title="Sposta su">${ms('arrow_upward')}</button>
    <button type="button" class="ib" data-mv="${key}:${i}:1" ${i < n - 1 ? '' : 'disabled'} title="Sposta giù">${ms('arrow_downward')}</button>
    <button type="button" class="ib" data-rm="${key}:${i}" title="Elimina">${ms('delete')}</button>`;
  /** Editor di tappe (anno, titolo, testo). */
  const milestones = (d, key, item, num, add) => `${(d[key] || []).map((m, i) => `<div class="card" style="padding:.5rem .5rem 1rem 1rem;margin-bottom:.875rem;background:#FAFAF8">
    <div style="display:flex;align-items:center"><b style="flex:1">${esc(item)} ${i + 1}</b>${ctl(key, i, d[key].length)}</div>
    <div class="frow-a" style="grid-template-columns:6.875rem 1fr">${f(num, `${key}.${i}.year`, d)}${f('Titolo', `${key}.${i}.title`, d)}</div>
    <div style="margin-top:1rem">${f('Testo', `${key}.${i}.text`, d, { area: true, rows: 3 })}</div></div>`).join('')}
    <button type="button" class="b out" data-add="${key}" data-kind="ms">${ms('add')}${esc(add)}</button>`;

  /** Pagina di testi a bozza con elenchi modificabili. */
  function contentPage(title, subtitle, build, stringLists = []) {
    return A.draftPage({
      title, subtitle,
      source: () => A.D.content,
      build,
      save: A.saveContent,
      mount(root, d, dirty, redraw) {
        A.bindImages(root, (k, v) => { A.setPath(d, k, v); dirty(); });
        stringLists.forEach((k) => A.bindStringList(root, k, d[k] ||= [], dirty));
        // Sul contenuto interno, che viene ridisegnato: così i gestori non si accumulano.
        $('.adm-inner', root).addEventListener('click', (e) => {
          const add = e.target.closest('[data-add]');
          if (add) {
            const k = add.dataset.add;
            const list = A.getPath(d, k);
            if (add.dataset.kind === 'hl') list.push({ title: '', text: '' });
            else if (add.dataset.kind === 'ms') list.push({ year: String(list.length + 1).padStart(2, '0'), title: '', text: '' });
            else if (add.dataset.kind === 'team') list.push({ id: newId(), name: '', role: '', photo: '' });
            redraw();
            return;
          }
          const mv = e.target.closest('[data-mv]');
          if (mv) { const [k, i, dir] = mv.dataset.mv.split(':'); A.moveItem(A.getPath(d, k), +i, +i + +dir); redraw(); return; }
          const rm = e.target.closest('[data-rm]');
          if (rm) { const [k, i] = rm.dataset.rm.split(':'); A.getPath(d, k).splice(+i, 1); redraw(); }
        });
      },
    });
  }

  A.pages.home = () => contentPage('Pagina Home', 'I testi della prima pagina. Le foto della prima schermata sono le copertine dei progetti in evidenza.', (d) =>
    A.panel('Prima schermata', '', `<div class="stack">${f('Etichetta', 'heroKicker', d)}${f('Titolo', 'heroTitle', d, { area: true, rows: 3, help: TITLE_HELP })}
      ${f('Sottotitolo', 'heroSubtitle', d, { area: true, rows: 3 })}</div>`, `<a class="b text" href="#/admin/progetti">${ms('star_outline')}Scegli i progetti in evidenza</a>`)
    + A.panel('Presentazione e numeri', 'I numeri "contano" fino al valore quando compaiono (es. 420+, 180k).', `<div class="stack">${f('Etichetta', 'introKicker', d)}
      ${f('Titolo', 'introTitle', d, { area: true, rows: 3, help: TITLE_HELP })}${f('Testo', 'introText', d, { area: true, rows: 5 })}</div>
      <div style="margin-top:1.375rem">${highlights(d, 'stats', 'Numero', 'Descrizione', 'Aggiungi numero')}</div>`)
    + A.panel('Progetti', 'Il titolo della sezione in Home e in cima alla pagina Progetti.', `<div class="stack">${f('Etichetta', 'projectsKicker', d)}
      ${f('Titolo', 'projectsTitle', d, { area: true, rows: 3, help: TITLE_HELP })}${f('Testo', 'projectsText', d, { area: true, rows: 3 })}</div>`)
    + A.panel('Pagina Servizi', 'Il titolo e il testo in cima alla pagina Servizi.', `<div class="stack">${f('Etichetta', 'servicesKicker', d)}
      ${f('Titolo', 'servicesTitle', d, { area: true, rows: 3, help: TITLE_HELP })}${f('Testo', 'servicesText', d, { area: true, rows: 3 })}</div>`,
      `<a class="b text" href="#/admin/servizi">${ms('construction')}Gestisci i servizi</a>`)
    + A.panel('Nastro scorrevole', 'Le parole che scorrono a tutta larghezza.', A.stringList('ticker', d.ticker || [], 'Nuova parola')), ['ticker']);

  A.pages.azienda = () => contentPage('Azienda', 'Storia, valori, tappe e persone della pagina Azienda.', (d) =>
    A.panel('Apertura', '', `<div class="stack">${f('Etichetta', 'aboutKicker', d)}${f('Titolo', 'aboutTitle', d, { area: true, rows: 3, help: TITLE_HELP })}
      ${f('Introduzione', 'aboutIntro', d, { area: true, rows: 3 })}${A.imgField('Foto di apertura', d.aboutImage, 'aboutImage')}</div>`)
    + A.panel('La storia', '', `<div class="stack">${f('Testo', 'aboutText', d, { area: true, rows: 10, help: 'Lascia una riga vuota per un nuovo paragrafo.' })}
      ${A.imgField('Seconda foto', d.aboutImage2, 'aboutImage2')}<div class="subh" style="margin:0">Certificazioni</div>${A.stringList('certifications', d.certifications || [], 'Nuova certificazione')}</div>`)
    + A.panel('Valori', 'Le iniziali dei valori compaiono come grandi lettere.', highlights(d, 'values', 'Valore', 'Descrizione', 'Aggiungi valore', 2))
    + A.panel('Le tappe', '', milestones(d, 'timeline', 'Tappa', 'Anno', 'Aggiungi tappa'))
    + A.panel('Le persone', '', `${(d.team || []).map((m, i) => `<div class="card" style="padding:.5rem .5rem 1rem 1rem;margin-bottom:.875rem;background:#FAFAF8">
      <div style="display:flex;align-items:center"><b style="flex:1">${esc(m.name || 'Persona ' + (i + 1))}</b>${ctl('team', i, d.team.length)}</div>
      <div class="frow-a">${f('Nome', `team.${i}.name`, d)}${f('Ruolo', `team.${i}.role`, d)}</div>
      <div style="margin-top:1rem">${A.imgField('Foto', m.photo, `team.${i}.photo`, 4 / 5)}</div></div>`).join('')}
      <button type="button" class="b out" data-add="team" data-kind="team">${ms('add')}Aggiungi persona</button>`), ['certifications']);

  A.pages.contatti = () => contentPage('Identità e contatti', 'Nome, logo, recapiti, modulo contatti e categorie dei progetti.', (d) =>
    A.panel('Identità', '', `<div class="stack"><div class="frow-a">${f('Ragione sociale', 'companyName', d)}${f('Nome breve (nel logo)', 'shortName', d)}</div>
      ${f('Slogan', 'tagline', d)}${f('Testo del piè di pagina', 'footerText', d, { area: true, rows: 3 })}
      ${A.imgField('Logo (facoltativo: se vuoto si usa il logo disegnato)', d.logo, 'logo', 3)}</div>`)
    + A.panel('Recapiti', '', `<div class="stack"><div class="frow-a">${f('Telefono', 'contacts.phone', d)}${f('WhatsApp', 'contacts.whatsapp', d)}</div>
      <div class="frow-a">${f('Email', 'contacts.email', d)}${f('PEC', 'contacts.pec', d)}</div>${f('Indirizzo della sede', 'contacts.address', d)}
      <div class="frow-a">${f('Orari ufficio', 'contacts.hours', d)}${f('Partita IVA', 'contacts.vat', d)}</div>
      <div class="frow-a" style="--n:3">${f('Instagram (link)', 'contacts.instagram', d)}${f('Facebook (link)', 'contacts.facebook', d)}${f('LinkedIn (link)', 'contacts.linkedin', d)}</div></div>`)
    + A.panel('Pagina e modulo contatti', '', `<div class="stack">${f('Titolo', 'contactTitle', d, { area: true, rows: 3, help: TITLE_HELP })}
      ${f('Testo', 'contactText', d, { area: true, rows: 3 })}<div class="subh" style="margin:0">Tipi di lavoro (scelta nel modulo)</div>
      ${A.stringList('requestTypes', d.requestTypes || [], 'Nuovo tipo')}</div>`)
    + A.panel('Categorie dei progetti', "L'ordine dei filtri nella pagina Progetti.", A.stringList('categories', d.categories || [], 'Nuova categoria')),
  ['requestTypes', 'categories']);
})();
