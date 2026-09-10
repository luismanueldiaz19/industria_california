<style>
    .pdf-header {
        width: 100%;
        border-bottom: 2px solid #e2e8f0;
        padding-bottom: 15px;
        margin-bottom: 25px;
        display: table;
    }
    .header-logo {
        display: table-cell;
        width: 25%;
        vertical-align: middle;
    }
    .header-logo img {
        max-width: 140px;
        max-height: 70px;
    }
    .header-company-info {
        display: table-cell;
        width: 45%;
        vertical-align: middle;
        text-align: center;
        line-height: 1.3;
    }
    .header-company-info h1 {
        margin: 0;
        font-size: 16px;
        color: #0f172a;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    .header-company-info p {
        margin: 2px 0 0 0;
        font-size: 9px;
        color: #64748b;
    }
    .header-meta {
        display: table-cell;
        width: 30%;
        vertical-align: middle;
        text-align: right;
        font-size: 9px;
        color: #64748b;
        line-height: 1.4;
    }
    .header-meta .doc-title {
        font-size: 14px;
        font-weight: bold;
        color: #0f172a;
        text-transform: uppercase;
        margin-bottom: 4px;
    }
    .header-meta .doc-subtitle {
        font-size: 10px;
        color: #3b82f6;
        margin-bottom: 8px;
    }
    .header-meta strong {
        color: #334155;
    }
</style>

<div class="pdf-header">
    <div class="header-logo">
        @php $imagePath = public_path('logo_california.png'); @endphp
        @if(file_exists($imagePath)) 
            <img src="{{ $imagePath }}" alt="Logo Empresa"> 
        @else
            <h2 style="margin:0; color:#0f172a;">INDUSTRIA CALIFORNIA</h2>
        @endif
    </div>
    <div class="header-company-info">
        <h1>Industria California, SRL</h1>
        <p>RNC: 132839935</p>
        <p>Calle 16 Agosto, #91, Moca, Rep. Dom.</p>
        <p>Tel: +1 829-477-8000 | Cel: +1 (809) xxx-xxxx</p>
        <div style="margin-top: 4px;">
            <span style="display: inline-block; background-color: #fef3c7; color: #b45309; border: 1px solid #f59e0b; padding: 1px 7px; border-radius: 3px; font-size: 8px; font-weight: bold; letter-spacing: 0.6px;">
                VERSIÓN DEMO — DOCUMENTO DE EVALUACIÓN
            </span>
        </div>
    </div>
    <div class="header-meta">
        <div class="doc-title">{{ $title ?? 'Documento' }} <span style="color: #d97706; font-size: 10px; font-weight: bold;">(DEMO)</span></div>
        @if(isset($subtitle) && $subtitle != '')
            <div class="doc-subtitle">{{ $subtitle }}</div>
        @endif
        <strong>Generado:</strong> {{ \Carbon\Carbon::now()->subHours(4)->format('d/m/Y') }}<br>
        <strong>Usuario:</strong> {{ request()->user() ? request()->user()->name : 'Sistema' }}
    </div>
</div>
