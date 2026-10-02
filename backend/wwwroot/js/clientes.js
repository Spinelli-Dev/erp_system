/*
==============================================================================================================================
        TELA: CLIENTES (Pages/Clientes) — a lista e o cadastro são do servidor.
        Aqui fica só o preenchimento do endereço pelo CEP no modal (busca, ordenação, cartões e o modal
        em si estão no main.js).
==============================================================================================================================
*/
document.addEventListener('DOMContentLoaded', () => {
    const inputCep = document.getElementById('cliCEP');
    if (!inputCep) return; // não estamos na tela de clientes

    let ultimoCepConsultado = '';

    inputCep.addEventListener('input', async () => {
        const digitos = inputCep.value.replace(/\D/g, '');
        if (digitos.length !== 8 || digitos === ultimoCepConsultado) return;
        ultimoCepConsultado = digitos;

        const aviso = document.querySelector('.aviso-cep');
        try {
            const endereco = await apiFetch(`/ViaCep/${digitos}`);
            if (ultimoCepConsultado !== digitos) return; // o CEP mudou enquanto consultava
            document.getElementById('cliRua').value = endereco.logradouro || '';
            document.getElementById('cliBairro').value = endereco.bairro || '';
            document.getElementById('cliCidade').value = endereco.localidade || '';
            document.getElementById('cliUF').value = endereco.uf || '';
            if (aviso) aviso.textContent = '→ Rua, Bairro, Cidade e UF autopreenchidos';
            document.getElementById('cliNum').focus();
        } catch (erro) {
            // CEP não encontrado ou ViaCEP fora do ar: o endereço pode ser digitado à mão.
            if (aviso) aviso.textContent = '→ CEP não encontrado: preencha o endereço à mão';
        }
    });
});
