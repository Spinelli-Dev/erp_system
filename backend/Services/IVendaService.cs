// Contrato do VendaService — alinhado ao diagrama UML.
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;

namespace MaxiMassasAPI.Services;

public interface IVendaService
{
    Task<IEnumerable<VendaResponse>> GetAllAsync();
    Task<VendaResponse?> GetByIdAsync(int id);
    /// <summary>Cria venda, reduz estoque e registra movimentações. UML regras 8 e 9.</summary>
    Task<VendaResponse> CreateAsync(VendaRequest request, int usuarioId);
    /// <summary>Atualiza Status da Venda e StatusPagamento do Pagamento de forma independente.</summary>
    Task<VendaResponse?> UpdateAsync(int id, VendaUpdateRequest request);
    Task<bool> DeleteAsync(int id);
}
