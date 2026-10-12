# Reemplaza el uso de passlib (incompatible con bcrypt 5.x) por bcrypt
# directo, y trunca a 72 bytes antes de hashear (limite duro de bcrypt).
# Se corre una sola vez, despues de que patch_bcrypt_passwords.py fallo
# a mitad de camino.

with open("main.py", encoding="utf-8") as f:
    main_content = f.read()

viejo = '''from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(password_plano: str, password_hash: str) -> bool:
    try:
        return pwd_context.verify(password_plano, password_hash)
    except Exception:
        return False'''

nuevo = '''import bcrypt

def hash_password(password: str) -> str:
    password_bytes = password.encode("utf-8")[:72]
    return bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode("utf-8")

def verify_password(password_plano: str, password_hash: str) -> bool:
    try:
        password_bytes = password_plano.encode("utf-8")[:72]
        return bcrypt.checkpw(password_bytes, password_hash.encode("utf-8"))
    except Exception:
        return False'''

assert viejo in main_content, "no se encontro el bloque de passlib tal como se esperaba"
main_content = main_content.replace(viejo, nuevo, 1)
with open("main.py", "w", encoding="utf-8") as f:
    f.write(main_content)
print("main.py: reemplazado passlib por bcrypt directo")
