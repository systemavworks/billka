import "./../styles/globals.css";

export const metadata = {
  title: "Billka",
  description: "QR fiscal, cotejo AEAT y evidencia para empresas y autónomos"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
