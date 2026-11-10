export default function HomePage() {
  return (
    <main style={{ padding: 32, fontFamily: "system-ui", background: "#0b0f14", color: "#fff", minHeight: "100vh" }}>
      <img src="/logo_billka.jpeg" alt="Billka" style={{ width: 96, height: 96, borderRadius: 16, objectFit: "cover" }} />
      <h1>Billka</h1>
      <p>QR fiscal, cotejo AEAT y evidencia criptográfica para empresas y autónomos.</p>
      <p style={{ color: "#9ca3af" }}>
        Scaffold inicial. Emisión fiscal desactivada hasta cerrar integración SIF/proveedor.
      </p>
    </main>
  );
}
