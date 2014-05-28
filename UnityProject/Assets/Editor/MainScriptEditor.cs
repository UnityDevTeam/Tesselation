using UnityEditor;
using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

public class MyWindow : EditorWindow
{	
	// Add menu item named "My Window" to the Window menu
	[MenuItem("CellUnity/Show Window")]
	public static void ShowWindow()
	{
		//Show existing window instance. If one doesn't exist, make one.
		EditorWindow.GetWindow(typeof(MyWindow));
	}
	
	void OnGUI()
	{
		if(GUILayout.Button ("Init Scene")) 
		{

		}
	}
}
