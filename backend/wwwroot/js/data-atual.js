function atualizarData() {
    const elementoData = document.getElementById('data-atual');
    if (elementoData) {
        const data = new Date();
        const opcoes = { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
        };
        
        // Formata para o padrão: Segunda-feira, 20 de abril de 2026
        let dataFormatada = data.toLocaleDateString('pt-BR', opcoes);
        
        // Deixa a primeira letra maiúscula (opcional)
        dataFormatada = dataFormatada.charAt(0).toUpperCase() + dataFormatada.slice(1);
        
        elementoData.textContent = dataFormatada;
    }
}

// Chama a função assim que carregar a página
document.addEventListener('DOMContentLoaded', atualizarData);