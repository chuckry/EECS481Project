//
//  HorizontalPageViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit

class HorizontalPageViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dataSource = self
        
        setViewControllers([orderedViewControllers[1]], direction: .forward, animated: true, completion: nil)
        let vertical = orderedViewControllers[1] as! VerticalPageViewController
        vertical.horizontalPageVC = self
        let favorites = orderedViewControllers[2] as! FavoritesViewController
        favorites.horizontalPageVC = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InputViewController"), UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VerticalPageViewController"),UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FavoritesViewController")]
    }()
    
    public func disableScrolling() {
        dataSource = nil
    }
    
    public func enableScrolling() {
        dataSource = self
        setViewControllers([orderedViewControllers[1]], direction: .forward, animated: true, completion: nil)
    }
    
    public func returnToMainScreen() {
        setViewControllers([orderedViewControllers[1]], direction: .forward, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HorizontalPageViewController: UIPageViewControllerDataSource {
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
        
        // Pass any data back and forth here!!
        
        
        return orderedViewControllers[previousIndex]
    }
    
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


