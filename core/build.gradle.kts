plugins {
    kotlin("jvm") version "2.1.0"
    application
}

group = "es.billka"
version = "0.1.0"

repositories {
    mavenCentral()
}

dependencies {
    implementation(project(":fiscal-kit"))
    testImplementation(kotlin("test"))
}

kotlin {
    // JDK 21 obligatorio (LTS). Gradle 8.10 detecta el toolchain instalado o descargado en
    // ~/.gradle/jdks; un CI limpio debe instalar el JDK 21 antes de invocar ./gradlew.
    jvmToolchain(21)
}

application {
    // Todavía no existe: se crea en el paso 5 del roadmap (Ktor). `./gradlew run` fallará
    // hasta entonces; `./gradlew build` compila en verde con 0 fuentes.
    mainClass.set("es.billka.core.MainKt")
}

tasks.test {
    useJUnitPlatform()
}
