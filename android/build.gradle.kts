buildscript {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://flutter-io.cn' }
        google()
        jcenter()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:9.0.1'
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20'
    }
}

allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://flutter-io.cn' }
        google()
        jcenter()
    }
}

rootProject.layout.buildDirectory.value(new File(rootProject.projectDir.parentFile, "../build"))

subprojects {
    project.layout.buildDirectory.value(new File(rootProject.layout.buildDirectory.get(), project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete) {
    delete rootProject.layout.buildDirectory
}