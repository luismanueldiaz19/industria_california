<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Chofer;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class ChoferController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $choferes = Chofer::with('user:id,name,email,username')->get();
        return response()->json($choferes);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users',
            'email' => 'nullable|email|max:255|unique:users',
            'password' => 'nullable|string|min:6',
            'numero_licencia' => 'nullable|string|max:255',
            'tipo_licencia' => 'nullable|string|max:255',
            'vencimiento_licencia' => 'nullable|date',
            'contacto_emergencia' => 'nullable|string|max:255',
            'estado' => 'required|in:activo,inactivo,vacaciones',
        ]);

        try {
            DB::beginTransaction();

            $user = User::create([
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
                'password' => Hash::make($request->password ?: '12345678'), // Default password if empty
            ]);

            // Assign role 'chofer' if it exists in Spatie permissions
            $user->assignRole('chofer');

            $chofer = Chofer::create([
                'user_id' => $user->id,
                'numero_licencia' => $request->numero_licencia,
                'tipo_licencia' => $request->tipo_licencia,
                'vencimiento_licencia' => $request->vencimiento_licencia,
                'contacto_emergencia' => $request->contacto_emergencia,
                'estado' => $request->estado,
            ]);

            DB::commit();

            return response()->json($chofer->load('user'), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al crear chofer', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $chofer = Chofer::with('user')->findOrFail($id);
        return response()->json($chofer);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $chofer = Chofer::with('user')->findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users,username,' . $chofer->user_id,
            'email' => 'nullable|email|max:255|unique:users,email,' . $chofer->user_id,
            'password' => 'nullable|string|min:6',
            'numero_licencia' => 'nullable|string|max:255',
            'tipo_licencia' => 'nullable|string|max:255',
            'vencimiento_licencia' => 'nullable|date',
            'contacto_emergencia' => 'nullable|string|max:255',
            'estado' => 'required|in:activo,inactivo,vacaciones',
        ]);

        try {
            DB::beginTransaction();

            $userData = [
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
            ];
            
            if ($request->filled('password')) {
                $userData['password'] = Hash::make($request->password);
            }

            $chofer->user->update($userData);

            $chofer->update([
                'numero_licencia' => $request->numero_licencia,
                'tipo_licencia' => $request->tipo_licencia,
                'vencimiento_licencia' => $request->vencimiento_licencia,
                'contacto_emergencia' => $request->contacto_emergencia,
                'estado' => $request->estado,
            ]);

            DB::commit();

            return response()->json($chofer->fresh('user'));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al actualizar chofer', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $chofer = Chofer::findOrFail($id);
        try {
            DB::beginTransaction();
            // Optional: delete user as well if chofer is deleted, or just delete chofer.
            // Depending on business logic, we might just soft delete or delete the chofer profile.
            // Let's delete the chofer profile.
            $chofer->delete();
            DB::commit();
            return response()->json(['message' => 'Chofer eliminado correctamente.']);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al eliminar chofer', 'error' => $e->getMessage()], 500);
        }
    }

    public function getChoferesPdfUrl(Request $request)
    {
        $prefix = request()->segment(3) == 'industria-california' ? 'industria-california' : 'ledhouse';
        $routeName = $prefix == 'industria-california' ? 'choferes.pdf' : 'choferes.pdf.legacy';

        $url = \Illuminate\Support\Facades\URL::temporarySignedRoute(
            $routeName,
            now()->addMinutes(60)
        );

        $tokenUrl = \App\Services\PdfSecurityService::generarUrl('choferes', [], null, 60);

        return response()->json(['url' => $tokenUrl]);
    }

    public function generateChoferesPdf(Request $request)
    {
        if (!$request->hasValidSignature()) {
            abort(401, 'Enlace expirado o inválido.');
        }

        $choferes = Chofer::with('user:id,name,email,username')->get();
        
        $pdfService = new \App\Services\PdfSecurityService();
        return $pdfService->generateSecurePdf('pdf.choferes', compact('choferes'), 'reporte_choferes');
    }
}
