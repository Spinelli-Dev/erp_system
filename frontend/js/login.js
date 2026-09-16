// 1. Limpa o campo de e-mail e senha assim que a página carrega
document.addEventListener('DOMContentLoaded', function() {
    
    // Verificamos se estamos realmente na tela de login antes de agir
    // Isso evita erros caso o script seja carregado em outras páginas
    const emailInput = document.getElementById('email');
    const senhaInput = document.getElementById('senha');

    if (emailInput && senhaInput) {
        // Se os campos existem, nós os limpamos
        emailInput.value = '';
        senhaInput.value = '';
        console.log("Sistema de Login Inicializado: Campos limpos.");
    }
});

/**
 * Alterna a visibilidade da senha e troca o ícone do olhinho
 */
function alternarSenha() {
    const inputSenha = document.getElementById('senha');
    const iconeSenha = document.getElementById('icone-senha');

    // Verificação de segurança para garantir que os elementos existem
    if (!inputSenha || !iconeSenha) return;

    if (inputSenha.type === 'password') {
        inputSenha.type = 'text';
        iconeSenha.src = '../frontend/assets/icons/icone-esconder.svg';
    } else {
        inputSenha.type = 'password';
        iconeSenha.src = '../frontend/assets/icons/icone-ver.svg';
    }
}

/**
 * Simulação de validação de acesso
 */
function realizarLogin() {
    const email = document.getElementById('email')?.value;
    const senha = document.getElementById('senha')?.value;
    const divErro = document.getElementById('mensagem-erro');

    // Credenciais de teste
    const emailCorreto = 'admin@maximassas.com.br';
    const senhaCorreta = 'senhapim';

    if (email === emailCorreto && senha === senhaCorreta) {
        if (divErro) divErro.classList.add('d-none');
        
        // Feedback visual antes de redirecionar (opcional, mas legal)
        console.log("Acesso concedido! Redirecionando...");
        window.location.href = '../frontend/pages/dashboard.html'; 
    } else {
        if (divErro) {
            divErro.classList.remove('d-none');
            
            // Auto-ocultar a mensagem de erro
            setTimeout(() => {
                divErro.classList.add('d-none');
            }, 3500);
        }
    }
}
