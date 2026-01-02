//> using scala "3.7.3"

import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.net.URI
import java.nio.file.{Files, Paths}
import java.io.{ByteArrayOutputStream, FileOutputStream}
import java.util.UUID

object BackgroundRemoval:
  case class Config(src: String, dst: String, apiKey: String)

  @main def run(args: String*): Unit =
    val cfg = parseArgs(args.toList)
    val (body, contentType) = buildMultipart(cfg.src)
    val client = HttpClient.newBuilder()
      .followRedirects(HttpClient.Redirect.NEVER) // don't auto-retry a POST
      .build()

    val req = HttpRequest.newBuilder()
      .uri(URI.create("https://api.backgrounderase.net/v2"))
      .header("Content-Type", contentType)
      .header("x-api-key", cfg.apiKey)
      .POST(HttpRequest.BodyPublishers.ofByteArray(body))
      .build()

    val resp = client.send(req, HttpResponse.BodyHandlers.ofByteArray())
    val status = resp.statusCode()
    if status == 200 then
      Files.write(Paths.get(cfg.dst), resp.body())
      println(s"✅ Saved: ${cfg.dst}")
    else
      val errText = new String(resp.body(), "UTF-8")
      System.err.println(s"❌ $status\n$errText")

  private def parseArgs(args: List[String]): Config =
    def usage() =
      System.err.println(
        """
        |Usage:
        |  scala-cli run BackgroundRemoval.scala -- <src> <dst> [--api-key YOUR_API_KEY]
        |
        |Or with env var:
        |  BG_ERASE_API_KEY=YOUR_API_KEY scala-cli run BackgroundRemoval.scala -- <src> <dst>
        |""".stripMargin)
      sys.exit(2)

    var apiKeyOpt: Option[String] = None
    val pos = scala.collection.mutable.ArrayBuffer.empty[String]

    val it = args.iterator
    while it.hasNext do
      it.next() match
        case "--api-key" if it.hasNext => apiKeyOpt = Some(it.next())
        case v                         => pos += v

    if pos.length != 2 then usage()
    val apiKey = apiKeyOpt
      .orElse(sys.env.get("BG_ERASE_API_KEY"))
      .getOrElse {
        System.err.println("Missing API key. Provide --api-key or BG_ERASE_API_KEY.")
        sys.exit(2)
      }

    Config(pos(0), pos(1), apiKey)

  private def buildMultipart(src: String): (Array[Byte], String) =
    val filePath = Paths.get(src)
    if !Files.exists(filePath) then
      System.err.println(s"❌ File not found: $src"); sys.exit(1)

    val boundary = "----" + UUID.randomUUID().toString.replace("-", "")
    val CRLF = "\r\n"
    val fileName = filePath.getFileName.toString
    val mimeType = Option(Files.probeContentType(filePath)).getOrElse("application/octet-stream")

    val header =
      s"--$boundary$CRLF" +
      s"""Content-Disposition: form-data; name="image_file"; filename="$fileName"$CRLF""" +
      s"Content-Type: $mimeType$CRLF$CRLF"
    val footer = s"$CRLF--$boundary--$CRLF"

    val baos = new ByteArrayOutputStream()
    baos.write(header.getBytes("UTF-8"))
    baos.write(Files.readAllBytes(filePath))
    baos.write(footer.getBytes("UTF-8"))
    (baos.toByteArray, s"multipart/form-data; boundary=$boundary")
