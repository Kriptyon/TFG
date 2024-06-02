import os
from pymongo import MongoClient
from faker import Faker
import random

# Leer credenciales de las variables de entorno
username = os.getenv("DOCDB_USERNAME")
password = os.getenv("DOCDB_PASSWORD")
cluster_endpoint = os.getenv("DOCDB_CLUSTER_ENDPOINT")

# Verificar que las variables de entorno están configuradas
if not all([username, password, cluster_endpoint]):
    raise EnvironmentError("Por favor, configura las variables de entorno DOCDB_USERNAME, DOCDB_PASSWORD y DOCDB_CLUSTER_ENDPOINT.")

# Conexión al clúster DocumentDB
uri = f"mongodb://{username}:{password}@{cluster_endpoint}:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
client = MongoClient(uri)
# Crear la base de datos
db = client["HealthCert"]

# Conectar a las colecciones
medicos = db["medicos"]
pacientes = db["pacientes"]
historial_medico = db["historial_medico"]
citas_medicas = db["citas_medicas"]

# Generador de datos aleatorios
fake = Faker()

# Crear médicos
medicos_ids = []
for _ in range(10):
    medico_id = fake.uuid4()
    medicos_ids.append(medico_id)
    medico = {
        "_id": medico_id,
        "nombre": fake.first_name(),
        "apellido": fake.last_name(),
        "telefono": fake.phone_number(),
        "edad": random.randint(30, 65),
        "numero_colegiado": fake.numerify(text="#####"),
        "especialidad": random.choice(["Cardiología", "Dermatología", "Neurología", "Pediatría", "Psiquiatría"]),
        "pacientes": [],
        "salario": random.randint(50000, 120000)
    }
    medicos.insert_one(medico)

# Crear pacientes
pacientes_ids = []
for _ in range(50):
    paciente_id = fake.uuid4()
    pacientes_ids.append(paciente_id)
    paciente = {
        "_id": paciente_id,
        "nombre": fake.first_name(),
        "apellido": fake.last_name(),
        "edad": random.randint(1, 90),
        "telefono": fake.phone_number(),
        "direccion": fake.address(),
        "aseguradora": fake.company(),
        "numero_poliza": fake.numerify(text="POL-#####"),
        "medico_asignado": random.choice(medicos_ids)
    }
    pacientes.insert_one(paciente)

# Asignar pacientes a médicos
for paciente_id in pacientes_ids:
    medico_id = random.choice(medicos_ids)
    medicos.update_one({"_id": medico_id}, {"$push": {"pacientes": paciente_id}})

# Crear historial médico
for paciente_id in pacientes_ids:
    historial = {
        "_id": fake.uuid4(),
        "paciente": paciente_id,
        "medico": random.choice(medicos_ids),
        "diagnostico": random.choice(["Hipertensión", "Diabetes", "Resfriado Común", "Gripe", "Migraña"]),
        "tratamiento": random.choice(["Medicamento A", "Medicamento B", "Terapia X", "Cirugía Y"]),
        "cubierto": random.choice([True, False]),
        "cobro_servicio": random.randint(100, 1000)
    }
    historial_medico.insert_one(historial)

# Crear citas médicas
for _ in range(100):
    cita = {
        "_id": fake.uuid4(),
        "dia": random.randint(1, 28),
        "mes": random.randint(1, 12),
        "año": random.randint(2022, 2024),
        "hora": f"{random.randint(8, 17)}:{random.choice(['00', '15', '30', '45'])}",
        "paciente": random.choice(pacientes_ids),
        "medico": random.choice(medicos_ids)
    }
    citas_medicas.insert_one(cita)

print("Script de generación de datos aleatorios en HealthCert ejecutado con éxito")
