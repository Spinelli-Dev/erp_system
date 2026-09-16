Chart.register(ChartDataLabels);

document.addEventListener('DOMContentLoaded', function() {

    const isMobile = () => window.innerWidth < 768;

    const fontLinha = { family: 'Inter', size: 13, weight: 600 };
    const fontBarra = { family: 'Inter', size: 10, weight: 400 };
    const fontProdX = { family: 'Inter', size: 11, weight: 600 };
    
    const produtosBase = [
        "Sofioli Brócolis", "Conchiglione", "Molho Branco", "Lasanha", 
        "Canelone 4Q", "Nhoque Batata", "Queijo Ralado", "Nhoque Mussarela", 
        "Sofioli Frango", "Canelone P&Q", "Pão de Queijo", "Nhoque Batata"
    ];

    // ==========================================
    // 1. BANCO DE DADOS SIMULADO
    // ==========================================
    const dadosSimulados = {
        'Mês': { 
            labelsTempo: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
            receitaTempo: [18, 15, 20, 16, 22, 13, 23, 21, 19, 24, 25, 30],
            lucroTempo: [4, 3.5, 4.5, 3.8, 5, 3.2, 5.2, 4.8, 4.3, 5.5, 6, 7.2],
            receitaProd: [18, 15, 20, 16, 22, 13, 23, 21, 19, 24, 25, 30],
            qtdProd: [125, 101, 152, 117, 174, 92, 196, 155, 119, 210, 219, 248]
        },
        'Dia do Mês': {
            labelsTempo: ['01/Mai', '05/Mai', '10/Mai', '15/Mai', '20/Mai', '25/Mai', '30/Mai'],
            receitaTempo: [12, 18, 14, 25, 19, 22, 28],
            lucroTempo: [3, 4.5, 3.2, 6, 4.8, 5.2, 7],
            receitaProd: [10, 8, 12, 9, 14, 7, 15, 11, 8, 16, 18, 20],
            qtdProd: [80, 65, 90, 75, 110, 50, 120, 85, 60, 130, 145, 160]
        },
        'Semana': {
            labelsTempo: ['Semana 1', 'Semana 2', 'Semana 3', 'Semana 4'],
            receitaTempo: [20, 18, 25, 29],
            lucroTempo: [5, 4.2, 6.1, 7.5],
            receitaProd: [15, 12, 18, 14, 20, 10, 22, 17, 13, 25, 28, 32],
            qtdProd: [100, 85, 130, 95, 150, 70, 180, 140, 90, 190, 200, 220]
        },
        'Ano': {
            labelsTempo: ['2023', '2024', '2025', '2026'],
            receitaTempo: [22, 24, 28, 30],
            lucroTempo: [5.5, 6.2, 6.8, 7.8],
            receitaProd: [25, 20, 28, 22, 30, 18, 32, 29, 26, 35, 38, 42],
            qtdProd: [180, 150, 210, 170, 230, 130, 250, 220, 190, 280, 310, 350]
        }
    };

    // ==========================================
    // 2. INICIALIZAÇÃO DOS GRÁFICOS
    // ==========================================
    
    const ctxFaturamento = document.getElementById('chartFaturamento').getContext('2d');
    let graficoFat = new Chart(ctxFaturamento, {
        type: 'bar',
        data: {
            labels: dadosSimulados['Mês'].labelsTempo,
            datasets: [
                {
                    type: 'line', label: 'Receita Bruta', data: dadosSimulados['Mês'].receitaTempo,
                    borderColor: '#9A1006', borderWidth: 2, tension: 0.3, pointRadius: 4, pointBackgroundColor: '#9A1006',
                    yAxisID: 'yLinha',
                    datalabels: { color: '#9A1006', font: fontLinha, align: 'top', anchor: 'end', offset: 4, formatter: (val) => isMobile() ? val + 'k' : 'R$ ' + val + 'k' }
                },
                {
                    type: 'bar', label: 'Lucro Líquido', data: dadosSimulados['Mês'].lucroTempo,
                    backgroundColor: 'rgba(154, 16, 6, 0.25)', borderRadius: 4, barPercentage: 0.6,
                    yAxisID: 'yBarra',
                    datalabels: { color: '#4B5663', font: fontBarra, align: 'end', anchor: 'end', formatter: (val) => isMobile() ? val + 'k' : 'R$ ' + val + 'k' }
                }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false, layout: { padding: { top: isMobile() ? 25 : 10 } },
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 12 }, maxRotation: isMobile() ? 90 : 0, minRotation: isMobile() ? 90 : 0 } },
                // SUAVIZADO: Limites mais justos para a proporção do Card 1
                yBarra: { type: 'linear', display: false, position: 'left', min: 0, max: isMobile() ? 20 : 15 },
                yLinha: { type: 'linear', display: false, position: 'right', min: isMobile() ? -5 : 0, max: isMobile() ? 38 : 35 }
            }
        }
    });

    const ctxProdutos = document.getElementById('chartProdutos').getContext('2d');
    let graficoProd = new Chart(ctxProdutos, {
        type: 'bar',
        data: {
            labels: produtosBase, 
            datasets: [
                {
                    type: 'line', label: 'Faturamento', data: dadosSimulados['Mês'].receitaProd,
                    borderColor: '#9A1006', borderWidth: 2, tension: 0.3, pointRadius: 4, pointBackgroundColor: '#9A1006',
                    yAxisID: 'yLinha',
                    datalabels: { color: '#9A1006', font: fontLinha, align: 'top', anchor: 'end', formatter: (val) => isMobile() ? val + 'k' : 'R$ ' + val + 'k' }
                },
                {
                    type: 'bar', label: 'Quantidade', data: dadosSimulados['Mês'].qtdProd,
                    backgroundColor: 'rgba(154, 16, 6, 0.25)', borderRadius: 4, barPercentage: 0.6,
                    yAxisID: 'yBarra',
                    datalabels: { color: '#4B5663', font: fontBarra, align: 'end', anchor: 'end' }
                }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false, layout: { padding: { top: isMobile() ? 25 : 10 } },
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { display: false }, ticks: { color: '#9A1006', font: fontProdX, maxRotation: isMobile() ? 90 : 45, minRotation: isMobile() ? 90 : 45 } },
                // Distanciamento do Card 2 
                yBarra: { type: 'linear', display: false, position: 'left', min: 0, max: isMobile() ? 1000 : 700 }, 
                yLinha: { type: 'linear', display: false, position: 'right', min: isMobile() ? -30 : -20, max: isMobile() ? 65 : 55 } 
            }
        }
    });

    // ==========================================
    // 3. LÓGICA DE INTERAÇÃO DOS BOTÕES
    // ==========================================
    const botoesFiltro = document.querySelectorAll('.btn-filtro-evo');
    
    botoesFiltro.forEach(botao => {
        botao.addEventListener('click', function() {
            botoesFiltro.forEach(b => b.classList.remove('active'));
            this.classList.add('active');

            const periodoSelecionado = this.innerText.trim();
            const novosDados = dadosSimulados[periodoSelecionado];

            graficoFat.data.labels = novosDados.labelsTempo;
            graficoFat.data.datasets[0].data = novosDados.receitaTempo;
            graficoFat.data.datasets[1].data = novosDados.lucroTempo;
            graficoFat.update();

            graficoProd.data.datasets[0].data = novosDados.receitaProd;
            graficoProd.data.datasets[1].data = novosDados.qtdProd;
            graficoProd.update();
        });
    });
});