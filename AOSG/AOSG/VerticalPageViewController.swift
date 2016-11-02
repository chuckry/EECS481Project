//
//  VerticalPageViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit

class VerticalPageViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        dataSource = self
        setViewControllers([orderedViewControllers[1]], direction: .forward, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PromptViewController"), UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController"),UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController")]
    }()
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension VerticalPageViewController: UIPageViewControllerDataSource {
	
	//Settings
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
		
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 && orderedViewControllers.count > previousIndex else {
            return nil
        }
		
		Stuff.things.message = "this is your passing string!";
		// Pass any data back and forth here!!
		

        return orderedViewControllers[previousIndex]
    }
	
	//
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        guard nextIndex >= 0 && orderedViewControllers.count > nextIndex else {
            return nil
        }
        
		// Pass any data back and forth here!!
		
        return orderedViewControllers[nextIndex]
    }
}
