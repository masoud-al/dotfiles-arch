lsmod | awk 'BEGIN{print "digraph{"}{split($4, a, ","); for (i in a) print $1, "->", a[i]}END{print "}"}'|display

