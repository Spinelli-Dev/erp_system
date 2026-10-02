/*
==============================================================================================================================
        TELAS: MEU PERFIL e USUÁRIOS — máscara de telefone (o resto é do servidor)
==============================================================================================================================
*/
function mascararTelefone(input) {
    let d = input.value.replace(/\D/g, '').substring(0, 11);
    if (d.length > 10) d = `(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}`;
    else if (d.length > 6) d = `(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}`;
    else if (d.length > 2) d = `(${d.substring(0, 2)}) ${d.substring(2)}`;
    else if (d.length > 0) d = `(${d}`;
    input.value = d;
}

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.mascara-telefone').forEach(input => {
        input.addEventListener('input', () => mascararTelefone(input));
    });
});
