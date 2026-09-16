/* =========================================================================================================
        TELA: NOVA VENDA (FRENTE DE CAIXA / PDV)
========================================================================================================= */

// BANCO DE DADOS SIMULADO
const bancoClientes = [
    { id: 1, nome: 'Maria Fernanda Costa', tel: '(16) 9 9876-5432', rua: 'Rua das Flores', num: '142', bairro: 'Jardim Europa', cid: 'Itápolis', uf: 'SP', comp: '' },
    { id: 2, nome: 'João Paulo Souza', tel: '(16) 9 8765-4321', rua: 'Av. Brasil', num: '890', bairro: 'Centro', cid: 'Itápolis', uf: 'SP', comp: 'Apto. 24' },
    { id: 3, nome: 'Ana Claudia Ribeiro', tel: '(16) 9 7654-3210', rua: 'Rua Marechal', num: '55', bairro: 'Vila Nova', cid: 'Itápolis', uf: 'SP', comp: '' }
];

const bancoProdutosPDV = [
    { id: 1, nome: 'Canelone', sabor: '4 Queijos', peso: '700g', preco: 39.90 },
    { id: 2, nome: 'Canelone', sabor: 'Brócolis e Mussarela', peso: '700g', preco: 39.90 },
    { id: 3, nome: 'Canelone', sabor: 'Frango e Requeijão', peso: '700g', preco: 39.90 },
    { id: 4, nome: 'Massa de Lasanha', sabor: 'Tradicional', peso: '500g', preco: 12.00 },
    { id: 5, nome: 'Sofioli', sabor: '4 Queijos', peso: '700g', preco: 39.90 },
    { id: 6, nome: 'Sofioli', sabor: 'Brócolis e Mussarela', peso: '700g', preco: 39.90 },
    { id: 7, nome: 'Sofioli', sabor: 'Frango e Requeijão', peso: '700g', preco: 39.90 },
    { id: 8, nome: 'Sofioli', sabor: 'Presunto e Mussarela', peso: '700g', preco: 39.90 },
    { id: 9, nome: 'Molho', sabor: 'Tomate Tradicional', peso: '300g', preco: 2.50 },
    { id: 10, nome: 'Molho', sabor: 'Branco', peso: '240g', preco: 5.90 },
    { id: 11, nome: 'Molho', sabor: 'Especial Sacciali Arrabiata', peso: '530g', preco: 16.90 },
    { id: 12, nome: 'Queijo Ralado', sabor: 'Tradicional', peso: '40g', preco: 5.50 }
];

// ESTADO GLOBAL DA VENDA (O carrinho de compras)
let estadoVenda = {
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


// #region 1. CONTROLE DE DATA E HORA DO PEDIDO
function iniciarRelogioPDV() {
    const elRelogio = document.getElementById('relogioPDV');
    const elInfoComanda = document.getElementById('infoComandaHeader');
    if (!elRelogio || !elInfoComanda) return;

    // Número fixo para protótipo
    const numeroPedido = "0042";

    function atualizarInstante() {
        const agora = new Date();
        const dataStr = agora.toLocaleDateString('pt-BR');
        const horaStr = agora.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        
        elRelogio.textContent = `${dataStr} ${horaStr}`;
        elInfoComanda.textContent = `Pedido #${numeroPedido} • ${dataStr} ${horaStr}`;
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
    const boxSelecionado = document.getElementById('boxClienteSelecionado');
    const blocoEndereco = document.getElementById('blocoEnderecoPDV');
    
    if (!buscaInput || !dropdown) return;

    buscaInput.addEventListener('input', function() {
        const termo = this.value.toLowerCase().trim();
        dropdown.innerHTML = '';
        
        if (termo === '') {
            dropdown.classList.add('d-none');
            return;
        }

        const filtrados = bancoClientes.filter(c => 
            c.nome.toLowerCase().includes(termo) || c.tel.includes(termo)
        );

        if (filtrados.length > 0) {
            filtrados.forEach(cliente => {
                const li = document.createElement('li');
                li.className = 'autocomplete-item';
                li.innerHTML = `<span class="auto-nome">${cliente.nome}</span><span class="auto-detalhes">${cliente.tel}</span>`;
                
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

function selecionarClientePDV(cliente) {
    estadoVenda.cliente = cliente;
    
    // Mostra o box
    document.getElementById('nomeClientePDV').textContent = cliente.nome;
    document.getElementById('telClientePDV').textContent = cliente.tel;
    document.getElementById('boxClienteSelecionado').classList.remove('d-none');

    // Preenche Endereço "Invisível"
    document.getElementById('endRuaPDV').value = cliente.rua;
    document.getElementById('endNumPDV').value = cliente.num;
    document.getElementById('endBairroPDV').value = cliente.bairro;
    document.getElementById('endCidPDV').value = cliente.cid;
    document.getElementById('endUFPDV').value = cliente.uf;
    document.getElementById('endCompPDV').value = cliente.comp;

    atualizarComandaPDV();
}

function removerClientePDV() {
    estadoVenda.cliente = null;
    
    // Esconde o box e mostra a busca de novo
    document.getElementById('boxClienteSelecionado').classList.add('d-none');
    document.getElementById('buscaClientePDV').parentElement.classList.remove('d-none');
    
    // Limpa endereço
    document.querySelectorAll('.pdv-input-end').forEach(input => input.value = '');
    
    // Se o tipo de entrega era Delivery, vamos resetar a taxa
    if(estadoVenda.tipoEntrega === 'Delivery') aplicarTaxaEntrega(0);

    atualizarComandaPDV();
}
// #endregion

// #region 3. BOTÕES SELECIONÁVEIS (TOGGLES) E LÓGICA DE DELIVERY
function configurarBotoesTogglePDV() {
    // 1. Tipo de Entrega
    const btnEntregas = document.querySelectorAll('.btn-tipo-entrega');
    const blocoEndereco = document.getElementById('blocoEnderecoPDV');

    btnEntregas.forEach(btn => {
        btn.addEventListener('click', () => {
            // Remove o active de todos e bota só no clicado
            btnEntregas.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            estadoVenda.tipoEntrega = btn.dataset.value;

            if (estadoVenda.tipoEntrega === 'Delivery') {
                blocoEndereco.classList.remove('d-none');
                aplicarTaxaEntrega(5.00); // Exemplo de taxa fixa ao escolher Delivery
            } else {
                blocoEndereco.classList.add('d-none');
                aplicarTaxaEntrega(0);
            }
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

    if(btnRs && btnPct && inputDesc) {
        btnRs.addEventListener('click', () => {
            btnRs.classList.add('active');
            btnPct.classList.remove('active');
            estadoVenda.tipoDesconto = 'RS';
            document.getElementById('comandaTipoDesc').textContent = 'R$';
            atualizarComandaPDV();
        });

        btnPct.addEventListener('click', () => {
            btnPct.classList.add('active');
            btnRs.classList.remove('active');
            estadoVenda.tipoDesconto = 'PCT';
            document.getElementById('comandaTipoDesc').textContent = '%';
            atualizarComandaPDV();
        });

        inputDesc.addEventListener('input', (e) => {
            const val = parseFloat(e.target.value);
            estadoVenda.valorDesconto = isNaN(val) ? 0 : val;
            atualizarComandaPDV();
        });
    }

    // Ouvinte para as Observações
    const obsInput = document.getElementById('obsPDV');
    if(obsInput) {
        obsInput.addEventListener('input', (e) => {
            estadoVenda.obs = e.target.value;
            atualizarComandaPDV();
        });
    }
}

function aplicarTaxaEntrega(valor) {
    estadoVenda.taxaEntrega = valor;
}
// #endregion

// #region 4. LISTA DE PRODUTOS AGRUPADOS (ESTILO REPOSIÇÃO COMPACTO)
function carregarListaProdutosPDV() {
    const container = document.getElementById('containerProdutosPDV');
    if (!container) return;

    container.innerHTML = ''; // Limpa

    // Descobre as categorias únicas (nomes principais)
    const nomesUnicos = [...new Set(bancoProdutosPDV.map(p => p.nome))];

    nomesUnicos.forEach(nomeFantasia => {
        // 1. Cria a estrutura do Card de Reposição para a Categoria
        const cardHtml = document.createElement('div');
        cardHtml.className = 'card-reposicao mx-3 mb-3'; 
        
        // Cabeçalho com borda inferior mantida (Ex: "Canelone")
        cardHtml.innerHTML = `<div class="card-reposicao-header border-bottom">${nomeFantasia}</div>`;
        
        // Corpo que vai receber as linhas (padding reduzido para "espremer" os itens)
        const bodyHtml = document.createElement('div');
        bodyHtml.className = 'card-reposicao-body p-2'; 

        // 2. Filtra os produtos
        const produtosDaCategoria = bancoProdutosPDV.filter(p => p.nome === nomeFantasia);

        produtosDaCategoria.forEach(produto => {
            const tituloSabor = produto.sabor === 'Tradicional' || produto.sabor === '' ? 'Tradicional' : produto.sabor;
            
            // Removida a borda inferior (border-bottom) e ajustado o padding (py-1 e px-2) || adicione '• R$ ${produto.preco.toFixed(2).replace('.', ',')}' para mostrar os valores dentro dos campos de produtos.
            const linhaHtml = `
                <div class="linha-produto-reposicao px-2 py-1">
                    <span class="sabor-peso-text" style="color: #4B5563; font-weight: 500;">${tituloSabor} • ${produto.peso}</span> 
                    <div class="contador-wrapper">
                        <button class="btn-contador" onclick="alterarQtdProduto(${produto.id}, -1)">-</button>
                        <span class="qtd-contador" id="qtd-prod-${produto.id}">0</span>
                        <button class="btn-contador" onclick="alterarQtdProduto(${produto.id}, 1)">+</button>
                    </div>
                </div>
            `; 
            bodyHtml.innerHTML += linhaHtml;
        });

        cardHtml.appendChild(bodyHtml);
        container.appendChild(cardHtml);
    });
}
// #endregion

function alterarQtdProduto(idProduto, mudanca) {
    let itemExistente = estadoVenda.itens.find(i => i.idProduto === idProduto);
    let qtdAtual = itemExistente ? itemExistente.qtd : 0;
    
    let novaQtd = qtdAtual + mudanca;
    if (novaQtd < 0) novaQtd = 0;

    // Atualiza o estado
    if (novaQtd === 0) {
        estadoVenda.itens = estadoVenda.itens.filter(i => i.idProduto !== idProduto);
    } else {
        if (itemExistente) {
            itemExistente.qtd = novaQtd;
        } else {
            estadoVenda.itens.push({ idProduto: idProduto, qtd: novaQtd });
        }
    }

    // Atualiza o número no visor do produto na lista central
    document.getElementById(`qtd-prod-${idProduto}`).textContent = novaQtd;

    atualizarComandaPDV();
}
// #endregion

// #region 5. MATEMÁTICA E RENDERIZAÇÃO DA COMANDA FINAL
function atualizarComandaPDV() {
    // Textos informativos
    document.getElementById('comandaNome').textContent = estadoVenda.cliente ? estadoVenda.cliente.nome : '---';
    document.getElementById('comandaTel').textContent = estadoVenda.cliente ? estadoVenda.cliente.tel : '---';
    
    let endStr = '---';
    if(estadoVenda.cliente && estadoVenda.tipoEntrega === 'Delivery') {
        const c = estadoVenda.cliente;
        endStr = `${c.rua}, ${c.num} - ${c.bairro}`;
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
            if(p) {
                const totalItem = p.preco * itemVenda.qtd;
                subtotal += totalItem;

                const titulo = p.sabor !== 'Tradicional' ? `${p.nome} ${p.sabor}` : p.nome;
                
                listaItensHtml.innerHTML += `
                    <div class="comanda-item-row">
                        <span>${itemVenda.qtd}x ${titulo} ${p.peso}</span>
                        <span>R$ ${totalItem.toFixed(2).replace('.', ',')}</span>
                    </div>
                `;
            }
        });
    }

    // Cálculos
    let valorDesc = 0;
    if(estadoVenda.valorDesconto > 0) {
        if(estadoVenda.tipoDesconto === 'RS') {
            valorDesc = estadoVenda.valorDesconto;
        } else { // PCT
            valorDesc = subtotal * (estadoVenda.valorDesconto / 100);
        }
    }

    // Não permite desconto maior que o subtotal
    if(valorDesc > subtotal) valorDesc = subtotal;

    const totalCalculado = (subtotal - valorDesc) + estadoVenda.taxaEntrega;

    // Atualiza valores na tela
    document.getElementById('comandaSub').textContent = `R$ ${subtotal.toFixed(2).replace('.', ',')}`;
    document.getElementById('comandaDesc').textContent = `- R$ ${valorDesc.toFixed(2).replace('.', ',')}`;
    document.getElementById('comandaTaxa').textContent = `R$ ${estadoVenda.taxaEntrega.toFixed(2).replace('.', ',')}`;
    document.getElementById('comandaTotal').textContent = `R$ ${totalCalculado.toFixed(2).replace('.', ',')}`;
}

// Botão Limpar Comanda
function limparPDV() {
    // Reseta estado
    estadoVenda = {
        cliente: null,
        itens: [],
        tipoDesconto: 'RS',
        valorDesconto: 0,
        taxaEntrega: 0,
        tipoEntrega: '',
        plataforma: '',
        pagamento: '',
        status: '',
        obs: ''
    };

    // Remove botões ativos
    document.querySelectorAll('.btn-toggle-pdv').forEach(b => b.classList.remove('active'));
    
    // Esconde endereco
    document.getElementById('blocoEnderecoPDV').classList.add('d-none');
    
    // Reseta Inputs text
    document.querySelectorAll('input').forEach(i => i.value = '');
    
    // Volta botão R$
    document.getElementById('btnDescRs').classList.add('active');
    document.getElementById('btnDescPct').classList.remove('active');

    // Volta layout do cliente
    removerClientePDV();

    // Zera contadores da coluna do meio
    document.querySelectorAll('.qtd-contador').forEach(span => span.textContent = '0');

    atualizarComandaPDV();
}

// #endregion

// #region 6. CARREGAR VENDA PARA EDIÇÃO (HYDRATION)
function carregarVendaParaEdicao() {
    // Verifica se existe dados salvos na memória
    const dadosStr = localStorage.getItem('vendaEmEdicao');
    if (!dadosStr) return; // Se não tiver, é uma "Nova Venda" normal, encerra aqui.

    // Transforma o texto salvo de volta em um Objeto JavaScript
    const vendaSalva = JSON.parse(dadosStr);
    
    // Substitui o estado global da tela pelos dados salvos
    estadoVenda = vendaSalva;

    // --- MÁGICA VISUAL: Preenchendo a tela ---

    // 1. Preenche o Cliente e Endereço
    if (estadoVenda.cliente) {
        document.getElementById('buscaClientePDV').parentElement.classList.add('d-none'); // Esconde a busca
        document.getElementById('nomeClientePDV').textContent = estadoVenda.cliente.nome;
        document.getElementById('telClientePDV').textContent = estadoVenda.cliente.tel;
        document.getElementById('boxClienteSelecionado').classList.remove('d-none'); // Mostra o card do cliente
        
        // Campos de Endereço invisíveis
        document.getElementById('endRuaPDV').value = estadoVenda.cliente.rua;
        document.getElementById('endNumPDV').value = estadoVenda.cliente.num;
        document.getElementById('endBairroPDV').value = estadoVenda.cliente.bairro;
        document.getElementById('endCidPDV').value = estadoVenda.cliente.cid;
        document.getElementById('endUFPDV').value = estadoVenda.cliente.uf;
        document.getElementById('endCompPDV').value = estadoVenda.cliente.comp;
    }

    // 2. Acende os botões corretos (Delivery, PIX, Status, etc)
    const acenderBotao = (seletor, valorAtivo) => {
        document.querySelectorAll(seletor).forEach(btn => {
            if (btn.dataset.value === valorAtivo) btn.classList.add('active');
            else btn.classList.remove('active');
        });
    };

    acenderBotao('.btn-tipo-entrega', estadoVenda.tipoEntrega);
    if (estadoVenda.tipoEntrega === 'Delivery') document.getElementById('blocoEnderecoPDV').classList.remove('d-none');
    
    acenderBotao('.btn-plataforma', estadoVenda.plataforma);
    acenderBotao('.btn-pagamento', estadoVenda.pagamento);
    acenderBotao('.btn-status', estadoVenda.status);

    // 3. Preenche a Observação
    if (estadoVenda.obs) document.getElementById('obsPDV').value = estadoVenda.obs;

    // 4. Atualiza os contadores na coluna do meio (Produtos)
    estadoVenda.itens.forEach(item => {
        const spanQtd = document.getElementById(`qtd-prod-${item.idProduto}`);
        if (spanQtd) spanQtd.textContent = item.qtd;
    });

    // 5. Atualiza a Comanda com as taxas e cálculos
    atualizarComandaPDV();

    // Limpa a memória para que a próxima vez que ele clicar em "+ NOVA VENDA", a tela venha zerada
    localStorage.removeItem('vendaEmEdicao');
}
// #endregion


// INICIALIZAÇÃO
document.addEventListener('DOMContentLoaded', () => {
    // Se a tela tiver o id exclusivo do Relógio, roda as funções do PDV
    if (document.getElementById('relogioPDV')) {
        iniciarRelogioPDV();
        aplicarMascarasPDV();
        configurarBuscaClientePDV();
        configurarBotoesTogglePDV();
        carregarListaProdutosPDV();

        carregarVendaParaEdicao();
        
        atualizarComandaPDV(); // Render inicial zerado
    }
});