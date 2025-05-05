# Lire un fichier SVG existant
with open("/var/log/sys_info/svg/total_procs.svg", "r", encoding="utf-8") as svg_file:
    svg_content = svg_file.read()

# Créer une page HTML avec le SVG inline
html_page = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Graphique SVG intégré</title>
</head>
<body>
    <h1>Mon graphique SVG en dur</h1>
    {svg_content}
</body>
</html>
"""

# Écrire le HTML dans un fichier
with open("page_svg_inline.html", "w", encoding="utf-8") as html_file:
    html_file.write(html_page)
