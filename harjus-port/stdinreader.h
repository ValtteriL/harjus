#include <QObject>
#include <QSocketNotifier>

// object for reading stdin and reacting to input
class StdinReader : public QObject
{
public:
  StdinReader() : QObject(nullptr), m_notifier(new QSocketNotifier(fileno(stdin), QSocketNotifier::Read, this))
  {
    connect(m_notifier, &QSocketNotifier::activated, this, &StdinReader::handleReadyRead);
  }

private slots:
  void handleReadyRead();

private:
  QSocketNotifier *m_notifier;
};