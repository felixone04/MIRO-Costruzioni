import '../models/models.dart';

/// Foto di esempio (Unsplash). La larghezza viene adattata allo schermo.
String _u(String id) =>
    'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=1600&q=80';

/// Contenuti di esempio: si sostituiscono dal gestionale.
class Seed {
  static SiteContent content() => SiteContent(
    companyName: 'M.I.R.O. Costruzioni',
    shortName: 'M.I.R.O.',
    tagline: 'Costruzioni, ristrutturazioni e restauri a Bari',
    footerText:
        'Impresa edile a Bari dal 1987. Costruiamo case, uffici e capannoni, '
        'ristrutturiamo e restauriamo con le nostre squadre.',
    heroKicker: 'Impresa edile a Bari dal 1987',
    heroTitle: 'Case fatte bene,\nda chi le costruisce.',
    heroSubtitle:
        'Costruiamo, ristrutturiamo e restauriamo in Puglia da tre '
        'generazioni, con le nostre squadre e un solo referente dall\'inizio '
        'alla fine.',
    introKicker: 'Chi siamo',
    introTitle: 'Un\'impresa di famiglia,\ncresciuta in cantiere.',
    introText:
        'Siamo partiti con tre operai e una betoniera presa in prestito. Oggi '
        'seguiamo case, condomini, uffici e capannoni, ma lavoriamo ancora come '
        'allora: tempi scritti nel contratto, prezzi chiari e la stessa squadra '
        'dal primo giorno alla consegna delle chiavi.',
    stats: [
      Highlight(title: '38', text: 'anni di lavoro'),
      Highlight(title: '420+', text: 'cantieri chiusi'),
      Highlight(title: '180k', text: 'metri quadri costruiti'),
      Highlight(title: '65', text: 'persone in squadra'),
    ],
    projectsKicker: 'Progetti',
    projectsTitle: 'Gli ultimi\ncantieri.',
    projectsText:
        'Ville, condomini, uffici e qualche recupero di cui andiamo '
        'particolarmente fieri.',
    servicesKicker: 'Servizi',
    servicesTitle: 'Cosa\nfacciamo.',
    servicesText:
        'Scegli un tipo di lavoro per vedere come lo affrontiamo e alcuni '
        'cantieri che abbiamo seguito.',
    ticker: [
      'Nuove costruzioni',
      'Ristrutturazioni',
      'Restauro',
      'Edilizia industriale',
      'Riqualificazione energetica',
      'Direzione lavori',
    ],
    aboutKicker: 'Azienda',
    aboutTitle: 'La nostra\nstoria.',
    aboutIntro:
        'Dal 1987 progettiamo e costruiamo con la stessa squadra: ingegneri, '
        'geometri e muratori che si conoscono da anni.',
    aboutText:
        'Tutto è iniziato con Michele Romano, muratore e poi capocantiere, e una '
        'betoniera presa in prestito. Oggi siamo più di sessanta, abbiamo i nostri '
        'mezzi e un ufficio tecnico interno, ma le decisioni importanti si prendono '
        'ancora in cantiere.\n\n'
        'Il nome raccoglie le iniziali di quattro parole a cui teniamo: '
        'Metodo, Integrità, Responsabilità, Opera.',
    aboutImage: _u('1626885930974-4b69aa21bbf9'),
    aboutImage2: _u('1504307651254-35680f356dfd'),
    values: [
      Highlight(
        title: 'Metodo',
        text: 'Cronoprogrammi reali, computi trasparenti, nessuna sorpresa a fine lavori.',
      ),
      Highlight(
        title: 'Integrità',
        text: 'Materiali certificati e tracciabili, lavorazioni eseguite a regola d\'arte.',
      ),
      Highlight(
        title: 'Responsabilità',
        text: 'Sicurezza in cantiere prima di tutto e rispetto per chi abita intorno.',
      ),
      Highlight(
        title: 'Opera',
        text: 'Ogni edificio è firmato: lo costruiamo perché duri generazioni.',
      ),
    ],
    timeline: [
      Milestone(
        year: '1987',
        title: 'La prima betoniera',
        text: 'Michele Romano fonda l\'impresa con tre operai e un cantiere a Bari.',
      ),
      Milestone(
        year: '1998',
        title: 'Il primo condominio',
        text: 'Ventiquattro alloggi consegnati in anticipo: nasce l\'ufficio tecnico.',
      ),
      Milestone(
        year: '2009',
        title: 'Restauro e recupero',
        text: 'Una squadra dedicata ai centri storici e ai beni vincolati.',
      ),
      Milestone(
        year: '2016',
        title: 'Certificazioni',
        text:
            'ISO 9001, ISO 45001 e attestazione SOA per gli appalti pubblici.',
      ),
      Milestone(
        year: '2024',
        title: 'Seconda generazione',
        text: 'Ilaria e Riccardo guidano l\'impresa verso l\'edilizia a basso consumo.',
      ),
    ],
    team: [
      TeamMember(
        name: 'Michele Romano',
        role: 'Fondatore',
        photo: _u('1500648767791-00dcc994a43e'),
      ),
      TeamMember(
        name: 'Ilaria Romano',
        role: 'Direzione tecnica',
        photo: _u('1438761681033-6461ffad8d80'),
      ),
      TeamMember(
        name: 'Riccardo Orlando',
        role: 'Responsabile cantieri',
        photo: _u('1507003211169-0a1dd7228f2d'),
      ),
      TeamMember(
        name: 'Ornella Mancini',
        role: 'Ufficio preventivi',
        photo: _u('1494790108377-be9c29b29330'),
      ),
    ],
    certifications: [
      'ISO 9001',
      'ISO 45001',
      'ISO 14001',
      'SOA OG1 · OG2',
      'White list Prefettura',
    ],
    contacts: Contacts(
      phone: '+39 080 123 4567',
      whatsapp: '+39 333 123 4567',
      email: 'info@mirocostruzioni.it',
      pec: 'mirocostruzioni@pec.it',
      address: 'Via delle Fornaci 18, 70126 Bari',
      hours: 'Lun–Ven 8:00–13:00 · 14:30–18:30',
      instagram: 'https://instagram.com/',
      facebook: 'https://facebook.com/',
      linkedin: 'https://linkedin.com/',
      vat: 'P.IVA 01234567890',
    ),
    requestTypes: [
      'Nuova costruzione',
      'Ristrutturazione',
      'Restauro',
      'Edificio commerciale / industriale',
      'Riqualificazione energetica',
      'Altro',
    ],
    timings: [
      'Il prima possibile',
      'Entro 6 mesi',
      'Entro un anno',
      'Sto solo valutando',
    ],
    contactTitle: 'Scrivici\ndue righe.',
    contactText:
        'Raccontaci cosa hai in mente: ti richiamiamo entro due giorni '
        'lavorativi.',
    contactImage: _u('1503387762-592deb58ef4e'),
    categories: [
      'Residenziale',
      'Ristrutturazione',
      'Commerciale',
      'Industriale',
      'Restauro',
    ],
  );

  static List<Project> projects() => [
    Project(
      id: 'p-villa-querce',
      title: 'Villa Le Querce',
      category: 'Residenziale',
      location: 'Monopoli (BA)',
      year: '2024',
      client: 'Privato',
      area: '420 m²',
      duration: '16 mesi',
      summary:
          'Villa unifamiliare in classe A4 immersa in un uliveto secolare.',
      description:
          'Una villa a due livelli costruita attorno a un patio verde, con grandi '
          'vetrate scorrevoli rivolte agli ulivi. Struttura in cemento armato, '
          'cappotto in fibra di legno e impianto fotovoltaico integrato in copertura.\n\n'
          'Abbiamo seguito l\'opera chiavi in mano: scavi, strutture, impianti, '
          'finiture interne e sistemazione del giardino.',
      works: [
        'Strutture in c.a.',
        'Involucro ad alta efficienza',
        'Impianti domotici',
        'Finiture e arredi fissi',
        'Sistemazioni esterne',
      ],
      cover: _u('1600585154340-be6161a56a0c'),
      photos: [
        ProjectPhoto(
          url: _u('1600585154340-be6161a56a0c'),
          caption: 'Il fronte sul giardino al tramonto',
        ),
        ProjectPhoto(
          url: _u('1600566753190-17f0baa2a6c3'),
          caption: 'Ingresso e rivestimento in legno',
        ),
        ProjectPhoto(
          url: _u('1600210492486-724fe5c67fb0'),
          caption: 'Il soggiorno a doppia altezza',
        ),
        ProjectPhoto(
          url: _u('1600573472550-8090b5e0745e'),
          caption: 'La scala sospesa',
        ),
        ProjectPhoto(
          url: _u('1600607687644-c7171b42498f'),
          caption: 'Camera padronale',
        ),
        ProjectPhoto(
          url: _u('1600566752355-35792bedcfea'),
          caption: 'Bagno in resina',
        ),
      ],
      before: _u('1503708928676-1cb796a0891e'),
      featured: true,
    ),
    Project(
      id: 'p-residenza-aurora',
      title: 'Residenza Aurora',
      category: 'Residenziale',
      location: 'Bari',
      year: '2023',
      client: 'Aurora Immobiliare S.r.l.',
      area: '3.200 m²',
      duration: '22 mesi',
      summary: 'Ventiquattro appartamenti con logge, giardini pensili e box interrati.',
      description:
          'Un edificio residenziale di sei piani con struttura antisismica, '
          'facciate ventilate e logge profonde che proteggono dal sole estivo. '
          'Al piano interrato 30 box auto e cantine.\n\n'
          'Consegnato con due settimane di anticipo sul cronoprogramma.',
      works: [
        'Fondazioni speciali',
        'Struttura antisismica',
        'Facciata ventilata',
        'Impianti centralizzati',
        'Parti comuni',
      ],
      cover: _u('1460317442991-0ec209397118'),
      photos: [
        ProjectPhoto(
          url: _u('1460317442991-0ec209397118'),
          caption: 'Le logge sul fronte sud',
        ),
        ProjectPhoto(
          url: _u('1545324418-cc1a3fa10c00'),
          caption: 'Il prospetto laterale',
        ),
        ProjectPhoto(
          url: _u('1574362848149-11496d93a7c7'),
          caption: 'La corte interna',
        ),
        ProjectPhoto(
          url: _u('1448630360428-65456885c650'),
          caption: 'Dettaglio della facciata',
        ),
        ProjectPhoto(
          url: _u('1560448204-e02f11c3d0e2'),
          caption: 'Un appartamento tipo',
        ),
      ],
      featured: true,
    ),
    Project(
      id: 'p-casa-bianca',
      title: 'Casa Bianca sul mare',
      category: 'Ristrutturazione',
      location: 'Polignano a Mare (BA)',
      year: '2023',
      client: 'Privato',
      area: '280 m²',
      duration: '9 mesi',
      summary: 'Una casa degli anni \'70 trasformata in villa contemporanea.',
      description:
          'Ristrutturazione integrale con ampliamento: abbiamo consolidato la struttura '
          'esistente, ridisegnato gli spazi interni e aggiunto una piscina a sfioro '
          'affacciata sul mare.\n\n'
          'Trascina il cursore qui sotto per confrontare il prima e il dopo.',
      works: [
        'Demolizioni e consolidamento',
        'Ampliamento',
        'Piscina a sfioro',
        'Nuovi impianti',
        'Finiture di pregio',
      ],
      cover: _u('1600596542815-ffad4c1539a9'),
      photos: [
        ProjectPhoto(
          url: _u('1600596542815-ffad4c1539a9'),
          caption: 'La piscina a sfioro',
        ),
        ProjectPhoto(
          url: _u('1600607687939-ce8a6c25118c'),
          caption: 'Il living aperto',
        ),
        ProjectPhoto(
          url: _u('1519710164239-da123dc03ef4'),
          caption: 'Angolo colazione',
        ),
        ProjectPhoto(
          url: _u('1584622650111-993a426fbf0a'),
          caption: 'Bagno ospiti',
        ),
        ProjectPhoto(
          url: _u('1600585152915-d208bec867a1'),
          caption: 'Zona giorno',
        ),
      ],
      before: _u('1517581177682-a085bb7ffb15'),
      featured: true,
    ),
    Project(
      id: 'p-hq-levante',
      title: 'Headquarters Levante',
      category: 'Commerciale',
      location: 'Modugno (BA)',
      year: '2022',
      client: 'Levante Tech S.p.A.',
      area: '1.800 m²',
      duration: '14 mesi',
      summary:
          'Nuova sede direzionale con open space, sale riunioni e terrazza.',
      description:
          'Un edificio per uffici su tre livelli con struttura in acciaio, '
          'pareti vetrate a controllo solare e pavimenti sopraelevati per la '
          'massima flessibilità degli spazi di lavoro.\n\n'
          'Lavori eseguiti con l\'azienda operativa nell\'edificio accanto, '
          'senza un giorno di fermo.',
      works: [
        'Struttura in acciaio',
        'Facciate continue',
        'Impianti HVAC',
        'Allestimento uffici',
      ],
      cover: _u('1497366811353-6870744d04b2'),
      photos: [
        ProjectPhoto(
          url: _u('1497366811353-6870744d04b2'),
          caption: 'Open space al primo piano',
        ),
        ProjectPhoto(
          url: _u('1497366216548-37526070297c'),
          caption: 'Area relax e cucina',
        ),
        ProjectPhoto(
          url: _u('1487958449943-2429e8be8625'),
          caption: 'Il volume d\'ingresso',
        ),
        ProjectPhoto(
          url: _u('1556761175-b413da4baf72'),
          caption: 'Sala progetti',
        ),
      ],
      featured: true,
    ),
    Project(
      id: 'p-masseria-san-vito',
      title: 'Masseria San Vito',
      category: 'Restauro',
      location: 'Fasano (BR)',
      year: '2021',
      client: 'Famiglia De Nicola',
      area: '950 m²',
      duration: '18 mesi',
      summary: 'Recupero conservativo di una masseria del Settecento.',
      description:
          'Restauro di un complesso rurale vincolato: consolidamento delle volte '
          'in pietra, recupero delle travi in legno originali e nuovi impianti '
          'invisibili, nel rispetto delle prescrizioni della Soprintendenza.',
      works: [
        'Consolidamento murature',
        'Recupero travi in legno',
        'Intonaci a calce',
        'Impianti sotto traccia',
      ],
      cover: _u('1590725140246-20acdee442be'),
      photos: [
        ProjectPhoto(
          url: _u('1590725140246-20acdee442be'),
          caption: 'Le travi originali recuperate',
        ),
        ProjectPhoto(
          url: _u('1558036117-15d82a90b9b1'),
          caption: 'La masseria nel paesaggio',
        ),
        ProjectPhoto(
          url: _u('1519643381401-22c77e60520e'),
          caption: 'La sala da pranzo',
        ),
        ProjectPhoto(
          url: _u('1595846519845-68e298c2edd8'),
          caption: 'Il salotto',
        ),
      ],
      before: _u('1517581177682-a085bb7ffb15'),
      featured: true,
    ),
    Project(
      id: 'p-polo-adriatico',
      title: 'Polo logistico Adriatico',
      category: 'Industriale',
      location: 'Molfetta (BA)',
      year: '2025',
      client: 'Adriatica Logistica S.r.l.',
      area: '6.500 m²',
      duration: '12 mesi',
      status: ProjectStatus.inCorso,
      summary: 'Magazzino automatizzato con uffici e copertura fotovoltaica.',
      description:
          'Capannone in carpenteria metallica con campate da 30 metri, '
          'pavimentazione industriale ad alta portata e 1 MW di fotovoltaico '
          'in copertura. Il cantiere è in corso: consegna prevista a primavera.',
      works: [
        'Carpenteria metallica',
        'Pavimentazioni industriali',
        'Fotovoltaico',
        'Piazzali e viabilità',
      ],
      cover: _u('1590069261209-f8e9b8642343'),
      photos: [
        ProjectPhoto(
          url: _u('1590069261209-f8e9b8642343'),
          caption: 'La struttura metallica',
        ),
        ProjectPhoto(
          url: _u('1429497419816-9ca5cfb4571a'),
          caption: 'Il montaggio con le gru',
        ),
        ProjectPhoto(
          url: _u('1503708928676-1cb796a0891e'),
          caption: 'Movimento terra',
        ),
        ProjectPhoto(
          url: _u('1626885930974-4b69aa21bbf9'),
          caption: 'Verifica in cantiere',
        ),
      ],
    ),
    Project(
      id: 'p-il-parco',
      title: 'Residenze Il Parco',
      category: 'Residenziale',
      location: 'Altamura (BA)',
      year: '2022',
      client: 'Cooperativa Il Parco',
      area: '2.100 m²',
      duration: '15 mesi',
      summary: 'Dodici villette a schiera con giardino privato.',
      description:
          'Un piccolo quartiere di case a schiera in classe A, con giardini '
          'privati, posti auto coperti e un parco comune piantumato.',
      works: ['Urbanizzazioni', 'Strutture', 'Finiture', 'Verde comune'],
      cover: _u('1567496898669-ee935f5f647a'),
      photos: [
        ProjectPhoto(
          url: _u('1567496898669-ee935f5f647a'),
          caption: 'Le schiere sul viale',
        ),
        ProjectPhoto(
          url: _u('1605276374104-dee2a0ed3cd6'),
          caption: 'I fronti d\'ingresso',
        ),
        ProjectPhoto(
          url: _u('1555636222-cae831e670b3'),
          caption: 'Il quartiere',
        ),
      ],
    ),
    Project(
      id: 'p-villa-azzurra',
      title: 'Villa Azzurra',
      category: 'Residenziale',
      location: 'Ostuni (BR)',
      year: '2020',
      client: 'Privato',
      area: '360 m²',
      duration: '13 mesi',
      summary: 'Linee pure e piscina tra gli ulivi della Valle d\'Itria.',
      description:
          'Villa contemporanea con struttura in c.a. a vista, ampie terrazze '
          'e una piscina a sfioro che riflette il paesaggio.',
      works: ['Strutture', 'Piscina', 'Domotica', 'Paesaggio'],
      cover: _u('1613490493576-7fde63acd811'),
      photos: [
        ProjectPhoto(
          url: _u('1613490493576-7fde63acd811'),
          caption: 'La piscina',
        ),
        ProjectPhoto(
          url: _u('1580587771525-78b9dba3b914'),
          caption: 'Il fronte principale',
        ),
        ProjectPhoto(
          url: _u('1503174971373-b1f69850bded'),
          caption: 'Il living',
        ),
        ProjectPhoto(
          url: _u('1513694203232-719a280e022f'),
          caption: 'Dettaglio d\'interni',
        ),
      ],
    ),
    Project(
      id: 'p-torre-meridiana',
      title: 'Torre Meridiana',
      category: 'Commerciale',
      location: 'Bari',
      year: '2026',
      client: 'Meridiana Sviluppo S.p.A.',
      area: '9.400 m²',
      duration: '30 mesi',
      status: ProjectStatus.inCorso,
      summary: 'Torre direzionale di dodici piani con facciata in vetro.',
      description:
          'Il cantiere più alto della nostra storia: dodici piani di uffici '
          'con nucleo in c.a., solai post-tesi e facciata continua a doppia pelle.',
      works: ['Nucleo in c.a.', 'Solai post-tesi', 'Facciata a doppia pelle'],
      cover: _u('1511818966892-d7d671e672a2'),
      photos: [
        ProjectPhoto(
          url: _u('1511818966892-d7d671e672a2'),
          caption: 'Render della torre',
        ),
        ProjectPhoto(
          url: _u('1531834685032-c34bf0d84c77'),
          caption: 'Getto dei solai',
        ),
        ProjectPhoto(
          url: _u('1508450859948-4e04fabaa4ea'),
          caption: 'Avanzamento lavori',
        ),
        ProjectPhoto(
          url: _u('1486406146926-c627a92ad1ab'),
          caption: 'Riferimenti di facciata',
        ),
      ],
    ),
  ];

  static List<ServiceItem> services() => [
    ServiceItem(
      id: 's-nuove',
      title: 'Nuove costruzioni',
      text:
          'Ville, palazzine e piccoli quartieri, dallo scavo alla consegna delle '
          'chiavi. Seguiamo noi strutture, impianti e finiture, così chi compra '
          'casa ha un solo numero da chiamare.',
      image: _u('1429497419816-9ca5cfb4571a'),
      points: [
        'Strutture antisismiche',
        'Classe energetica A',
        'Chiavi in mano',
      ],
      categories: ['Residenziale'],
    ),
    ServiceItem(
      id: 's-ristrutturazioni',
      title: 'Ristrutturazioni',
      text:
          'Appartamenti e case da rifare in tutto o in parte. Prima di iniziare '
          'mettiamo per iscritto lavori, tempi e prezzo; durante il cantiere '
          'ricevi ogni settimana le foto dei progressi.',
      image: _u('1600607687939-ce8a6c25118c'),
      points: [
        'Demolizioni e ricostruzioni',
        'Impianti nuovi',
        'Bonus edilizi',
      ],
      categories: ['Ristrutturazione'],
    ),
    ServiceItem(
      id: 's-restauro',
      title: 'Restauro',
      text:
          'Masserie, palazzi e case nei centri storici. Usiamo calce, pietra e '
          'legno come si faceva una volta e ci occupiamo noi delle pratiche con '
          'la Soprintendenza.',
      image: _u('1590725140246-20acdee442be'),
      points: ['Consolidamenti', 'Volte e murature', 'Beni vincolati'],
      categories: ['Restauro'],
    ),
    ServiceItem(
      id: 's-industriale',
      title: 'Commerciale e industriale',
      text:
          'Capannoni, uffici e negozi pensati per durare. Organizziamo il '
          'cantiere in modo che la tua attività possa andare avanti mentre '
          'lavoriamo.',
      image: _u('1590069261209-f8e9b8642343'),
      points: [
        'Carpenteria metallica',
        'Prefabbricati',
        'Pavimenti industriali',
      ],
      categories: ['Commerciale', 'Industriale'],
    ),
    ServiceItem(
      id: 's-energia',
      title: 'Efficienza energetica',
      text:
          'Cappotto, serramenti, fotovoltaico e pompe di calore. Partiamo da una '
          'diagnosi della casa e ti diciamo con onestà quali interventi conviene '
          'fare e quali no.',
      image: _u('1479839672679-a46483c0e7c8'),
      points: ['Cappotto termico', 'Fotovoltaico', 'Diagnosi energetica'],
      categories: ['Residenziale', 'Ristrutturazione'],
    ),
    ServiceItem(
      id: 's-progettazione',
      title: 'Progettazione',
      text:
          'Il nostro ufficio tecnico disegna il progetto, segue i permessi e la '
          'sicurezza e dirige i lavori fino al collaudo, parlando con te e con '
          'chi è in cantiere.',
      image: _u('1503387762-592deb58ef4e'),
      points: ['Pratiche edilizie', 'Computi metrici', 'Direzione lavori'],
      categories: ['Commerciale'],
    ),
  ];

  static List<Testimonial> testimonials() => [
    Testimonial(
      name: 'Francesca e Luca',
      role: 'Villa Le Querce',
      text:
          'Ci hanno consegnato la casa nel giorno esatto scritto nel contratto. '
          'Ogni venerdì ricevevamo le foto del cantiere: non ci siamo mai sentiti soli.',
    ),
    Testimonial(
      name: 'Giorgio Lattanzi',
      role: 'Levante Tech S.p.A.',
      text:
          'Lavorare accanto a un cantiere senza fermare l\'azienda sembrava '
          'impossibile. M.I.R.O. ci è riuscita, con ordine e pulizia ammirevoli.',
    ),
    Testimonial(
      name: 'Famiglia De Nicola',
      role: 'Masseria San Vito',
      text:
          'Hanno trattato le pietre della nostra masseria con il rispetto che '
          'meritavano. Il risultato è andato oltre ogni aspettativa.',
    ),
  ];
}
