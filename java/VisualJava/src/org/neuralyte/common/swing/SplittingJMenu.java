package org.neuralyte.common.swing;



// import java.awt.*;
// import java.awt.event.*;
// import java.io.*;
import java.lang.*;
import java.lang.reflect.*;
import java.util.*;
import java.awt.*;
import javax.swing.*;
// import javax.swing.text.*;
// import javax.swing.text.html.*;
// import jlib.*;

public class SplittingJMenu extends DetachableJMenu {

	private Vector items = new Vector();
	private boolean doneSorting = false;

	public static final int maxItems = 40;
	public static final int preferedSplits = 30;  // Actually prefered+1

    public SplittingJMenu(String s) {
        super(s);
    }

	public JMenuItem add(JMenuItem j) {
		// items.add(j);
		// Do a sorted insert
		boolean done=false;
		int i=0;
		while (i<items.size() && !done) {
			if (j.getText().compareTo(((JMenuItem)items.get(i)).getText())<0)
				done=true;
			else
				i++;
		}
		items.insertElementAt(j,i);
        // super.insert(j,i);
		return j;
	}

    public JMenuItem addDontSplit(JMenuItem j) {
        return super.add(j);
    }

    public void setSelected(boolean b) {
        ensurePopulated();
        super.setSelected(b);
    }

    public void ensurePopulated() {
        if (!doneSorting) {
            arrange();
            doneSorting = true;
        }
    }

    /*
    public void doClick(int pressTime) {
		if (doneSorting) {
			super.doClick(pressTime);
		} else {
			arrange();
			doneSorting=true;
			super.doClick(pressTime);
		}
	}
    */

	public void splitIfNeeded() {
		if (items.size()>maxItems) {
			int[] splitAt=new int[preferedSplits];
			// splitAt[0]=0;
			// splitAt[preferedSplits-1]=items.size()+1;
			for (int i=0;i<preferedSplits;i++) {
				splitAt[i]=items.size()*i/(preferedSplits-1);
			}
			Vector splits=new Vector();
			for (int i=0;i<preferedSplits-1;i++) {
				Vector tmp=new Vector();
				for (int j=splitAt[i];j<splitAt[i+1];j++) {
					tmp.add(items.get(j));
				}
				String first=((JMenuItem)tmp.get(0)).getText();
				String last=((JMenuItem)tmp.get(tmp.size()-1)).getText();
				SplittingJMenu sm=new SplittingJMenu("[ "+first+" ... "+last+" ]");
				for (int j=0;j<tmp.size();j++) {
					sm.add((JMenuItem)tmp.get(j));
				}
				splits.add(sm);
			}
			items=splits;
		}
	}

	public void arrange() {
		// System.out.println("Arranging "+this);
		splitIfNeeded();
		for (int i=0;i<items.size();i++) {
			JMenuItem mi=(JMenuItem)items.get(i);
			super.add(mi);
			if (mi instanceof SplittingJMenu)
				((SplittingJMenu)mi).arrange();
		}
	}

    /*
    public int getItemCount() {
        ensurePopulated();
        return super.getItemCount();
    }
    */

    public int getMenuComponentCount() {
        ensurePopulated();
        return super.getMenuComponentCount();
    }

    public Component[] getMenuComponents() {
        ensurePopulated();
        return super.getMenuComponents();
    }

}
