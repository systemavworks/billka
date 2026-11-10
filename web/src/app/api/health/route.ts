export async function GET() {
  return Response.json({
    ok: true,
    service: "billka-web",
    status: "scaffold"
  });
}
