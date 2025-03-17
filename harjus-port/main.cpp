#include <QCoreApplication>
#include <iostream>
#include <QSocketNotifier>
#include <QTextStream>


// object for reading stdin and reacting to input
class StdinReader : public QObject {
public:
    StdinReader() : QObject(nullptr), m_notifier(new QSocketNotifier(fileno(stdin), QSocketNotifier::Read, this)) {
        connect(m_notifier, &QSocketNotifier::activated, this, &StdinReader::handleReadyRead);
    }

private slots:
    void handleReadyRead() {
        QTextStream in(stdin);
        QString input = in.readLine();
        std::cout << "Input received: " << input.toStdString() << std::endl;
        // TODO: process price updates here
    }

private:
    QSocketNotifier *m_notifier;
};

int main(int argc, char *argv[])
{
    QCoreApplication a{argc, argv};

    // TODO: read trading paths here

    StdinReader reader;
    return a.exec();
}
