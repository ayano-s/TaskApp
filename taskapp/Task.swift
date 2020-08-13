//
//  Task.swift
//  taskapp
//
//  Created by ayano-s on 2020/08/10.
//  Copyright © 2020 ayano-s. All rights reserved.
//

import RealmSwift

class Task: Object {
    //管理用ID。primarykey
    @objc dynamic var id = 0
    
    //タイトル
    @objc dynamic var title = ""
    
    //カテゴリ
    @objc dynamic var category = ""
    
    //内容
    @objc dynamic var contents = ""
    
    //日時
    @objc dynamic var date = Date()
    
    //idをprimarykeyに設定
    override static func primaryKey() -> String? {
        return "id"
    }
}
