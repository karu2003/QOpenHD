#include "logger.h"


#if defined(__rasp_pi__)
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#endif

#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>
#include "localmessage.h"
#include "constants.h"

#include "logger_t.h"

/* this class needs work... right now just trying to solve pi crash issue
 * -the class is a bit hard to control with the build directive (enable_log)
 * -all of the platforms paths need to be determined.. the only accurate one
 * is for the rpi.
 * -the file should be opened in init once. not constantly opened and closed
 */


static Logger* _instance = new Logger();


Logger::Logger(QObject *parent): QObject(parent) {
    #if defined(ENABLE_LOG)
    qDebug() << "Logger::Logger()";
    init();
    #endif
}


Logger* Logger::instance() {
    return _instance;
}


void Logger::init() {
    qDebug() << "Logger::init()";

#if defined(__rasp_pi__)
filePath="/boot/QOpenHD_Log.log";
#endif
#if defined(__apple__)
filePath="/boot/QOpenHD_Log.log";
#endif
#if defined(__macos__)
filePath="/boot/QOpenHD_Log.log";
#endif
#if defined(__android__)
filePath="/boot/QOpenHD_Log.log";
#endif
#if defined(__desktoplinux__)
filePath="/tmp/QOpenHD-Logs.txt";
#endif
#if defined(__windows__)
filePath="/boot/QOpenHD_Log.log";
#endif

}

void Logger::logData(QString data, int level) {

#if defined(ENABLE_LOG)

    QFile outFile(filePath);

    outFile.open(QIODevice::WriteOnly | QIODevice::Append);

    if(!outFile.isOpen())
    {
        qDebug() << "Log File NOT open";
        LocalMessage::instance()->showMessage("Could Not Open Log File!", 4);
        return;
    }

    QDateTime dateTime(QDateTime::currentDateTime());

    QString timeStr(dateTime.toString("dd-MM-yyyy HH:mm:ss:zzz"));

    QTextStream outStream(&outFile);

    outStream << timeStr << " Data: " << data ;

    outFile.close();
#endif
}

QObject *loggerSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return _instance;
}
