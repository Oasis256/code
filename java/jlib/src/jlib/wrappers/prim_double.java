package jlib.wrappers;

import java.io.*;
import java.lang.*;
import java.lang.reflect.*;
import java.util.*;
import jlib.*;
import nuju.*;
import jlib.db.*;
import jlib.multiui.*;

public class prim_double extends Wrapper {

	double value;

	public prim_double() { }
	
	public prim_double(double v) {
		value=v;
	}

	public String toString() {
		return ""+value;
	}

	public static Object fromString(String s) {
		return new Double(s);
	}

	// public String SQLtype() {
		// return "double";
	// }

}
