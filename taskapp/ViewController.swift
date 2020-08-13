//
//  ViewController.swift
//  taskapp
//
//  Created by ayano-s on 2020/08/09.
//  Copyright © 2020 ayano-s. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
        
    //Realmのインスタンスを取得
    let realm = try! Realm()
    
    var tapGesture: UITapGestureRecognizer!
    
    //db内のタスクが格納されるリスト
    //日付の昇順（近い順）でソート
    //内容をupdateするとリストは自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        searchBar.showsCancelButton = true
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //データ（セル）の数を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    //各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //cellの値設定
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        tableView.tableFooterView = UIView()

        return cell
    }
        
    //検索時に実行されるメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
                
        //カテゴリ名と一致するデータを抽出
        guard let searchText = searchBar.text else {
            return
        }
         //検索文字列がない場合に全件表示
        if searchText.utf8.count == 0 {
             taskArray = realm.objects(Task.self)
        } else {
            let searchResult = realm.objects(Task.self).filter("'\(searchText)' == category")
            taskArray = searchResult
        }
        tableView.reloadData()
    }

    //キャンセルボタン押下時に実行されるメソッド
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.text = ""
        taskArray = realm.objects(Task.self)
        tableView.reloadData()
    }
    
    //入力モードになったらジェスチャーを加える
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.view.addGestureRecognizer(tapGesture)
    }
    
    //入力モードになったらジェスチャーを外す
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.view.removeGestureRecognizer(tapGesture)
    }
    
    //セル選択時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    //セル削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //削除するタスクを取得
            let task = self.taskArray[indexPath.row]
            
            //ローカル通知のキャンセル
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)] )
            
            //データベースから削除
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            //未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    //segueで画面遷移時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
            task.id = allTasks.max(ofProperty: "id")! + 1
            }

            inputViewController.task = task
        }
        
        dismissKeyboard()
    }
    
    //入力画面から戻ってきた時にTableViewを更新する
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @objc func dismissKeyboard() {
        //キーボードを閉じる
        searchBar.endEditing(true)
    }
}

