# 🧠 Git: Chuleta de comandos esenciales

## 🔄 Inicializar repositorio (si no existe)
```bash
git init
```

---

## 🔍 Ver estado de los archivos
```bash
git status
```

---

## 📦 Agregar archivos al área de staging
```bash
git add nombre_archivo.txt
# o para todos:
git add .
```

---

## ✅ Hacer commit
```bash
git commit -m "Tu mensaje claro y conciso"
```

---

## 🔼 Enviar los cambios a GitHub
```bash
git push
```

---

## 🔽 Traer los últimos cambios de GitHub
```bash
git pull
```

---

## 🌿 Ver ramas
```bash
git branch
```

---

## 🌱 Crear una nueva rama
```bash
git checkout -b nombre_de_rama
```

---

## 🔄 Cambiar de rama
```bash
git checkout main
```

---

## 🔀 Combinar ramas (merge)
```bash
git checkout main
git merge nombre_de_rama
```

---

## 🧨 Borrar una rama
```bash
git branch -d nombre_de_rama
```

---

## 🕵️ Ver historial de commits
```bash
git log --oneline --graph --decorate --all
```

---

## 📌 Ver último commit en un archivo
```bash
git log nombre_archivo.txt
```

---

## 🧹 Limpiar archivos no trackeados
```bash
git clean -fd
```

---

¡Y listo! Con esto tenés el 90% de Git dominado como un pro ninja 🥷
