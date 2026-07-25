import csv

INPUT_FILE = "origin.csv"
OUTPUT_FILE = "output.html"
COLUMNS = 3

with open(INPUT_FILE, "r", encoding="utf-8", newline="") as csvfile:
    reader = csv.DictReader(csvfile)
    items = list(reader)

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write("<table>\n")

    for index, item in enumerate(items):
        if index % COLUMNS == 0:
            f.write("<tr>\n")

        f.write(
f"""<td width="33.3%" align="center">

**{item["Name"]}**

[<img src="{item["Image URL"]}" width="220"/>]({item["Video URL"]})

[Get Code]({item["Code URL"]})

</td>

"""
        )

        if index % COLUMNS == COLUMNS - 1:
            f.write("</tr>\n\n")

    # Cierra la última fila si quedó incompleta
    remainder = len(items) % COLUMNS
    if remainder != 0:
        for _ in range(COLUMNS - remainder):
            f.write('<td width="33.3%"></td>\n')
        f.write("</tr>\n")

    f.write("</table>\n")

print(f"Generated '{OUTPUT_FILE}' successfully.")