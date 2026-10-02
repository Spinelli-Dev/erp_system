/*
==============================================================================================================================
        CLIENTE DA API (painel Razor) — chamadas à API e helpers de formatação
        O painel é servido pelo mesmo servidor da API: as chamadas vão para /api no mesmo endereço e são
        autenticadas pelo cookie de sessão criado no login (Pages/Login). Nenhuma senha fica no navegador.
==============================================================================================================================
*/
const API_BASE_URL = '/api';

/**
 * Chama a API MaxiMassas e desembrulha o ApiResponse<T>. O cookie de sessão vai junto sozinho
 * (mesma origem). Em caso de 401 — sessão expirada — volta para o login.
 */
async function apiFetch(endpoint, options = {}) {
    const { redirectOn401 = true, ...fetchOptions } = options;
    const headers = { 'Content-Type': 'application/json', ...(fetchOptions.headers || {}) };

    let resposta;
    try {
        resposta = await fetch(`${API_BASE_URL}${endpoint}`, { ...fetchOptions, headers });
    } catch (erroRede) {
        throw new Error('Não foi possível conectar à API. Verifique se o servidor está em execução.');
    }

    if (resposta.status === 401) {
        if (redirectOn401) window.location.href = '/Login?ReturnUrl=' + encodeURIComponent(location.pathname);
        const erro401 = new Error('Sessão expirada ou credenciais inválidas.');
        erro401.status = 401;
        throw erro401;
    }

    const texto = await resposta.text();
    let corpo = null;
    if (texto) {
        try { corpo = JSON.parse(texto); } catch (erroParse) { corpo = null; }
    }

    if (!resposta.ok || (corpo && corpo.success === false)) {
        const mensagem = (corpo && corpo.errors && corpo.errors.length)
            ? corpo.errors.join(', ')
            : (corpo && corpo.message) || `Erro ${resposta.status} ao acessar a API.`;
        throw new Error(mensagem);
    }

    return corpo ? corpo.data : null;
}

// #region - HELPERS DE FORMATAÇÃO E ESCAPE (compartilhados entre as telas)
/** Texto para comparar em buscas: sem acentos e em minúsculas ("Flávio" → "flavio"), para "fla" achar "Flávio". */
function normalizarBusca(texto) {
    return (texto ?? '').toString().normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

function formatarMoeda(valor) {
    return (Number(valor) || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function formatarDataBr(dataIso) {
    if (!dataIso) return '—';
    return new Date(dataIso).toLocaleDateString('pt-BR');
}

function formatarHoraBr(dataIso) {
    if (!dataIso) return '—';
    return new Date(dataIso).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
}

// Escapa texto vindo da API antes de injetar via innerHTML, evitando XSS.
function escapeHtml(texto) {
    const div = document.createElement('div');
    div.textContent = texto ?? '';
    return div.innerHTML;
}

function intervaloDoDia(data = new Date()) {
    const inicio = new Date(data.getFullYear(), data.getMonth(), data.getDate(), 0, 0, 0);
    const fim = new Date(data.getFullYear(), data.getMonth(), data.getDate(), 23, 59, 59);
    return { inicio: inicio.toISOString(), fim: fim.toISOString() };
}

function intervaloDoMes(ano, mes) {
    const inicio = new Date(ano, mes - 1, 1, 0, 0, 0);
    const fim = new Date(ano, mes, 0, 23, 59, 59);
    return { inicio: inicio.toISOString(), fim: fim.toISOString() };
}
// #endregion
