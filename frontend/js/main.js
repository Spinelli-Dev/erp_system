/* 
============================================================================================================================== 
        HEADER: DATA ATUALIZADA
============================================================================================================================== 
*/
// #region - ATUALIZA DATA  
function configurarFiltrosPeriodo() {
    const filtroMes = document.getElementById('filtro-mes');
    const filtroAno = document.getElementById('filtro-ano');

    // A função fica guardada aqui dentro, organizada
    function logPeriodo() {
        console.log(`Período selecionado: Mes ${filtroMes.value} de ${filtroAno.value}`);
        // Aqui no futuro você chamará a função que busca dados no C# ou Node
    }

    // Se os campos existirem na tela, adiciona os "ouvintes" de mudança
    if (filtroMes && filtroAno) {
        filtroMes.addEventListener('change', logPeriodo);
        filtroAno.addEventListener('change', logPeriodo);
    }
}
// #endregion



/* 
============================================================================================================================== 
        TELA: DASHBOARD
============================================================================================================================== 
*/
// #region - ALTERA COR CRESCIMENTO/DECRESCIMENTO  
function formatarCoresStatus() {
    const spansStatus = document.querySelectorAll('.comp-valor');
    
    spansStatus.forEach(span => {
        const texto = span.textContent.trim();
        
        if (texto.startsWith('+')) {
            span.classList.add('status-positivo');
            span.classList.remove('status-negativo');
        } else if (texto.startsWith('-')) {
            span.classList.add('status-negativo');
            span.classList.remove('status-positivo');
        }
    });
}
// #endregion

// #region - ALTERA COR ESTOQUE
function verificarEstoqueCores() {
    // Pega todos os elementos que tem a classe badge-estoque
    const badgesEstoque = document.querySelectorAll('.badge-estoque');
    
    badgesEstoque.forEach(badge => {
        // Pega o número inteiro do atributo data-qtd
        const quantidade = parseInt(badge.getAttribute('data-qtd'), 10);
        
        // Remove classes antigas (importante caso os dados sejam atualizados dinamicamente)
        badge.classList.remove('badge-critico', 'badge-alerta');

        // Aplica a lógica que você solicitou
        if (quantidade <= 3) {
            badge.classList.add('badge-critico');
        } else if (quantidade > 3 && quantidade <= 6) {
            badge.classList.add('badge-alerta');
        }
        // Se for > 6, ele fica sem cor de fundo padrão (ou você pode adicionar uma classe 'badge-ok' verde depois).
    });
}
// #endregion


/* 
============================================================================================================================== 
        TELA: VENDAS
============================================================================================================================== 
*/
// #region - CORES AUTOMÁTICAS: STATUS DE VENDAS
function aplicarCoresStatusVendas() {
    const statusElementos = document.querySelectorAll('.status-venda-text');
    if (statusElementos.length === 0) return;

    statusElementos.forEach(elemento => {
        const textoStatus = elemento.textContent.trim().toLowerCase();
        
        elemento.classList.remove('status-venda-concluido', 'status-venda-agendado', 'status-venda-pendente', 'status-venda-cancelado');

        if (textoStatus === 'concluído') {
            elemento.classList.add('status-venda-concluido');
        } else if (textoStatus === 'agendado') {
            elemento.classList.add('status-venda-agendado');
        } else if (textoStatus.includes('pendente')) { 
            // Usa 'includes' para pegar tanto "Pendente" quanto "Pendente Pagamento"
            elemento.classList.add('status-venda-pendente');
        } else if (textoStatus === 'cancelado') {
            elemento.classList.add('status-venda-cancelado');
        }
    });
}
// #endregion

// #region - FILTRO DA TELA DE VENDAS
function configurarFiltrosVendas() {
    const buscaInput = document.getElementById('buscaVenda');
    const filtroMes = document.getElementById('filtroMesVendas');
    const filtroAno = document.getElementById('filtroAnoVendas');
    const filtroProduto = document.getElementById('filtroProdutoVendas');
    const filtroStatus = document.getElementById('filtroStatusVendas');

    if (!buscaInput || !filtroMes || !filtroAno || !filtroProduto || !filtroStatus) return;

    function filtrarVendas() {
        const termoBusca = buscaInput.value.toLowerCase().trim();
        const mesSelecionado = filtroMes.value; 
        const anoSelecionado = filtroAno.value; 
        const produtoSelecionado = filtroProduto.value.toLowerCase();
        const statusSelecionado = filtroStatus.value.toLowerCase(); 

        // 1. Filtrar Tabela (Desktop)
        const linhas = document.querySelectorAll('.tabela-produtos tbody tr');
        
        linhas.forEach(linha => {
            if(linha.cells.length < 13) return; 

            // Textos para buscar no input livre (Nome e Telefone)
            const nomeTel = (linha.cells[1].textContent + " " + linha.cells[2].textContent).toLowerCase();
            
            // Coluna de Produtos (índice 5)
            const produtosLinha = linha.cells[5].textContent.toLowerCase();
            
            // Data (índice 3)
            const partesData = linha.cells[3].textContent.trim().split('/');
            const mesLinha = partesData[1];
            const anoLinha = partesData[2];

            // Status (penúltima coluna)
            const statusLinha = linha.querySelector('.status-venda-text').textContent.toLowerCase();

            const passaBusca = termoBusca === "" || nomeTel.includes(termoBusca);
            const passaMes = mesSelecionado === "" || mesLinha === mesSelecionado;
            const passaAno = anoSelecionado === "" || anoLinha === anoSelecionado;
            // Se o produto selecionado for "Molho", a linha "Molho Branco" passa porque contém a palavra.
            const passaProduto = produtoSelecionado === "" || produtosLinha.includes(produtoSelecionado);
            
            // Para o status pendente que tem 2 nomes
            let passaStatus = false;
            if(statusSelecionado === "") {
                passaStatus = true;
            } else if (statusSelecionado === "pendente" && statusLinha.includes("pendente")) {
                passaStatus = true;
            } else {
                passaStatus = statusLinha === statusSelecionado;
            }

            linha.style.display = (passaBusca && passaMes && passaAno && passaProduto && passaStatus) ? '' : 'none';
        });

        // 2. Filtrar Cards (Mobile) - Nos cards agrupados a lógica é mais simples pois não temos o produto visível no resumo
        const cards = document.querySelectorAll('.card-venda');
        
        cards.forEach(card => {
            const textoCard = card.textContent.toLowerCase();
            const statusCard = card.querySelector('.status-venda-text').textContent.toLowerCase();

            const passaBusca = termoBusca === "" || textoCard.includes(termoBusca);
            
            let passaStatus = false;
            if(statusSelecionado === "") {
                passaStatus = true;
            } else if (statusSelecionado === "pendente" && statusCard.includes("pendente")) {
                passaStatus = true;
            } else {
                passaStatus = statusCard === statusSelecionado;
            }

            // Nota: Filtros de Mês, Ano e Produto não afetam os cards agregados pois essas infos precisariam estar atreladas via Data-Attributes no card
            card.style.display = (passaBusca && passaStatus) ? 'flex' : 'none';
        });
    }

    buscaInput.addEventListener('input', filtrarVendas);
    filtroMes.addEventListener('change', filtrarVendas);
    filtroAno.addEventListener('change', filtrarVendas);
    filtroProduto.addEventListener('change', filtrarVendas);
    filtroStatus.addEventListener('change', filtrarVendas);
}
// #endregion

// #region - MODAL CONSUMO PRÓPRIO (AUTOCOMPLETE)
function configurarModalConsumoProprio() {
    const buscaInput = document.getElementById('buscaProdutoConsumo');
    const dropdown = document.getElementById('dropdownConsumo');
    
    if (!buscaInput || !dropdown) return;

    // 1. Simulação do Banco de Dados (Dados idênticos aos da tabela de Produtos)
    const bancoDeProdutos = [
        { nome: 'Canelone', sabor: '4 Queijos', peso: '700g', custo: 'R$ 21,90' },
        { nome: 'Canelone', sabor: 'Brócolis e Mussarela', peso: '700g', custo: 'R$ 18,90' },
        { nome: 'Canelone', sabor: 'Frango e Requeijão', peso: '700g', custo: 'R$ 18,90' },
        { nome: 'Massa de Lasanha', sabor: 'Tradicional', peso: '500g', custo: 'R$ 7,00' },
        { nome: 'Sofioli', sabor: '4 Queijos', peso: '700g', custo: 'R$ 21,90' },
        { nome: 'Sofioli', sabor: 'Brócolis e Mussarela', peso: '700g', custo: 'R$ 18,90' },
        { nome: 'Sofioli', sabor: 'Frango e Requeijão', peso: '700g', custo: 'R$ 18,90' },
        { nome: 'Sofioli', sabor: 'Presunto e Mussarela', peso: '700g', custo: 'R$ 18,90' },
        { nome: 'Molho', sabor: 'Tomate Tradicional', peso: '300g', custo: 'R$ 1,10' },
        { nome: 'Molho', sabor: 'Branco', peso: '240g', custo: 'R$ 3,02' },
        { nome: 'Molho', sabor: 'Especial Sacciali Arrabiata', peso: '530g', custo: 'R$ 9,60' },
        { nome: 'Queijo Ralado', sabor: 'Tradicional', peso: '40g', custo: 'R$ 2,79' }
    ];

    // 2. Evento disparado a cada tecla digitada
    buscaInput.addEventListener('input', function() {
        const termo = this.value.toLowerCase().trim();
        dropdown.innerHTML = ''; // Limpa a lista
        
        // Se apagar o campo, esconde a lista e limpa o formulário
        if (termo === '') {
            dropdown.classList.add('d-none');
            limparCamposConsumo();
            return;
        }

        // Filtra os produtos
        const filtrados = bancoDeProdutos.filter(p => {
            const termoCompleto = (p.nome + " " + p.sabor).toLowerCase();
            return termoCompleto.includes(termo);
        });

        // 3. Monta o visual do dropdown
        if (filtrados.length > 0) {
            filtrados.forEach(produto => {
                const li = document.createElement('li');
                li.className = 'autocomplete-item';
                
                const spanNome = document.createElement('span');
                spanNome.className = 'auto-nome';
                // Junta nome e sabor (ex: Sofioli 4 Queijos)
                const tituloCompleto = produto.sabor !== 'Tradicional' && produto.sabor !== '' 
                    ? `${produto.nome} ${produto.sabor}` 
                    : produto.nome;
                spanNome.textContent = tituloCompleto;

                const spanDetalhes = document.createElement('span');
                spanDetalhes.className = 'auto-detalhes';
                // Adiciona a bolinha separadora no HTML (•)
                spanDetalhes.innerHTML = `${produto.peso} &nbsp;&bull;&nbsp; Custo: ${produto.custo}`;

                li.appendChild(spanNome);
                li.appendChild(spanDetalhes);

                // Ação de selecionar o item
                li.addEventListener('click', () => selecionarProduto(produto, tituloCompleto));

                dropdown.appendChild(li);
            });
            dropdown.classList.remove('d-none'); // Mostra a lista
        } else {
            dropdown.classList.add('d-none');
        }
    });

    // 4. Esconder dropdown se clicar fora dele
    document.addEventListener('click', (e) => {
        if (!buscaInput.contains(e.target) && !dropdown.contains(e.target)) {
            dropdown.classList.add('d-none');
        }
    });

    // 5. Preencher campos automáticos (Mantive no "value" mas deixei o input "readonly" no HTML para UX perfeita)
    function selecionarProduto(produto, tituloCompleto) {
        document.getElementById('inputConsumoNome').value = produto.nome;
        document.getElementById('inputConsumoSabor').value = produto.sabor === 'Tradicional' || produto.sabor === '' ? '—' : produto.sabor;
        document.getElementById('inputConsumoPeso').value = produto.peso;
        
        buscaInput.value = tituloCompleto; // Fixa o nome na barra de busca
        dropdown.classList.add('d-none'); // Fecha a lista
    }

    function limparCamposConsumo() {
        document.getElementById('inputConsumoNome').value = '';
        document.getElementById('inputConsumoSabor').value = '';
        document.getElementById('inputConsumoPeso').value = '';
    }

    // 6. Resetar o modal ao abrir
    const modalElement = document.getElementById('modalConsumoProprio');
    modalElement.addEventListener('show.bs.modal', () => {
        document.getElementById('formConsumoProprio').reset();
        limparCamposConsumo();
        dropdown.classList.add('d-none');
    });
}
// #endregion

// #region
// SIMULAÇÃO: Abrir Venda para Edição a partir da Tabela/Cards
function editarVenda(idVenda) {
    // 1. Simula a busca no banco de dados (MySQL) de uma venda existente
    const vendaSimulada = {
        id: idVenda,
        cliente: { id: 1, nome: 'Maria Fernanda Costa', tel: '(16) 9 9876-5432', rua: 'Rua das Flores', num: '142', bairro: 'Jardim Europa', cid: 'Itápolis', uf: 'SP', comp: '' },
        itens: [
            { idProduto: 1, qtd: 2 },  // Ex: 2x Canelone 4 Queijos
            { idProduto: 10, qtd: 1 }  // Ex: 1x Molho Branco
        ],
        tipoDesconto: 'RS',
        valorDesconto: 0,
        taxaEntrega: 5.00,
        tipoEntrega: 'Delivery',
        plataforma: 'WhatsApp',
        pagamento: 'PIX',
        status: 'Pendente Pagamento',
        obs: 'Entregar na porta dos fundos.'
    };

    // 2. Salva essa venda na memória do navegador (localStorage)
    localStorage.setItem('vendaEmEdicao', JSON.stringify(vendaSimulada));

    // 3. Redireciona o usuário para a tela de Alterar Venda
    window.location.href = 'alterar-venda.html';
}
// #endregion



/* 
============================================================================================================================== 
        TELA: CLIENTES
============================================================================================================================== 
*/
// #region - CONTADOR E BUSCA DE CLIENTES
function configurarBuscaEContadorClientes() {
    const inputBusca = document.getElementById('buscaCliente');
    const spanDesktop = document.getElementById('qtd-desktop');
    const spanMobile = document.getElementById('qtd-mobile');
    
    // Função para atualizar os números nos badges
    function atualizarContador(quantidade) {
        if (spanDesktop) spanDesktop.textContent = `${quantidade} clientes`;
        if (spanMobile) spanMobile.textContent = `${quantidade} total`;
    }

    function filtrarEContar() {
        const termo = inputBusca ? inputBusca.value.toLowerCase().trim() : '';
        let visiveis = 0;

        // Filtro Tabela Desktop
        const linhas = document.querySelectorAll('.tabela-clientes tbody .linha-cliente');
        linhas.forEach(linha => {
            const textoLinha = linha.textContent.toLowerCase();
            if (textoLinha.includes(termo)) {
                linha.style.display = '';
                visiveis++; // Conta a linha visível
            } else {
                linha.style.display = 'none';
            }
        });

        // Filtro Cards Mobile (usa a mesma contagem para manter sincronizado)
        const cards = document.querySelectorAll('.card-cliente');
        let visiveisMobile = 0;
        cards.forEach(card => {
            const textoCard = card.textContent.toLowerCase();
            if (textoCard.includes(termo)) {
                card.style.display = 'flex';
                visiveisMobile++;
            } else {
                card.style.display = 'none';
            }
        });

        // Atualiza os badges com o número de itens encontrados (ou total se a busca estiver vazia)
        // Usa o maior número encontrado (caso a tela seja PC, as linhas existem; se for Mobile, os cards existem)
        atualizarContador(Math.max(visiveis, visiveisMobile));
    }

    // Chama na inicialização para contar a primeira vez
    filtrarEContar();

    // Adiciona o ouvinte para a busca em tempo real
    if (inputBusca) {
        inputBusca.addEventListener('input', filtrarEContar);
    }
}
// #endregion

// #region - EXPANSÃO DE CARDS MOBILE (VER/ESCONDER)
function configurarCardsExpansiveis() {
    const botoesToggle = document.querySelectorAll('.btn-toggle-card');
    
    botoesToggle.forEach(btn => {
        btn.addEventListener('click', function() {
            // Acha o card "pai" do botão que foi clicado
            const cardPai = this.closest('.card-cliente');
            const areaOculta = cardPai.querySelector('.area-expandida-cliente');
            const icone = this.querySelector('img');

            // Se está oculto, mostra. Se está mostrando, oculta. (E troca o ícone!)
            if (areaOculta.classList.contains('d-none')) {
                areaOculta.classList.remove('d-none');
                icone.src = '../assets/icons/icone-esconder.svg';
            } else {
                areaOculta.classList.add('d-none');
                icone.src = '../assets/icons/icone-ver.svg';
            }
        });
    });
}
// #endregion

// #region - ORDENAÇÃO DE TABELA (UNIVERSAL)
function configurarOrdenacaoUniversal() {
    const cabecalhosOrdenaveis = document.querySelectorAll('.coluna-ordenavel');
    
    cabecalhosOrdenaveis.forEach(th => {
        // Estado inicial de cada coluna: 'asc' = A-Z
        th.dataset.direcao = 'asc'; 

        th.addEventListener('click', () => {
            const tabela = th.closest('table');
            const tbody = tabela.querySelector('tbody');
            // Transforma os filhos do thead em um array para descobrir em qual coluna o usuário clicou (0, 1, 2...)
            const indiceColuna = Array.from(th.parentElement.children).indexOf(th);
            const linhasArray = Array.from(tbody.querySelectorAll('tr'));
            const direcaoAtual = th.dataset.direcao;

            // Ordena o array de linhas
            linhasArray.sort((a, b) => {
                const celulaA = a.cells[indiceColuna].textContent.trim().toLowerCase();
                const celulaB = b.cells[indiceColuna].textContent.trim().toLowerCase();

                if (celulaA < celulaB) return direcaoAtual === 'asc' ? -1 : 1;
                if (celulaA > celulaB) return direcaoAtual === 'asc' ? 1 : -1;
                return 0;
            });

            // Inverte a direção para o próximo clique
            th.dataset.direcao = direcaoAtual === 'asc' ? 'desc' : 'asc';

            // Limpa a tabela velha e injeta as linhas na nova ordem
            tbody.innerHTML = '';
            linhasArray.forEach(linha => tbody.appendChild(linha));
        });
    });
}
// #endregion

// #region - MODAL DE CADASTRAR / EDITAR CLIENTE
function configurarBotoesModalCliente() {
    const modalElement = document.getElementById('modalCliente');
    
    // A MÁGICA DA SEGURANÇA: Se o modal não existir nesta página, pare a função aqui e não trave o resto!
    if (!modalElement) return; 

    const btnNovo = document.querySelector('.btn-novo');
    const botoesEditar = document.querySelectorAll('.tabela-clientes .btn-icone, .card-cliente .btn-icone:last-child');
    const modalInstance = new bootstrap.Modal(document.getElementById('modalCliente'));
    const tituloModal = document.getElementById('modalClienteLabel');
    const form = document.getElementById('formCliente');

    // Abre Modal VAZIO
    if (btnNovo) {
        btnNovo.addEventListener('click', () => {
            form.reset(); // Limpa os campos
            tituloModal.textContent = 'Cadastrar Cliente';
            modalInstance.show();
        });
    }

    // Abre Modal PREENCHIDO
    botoesEditar.forEach(btn => {
        // Ignora o botão de "Ver" no mobile usando a imagem do lápis como trava
        if (btn.innerHTML.includes('icone-edicao')) {
            btn.addEventListener('click', function() {
                form.reset();
                tituloModal.textContent = 'Editar Cadastro';

                // Verifica se o clique veio do Desktop (TR) ou Mobile (Card)
                const linhaPC = this.closest('tr');
                const cardMobile = this.closest('.card-cliente');

                if (linhaPC) {
                    // Mapeia os dados do Desktop (td)
                    document.getElementById('cliNome').value = linhaPC.cells[1].textContent.trim();
                    document.getElementById('cliTel').value = linhaPC.cells[2].textContent.trim();
                    document.getElementById('cliCEP').value = linhaPC.cells[3].textContent.trim();
                    document.getElementById('cliRua').value = linhaPC.cells[4].textContent.trim();
                    document.getElementById('cliNum').value = linhaPC.cells[5].textContent.trim();
                    document.getElementById('cliBairro').value = linhaPC.cells[6].textContent.trim();
                    
                    let comp = linhaPC.cells[7].textContent.trim();
                    document.getElementById('cliComp').value = comp === '—' ? '' : comp;
                    
                    document.getElementById('cliCidade').value = linhaPC.cells[8].textContent.trim();
                    document.getElementById('cliUF').value = linhaPC.cells[9].textContent.trim();
                    
                    let obs = linhaPC.cells[12].textContent.trim();
                    document.getElementById('cliObs').value = obs === '—' ? '' : obs;
                    
                } else if (cardMobile) {
                    // Mapeia os dados do Mobile (Spans)
                    document.getElementById('cliNome').value = cardMobile.querySelector('.nome-item').textContent.trim();
                    document.getElementById('cliTel').value = cardMobile.querySelector('.telefone-item').textContent.trim();
                    
                    const infosOcultas = cardMobile.querySelectorAll('.area-expandida-cliente .val');
                    document.getElementById('cliCEP').value = infosOcultas[0].textContent.trim();
                    
                    // O Mobile tem o endereço agrupado: "Rua das Flores, 142 - Jardim Europa".
                    // Essa lógica separa Rua, Número e Bairro!
                    const endCompleto = infosOcultas[1].textContent.trim();
                    const separaEnd = endCompleto.match(/(.+),\s*(.+?)\s*-\s*(.+)/);
                    if (separaEnd) {
                        document.getElementById('cliRua').value = separaEnd[1].trim();
                        document.getElementById('cliNum').value = separaEnd[2].trim();
                        document.getElementById('cliBairro').value = separaEnd[3].trim();
                    }

                    let comp = infosOcultas[2].textContent.trim();
                    document.getElementById('cliComp').value = comp === '—' ? '' : comp;

                    // Cidade e UF agrupadas: "Itápolis - SP"
                    const cidUf = infosOcultas[3].textContent.trim().split(' - ');
                    document.getElementById('cliCidade').value = cidUf[0] ? cidUf[0].trim() : '';
                    document.getElementById('cliUF').value = cidUf[1] ? cidUf[1].trim() : '';

                    let obs = infosOcultas[4].textContent.trim();
                    document.getElementById('cliObs').value = obs === '—' ? '' : obs;
                }

                modalInstance.show();
            });
        }
    });
}
// #endregion



/* 
============================================================================================================================== 
        TELA: ESTOQUE
============================================================================================================================== 
*/

// #region - CÁLCULO DINÂMICO DE STATUS
function calcularStatusEstoque() {
    // Função auxiliar que aplica a regra matemática e pinta o texto
    function aplicarRegra(qtd, elementoStatus) {
        // Limpa as classes antes
        elementoStatus.classList.remove('status-encerrado', 'status-critico', 'status-baixo', 'status-ok');
        
        if (qtd === 0) {
            elementoStatus.textContent = 'Encerrado';
            elementoStatus.classList.add('status-encerrado');
        } else if (qtd <= 3) {
            elementoStatus.textContent = 'Crítico';
            elementoStatus.classList.add('status-critico');
        } else if (qtd <= 6) {
            elementoStatus.textContent = 'Baixo';
            elementoStatus.classList.add('status-baixo');
        } else {
            elementoStatus.textContent = 'Ok';
            elementoStatus.classList.add('status-ok');
        }
    }

    // Aplica na Tabela
    const linhas = document.querySelectorAll('.tabela-estoque tbody tr');
    linhas.forEach(linha => {
        const qtdText = linha.querySelector('.qtd-item').textContent;
        const statusEl = linha.querySelector('.status-item');
        aplicarRegra(parseInt(qtdText, 10), statusEl);
    });

    // Aplica nos Cards Mobile
    const cards = document.querySelectorAll('.card-estoque');
    cards.forEach(card => {
        const qtdText = card.querySelector('.m-qtd').textContent; // Ex: "3 un." (o parseInt entende e pega só o 3)
        const statusEl = card.querySelector('.status-item');
        aplicarRegra(parseInt(qtdText, 10), statusEl);
    });
}
// #endregion

// #region - FILTRO TRIPLO (BUSCA + TIPO + STATUS)
function configurarFiltrosEstoque() {
    const buscaInput = document.getElementById('buscaEstoque');
    const filtroTipo = document.getElementById('filtroTipoEstoque');
    const filtroStatus = document.getElementById('filtroStatusEstoque');

    if (!buscaInput || !filtroTipo || !filtroStatus) return;

    function filtrarGeral() {
        const termoBusca = buscaInput.value.toLowerCase().trim();
        const tipoSelecionado = filtroTipo.value.toLowerCase();
        const statusSelecionado = filtroStatus.value.toLowerCase(); // "ok", "baixo", "crítico", "encerrado"

        // Filtrar Tabela
        const linhas = document.querySelectorAll('.tabela-estoque tbody tr');
        linhas.forEach(linha => {
            const produtoSabor = (linha.cells[1].textContent + " " + linha.cells[2].textContent).toLowerCase();
            const tipo = linha.querySelector('.tipo-item').textContent.toLowerCase();
            const status = linha.querySelector('.status-item').textContent.toLowerCase();

            const passaBusca = produtoSabor.includes(termoBusca);
            const passaTipo = tipoSelecionado === "" || tipo === tipoSelecionado;
            const passaStatus = statusSelecionado === "" || status === statusSelecionado;

            linha.style.display = (passaBusca && passaTipo && passaStatus) ? '' : 'none';
        });

        // Filtrar Cards
        const cards = document.querySelectorAll('.card-estoque');
        cards.forEach(card => {
            const produtoSabor = card.querySelector('.card-prod-left').textContent.toLowerCase();
            const tipo = card.querySelector('.tipo-item').textContent.toLowerCase();
            const status = card.querySelector('.status-item').textContent.toLowerCase();

            const passaBusca = produtoSabor.includes(termoBusca);
            const passaTipo = tipoSelecionado === "" || tipo === tipoSelecionado;
            const passaStatus = statusSelecionado === "" || status === statusSelecionado;

            card.style.display = (passaBusca && passaTipo && passaStatus) ? 'flex' : 'none';
        });
    }

    // Liga os ouvintes (qualquer alteração nos 3 campos roda o filtro!)
    buscaInput.addEventListener('input', filtrarGeral);
    filtroTipo.addEventListener('change', filtrarGeral);
    filtroStatus.addEventListener('change', filtrarGeral);
}
// #endregion

// #region - CONTADORES DO MODAL REPOSIÇÃ O   
function configurarContadoresReposicao() {
    // Trava de segurança: Se não existir nenhum botão de 'menos' na página, ele para a função aqui.
    if (document.querySelectorAll('.btn-menos').length === 0) return;

    const botoesMenos = document.querySelectorAll('.btn-menos');
    const botoesMais = document.querySelectorAll('.btn-mais');

    botoesMenos.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            const spanQtd = btn.nextElementSibling;
            let qtd = parseInt(spanQtd.textContent, 10);
            if (qtd > 0) { // Não permite reposição negativa
                spanQtd.textContent = qtd - 1;
            }
        });
    });

    botoesMais.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            const spanQtd = btn.previousElementSibling;
            let qtd = parseInt(spanQtd.textContent, 10);
            spanQtd.textContent = qtd + 1;
        });
    });
}
// #endregion

// #region - PREENCHIMENTO DO MODAL AJUSTE
function configurarModalAjuste() {
    const modalAjusteElement = document.getElementById('modalAjuste');
    if (!modalAjusteElement) return;

    modalAjusteElement.addEventListener('show.bs.modal', function (event) {
        const botaoClicado = event.relatedTarget;
        
        // Descobre se clicou na tabela (PC) ou no Card (Mobile)
        const linhaTabela = botaoClicado.closest('tr');
        const cardMobile = botaoClicado.closest('.card-estoque');

        let nome = "", sabor = "", peso = "", qtd = "";

        if (linhaTabela) {
            nome = linhaTabela.cells[1].textContent.trim();
            sabor = linhaTabela.cells[2].textContent.trim();
            peso = linhaTabela.cells[3].textContent.trim();
            qtd = linhaTabela.querySelector('.qtd-item').textContent.trim();
        } else if (cardMobile) {
            nome = cardMobile.querySelector('.m-prod').textContent.trim();
            sabor = cardMobile.querySelector('.m-sabor').textContent.trim();
            peso = cardMobile.querySelector('.m-peso-tipo').textContent.split('•')[0].trim();
            qtd = cardMobile.querySelector('.m-qtd').textContent.replace('un.', '').trim();
        }

        // Escreve as informações de leitura
        document.getElementById('ajusteNome').innerHTML = `<strong>${nome}</strong>`;
        document.getElementById('ajusteSabor').textContent = sabor !== '—' ? sabor : 'Tradicional / Sem sabor';
        document.getElementById('ajustePeso').textContent = peso;
        
        // Preenche o input
        document.getElementById('inputAjusteQtd').value = qtd;
    });
}
// #endregion



/* 
============================================================================================================================== 
        TELA: PRODUTOS
============================================================================================================================== 
*/
// #region - FILTRO DA TABELA
function configurarOrdenacaoProdutos() {
    const thProduto = document.getElementById('th-produto');
    const tbody = document.querySelector('.tabela-produtos tbody');

    if (!thProduto || !tbody) return;

    let ascendente = true;

    thProduto.addEventListener('click', () => {
        // Pega todas as linhas da tabela e transforma em um Array
        const linhas = Array.from(tbody.querySelectorAll('tr'));
        
        // Faz a ordenação alfabética
        linhas.sort((a, b) => {
            // A coluna "Produto" é a segunda (índice 1)
            const produtoA = a.cells[1].textContent.trim().toLowerCase();
            const produtoB = b.cells[1].textContent.trim().toLowerCase();

            if (produtoA < produtoB) return ascendente ? -1 : 1;
            if (produtoA > produtoB) return ascendente ? 1 : -1;
            return 0; // Se forem iguais
        });

        // Inverte a direção para o próximo clique (A-Z ou Z-A)
        ascendente = !ascendente;

        // Limpa a tabela e devolve as linhas ordenadas
        tbody.innerHTML = '';
        linhas.forEach(linha => tbody.appendChild(linha));
    });
}

// #endregion 


// #region - CAMPO DE BUSCA 
function configurarBuscaProdutos() {
    const inputBusca = document.querySelector('.search-input');
    if (!inputBusca) return;

    inputBusca.addEventListener('input', function() {
        // Pega o texto digitado, converte para minúsculo e tira os espaços das pontas
        const termo = this.value.toLowerCase().trim();

        // 1. FILTRAR A TABELA (DESKTOP)
        const linhasTabela = document.querySelectorAll('.tabela-produtos tbody tr');
        linhasTabela.forEach(linha => {
            // Pega o texto da coluna Produto (índice 1) e Sabor (índice 2)
            const produto = linha.cells[1].textContent.toLowerCase();
            const sabor = linha.cells[2].textContent.toLowerCase();
            
            // Se o texto digitado estiver no produto OU no sabor, mostra a linha
            if (produto.includes(termo) || sabor.includes(termo)) {
                linha.style.display = ''; // Volta ao padrão do CSS
            } else {
                linha.style.display = 'none'; // Esconde
            }
        });

        // 2. FILTRAR OS CARDS (MOBILE)
        const cardsMobile = document.querySelectorAll('.card-produto');
        cardsMobile.forEach(card => {
            // Pega o texto dos spans de produto e sabor dentro do card
            const produto = card.querySelector('.m-prod').textContent.toLowerCase();
            const sabor = card.querySelector('.m-sabor').textContent.toLowerCase();
            
            if (produto.includes(termo) || sabor.includes(termo)) {
                card.style.display = 'flex'; // Volta ao padrão do card
            } else {
                card.style.display = 'none'; // Esconde
            }
        });
    });
}
// #endregion


// #region - COMPORTAMENTO MODAL PRODUTOS (CADASTRAR/ALTERAR)
function configurarModalProduto() {
    const modalProdutoElement = document.getElementById('modalProduto');
    if (!modalProdutoElement) return;

    modalProdutoElement.addEventListener('show.bs.modal', function (event) {
        // event.relatedTarget é o botão que abriu o modal
        const botaoClicado = event.relatedTarget;
        const tituloModal = document.getElementById('tituloModalProduto');
        const form = document.getElementById('formProduto');
        
        // Verifica se é o botão "NOVO" (Tem a classe btn-novo)
        if (botaoClicado.classList.contains('btn-novo')) {
            tituloModal.textContent = 'Cadastrar Produto';
            form.reset(); // Limpa todos os inputs
        } 
        // Verifica se é um botão de EDIÇÃO (Tem a classe 'btn-editar' nos ícones de lápis da sua tabela/cards)
        else if (botaoClicado.closest('.btn-icone')) {
            tituloModal.textContent = 'Alterar Produto';
            
            // Verifica se está vindo da Tabela (Desktop) ou Card (Mobile)
            const linhaTabela = botaoClicado.closest('tr');
            const cardMobile = botaoClicado.closest('.card-produto');

            if (linhaTabela) {
                // Preenche usando os dados das células da tabela (0='#', 1='Produto', 2='Sabor', 3='Peso', 4='Tipo', 5='Custo', 6='Preço', 7='Obs')
                document.getElementById('inputNome').value = linhaTabela.cells[1].textContent.trim();
                
                const saborText = linhaTabela.cells[2].textContent.trim();
                document.getElementById('inputSabor').value = saborText === '—' ? '' : saborText;
                
                document.getElementById('inputPeso').value = linhaTabela.cells[3].textContent.trim();
                document.getElementById('inputTipo').value = linhaTabela.cells[4].textContent.trim();
                document.getElementById('inputCusto').value = linhaTabela.cells[5].textContent.trim();
                document.getElementById('inputPreco').value = linhaTabela.cells[6].textContent.trim();
                
                const obsText = linhaTabela.cells[7].textContent.trim();
                document.getElementById('inputObs').value = obsText === '—' ? '' : obsText;
                
                // Estoque não temos na tabela visual atual, deixamos vazio ou preenchemos com dado falso para testar
                document.getElementById('inputEstoque').value = '10'; 
            } 
            else if (cardMobile) {
                // Preenche usando os spans do mobile
                document.getElementById('inputNome').value = cardMobile.querySelector('.m-prod').textContent.trim();
                
                const saborText = cardMobile.querySelector('.m-sabor').textContent.replace('Custo:', '').trim();
                // Lógica simples para pegar o sabor exato exigiria separar melhor os spans no HTML, mas para demonstração visual funciona:
                document.getElementById('inputSabor').value = cardMobile.querySelectorAll('.m-sabor')[0].textContent.trim() === '—' ? '' : cardMobile.querySelectorAll('.m-sabor')[0].textContent.trim();
                
                const pesoTipoSplit = cardMobile.querySelector('.m-peso-tipo').textContent.split('•');
                if(pesoTipoSplit.length === 2) {
                    document.getElementById('inputPeso').value = pesoTipoSplit[0].trim();
                    document.getElementById('inputTipo').value = pesoTipoSplit[1].trim();
                }
                
                document.getElementById('inputCusto').value = cardMobile.querySelectorAll('.m-sabor')[1].textContent.replace('Custo:', '').trim();
                document.getElementById('inputPreco').value = cardMobile.querySelector('.m-preco').textContent.trim();
                document.getElementById('inputEstoque').value = '10';
            }
        }
    });
}
// #endregion



/* 
============================================================================================================================== 
        TELA: ENTREGAS
============================================================================================================================== 
*/
// #region - CORES AUTOMÁTICAS: STATUS DE ENTREGAS
function aplicarCoresStatusEntregas() {
    // Busca todos os elementos que têm a classe de status na tela
    const statusElementos = document.querySelectorAll('.status-entrega-text');
    
    // Se não achar nenhum (ex: estiver em outra página), ele aborta com segurança
    if (statusElementos.length === 0) return;

    statusElementos.forEach(elemento => {
        const textoStatus = elemento.textContent.trim().toLowerCase();
        
        // Remove cores antigas para evitar conflito caso a tabela seja filtrada/atualizada
        elemento.classList.remove('status-verde', 'status-vermelho', 'status-preto');

        // Aplica a cor correta baseada no texto
        if (textoStatus === 'concluído') {
            elemento.classList.add('status-verde');
        } else if (textoStatus === 'pendente') {
            elemento.classList.add('status-vermelho');
        } else if (textoStatus === 'cancelado') {
            elemento.classList.add('status-preto');
        }
    });
}

// Executa a função assim que a página carregar
document.addEventListener('DOMContentLoaded', aplicarCoresStatusEntregas);
// #endregion

// #region - FILTRO TRIPLO DE ENTREGAS (BUSCA + DATA + STATUS)
function configurarFiltrosEntregas() {
    const buscaInput = document.getElementById('buscaEntrega');
    const filtroMes = document.getElementById('filtroMesEntregas');
    const filtroAno = document.getElementById('filtroAnoEntregas');
    const filtroStatus = document.getElementById('filtroStatusEntregas');

    // Trava de segurança: Se não estiver na tela de entregas, não faz nada
    if (!buscaInput || !filtroMes || !filtroAno || !filtroStatus) return;

    function filtrarEntregas() {
        const termoBusca = buscaInput.value.toLowerCase().trim();
        const mesSelecionado = filtroMes.value; // Ex: "04"
        const anoSelecionado = filtroAno.value; // Ex: "2026"
        const statusSelecionado = filtroStatus.value.toLowerCase(); // "concluído", "pendente"...

        // 1. Filtrar Tabela (Desktop)
        // Seleciona as linhas da tabela. (Como você reaproveitou as classes, busca por tbody tr)
        const linhas = document.querySelectorAll('.tabela-produtos tbody tr');
        
        linhas.forEach(linha => {
            // Se for uma tela sem dados, ignora
            if(linha.cells.length < 12) return; 

            // Pega os textos para busca (Nome, Endereço, etc)
            const textoLinha = linha.textContent.toLowerCase();
            
            // A data está na coluna 2 (índice 2). Ex: "25/04/2026"
            const dataTexto = linha.cells[2].textContent.trim(); 
            const partesData = dataTexto.split('/'); // Vira um array: ["25", "04", "2026"]
            const mesLinha = partesData[1];
            const anoLinha = partesData[2];

            // Pega o status na última coluna
            const statusLinha = linha.querySelector('.status-entrega-text').textContent.toLowerCase();

            // Validações
            const passaBusca = textoLinha.includes(termoBusca);
            const passaMes = mesSelecionado === "" || mesLinha === mesSelecionado;
            const passaAno = anoSelecionado === "" || anoLinha === anoSelecionado;
            const passaStatus = statusSelecionado === "" || statusLinha === statusSelecionado;

            // Só mostra a linha se passar em TODOS os filtros
            linha.style.display = (passaBusca && passaMes && passaAno && passaStatus) ? '' : 'none';
        });

        // 2. Filtrar Cards (Mobile)
        const cards = document.querySelectorAll('.card-entrega');
        
        cards.forEach(card => {
            const textoCard = card.textContent.toLowerCase();
            
            // Nos cards, a data é o primeiro span secundário. Ex: "25/04/2026 • 11:30"
            const spanDataCompleta = card.querySelectorAll('.m-entrega-data')[0].textContent;
            // Pega só os 10 primeiros caracteres ("25/04/2026")
            const dataApenas = spanDataCompleta.substring(0, 10); 
            const partesData = dataApenas.split('/');
            const mesCard = partesData[1];
            const anoCard = partesData[2];

            const statusCard = card.querySelector('.status-entrega-text').textContent.toLowerCase();

            // Validações
            const passaBusca = textoCard.includes(termoBusca);
            const passaMes = mesSelecionado === "" || mesCard === mesSelecionado;
            const passaAno = anoSelecionado === "" || anoCard === anoSelecionado;
            const passaStatus = statusSelecionado === "" || statusCard === statusSelecionado;

            card.style.display = (passaBusca && passaMes && passaAno && passaStatus) ? 'flex' : 'none';
        });
    }

    // Pendura os "ouvidos" nos inputs para rodar a função toda vez que algo mudar
    buscaInput.addEventListener('input', filtrarEntregas);
    filtroMes.addEventListener('change', filtrarEntregas);
    filtroAno.addEventListener('change', filtrarEntregas);
    filtroStatus.addEventListener('change', filtrarEntregas);
}
// #endregion



/* 
==============================================================================================================================
   2. INICIALIZAÇÃO ÚNICA
==============================================================================================================================
*/
// #region - CHAMADAS/INICIALIZAÇÕES
document.addEventListener('DOMContentLoaded', () => {
    // Modais Cadastro de Produto
    if (typeof configurarModalProduto === 'function') configurarModalProduto();

    // Funções gerais
    if (typeof atualizarData === 'function') atualizarData();
    
    // Funções Tela: Dashboard
    if (typeof formatarCoresStatus === 'function') formatarCoresStatus();
    if (typeof verificarEstoqueCores === 'function') verificarEstoqueCores();
    if (typeof configurarFiltrosPeriodo === 'function') configurarFiltrosPeriodo();

    // Funções Tela: Vendas
    if (typeof aplicarCoresStatusVendas === 'function') aplicarCoresStatusVendas();
    if (typeof configurarFiltrosVendas === 'function') configurarFiltrosVendas();
    if (typeof configurarModalConsumoProprio === 'function') configurarModalConsumoProprio();

    // Funções Tela: Clientes
    if (typeof configurarBuscaEContadorClientes === 'function') configurarBuscaEContadorClientes();
    if (typeof configurarCardsExpansiveis === 'function') configurarCardsExpansiveis();
    if (typeof configurarOrdenacaoUniversal === 'function') configurarOrdenacaoUniversal();
    if (typeof configurarBotoesModalCliente === 'function') configurarBotoesModalCliente();

    // Funções Tela: Estoque
    if (typeof calcularStatusEstoque === 'function') calcularStatusEstoque();
    if (typeof configurarFiltrosEstoque === 'function') configurarFiltrosEstoque();
    if (typeof configurarContadoresReposicao === 'function') configurarContadoresReposicao();
    if (typeof configurarModalAjuste === 'function') configurarModalAjuste();

    // Funções Tela: Produtos
    if (typeof configurarOrdenacaoProdutos === 'function') configurarOrdenacaoProdutos();
    if (typeof configurarBuscaProdutos === 'function') configurarBuscaProdutos();

    // Funções Tela: Entregas
    if (typeof aplicarCoresStatusEntregas === 'function') aplicarCoresStatusEntregas();
    if (typeof configurarFiltrosEntregas === 'function') configurarFiltrosEntregas();

});

// #endregion






// #region  

// #endregion