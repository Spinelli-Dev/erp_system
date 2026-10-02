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
        const termoBusca = normalizarBusca(buscaInput.value);
        const mesSelecionado = filtroMes.value; 
        const anoSelecionado = filtroAno.value; 
        const produtoSelecionado = filtroProduto.value.toLowerCase();
        const statusSelecionado = filtroStatus.value.toLowerCase(); 

        // 1. Filtrar Tabela (Desktop)
        const linhas = document.querySelectorAll('.tabela-produtos tbody tr');
        
        linhas.forEach(linha => {
            if(linha.cells.length < 13) return; 

            // Textos para buscar no input livre (Nome e Telefone)
            const nomeTel = normalizarBusca(linha.cells[1].textContent + " " + linha.cells[2].textContent);
            
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
            const textoCard = normalizarBusca(card.textContent);
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

    // 1. Catálogo de produtos: vem pronto na página (Pages/Vendas), sem chamar a API.
    const bancoDeProdutos = window.CONSUMO_PRODUTOS || [];
    const campoProdutoId = document.getElementById('inputConsumoProdutoId');

    // 2. Evento disparado a cada tecla digitada
    buscaInput.addEventListener('input', function() {
        const termo = normalizarBusca(this.value);
        dropdown.innerHTML = ''; // Limpa a lista
        limparCamposConsumo(); // digitou de novo: o produto escolhido deixa de valer

        if (termo === '') {
            dropdown.classList.add('d-none');
            return;
        }

        // Filtra os produtos
        const filtrados = bancoDeProdutos.filter(p => normalizarBusca(p.nome + ' ' + p.sabor).includes(termo));

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
                spanDetalhes.textContent = `${produto.peso} • Custo: ${produto.custo} • ${produto.estoque} em estoque`;

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

    // 5. Preencher campos automáticos (o Id vai para o servidor; o resto é só leitura)
    function selecionarProduto(produto, tituloCompleto) {
        campoProdutoId.value = produto.id;
        document.getElementById('inputConsumoNome').value = produto.nome;
        document.getElementById('inputConsumoSabor').value = produto.sabor === 'Tradicional' || produto.sabor === '' ? '—' : produto.sabor;
        document.getElementById('inputConsumoPeso').value = produto.peso;
        document.getElementById('inputConsumoQtd').max = produto.estoque;

        buscaInput.value = tituloCompleto; // Fixa o nome na barra de busca
        dropdown.classList.add('d-none'); // Fecha a lista
    }

    function limparCamposConsumo() {
        campoProdutoId.value = '0';
        document.getElementById('inputConsumoNome').value = '';
        document.getElementById('inputConsumoSabor').value = '';
        document.getElementById('inputConsumoPeso').value = '';
        document.getElementById('inputConsumoQtd').removeAttribute('max');
    }

    // 6. Resetar o modal ao abrir pelo botão (quando o servidor reabre após erro, mantém a mensagem)
    const modalElement = document.getElementById('modalConsumoProprio');
    modalElement.addEventListener('show.bs.modal', (event) => {
        if (!event.relatedTarget) return;
        document.getElementById('formConsumoProprio').reset();
        limparCamposConsumo();
        dropdown.classList.add('d-none');
        const erro = document.getElementById('erroConsumo');
        if (erro) erro.remove();
    });

    if (window.REABRIR_MODAL_CONSUMO) bootstrap.Modal.getOrCreateInstance(modalElement).show();

    // 7. Salvar: precisa ter escolhido um produto na lista
    document.getElementById('formConsumoProprio').addEventListener('submit', (e) => {
        if (campoProdutoId.value === '0') {
            e.preventDefault();
            buscaInput.focus();
            buscaInput.setCustomValidity('Escolha o produto na lista');
            buscaInput.reportValidity();
            setTimeout(() => buscaInput.setCustomValidity(''), 2000);
            return;
        }
        const botao = document.getElementById('btnSalvarConsumo');
        botao.disabled = true;
        botao.textContent = 'Salvando...';
    });
}
// #endregion

// #region - Abrir Venda para Edição a partir da Tabela/Cards
// O servidor carrega a venda (Pages/AlterarVenda) — nada passa pelo localStorage.
function editarVenda(idVenda) {
    window.location.href = `/AlterarVenda/${idVenda}`;
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
        const termo = inputBusca ? normalizarBusca(inputBusca.value) : '';
        let visiveis = 0;

        // Filtro Tabela Desktop
        const linhas = document.querySelectorAll('.tabela-clientes tbody .linha-cliente');
        linhas.forEach(linha => {
            const textoLinha = normalizarBusca(linha.textContent);
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
            const textoCard = normalizarBusca(card.textContent);
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
                icone.src = '/assets/icons/icone-esconder.svg';
            } else {
                areaOculta.classList.add('d-none');
                icone.src = '/assets/icons/icone-ver.svg';
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
// O formulário grava no servidor (Pages/Clientes). Os dados de cada cliente vêm nos atributos data-* do
// botão de editar — inclusive o Id, que diz ao servidor se é cadastro novo (0) ou alteração.
function configurarBotoesModalCliente() {
    const modalElement = document.getElementById('modalCliente');

    // A MÁGICA DA SEGURANÇA: Se o modal não existir nesta página, pare a função aqui e não trave o resto!
    if (!modalElement) return;

    const modalInstance = bootstrap.Modal.getOrCreateInstance(modalElement);
    const tituloModal = document.getElementById('modalClienteLabel');
    const form = document.getElementById('formCliente');
    const campos = {
        id: 'cliId', nome: 'cliNome', tel: 'cliTel', cep: 'cliCEP', rua: 'cliRua', num: 'cliNum',
        bairro: 'cliBairro', cidade: 'cliCidade', uf: 'cliUF', comp: 'cliComp', obs: 'cliObs'
    };

    function abrir(dados, titulo) {
        Object.entries(campos).forEach(([chave, id]) => { document.getElementById(id).value = dados[chave] || ''; });
        if (!dados.id) document.getElementById('cliId').value = '0';
        const erros = document.getElementById('errosCliente');
        if (erros) erros.remove(); // erros eram do envio anterior
        tituloModal.textContent = titulo;
        modalInstance.show();
    }

    const btnNovo = document.querySelector('.btn-novo');
    if (btnNovo) btnNovo.addEventListener('click', () => abrir({}, 'Cadastrar Cliente'));

    document.querySelectorAll('.btn-editar-cliente').forEach(btn => {
        btn.addEventListener('click', () => abrir(btn.dataset, 'Editar Cadastro'));
    });

    // O servidor recusou o envio: reabre o modal com o que foi digitado e as mensagens.
    if (window.REABRIR_MODAL_CLIENTE) {
        tituloModal.textContent = document.getElementById('cliId').value !== '0' ? 'Editar Cadastro' : 'Cadastrar Cliente';
        modalInstance.show();
    }

    // Evita cadastrar o mesmo cliente duas vezes num clique duplo.
    form.addEventListener('submit', () => {
        const botao = document.getElementById('btnSalvarCliente');
        botao.disabled = true;
        botao.textContent = 'Salvando...';
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
        const termoBusca = normalizarBusca(buscaInput.value);
        const tipoSelecionado = filtroTipo.value.toLowerCase();
        const statusSelecionado = filtroStatus.value.toLowerCase(); // "ok", "baixo", "crítico", "encerrado"

        // Filtrar Tabela
        const linhas = document.querySelectorAll('.tabela-estoque tbody tr');
        linhas.forEach(linha => {
            const produtoSabor = normalizarBusca(linha.cells[1].textContent + " " + linha.cells[2].textContent);
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
            const produtoSabor = normalizarBusca(card.querySelector('.card-prod-left').textContent);
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

// #region - CONTADORES DO MODAL REPOSIÇÃO
// Cada contador atualiza também o campo oculto que vai para o servidor (Pages/Estoque, handler Reposicao).
function configurarContadoresReposicao() {
    // Trava de segurança: Se não existir nenhum botão de 'menos' na página, ele para a função aqui.
    if (document.querySelectorAll('.btn-menos').length === 0) return;

    function definirQuantidade(btn, delta) {
        const wrapper = btn.closest('.contador-wrapper');
        const spanQtd = wrapper.querySelector('.qtd-contador');
        const nova = Math.max(0, parseInt(spanQtd.textContent, 10) + delta); // Não permite reposição negativa
        spanQtd.textContent = nova;
        const campo = wrapper.querySelector('.qtd-reposicao');
        if (campo) campo.value = nova;
    }

    document.querySelectorAll('.btn-menos').forEach(btn => btn.addEventListener('click', (e) => {
        e.preventDefault();
        definirQuantidade(btn, -1);
    }));
    document.querySelectorAll('.btn-mais').forEach(btn => btn.addEventListener('click', (e) => {
        e.preventDefault();
        definirQuantidade(btn, 1);
    }));

    const form = document.getElementById('formReposicao');
    if (form) form.addEventListener('submit', () => {
        const botao = document.getElementById('btnSalvarReposicao');
        botao.disabled = true;
        botao.textContent = 'Salvando...';
    });
}
// #endregion

// #region - PREENCHIMENTO DO MODAL AJUSTE
// Os dados vêm nos atributos data-* do botão de editar (inclusive o Id do produto, enviado ao servidor).
function configurarModalAjuste() {
    const modalAjusteElement = document.getElementById('modalAjuste');
    if (!modalAjusteElement) return;

    modalAjusteElement.addEventListener('show.bs.modal', function (event) {
        const dados = event.relatedTarget ? event.relatedTarget.dataset : null;
        if (!dados) return;

        document.getElementById('inputAjusteProdutoId').value = dados.produtoId;
        document.getElementById('ajusteNome').innerHTML = `<strong>${escapeHtml(dados.nome)}</strong>`;
        document.getElementById('ajusteSabor').textContent = dados.sabor ? dados.sabor : 'Tradicional / Sem sabor';
        document.getElementById('ajustePeso').textContent = dados.peso;
        document.getElementById('inputAjusteQtd').value = dados.qtd;
    });

    const form = document.getElementById('formAjuste');
    if (form) form.addEventListener('submit', () => {
        const botao = document.getElementById('btnSalvarAjuste');
        botao.disabled = true;
        botao.textContent = 'Salvando...';
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
        const termo = normalizarBusca(this.value);

        // 1. FILTRAR A TABELA (DESKTOP)
        const linhasTabela = document.querySelectorAll('.tabela-produtos tbody tr');
        linhasTabela.forEach(linha => {
            // Pega o texto da coluna Produto (índice 1) e Sabor (índice 2)
            const produto = normalizarBusca(linha.cells[1].textContent);
            const sabor = normalizarBusca(linha.cells[2].textContent);
            
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
            const produto = normalizarBusca(card.querySelector('.m-prod').textContent);
            const sabor = normalizarBusca(card.querySelector('.m-sabor').textContent);
            
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
// O formulário grava no servidor (Pages/Produtos). Os dados de cada produto vêm nos atributos data-* do
// botão de editar, inclusive o Id. Na alteração, o estoque só aparece: muda na tela de Estoque (com motivo).
function configurarModalProduto() {
    const modalProdutoElement = document.getElementById('modalProduto');
    if (!modalProdutoElement) return;

    const campos = {
        id: 'inputId', nome: 'inputNome', sabor: 'inputSabor', peso: 'inputPeso', custo: 'inputCusto',
        preco: 'inputPreco', estoque: 'inputEstoque', tipo: 'inputTipo', obs: 'inputObs'
    };

    modalProdutoElement.addEventListener('show.bs.modal', function (event) {
        // event.relatedTarget é o botão que abriu o modal (vazio quando o servidor reabre após erro)
        const botaoClicado = event.relatedTarget;
        if (!botaoClicado) return;

        const editando = botaoClicado.classList.contains('btn-editar-produto');
        const dados = editando ? botaoClicado.dataset : { id: '0' };

        Object.entries(campos).forEach(([chave, id]) => { document.getElementById(id).value = dados[chave] || ''; });
        const estoque = document.getElementById('inputEstoque');
        estoque.readOnly = editando;
        estoque.required = !editando;
        estoque.title = editando ? 'Para mudar o estoque, use a tela de Estoque' : '';

        const erros = document.getElementById('errosProduto');
        if (erros) erros.remove(); // erros eram do envio anterior
        document.getElementById('tituloModalProduto').textContent = editando ? 'Alterar Produto' : 'Cadastrar Produto';
    });

    // O servidor recusou o envio: reabre o modal com o que foi digitado e as mensagens.
    if (window.REABRIR_MODAL_PRODUTO) {
        const editando = document.getElementById('inputId').value !== '0';
        document.getElementById('inputEstoque').readOnly = editando;
        document.getElementById('tituloModalProduto').textContent = editando ? 'Alterar Produto' : 'Cadastrar Produto';
        bootstrap.Modal.getOrCreateInstance(modalProdutoElement).show();
    }

    // Evita cadastrar o mesmo produto duas vezes num clique duplo.
    document.getElementById('formProduto').addEventListener('submit', () => {
        const botao = document.getElementById('btnSalvarProduto');
        botao.disabled = true;
        botao.textContent = 'Salvando...';
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
        const termoBusca = normalizarBusca(buscaInput.value);
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
            const textoLinha = normalizarBusca(linha.textContent);
            
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
            const textoCard = normalizarBusca(card.textContent);
            
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