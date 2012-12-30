/***********************************************************************
* Copyright 2003-2004  Max Howell <max.howell@methylblue.com>
* Copyright 2008-2009  Martin Sandsmark <martin.sandsmark@kde.org>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; either version 2 of
* the License or (at your option) version 3 or any later version
* accepted by the membership of KDE e.V. (or its successor approved
* by the membership of KDE e.V.), which shall act as a proxy
* defined in Section 14 of version 3 of the license.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
***********************************************************************/

#ifndef SETTINGSDIALOG_H
#define SETTINGSDIALOG_H

#include "ui_dialog.h" //generated by uic

#include <QtCore/QTimer>
#include <QtGui/QCloseEvent>


class SettingsDialog : public KDialog, public Ui::Dialog
{
    Q_OBJECT

public:
    explicit SettingsDialog(QWidget* = 0);

protected:
    virtual void closeEvent(QCloseEvent *);
    virtual void reject();

public slots:
    void addFolder();
    void removeFolder();
    void toggleScanAcrossMounts(bool);
    void toggleDontScanRemoteMounts(bool);
    void toggleDontScanRemovableMedia(bool);
    void reset();
    void startTimer();
    void toggleUseAntialiasing(bool = true);
    void toggleVaryLabelFontSizes(bool);
    void changeContrast(int);
    void changeScheme(int);
    void changeMinFontPitch(int);
    void toggleShowSmallFiles(bool);
    void slotSliderReleased();

signals:
    void mapIsInvalid();
    void canvasIsDirty(int);

private:
    QTimer m_timer;

    static const uint TIMEOUT=1000;
};

#endif
