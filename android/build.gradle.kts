allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        // Maven Central mirror to mitigate temporary DNS/availability issues
        maven { url = uri("https://repo1.maven.org/maven2/") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // Correctif de compatibilité AGP 8+ : certains plugins anciens (ex.
    // sms_sender_background 1.0.7) ne déclarent pas de `namespace`, ce qui est
    // désormais obligatoire. On l'injecte dès qu'un plugin Android est appliqué
    // (avant l'évaluation forcée par evaluationDependsOn), par réflexion pour ne
    // pas dépendre des types AGP à la compilation du script.
    val injectNamespace = {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                if (getNamespace.invoke(androidExt) == null) {
                    androidExt.javaClass
                        .getMethod("setNamespace", String::class.java)
                        .invoke(androidExt, "com.example.${project.name}")
                }
            } catch (_: NoSuchMethodException) {
                // Extension sans notion de namespace : rien à faire.
            }
        }
    }
    project.plugins.withId("com.android.library") { injectNamespace() }
    project.plugins.withId("com.android.application") { injectNamespace() }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
