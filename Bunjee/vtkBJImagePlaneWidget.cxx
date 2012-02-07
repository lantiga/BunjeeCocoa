/*
 *  vtkBJImagePlaneWidget.cxx
 *  BJ
 *
 *  Created by Luca Antiga on 3/7/09.
 *  Copyright 2010-2011 Orobix. All rights reserved.
 *
 */

#include "vtkBJImagePlaneWidget.h"
#include "vtkTextProperty.h"
#include "vtkObjectFactory.h"

vtkCxxRevisionMacro(vtkBJImagePlaneWidget, "$Revision: 1.19 $");
vtkStandardNewMacro(vtkBJImagePlaneWidget);

vtkBJImagePlaneWidget::vtkBJImagePlaneWidget()
{
	this->GetTextProperty()->SetFontSize(12);
}

vtkBJImagePlaneWidget::~vtkBJImagePlaneWidget()
{

}

void vtkBJImagePlaneWidget::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);
}