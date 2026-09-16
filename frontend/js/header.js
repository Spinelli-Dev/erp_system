function carregarMenu() {
    fetch('../pages/header.html')
        .then(response => response.text())
        .then(data => {
            document.getElementById('header-placeholder').innerHTML = data;
        })
        .catch(error => console.error('Erro ao carregar o menu:', error));
}

window.onload = carregarMenu;