/***************************************************************************
                          historyaction.h  -  description
                             -------------------
    begin                : Tue Sep 16 2003
    copyright            : (C) 2003 by Max Howell
    email                : max.howell@methylblue.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef HISTORYACTION_H
#define HISTORYACTION_H

#include <qobject.h>
#include <qstring.h>
#include <qstringlist.h>

#include <kaccel.h>
#include <kconfig.h>
#include <klocale.h>
#include <kaction.h>
#include <kurl.h>
#include <kapp.h>          //KDE_VERSION
#include <kdebug.h>



//**** the only sucky bit here is excessive signal/slotting

class HistoryAction : KAction
{
Q_OBJECT

  HistoryAction( const QString &text, const char *icon, const KShortcut &cut, KActionCollection *ac, const char *name );

  friend class HistoryCollection;

signals:
  void activated( HistoryAction*, const QString & );

public slots:
  void setEnabled( bool b = true )
    { if( b ) b = !m_list.isEmpty(); KAction::setEnabled( b ); }
  void push( const QString &path )
    { if( !path.isEmpty() && m_list.last() != path ) { m_list.append( path ); setText(); KAction::setEnabled( true ); } }
  void pop()
    { const QString s = m_list.last(); m_list.pop_back(); emit activated( this, s ); setText(); setEnabled(); }

private:
  void clear()
    { m_list.clear(); KAction::setText( m_text ); }
  void setText()
    { if( !m_list.isEmpty() ) KAction::setText( m_text + ": " + m_list.last() ); else KAction::setText( m_text ); }

  const QString m_text;
  QStringList m_list;
};


class HistoryCollection : public QObject
{
Q_OBJECT

public:
    HistoryCollection( KActionCollection *ac, QObject *parent, const char *name );

    void save( KConfig *config );
    void restore( KConfig *config );

signals:
    void activated( const KURL & );
                    
public slots:
    void push( const KURL &url )
    {
      if( m_receiver == NULL )
      {
        m_f->clear();
        m_receiver = m_b;
      }

      m_receiver->push( url.path( 1 ) );
      m_receiver = NULL;
    }
    void stop() { m_receiver = NULL; }
        
private slots:
    void process( HistoryAction *ha, const QString &path )
    {
      //**** sucks! sucks!
      m_receiver = ( ha == m_b ) ? m_f : m_b;
      emit activated( path );
    }

private:
    HistoryAction *m_b, *m_f, *m_receiver;
};

#endif
