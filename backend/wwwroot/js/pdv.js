/* =========================================================================================================
        TELA: NOVA VENDA / EDITAR VENDA (FRENTE DE CAIXA / PDV) — Pages/NovaVenda e Pages/AlterarVenda
        A tela continua interativa aqui (contadores, comanda ao vivo), mas quem grava é o servidor:
        "Salvar Venda" envia o formulário #formPDV com o estado da comanda em campos ocultos.
        Catálogo, regra da taxa de entrega e a comanda a restaurar chegam prontos em window.PDV_DADOS.
========================================================================================================= */

const DADOS_PDV = window.PDV_DADOS || {};
const MODO_EDICAO = DADOS_PDV.modo === 'edicao';

let bancoClientes = DADOS_PDV.clientes || [];
let bancoProdutosPDV = DADOS_PDV.produtos || [];
const regraEntregaPDV = DADOS_PDV.regraEntrega || { taxa: 0, minimoGratis: 0 };

// ESTADO GLOBAL DA VENDA (O carrinho de compras)
let estadoVenda = estadoVazioPDV();

function estadoVazioPDV() {
    return {
        cliente: null,
        itens: [], // [{ idProduto: 1, qtd: 2 }]
        tipoDesconto: 'RS', // 'RS' ou 'PCT'
        valorDesconto: 0,
        taxaEntrega: 0,
        tipoEntrega: '',
        plataforma: '',
        pagamento: '',
        status: '',
        obs: ''
    };
}

const formatarReaisPDV = valor => `R$ ${valor.toFixed(2).replace('.', ',')}`;


// #region 1. CONTROLE DE DATA E HORA DO PEDIDO
function iniciarRelogioPDV() {
    const elRelogio = document.getElementById('relogioPDV');
    const elInfoComanda = document.getElementById('infoComandaHeader');
    if (!elRelogio || !elInfoComanda) return;

    // Na edição, o pedido já tem número e data; na nova venda, o número sai ao salvar.
    if (MODO_EDICAO) {
        const quando = (DADOS_PDV.estado && DADOS_PDV.estado.dataVenda) || '';
        elRelogio.textContent = quando;
        elInfoComanda.textContent = `Pedido #${DADOS_PDV.vendaId} • ${quando}`;
        return;
    }

    function atualizarInstante() {
        const agora = new Date();
        const dataStr = agora.toLocaleDateString('pt-BR');
        const horaStr = agora.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

        elRelogio.textContent = `${dataStr} ${horaStr}`;
        elInfoComanda.textContent = `Pedido #novo • ${dataStr} ${horaStr}`;
    }

    atualizarInstante();
    setInterval(atualizarInstante, 60000); // Atualiza a cada minuto
}

// Máscaras Simples de Digitação
function aplicarMascarasPDV() {
    const inputData = document.querySelector('.mascara-data');
    const inputHora = document.querySelector('.mascara-hora');

    if (inputData) {
        inputData.addEventListener('input', function(e) {
            let v = e.target.value.replace(/\D/g, ''); // Remove não números
            if (v.length > 8) v = v.substring(0, 8);
            if (v.length >= 5) v = `${v.substring(0, 2)}/${v.substring(2, 4)}/${v.substring(4, 8)}`;
            else if (v.length >= 3) v = `${v.substring(0, 2)}/${v.substring(2, 4)}`;
            e.target.value = v;
        });
    }

    if (inputHora) {
        inputHora.addEventListener('input', function(e) {
            let v = e.target.value.replace(/\D/g, '');
            if (v.length > 4) v = v.substring(0, 4);
            if (v.length >= 3) v = `${v.substring(0, 2)}:${v.substring(2, 4)}`;
            e.target.value = v;
        });
    }
}
// #endregion

// #region 2. BUSCA DE CLIENTES (AUTOCOMPLETE) E ENDEREÇO
function configurarBuscaClientePDV() {
    const buscaInput = document.getElementById('buscaClientePDV');
    const dropdown = document.getElementById('dropdownClientePDV');

    if (!buscaInput || !dropdown) return;

    buscaInput.addEventListener('input', function() {
        // Sem acentos: "fla" encontra "Flávio". Telefone compara só os dígitos.
        const termo = normalizarBusca(this.value);
        const digitos = termo.replace(/\D/g, '');
        dropdown.innerHTML = '';

        if (termo === '') {
            dropdown.classList.add('d-none');
            return;
        }

        const filtrados = bancoClientes.filter(c =>
            normalizarBusca(c.nome).includes(termo) ||
            (digitos.length > 0 && (c.tel || '').replace(/\D/g, '').includes(digitos))
        );

        if (filtrados.length > 0) {
            filtrados.forEach(cliente => {
                const li = document.createElement('li');
                li.className = 'autocomplete-item';
                li.innerHTML = `<span class="auto-nome">${escapeHtml(cliente.nome)}</span><span class="auto-detalhes">${escapeHtml(cliente.tel)}</span>`;

                li.addEventListener('click', () => {
                    selecionarClientePDV(cliente);
                    dropdown.classList.add('d-none');
                    buscaInput.value = ''; // Limpa o input
                    buscaInput.parentElement.classList.add('d-none'); // Esconde a barra de busca
                });

                dropdown.appendChild(li);
            });
            dropdown.classList.remove('d-none');
        } else {
            dropdown.classList.add('d-none');
        }
    });

    // Fechar ao clicar fora
    document.addEventListener('click', (e) => {
        if (!buscaInput.contains(e.target) && !dropdown.contains(e.target)) dropdown.classList.add('d-none');
    });
}

function preencherEnderecoPDV(end) {
    document.getElementById('endRuaPDV').value = end.rua || '';
    document.getElementById('endNumPDV').value = end.num || '';
    document.getElementById('endBairroPDV').value = end.bairro || '';
    document.getElementById('endCidPDV').value = end.cid || '';
    document.getElementById('endUFPDV').value = end.uf || '';
    document.getElementById('endCompPDV').value = end.comp || '';
}

function mostrarClientePDV(cliente) {
    document.getElementById('nomeClientePDV').textContent = cliente.nome;
    document.getElementById('telClientePDV').textContent = cliente.tel;
    document.getElementById('boxClienteSelecionado').classList.remove('d-none');
    document.getElementById('buscaClientePDV').parentElement.classList.add('d-none');
}

function selecionarClientePDV(cliente) {
    estadoVenda.cliente = cliente;
    mostrarClientePDV(cliente);
    // Endereço do cadastro já preenchido; dá para trocar se a entrega for em outro lugar.
    preencherEnderecoPDV(cliente);
    renderizarSugestoesPDV();
    atualizarComandaPDV();
}

function removerClientePDV() {
    estadoVenda.cliente = null;
    renderizarSugestoesPDV();

    // Esconde o box e mostra a busca de novo
    document.getElementById('boxClienteSelecionado').classList.add('d-none');
    document.getElementById('buscaClientePDV').parentElement.classList.remove('d-none');

    // Limpa endereço
    document.querySelectorAll('.pdv-input-end').forEach(input => input.value = '');

    atualizarComandaPDV();
}
// #endregion

// #region 3. BOTÕES SELECIONÁVEIS (TOGGLES) E LÓGICA DE DELIVERY
function acenderBotaoPDV(seletor, valorAtivo) {
    document.querySelectorAll(seletor).forEach(btn => btn.classList.toggle('active', btn.dataset.value === valorAtivo));
}

function configurarBotoesTogglePDV() {
    // 1. Tipo de Entrega
    const btnEntregas = document.querySelectorAll('.btn-tipo-entrega');
    const blocoEndereco = document.getElementById('blocoEnderecoPDV');

    btnEntregas.forEach(btn => {
        btn.addEventListener('click', () => {
            btnEntregas.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            estadoVenda.tipoEntrega = btn.dataset.value;
            blocoEndereco.classList.toggle('d-none', estadoVenda.tipoEntrega !== 'Delivery');
            atualizarComandaPDV();
        });
    });

    // 2. Plataforma, Pagamento, Status (Lógica genérica de grupo)
    const grupos = [
        { seletor: '.btn-plataforma', campoEstado: 'plataforma' },
        { seletor: '.btn-pagamento', campoEstado: 'pagamento' },
        { seletor: '.btn-status', campoEstado: 'status' }
    ];

    grupos.forEach(grupo => {
        const botoes = document.querySelectorAll(grupo.seletor);
        botoes.forEach(btn => {
            btn.addEventListener('click', () => {
                botoes.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                estadoVenda[grupo.campoEstado] = btn.dataset.value;
                atualizarComandaPDV();
            });
        });
    });

    // 3. Switch de Desconto
    const btnRs = document.getElementById('btnDescRs');
    const btnPct = document.getElementById('btnDescPct');
    const inputDesc = document.getElementById('inputValorDesconto');

    if (btnRs && btnPct && inputDesc) {
        btnRs.addEventListener('click', () => definirTipoDescontoPDV('RS'));
        btnPct.addEventListener('click', () => definirTipoDescontoPDV('PCT'));

        inputDesc.addEventListener('input', (e) => {
            const val = parseFloat(e.target.value);
            estadoVenda.valorDesconto = isNaN(val) || val < 0 ? 0 : val;
            atualizarComandaPDV();
        });
    }

    // Ouvinte para as Observações
    const obsInput = document.getElementById('obsPDV');
    if (obsInput) {
        obsInput.addEventListener('input', (e) => {
            estadoVenda.obs = e.target.value;
            atualizarComandaPDV();
        });
    }

    // O endereço de entrega pode ser editado: a comanda acompanha.
    document.querySelectorAll('.pdv-input-end').forEach(input => input.addEventListener('input', atualizarComandaPDV));
}

function definirTipoDescontoPDV(tipo) {
    estadoVenda.tipoDesconto = tipo;
    document.getElementById('btnDescRs').classList.toggle('active', tipo === 'RS');
    document.getElementById('btnDescPct').classList.toggle('active', tipo === 'PCT');
    document.getElementById('comandaTipoDesc').textContent = tipo === 'PCT' ? '%' : 'R$';
    atualizarComandaPDV();
}

/** Taxa definida pelos gestores (Entregas → Pedido mínimo e taxa). Na edição, vale a que foi cobrada. */
function taxaEntregaPDV(subtotal) {
    if (estadoVenda.tipoEntrega !== 'Delivery') return 0;
    if (MODO_EDICAO) return estadoVenda.taxaEntrega || 0;
    const gratis = regraEntregaPDV.minimoGratis > 0 && subtotal >= regraEntregaPDV.minimoGratis;
    return gratis ? 0 : regraEntregaPDV.taxa;
}
// #endregion

// #region 4. LISTA DE PRODUTOS AGRUPADOS (ESTILO REPOSIÇÃO COMPACTO)
function carregarListaProdutosPDV() {
    const container = document.getElementById('containerProdutosPDV');
    if (!container) return;

    container.innerHTML = ''; // Limpa

    if (bancoProdutosPDV.length === 0) {
        container.innerHTML = '<p class="text-center py-3 mb-0" style="font-size: 12px; color:#9CA3AC;">Nenhum produto cadastrado</p>';
        return;
    }

    // Descobre as categorias únicas (nomes principais)
    const nomesUnicos = [...new Set(bancoProdutosPDV.map(p => p.nome))];

    nomesUnicos.forEach(nomeFantasia => {
        // 1. Cria a estrutura do Card de Reposição para a Categoria
        const cardHtml = document.createElement('div');
        cardHtml.className = 'card-reposicao mx-3 mb-3';
        cardHtml.innerHTML = `<div class="card-reposicao-header border-bottom">${escapeHtml(nomeFantasia)}</div>`;

        const bodyHtml = document.createElement('div');
        bodyHtml.className = 'card-reposicao-body p-2';

        // 2. Filtra os produtos
        bancoProdutosPDV.filter(p => p.nome === nomeFantasia).forEach(produto => {
            const tituloSabor = produto.sabor === 'Tradicional' || produto.sabor === '' ? 'Tradicional' : produto.sabor;
            const semEstoque = produto.estoque <= 0 && !MODO_EDICAO;

            bodyHtml.innerHTML += `
                <div class="linha-produto-reposicao px-2 py-1">
                    <span class="sabor-peso-text" style="color: #4B5563; font-weight: 500;">
                        ${escapeHtml(tituloSabor)} • ${escapeHtml(produto.peso)}
                        <small class="d-block" style="color: ${semEstoque ? '#B91C1C' : '#9CA3AC'}; font-weight: 400;">
                            ${semEstoque ? 'Sem estoque' : `${produto.estoque} em estoque`}
                        </small>
                    </span>
                    <div class="contador-wrapper">
                        <button type="button" class="btn-contador" id="menos-prod-${produto.id}" onclick="alterarQtdProduto(${produto.id}, -1)">-</button>
                        <span class="qtd-contador" data-qtd-produto="${produto.id}">0</span>
                        <button type="button" class="btn-contador" data-mais-produto="${produto.id}" onclick="alterarQtdProduto(${produto.id}, 1)"
                                title="${semEstoque ? 'Sem estoque' : ''}">+</button>
                    </div>
                </div>
            `;
        });

        cardHtml.appendChild(bodyHtml);
        container.appendChild(cardHtml);
    });

    atualizarBotoesEstoquePDV();
}

/**
 * Card "Pedido Sugerido": os produtos que o cliente selecionado mais compra (calculado no servidor a partir
 * do histórico dele). Os contadores são os mesmos da lista de produtos — mexer em um atualiza o outro.
 */
function renderizarSugestoesPDV() {
    const lista = document.getElementById('listaSugestaoPDV');
    if (!lista) return;

    const aviso = texto => { lista.innerHTML = `<span class="pdv-subtitulo">${texto}</span>`; };
    if (!estadoVenda.cliente) return aviso('Selecione um cliente para ver as sugestões.');

    const sugestoes = ((DADOS_PDV.sugestoes || {})[estadoVenda.cliente.id] || [])
        .map(s => ({ ...s, produto: bancoProdutosPDV.find(p => p.id === s.produtoId) }))
        .filter(s => s.produto);
    if (sugestoes.length === 0) return aviso('Este cliente ainda não tem pedidos para sugerir.');

    lista.innerHTML = sugestoes.map(({ produto, porPedido }) => {
        const item = estadoVenda.itens.find(i => i.idProduto === produto.id);
        const sabor = produto.sabor && produto.sabor !== 'Tradicional' ? `${produto.sabor} • ` : '';
        const semEstoque = produto.estoque <= 0 && !MODO_EDICAO;
        return `
            <div class="sugestao-box">
                <div class="sugestao-info">
                    <span class="sugestao-nome">${escapeHtml(produto.nome)}</span>
                    <span class="sugestao-detalhe">${escapeHtml(sabor)}${escapeHtml(produto.peso)} • costuma levar ${porPedido}${semEstoque ? ' • sem estoque' : ''}</span>
                </div>
                <div class="contador-wrapper">
                    <button type="button" class="btn-contador" onclick="alterarQtdProduto(${produto.id}, -1)">-</button>
                    <span class="qtd-contador" data-qtd-produto="${produto.id}">${item ? item.qtd : 0}</span>
                    <button type="button" class="btn-contador" data-mais-produto="${produto.id}" onclick="alterarQtdProduto(${produto.id}, 1)">+</button>
                </div>
            </div>`;
    }).join('');

    atualizarBotoesEstoquePDV();
    if (MODO_EDICAO) lista.querySelectorAll('.btn-contador').forEach(b => { b.disabled = true; b.style.opacity = '0.6'; });
}

/** Mesmo produto aparece na lista e nas sugestões: atualiza todos os visores dele. */
function mostrarQuantidadePDV(idProduto, qtd) {
    document.querySelectorAll(`[data-qtd-produto="${idProduto}"]`).forEach(span => { span.textContent = qtd; });
}

/** "+" trava no estoque de cada produto (mesma regra do app); o servidor confere de novo ao salvar. */
function atualizarBotoesEstoquePDV() {
    if (MODO_EDICAO) return;
    bancoProdutosPDV.forEach(produto => {
        const item = estadoVenda.itens.find(i => i.idProduto === produto.id);
        const noLimite = (item ? item.qtd : 0) >= produto.estoque;
        // "+" da lista de produtos e, se o produto estiver sugerido, o do card de sugestões
        document.querySelectorAll(`[data-mais-produto="${produto.id}"]`).forEach(btnMais => {
            btnMais.disabled = noLimite;
            btnMais.title = noLimite ? 'Limite máximo em estoque atingido' : '';
        });
    });
}

function alterarQtdProduto(idProduto, mudanca) {
    if (MODO_EDICAO) return;
    const produto = bancoProdutosPDV.find(p => p.id === idProduto);
    let itemExistente = estadoVenda.itens.find(i => i.idProduto === idProduto);
    let qtdAtual = itemExistente ? itemExistente.qtd : 0;

    let novaQtd = qtdAtual + mudanca;
    if (novaQtd < 0) novaQtd = 0;
    if (produto && novaQtd > produto.estoque) novaQtd = produto.estoque;

    // Atualiza o estado
    if (novaQtd === 0) {
        estadoVenda.itens = estadoVenda.itens.filter(i => i.idProduto !== idProduto);
    } else if (itemExistente) {
        itemExistente.qtd = novaQtd;
    } else {
        estadoVenda.itens.push({ idProduto: idProduto, qtd: novaQtd });
    }

    // Atualiza o número no visor do produto na lista central
    mostrarQuantidadePDV(idProduto, novaQtd);

    atualizarBotoesEstoquePDV();
    atualizarComandaPDV();
}
// #endregion

// #region 5. MATEMÁTICA E RENDERIZAÇÃO DA COMANDA FINAL
function atualizarComandaPDV() {
    // Textos informativos
    document.getElementById('comandaNome').textContent = estadoVenda.cliente ? estadoVenda.cliente.nome : '---';
    document.getElementById('comandaTel').textContent = estadoVenda.cliente ? estadoVenda.cliente.tel : '---';

    let endStr = '---';
    if (estadoVenda.tipoEntrega === 'Delivery') {
        const rua = document.getElementById('endRuaPDV').value.trim();
        const num = document.getElementById('endNumPDV').value.trim();
        const bairro = document.getElementById('endBairroPDV').value.trim();
        if (rua) endStr = `${rua}, ${num || 's/n'}${bairro ? ` - ${bairro}` : ''}`;
    }
    document.getElementById('comandaEnd').textContent = endStr;

    document.getElementById('comandaEnt').textContent = estadoVenda.tipoEntrega || '---';
    document.getElementById('comandaPlat').textContent = estadoVenda.plataforma || '---';
    document.getElementById('comandaPag').textContent = estadoVenda.pagamento || '---';
    document.getElementById('comandaObs').textContent = estadoVenda.obs || '---';

    // Itens Comprados
    const listaItensHtml = document.getElementById('listaItensComanda');
    listaItensHtml.innerHTML = '';

    let subtotal = 0;

    if (estadoVenda.itens.length === 0) {
        listaItensHtml.innerHTML = '<div class="text-center" style="font-size: 11px; color:#9CA3AC;">Nenhum produto selecionado</div>';
    } else {
        estadoVenda.itens.forEach(itemVenda => {
            const p = bancoProdutosPDV.find(prod => prod.id === itemVenda.idProduto);
            if (p) {
                const totalItem = p.preco * itemVenda.qtd;
                subtotal += totalItem;

                const titulo = p.sabor !== 'Tradicional' ? `${p.nome} ${p.sabor}` : p.nome;

                listaItensHtml.innerHTML += `
                    <div class="comanda-item-row">
                        <span>${itemVenda.qtd}x ${escapeHtml(titulo)} ${escapeHtml(p.peso)}</span>
                        <span>${formatarReaisPDV(totalItem)}</span>
                    </div>
                `;
            }
        });
    }

    // Cálculos (o servidor refaz a mesma conta ao salvar)
    let valorDesc = 0;
    if (estadoVenda.valorDesconto > 0) {
        valorDesc = estadoVenda.tipoDesconto === 'RS'
            ? estadoVenda.valorDesconto
            : subtotal * (estadoVenda.valorDesconto / 100);
    }

    // Não permite desconto maior que o subtotal
    if (valorDesc > subtotal) valorDesc = subtotal;

    const taxa = taxaEntregaPDV(subtotal);
    const totalCalculado = (subtotal - valorDesc) + taxa;

    // Atualiza valores na tela
    document.getElementById('comandaSub').textContent = formatarReaisPDV(subtotal);
    document.getElementById('comandaDesc').textContent = `- ${formatarReaisPDV(valorDesc)}`;
    document.getElementById('comandaTaxa').textContent = formatarReaisPDV(taxa);
    document.getElementById('comandaTotal').textContent = formatarReaisPDV(totalCalculado);
}

// Botão Limpar Comanda
function limparPDV() {
    if (MODO_EDICAO) return;
    estadoVenda = estadoVazioPDV();

    // Remove botões ativos
    document.querySelectorAll('.btn-toggle-pdv').forEach(b => b.classList.remove('active'));

    // Esconde endereco
    document.getElementById('blocoEnderecoPDV').classList.add('d-none');

    // Reseta os campos visíveis (os ocultos do formulário, inclusive o token de segurança, ficam)
    document.querySelectorAll('main input:not([type="hidden"])').forEach(i => i.value = '');

    definirTipoDescontoPDV('RS');

    // Volta layout do cliente
    removerClientePDV();

    // Zera contadores da coluna do meio
    document.querySelectorAll('.qtd-contador').forEach(span => span.textContent = '0');

    const erro = document.getElementById('erroPDV');
    if (erro) erro.classList.add('d-none');

    atualizarBotoesEstoquePDV();
    atualizarComandaPDV();
}
// #endregion

// #region 6. RESTAURAR A COMANDA (EDIÇÃO, OU FORMULÁRIO DEVOLVIDO COM ERRO)
function restaurarEstadoPDV(salvo) {
    if (!salvo) return;

    estadoVenda = {
        ...estadoVazioPDV(),
        cliente: salvo.cliente || null,
        itens: (salvo.itens || []).map(i => ({ idProduto: i.idProduto, qtd: i.qtd })),
        tipoDesconto: salvo.tipoDesconto === 'PCT' ? 'PCT' : 'RS',
        valorDesconto: Number(salvo.valorDesconto) || 0,
        taxaEntrega: Number(salvo.taxaEntrega) || 0,
        tipoEntrega: salvo.tipoEntrega || '',
        plataforma: salvo.plataforma || '',
        pagamento: salvo.pagamento || '',
        status: salvo.status || '',
        obs: salvo.obs || ''
    };

    // 1. Cliente e endereço (o endereço da entrega pode diferir do cadastro)
    if (estadoVenda.cliente) {
        mostrarClientePDV(estadoVenda.cliente);
        preencherEnderecoPDV(salvo.endereco || estadoVenda.cliente);
    }

    // 2. Acende os botões corretos (Delivery, PIX, Status, etc)
    acenderBotaoPDV('.btn-tipo-entrega', estadoVenda.tipoEntrega);
    document.getElementById('blocoEnderecoPDV').classList.toggle('d-none', estadoVenda.tipoEntrega !== 'Delivery');
    acenderBotaoPDV('.btn-plataforma', estadoVenda.plataforma);
    acenderBotaoPDV('.btn-pagamento', estadoVenda.pagamento);
    acenderBotaoPDV('.btn-status', estadoVenda.status);

    // 3. Campos de texto
    document.getElementById('obsPDV').value = estadoVenda.obs;
    document.getElementById('dataAgendadaPDV').value = salvo.dataAgendada || '';
    document.getElementById('horaAgendadaPDV').value = salvo.horaAgendada || '';
    document.getElementById('inputValorDesconto').value = estadoVenda.valorDesconto || '';
    definirTipoDescontoPDV(estadoVenda.tipoDesconto);

    // 4. Contadores na coluna do meio (Produtos)
    estadoVenda.itens.forEach(item => mostrarQuantidadePDV(item.idProduto, item.qtd));
    renderizarSugestoesPDV();

    atualizarBotoesEstoquePDV();
    atualizarComandaPDV();
}

/** Na edição, só status, pagamento, plataforma e observação mudam: o resto fica travado. */
function travarCamposEdicaoPDV() {
    if (!MODO_EDICAO) return;
    document.getElementById('avisoEdicaoPDV').classList.remove('d-none');
    document.querySelector('.btn-remover-cliente').classList.add('d-none');
    document.getElementById('btnLimparPDV').disabled = true;

    const travar = el => { el.disabled = true; el.style.opacity = '0.6'; el.style.cursor = 'not-allowed'; };
    document.querySelectorAll('#containerProdutosPDV .btn-contador, .btn-tipo-entrega, #btnDescRs, #btnDescPct')
        .forEach(travar);
    document.querySelectorAll('#inputValorDesconto, #dataAgendadaPDV, #horaAgendadaPDV, .pdv-input-end')
        .forEach(el => { el.readOnly = true; el.style.opacity = '0.7'; });
}
// #endregion

// #region 7. SALVAR (ENVIO AO SERVIDOR)
function configurarEnvioPDV() {
    const form = document.getElementById('formPDV');
    if (!form) return;

    form.addEventListener('submit', () => {
        const valor = id => document.getElementById(id).value.trim();
        const definir = (id, v) => { document.getElementById(id).value = v ?? ''; };

        definir('hidClienteId', estadoVenda.cliente ? estadoVenda.cliente.id : '');
        definir('hidItensJson', JSON.stringify(estadoVenda.itens.map(i => ({ produtoId: i.idProduto, quantidade: i.qtd }))));
        definir('hidTipoEntrega', estadoVenda.tipoEntrega);
        definir('hidDataAgendada', valor('dataAgendadaPDV'));
        definir('hidHoraAgendada', valor('horaAgendadaPDV'));
        definir('hidRua', valor('endRuaPDV'));
        definir('hidNumero', valor('endNumPDV'));
        definir('hidBairro', valor('endBairroPDV'));
        definir('hidCidade', valor('endCidPDV'));
        definir('hidUf', valor('endUFPDV').toUpperCase());
        definir('hidComplemento', valor('endCompPDV'));
        definir('hidPlataforma', estadoVenda.plataforma);
        definir('hidPagamento', estadoVenda.pagamento);
        definir('hidStatus', estadoVenda.status);
        definir('hidTipoDesconto', estadoVenda.tipoDesconto);
        definir('hidDesconto', String(estadoVenda.valorDesconto || 0)); // ponto decimal (lido assim no servidor)
        definir('hidObservacao', estadoVenda.obs);

        // Evita registrar a mesma venda duas vezes num clique duplo.
        const botao = document.getElementById('btnSalvarPDV');
        botao.disabled = true;
        botao.textContent = 'Salvando...';
    });
}
// #endregion


// INICIALIZAÇÃO
document.addEventListener('DOMContentLoaded', () => {
    // Se a tela tiver o id exclusivo do Relógio, roda as funções do PDV
    if (!document.getElementById('relogioPDV')) return;

    iniciarRelogioPDV();
    aplicarMascarasPDV();
    configurarBuscaClientePDV();
    configurarBotoesTogglePDV();
    carregarListaProdutosPDV();
    configurarEnvioPDV();

    restaurarEstadoPDV(DADOS_PDV.estado);
    travarCamposEdicaoPDV();

    atualizarComandaPDV(); // Render inicial
});
