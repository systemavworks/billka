plugins {
    kotlin("jvm") version "2.1.0"
    `java-library`
}

group = "es.billka"
version = "0.1.0"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(kotlin("test"))
}

kotlin {
    // Debe coincidir con el consumidor (core). Un fiscal-kit compilado a JDK 17 no rompe nada,
    // pero un toolchain distinto sí cambia el resultado de los hashes byte a byte de XML.
    jvmToolchain(21)
}

tasks.test {
    useJUnitPlatform()
}
