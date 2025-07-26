allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(35)
                buildToolsVersion("35.0.0")
                
                // Auto-assign namespace for libraries that don't have one
                if (this is com.android.build.gradle.LibraryExtension && namespace == null) {
                    namespace = when (project.name) {
                        "isar_flutter_libs" -> "dev.isar.isar_flutter_libs"
                        else -> "com.example.${project.name}"
                    }
                }
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
