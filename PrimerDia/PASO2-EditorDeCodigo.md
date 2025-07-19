# Manual Rápido: Uso de Editores (VS Code / Cursor / Trae) con `GDI-PRODUCTO`

## Objetivo

Ya TENÉS la carpeta local sincronizada (`GDI-PRODUCTO`). Ahora aprenderás a **abrir, editar y actualizar** el repo usando **VS Code**, **Cursor** o un IDE web tipo **Trae**. Mismo flujo Git, distinto entorno.

---

## 1. Estructura Mental Ultra Corta

1. **Abrir editor** sobre la carpeta.
2. **Actualizar** (pull) antes de tocar nada.
3. **Editar / Guardar**.
4. **Agregar + Commit + Push**.
5. Repetir.

> Fórmula: *Pull → Cambios → Add → Commit → Push*.

---

## Cursor (Desktop + IA)

> Igual que VS Code, pero con ayuda de IA.

### Abrir

1. Abrí **Cursor**.
2. `Open...` → seleccionar carpeta `GDI-PRODUCTO`.

### Actualizar

```bash
gdi   # o
git pull --rebase origin main
```

### Usar IA (opcional)

Seleccionás código → tecla de comando IA (según config) → pedís: *“Explicá”*, *“Refactor”*, *“Generá doc”*.

### Subir cambios (igual)

```bash
git add .
git commit -m "feat: agrega X"
git push origin main
```

> Mantener mensajes cortos y descriptivos.

---

También podes usar VS Code, TraeIA y otros.
Además para los momentos que necesitamos trabajar "ONLINE 100% podemos ir a https://hackmd.io/ o simplemente trabajar cualquier herramienta colaborativa)
