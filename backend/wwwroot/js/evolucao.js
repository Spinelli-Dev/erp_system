/*
==============================================================================================================================
        TELA: EVOLUÇÃO (Pages/Evolucao) — as séries de cada período vêm calculadas do servidor em window.EVOLUCAO_DADOS;
        aqui só se desenha com Chart.js (mesma aparência de antes).
==============================================================================================================================
*/
Chart.register(ChartDataLabels);

let graficoFat, graficoProd;

document.addEventListener('DOMContentLoaded', function () {
    const canvasFat = document.getElementById('chartFaturamento');
    const canvasProd = document.getElementById('chartProdutos');
    if (!canvasFat || !canvasProd) return;

    const isMobile = () => window.innerWidth < 768;
    const fontLinha = { family: 'Inter', size: 13, weight: 600 };
    const fontBarra = { family: 'Inter', size: 10, weight: 400 };
    const fontProdX = { family: 'Inter', size: 11, weight: 600 };

    graficoFat = new Chart(canvasFat.getContext('2d'), {
        type: 'bar',
        data: {
            labels: [],
            datasets: [
                {
                    type: 'line', label: 'Receita Bruta', data: [],
                    borderColor: '#9A1006', borderWidth: 2, tension: 0.3, pointRadius: 4, pointBackgroundColor: '#9A1006',
                    yAxisID: 'yLinha',
                    datalabels: { color: '#9A1006', font: fontLinha, align: 'top', anchor: 'end', offset: 4, formatter: (val) => isMobile() ? `${val}k` : `R$ ${val}k` }
                },
                {
                    type: 'bar', label: 'Lucro Líquido', data: [],
                    backgroundColor: 'rgba(154, 16, 6, 0.25)', borderRadius: 4, barPercentage: 0.6,
                    yAxisID: 'yBarra',
                    datalabels: { color: '#4B5663', font: fontBarra, align: 'end', anchor: 'end', formatter: (val) => isMobile() ? `${val}k` : `R$ ${val}k` }
                }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false, layout: { padding: { top: isMobile() ? 25 : 10 } },
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 12 }, maxRotation: isMobile() ? 90 : 0, minRotation: isMobile() ? 90 : 0 } },
                yBarra: { type: 'linear', display: false, position: 'left', beginAtZero: true },
                yLinha: { type: 'linear', display: false, position: 'right', beginAtZero: true }
            }
        }
    });

    graficoProd = new Chart(canvasProd.getContext('2d'), {
        type: 'bar',
        data: {
            labels: [],
            datasets: [
                {
                    type: 'line', label: 'Faturamento', data: [],
                    borderColor: '#9A1006', borderWidth: 2, tension: 0.3, pointRadius: 4, pointBackgroundColor: '#9A1006',
                    yAxisID: 'yLinha',
                    datalabels: { color: '#9A1006', font: fontLinha, align: 'top', anchor: 'end', formatter: (val) => isMobile() ? `${val}k` : `R$ ${val}k` }
                },
                {
                    type: 'bar', label: 'Quantidade', data: [],
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
                yBarra: { type: 'linear', display: false, position: 'left', beginAtZero: true },
                yLinha: { type: 'linear', display: false, position: 'right', beginAtZero: true }
            }
        }
    });

    atualizarGraficosEvolucao('Mês');

    document.querySelectorAll('.btn-filtro-evo').forEach(botao => {
        botao.addEventListener('click', function () {
            document.querySelectorAll('.btn-filtro-evo').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            atualizarGraficosEvolucao(this.textContent.trim());
        });
    });
});

function arredondarMilEvolucao(valor) {
    return Math.round((valor / 1000) * 10) / 10;
}

function atualizarGraficosEvolucao(periodo) {
    const dados = (window.EVOLUCAO_DADOS || {})[periodo] || { labels: [], receita: [], lucro: [], produtos: [] };

    graficoFat.data.labels = dados.labels;
    graficoFat.data.datasets[0].data = dados.receita.map(arredondarMilEvolucao);
    graficoFat.data.datasets[1].data = dados.lucro.map(arredondarMilEvolucao);
    graficoFat.update();

    graficoProd.data.labels = dados.produtos.map(p => p.nome);
    graficoProd.data.datasets[0].data = dados.produtos.map(p => arredondarMilEvolucao(p.faturado));
    graficoProd.data.datasets[1].data = dados.produtos.map(p => p.quantidade);
    graficoProd.update();
}
