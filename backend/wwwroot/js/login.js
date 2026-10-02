/**
 * Tela de login do painel (Pages/Login.cshtml). A autenticação é feita pelo servidor
 * (formulário com POST); aqui fica só o "olhinho" de mostrar/esconder a senha.
 */
function alternarSenha() {
    const inputSenha = document.getElementById('senha');
    const iconeSenha = document.getElementById('icone-senha');

    if (!inputSenha || !iconeSenha) return;

    const mostrar = inputSenha.type === 'password';
    inputSenha.type = mostrar ? 'text' : 'password';
    iconeSenha.src = mostrar ? '/assets/icons/icone-esconder.svg' : '/assets/icons/icone-ver.svg';
    iconeSenha.alt = mostrar ? 'Esconder senha' : 'Ver senha';
}
