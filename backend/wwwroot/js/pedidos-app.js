/**
 * Aviso de pedido novo do app (todas as páginas do painel, via _Layout).
 *
 * A cada INTERVALO consulta /PedidosApp, que devolve os pedidos do app ainda "Pendentes".
 * - Contador vermelho no menu "Vendas" (desktop e mobile) e "(n)" no título da aba.
 * - Pedido com id novo: toca um som e mostra um aviso no canto, com link para o pedido.
 * O pedido some do contador quando alguém muda o status dele (Agendado, Pago, Concluído, Cancelado).
 *
 * O último id avisado fica no localStorage: trocar de página não repete o aviso.
 */
(function () {
    const INTERVALO = 20000;
    const CHAVE_VISTO = 'maximassas.pedidosApp.ultimoId';
    const CHAVE_SOM = 'maximassas.pedidosApp.som';
    const tituloOriginal = document.title;

    // O navegador pode deixar o som "suspenso" até a pessoa clicar em algo na página; qualquer clique libera.
    const audio = window.AudioContext ? new AudioContext() : null;
    let primeira = true;

    const ler = (chave) => { try { return localStorage.getItem(chave); } catch { return null; } };
    const gravar = (chave, valor) => { try { localStorage.setItem(chave, valor); } catch { /* modo privado */ } };
    const somLigado = () => ler(CHAVE_SOM) !== 'off';

    document.addEventListener('click', () => {
        if (audio && audio.state === 'suspended') audio.resume();
    }, { passive: true });

    /** Dois toques curtos ("plim-plim"), gerados na hora — sem arquivo de áudio. */
    function tocar() {
        if (!audio || !somLigado()) return;
        if (audio.state === 'suspended') audio.resume();
        [0, 0.22].forEach((atraso, i) => {
            const osc = audio.createOscillator();
            const ganho = audio.createGain();
            const t = audio.currentTime + atraso;
            osc.type = 'sine';
            osc.frequency.value = i === 0 ? 880 : 1320;
            ganho.gain.setValueAtTime(0.0001, t);
            ganho.gain.exponentialRampToValueAtTime(0.35, t + 0.02);
            ganho.gain.exponentialRampToValueAtTime(0.0001, t + 0.35);
            osc.connect(ganho).connect(audio.destination);
            osc.start(t);
            osc.stop(t + 0.4);
        });
    }

    function atualizarContador(total) {
        document.querySelectorAll('a[href="/Vendas"]').forEach((link) => {
            let badge = link.querySelector('.badge-pedidos-app');
            if (!badge) {
                badge = document.createElement('span');
                badge.className = 'badge-pedidos-app';
                link.appendChild(badge);
            }
            badge.textContent = total > 9 ? '9+' : String(total);
            badge.title = `${total} pedido(s) do app aguardando`;
            badge.hidden = total === 0;
        });
        document.title = total > 0 ? `(${total}) ${tituloOriginal}` : tituloOriginal;
    }

    function container() {
        let c = document.getElementById('avisos-pedidos-app');
        if (!c) {
            c = document.createElement('div');
            c.id = 'avisos-pedidos-app';
            c.setAttribute('aria-live', 'polite');
            document.body.appendChild(c);
        }
        return c;
    }

    const esc = (s) => String(s).replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));

    function mostrarAviso(novos) {
        const aviso = document.createElement('div');
        aviso.className = 'aviso-pedido-app';
        aviso.setAttribute('role', 'alert');
        const titulo = novos.length === 1 ? 'Novo pedido pelo app!' : `${novos.length} novos pedidos pelo app!`;
        aviso.innerHTML = `
            <div class="d-flex justify-content-between align-items-start mb-1">
                <strong>${titulo}</strong>
                <button type="button" class="btn-close btn-sm" aria-label="Fechar"></button>
            </div>
            ${novos.slice(0, 3).map((p) => `
                <a class="aviso-pedido-app-item" href="${esc(p.url)}">
                    <span>#${p.id} • ${esc(p.cliente)}</span>
                    <span>${esc(p.tipo)} • ${esc(p.valor)} • ${esc(p.hora)}</span>
                </a>`).join('')}
            <div class="d-flex justify-content-between align-items-center mt-2">
                <a href="/Vendas" class="aviso-pedido-app-link">Ver vendas</a>
                <button type="button" class="aviso-pedido-app-som">${somLigado() ? 'Silenciar som' : 'Ativar som'}</button>
            </div>`;
        aviso.querySelector('.btn-close').addEventListener('click', () => aviso.remove());
        aviso.querySelector('.aviso-pedido-app-som').addEventListener('click', (e) => {
            gravar(CHAVE_SOM, somLigado() ? 'off' : 'on');
            e.target.textContent = somLigado() ? 'Silenciar som' : 'Ativar som';
        });
        container().prepend(aviso);
    }

    async function consultar() {
        let dados;
        try {
            const resp = await fetch('/PedidosApp', { headers: { Accept: 'application/json' }, cache: 'no-store' });
            // Sessão expirada: o servidor manda para o login (HTML) — para de consultar.
            if (!resp.ok || !(resp.headers.get('content-type') || '').includes('json')) return false;
            dados = await resp.json();
        } catch {
            return true; // sem conexão: tenta de novo no próximo ciclo
        }

        atualizarContador(dados.total);

        const ultimoVisto = Number(ler(CHAVE_VISTO) || 0);
        const maiorId = dados.pedidos.reduce((m, p) => Math.max(m, p.id), 0);
        // Na primeira consulta deste navegador só marca o que já existe (o contador já mostra).
        if (ultimoVisto === 0 && primeira) {
            gravar(CHAVE_VISTO, String(maiorId));
        } else {
            const novos = dados.pedidos.filter((p) => p.id > ultimoVisto);
            if (novos.length > 0) {
                gravar(CHAVE_VISTO, String(maiorId));
                mostrarAviso(novos);
                tocar();
            }
        }
        primeira = false;
        return true;
    }

    async function ciclo() {
        if (await consultar()) setTimeout(ciclo, INTERVALO);
    }

    ciclo();
})();
