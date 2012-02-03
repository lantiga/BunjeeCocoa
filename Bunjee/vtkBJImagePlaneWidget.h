/*
 *  vtkBJImagePlaneWidget.h
 *  BJ
 *
 *  Created by Luca Antiga on 3/7/09.
 *  Copyright 2010-2011 Orobix. All rights reserved.
 *
 */

#ifndef __vtkBJImagePlaneWidget_h
#define __vtkBJImagePlaneWidget_h

#include "vtkImagePlaneWidget.h"

class vtkBJImagePlaneWidget : public vtkImagePlaneWidget
{
public:
  static vtkBJImagePlaneWidget *New();

  vtkTypeRevisionMacro(vtkBJImagePlaneWidget,vtkImagePlaneWidget);
  void PrintSelf(ostream& os, vtkIndent indent);

protected:
  vtkBJImagePlaneWidget();
  ~vtkBJImagePlaneWidget();

private:
  vtkBJImagePlaneWidget(const vtkBJImagePlaneWidget&);  //Not implemented
  void operator=(const vtkBJImagePlaneWidget&);  //Not implemented
};

#endif