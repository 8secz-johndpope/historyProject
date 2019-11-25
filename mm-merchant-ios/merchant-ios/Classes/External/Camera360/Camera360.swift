//
//  Camera360.swift
//  Camera360
//
//  Created by Alan YU on 6/9/2017.
//  Copyright © 2017 YDIVA.COM. All rights reserved.
//

import UIKit
import Foundation
import PromiseKit
import ObjectMapper
import Alamofire

class Camera360 {
    
    enum Filter {
        // 魔法美肤 | 自然美肤
        case C360_Skin_Soft (strength: Int)
        // 魔法美肤 | 光滑美肤
        case C360_Skin_DepthClean (strength: Int)
        // 魔法美肤 | 轻度美白
        case C360_Skin_SoftWhitening (strength: Int)
        // 魔法美肤 | 深度美白
        case C360_Skin_DepthWhitening (strength: Int)
        // 魔法美肤 | 艺术黑白
        case C360_Skin_CleanBW (strength: Int)
        // 魔法美肤 | 暖暖阳光
        case C360_Skin_Sunshine (strength: Int)
        // 魔法美肤 | 清新丽人
        case C360_Skin_Greenish (strength: Int)
        // 魔法美肤 | 香艳红唇
        case C360_Skin_RedLip (strength: Int)
        // 魔法美肤 | 甜美可人1
        case C360_Skin_Sweet (strength: Int)
        // 魔法美肤 | 甜美可人2
        case C360_Skin_SweetNew (strength: Int)
        // 日系 | 甜美
        case C360_LightColor_SweetRed (strength: Int)
        // 日系 | 清凉
        case C360_LightColor_ColorBlue (strength: Int)
        // 日系 | 阳光灿烂
        case C360_LightColor_Lighting0 (strength: Int)
        // 日系 | 一米阳光
        case C360_LightColor_Lighting1 (strength: Int)
        // 日系 | 唯美
        case C360_LightColor_Beauty (strength: Int)
        // 日系 | 果冻
        case C360_LightColor_Cyan (strength: Int)
        // 日系 | 淡雅
        case C360_LightColor_LowSatGreen (strength: Int)
        // 日系 | 清新
        case C360_LightColor_NatureFresh (strength: Int)
        // 日系 | 温暖
        case C360_LightColor_NatureWarm (strength: Int)
        // 韩范 | 浅咖啡
        case C360_Seulki (strength: Int)
        // 韩范 | 薄荷绿
        case C360_Yuri (strength: Int)
        // 韩范 | 清新蓝
        case C360_Hyejin (strength: Int)
        // 韩范 | 甜蜜粉
        case C360_Miyeon (strength: Int)
        // 韩范 | 优雅白
        case C360_Doona (strength: Int)
        // 韩范 | 浆果红
        case C360_Eunjin (strength: Int)
        // 韩范 | 妩媚紫
        case C360_Hyori (strength: Int)
        // 欧美风 | 渔人码头
        case C360_H1 (strength: Int)
        // 欧美风 | 夏威夷
        case C360_H2 (strength: Int)
        // 欧美风 | 西雅图
        case C360_H3 (strength: Int)
        // 欧美风 | 好莱坞
        case C360_H4 (strength: Int)
        // 欧美风 | 密西西比
        case C360_H5 (strength: Int)
        // 欧美风 | 奥斯丁
        case C360_H6 (strength: Int)
        // 视觉人像 | 松烟墨
        case C360_V5 (strength: Int)
        // 视觉人像 | 松脂
        case C360_V6 (strength: Int)
        // 视觉人像 | 胡桃栗
        case C360_V7 (strength: Int)
        // 视觉人像 | 翡冷翠
        case C360_V8 (strength: Int)
        // 一妆到底 | 亮颜发光
        case C360_Skin_S1 (strength: Int)
        // 一妆到底 | 平衡哑光
        case C360_Skin_S2 (strength: Int)
        // 一妆到底 | 明眸亮唇
        case C360_Skin_S3 (strength: Int)
        // 宛如初现 | 初现美白
        case C360_w1 (strength: Int)
        // 宛如初现 | 初现丽人
        case C360_w2 (strength: Int)
        // 宛如初现 | 初现增强
        case C360_w3 (strength: Int)
        // 宛如初现 | 初现韩范
        case C360_w4 (strength: Int)
        // 宛如初现 | 初现日系
        case C360_w5 (strength: Int)
        // 宛如初现 | 初现红润
        case C360_w6 (strength: Int)
        // 手绘 | 黑白线条
        case C360_Sketch_Line (strength: Int)
        // 手绘 | 黑白超现实
        case C360_Sketch_BW (strength: Int)
        // 手绘 | 那些年
        case C360_Sketch_Yellow (strength: Int)
        // 手绘 | 彩色
        case C360_Sketch_Color (strength: Int)
        // 手绘 | 油彩画
        case C360_Sketch_ColorMul (strength: Int)
        // 手绘 | 霓虹
        case C360_Sketch_Neon (strength: Int)
        // 手绘 | 炭笔画
        case C360_Sketch_WideLine (strength: Int)
        // 手绘 | 亮彩
        case C360_Sketch_LightColor (strength: Int)
        // 手绘 | 淡彩
        case C360_Sketch_SoftColor (strength: Int)
        // 漫画 | 线条卡通
        case C360_CartoonEX_Line (strength: Int)
        // 漫画 | 彩色线条卡通
        case C360_CartoonEX_Color (strength: Int)
        // 漫画 | 彩色块卡通
        case C360_CartoonEX_BlockColor (strength: Int)
        // 漫画 | 甜美卡通
        case C360_CartoonEX_Sweet (strength: Int)
        // 漫画 | 多彩卡通
        case C360_CartoonEX_Colorful (strength: Int)
        // 漫画 | 素雅卡通
        case C360_CartoonEX_Greenish (strength: Int)
        // 漫画 | 彩色卡通
        case C360_CartoonEX_Color2 (strength: Int)
        // 漫画 | 诱惑
        case C360_CartoonEX_RedLip (strength: Int)
        // 漫画 | 新奥巴马头像
        case C360_CartoonEX_NewOubama (strength: Int)
        // 漫画 | 新印章
        case C360_CartoonEX_NewBadge (strength: Int)
        // 复古 | 紫色迷情
        case C360_Retro_Decadent (strength: Int)
        // 复古 | 复古暖黄
        case C360_Retro_Hazy (strength: Int)
        // 复古 | 金色年华
        case C360_Retro_Rustic (strength: Int)
        // 复古 | 橙黄回忆
        case C360_Retro_Recall (strength: Int)
        // 复古 | 夜色朦胧
        case C360_Retro_Blue (strength: Int)
        // 复古 | 蓦然回首
        case C360_Retro_Turn (strength: Int)
        // 复古 | 泛黄记忆
        case C360_Retro_Yellow (strength: Int)
        // 复古 | 祖母绿
        case C360_Retro_Greenish (strength: Int)
        // 复古 | 弥漫森林
        case C360_Retro_Blueish (strength: Int)
        // LOMO | 青色
        case C360_LOMO_Cyan (strength: Int)
        // LOMO | 电影
        case C360_LOMO_Film (strength: Int)
        // LOMO | 淡青
        case C360_LOMO_Greenish (strength: Int)
        // LOMO | 时尚
        case C360_LOMO_Fashion (strength: Int)
        // LOMO | 浅回忆
        case C360_LOMO_Recall (strength: Int)
        // LOMO | 冷艳
        case C360_LOMO_Cold (strength: Int)
        // LOMO | 暖秋
        case C360_LOMO_Warm (strength: Int)
        // LOMO | 热情
        case C360_LOMO_Zest (strength: Int)
        // LOMO | 枫叶
        case C360_LOMO_Leaf (strength: Int)
        // LOFT | 青涩
        case E_119 (strength: Int)
        // LOFT | 慵懒
        case E_120 (strength: Int)
        // LOFT | 沉静
        case E_121 (strength: Int)
        // LOFT | 午后
        case E_122 (strength: Int)
        // LOFT | 暮色
        case E_123 (strength: Int)
        // LOFT | 流年
        case E_124 (strength: Int)
        // 弗莱胶片 | Gold
        case E_112 (strength: Int)
        // 弗莱胶片 | Vista
        case E_113 (strength: Int)
        // 弗莱胶片 | Xtra
        case E_114 (strength: Int)
        // 弗莱胶片 | Ektar
        case E_115 (strength: Int)
        // 弗莱胶片 | Veliva
        case E_116 (strength: Int)
        // 弗莱胶片 | Profoto
        case E_117 (strength: Int)
        // 弗莱胶片 | Superia
        case E_118 (strength: Int)
        // 风景 | 轻柔
        case C360_HDR_Soft (strength: Int)
        // 风景 | 绚丽
        case C360_HDR_Vivid (strength: Int)
        // 风景 | 经典
        case C360_HDR_Enhance (strength: Int)
        // 风景 | 光绚
        case C360_HDR_Shine (strength: Int)
        // 风景 | 风暴
        case C360_HDR_Storm (strength: Int)
        // 风景 | HDR黑白1
        case C360_HDR_BW1 (strength: Int)
        // 风景 | HDR黑白2
        case C360_HDR_BW (strength: Int)
        // 风景 | HDR标准
        case C360_HDR_Stand (strength: Int)
        // 风景 | HDR浓郁
        case C360_HDR_Strong (strength: Int)
        // 风景 | HDR原色
        case C360_HDR_Natural (strength: Int)
        // 风景 | HDR亮丽
        case C360_HDR_Lighting (strength: Int)
        // 风景 | HDR夜间补光
        case C360_HDR_Night (strength: Int)
        // 流光溢彩 | 彩虹
        case C360_Colorful_rainbow (strength: Int)
        // 流光溢彩 | 水晶
        case C360_Colorful_Crystal (strength: Int)
        // 流光溢彩 | 碧空如洗
        case C360_Colorful_Sky (strength: Int)
        // 流光溢彩 | 天高云淡
        case C360_Colorful_Cloud (strength: Int)
        // 流光溢彩 | 微波荡漾
        case C360_Colorful_Ripple (strength: Int)
        // 流光溢彩 | 绚丽多彩
        case C360_Colorful_Vivid (strength: Int)
        // 流光溢彩 | 流云漓彩
        case C360_Colorful_Flow (strength: Int)
        // 流光溢彩 | 姹紫嫣红
        case C360_Colorful_Red (strength: Int)
        // 流光溢彩 | 金色秋天
        case C360_Colorful_Gold (strength: Int)
        // 流光溢彩 | 紫色迷情
        case C360_Colorful_Purple (strength: Int)
        // 魔法色彩 | 樱桃红
        case C360_ShiftColor_Red1 (strength: Int)
        // 魔法色彩 | 中国红
        case C360_ShiftColor_Red2 (strength: Int)
        // 魔法色彩 | 橘子橙
        case C360_ShiftColor_Yellow1 (strength: Int)
        // 魔法色彩 | 绿之森
        case C360_ShiftColor_Green (strength: Int)
        // 魔法色彩 | 深海蓝
        case C360_ShiftColor_Blue (strength: Int)
        // 魔法色彩 | 天空蓝
        case C360_ShiftColor_SkyBlue (strength: Int)
        // 魔法色彩 | 柠檬黄
        case C360_ShiftColor_Yellow2 (strength: Int)
        // 魔法色彩 | 熏衣紫
        case C360_ShiftColor_Purple (strength: Int)
        // 魔法色彩 | 魔法夏天
        case C360_ShiftColor_Summer (strength: Int)
        // 黑白 | 标准
        case C360_BW_Normal (strength: Int)
        // 黑白 | 雅黑
        case C360_BW_Enhance (strength: Int)
        // 黑白 | 强烈
        case C360_BW_Strong (strength: Int)
        // 黑白 | 黑白风暴
        case C360_BW_Storm (strength: Int)
        // 黑白 | 黑白艺术
        case C360_BW_Art (strength: Int)
        
        var values: (key: String, strength: Int) {
            get {
                switch self {
                case .C360_Skin_Soft(let strength):
                    return (strength: strength, key: "C360_Skin_Soft")
                case .C360_Skin_DepthClean(let strength):
                    return (strength: strength, key: "C360_Skin_DepthClean")
                case .C360_Skin_SoftWhitening(let strength):
                    return (strength: strength, key: "C360_Skin_SoftWhitening")
                case .C360_Skin_DepthWhitening(let strength):
                    return (strength: strength, key: "C360_Skin_DepthWhitening")
                case .C360_Skin_CleanBW(let strength):
                    return (strength: strength, key: "C360_Skin_CleanBW")
                case .C360_Skin_Sunshine(let strength):
                    return (strength: strength, key: "C360_Skin_Sunshine")
                case .C360_Skin_Greenish(let strength):
                    return (strength: strength, key: "C360_Skin_Greenish")
                case .C360_Skin_RedLip(let strength):
                    return (strength: strength, key: "C360_Skin_RedLip")
                case .C360_Skin_Sweet(let strength):
                    return (strength: strength, key: "C360_Skin_Sweet")
                case .C360_Skin_SweetNew(let strength):
                    return (strength: strength, key: "C360_Skin_SweetNew")
                case .C360_LightColor_SweetRed(let strength):
                    return (strength: strength, key: "C360_LightColor_SweetRed")
                case .C360_LightColor_ColorBlue(let strength):
                    return (strength: strength, key: "C360_LightColor_ColorBlue")
                case .C360_LightColor_Lighting0(let strength):
                    return (strength: strength, key: "C360_LightColor_Lighting0")
                case .C360_LightColor_Lighting1(let strength):
                    return (strength: strength, key: "C360_LightColor_Lighting1")
                case .C360_LightColor_Beauty(let strength):
                    return (strength: strength, key: "C360_LightColor_Beauty")
                case .C360_LightColor_Cyan(let strength):
                    return (strength: strength, key: "C360_LightColor_Cyan")
                case .C360_LightColor_LowSatGreen(let strength):
                    return (strength: strength, key: "C360_LightColor_LowSatGreen")
                case .C360_LightColor_NatureFresh(let strength):
                    return (strength: strength, key: "C360_LightColor_NatureFresh")
                case .C360_LightColor_NatureWarm(let strength):
                    return (strength: strength, key: "C360_LightColor_NatureWarm")
                case .C360_Seulki(let strength):
                    return (strength: strength, key: "C360_Seulki")
                case .C360_Yuri(let strength):
                    return (strength: strength, key: "C360_Yuri")
                case .C360_Hyejin(let strength):
                    return (strength: strength, key: "C360_Hyejin")
                case .C360_Miyeon(let strength):
                    return (strength: strength, key: "C360_Miyeon")
                case .C360_Doona(let strength):
                    return (strength: strength, key: "C360_Doona")
                case .C360_Eunjin(let strength):
                    return (strength: strength, key: "C360_Eunjin")
                case .C360_Hyori(let strength):
                    return (strength: strength, key: "C360_Hyori")
                case .C360_H1(let strength):
                    return (strength: strength, key: "C360_H1")
                case .C360_H2(let strength):
                    return (strength: strength, key: "C360_H2")
                case .C360_H3(let strength):
                    return (strength: strength, key: "C360_H3")
                case .C360_H4(let strength):
                    return (strength: strength, key: "C360_H4")
                case .C360_H5(let strength):
                    return (strength: strength, key: "C360_H5")
                case .C360_H6(let strength):
                    return (strength: strength, key: "C360_H6")
                case .C360_V5(let strength):
                    return (strength: strength, key: "C360_V5")
                case .C360_V6(let strength):
                    return (strength: strength, key: "C360_V6")
                case .C360_V7(let strength):
                    return (strength: strength, key: "C360_V7")
                case .C360_V8(let strength):
                    return (strength: strength, key: "C360_V8")
                case .C360_Skin_S1(let strength):
                    return (strength: strength, key: "C360_Skin_S1")
                case .C360_Skin_S2(let strength):
                    return (strength: strength, key: "C360_Skin_S2")
                case .C360_Skin_S3(let strength):
                    return (strength: strength, key: "C360_Skin_S3")
                case .C360_w1(let strength):
                    return (strength: strength, key: "C360_w1")
                case .C360_w2(let strength):
                    return (strength: strength, key: "C360_w2")
                case .C360_w3(let strength):
                    return (strength: strength, key: "C360_w3")
                case .C360_w4(let strength):
                    return (strength: strength, key: "C360_w4")
                case .C360_w5(let strength):
                    return (strength: strength, key: "C360_w5")
                case .C360_w6(let strength):
                    return (strength: strength, key: "C360_w6")
                case .C360_Sketch_Line(let strength):
                    return (strength: strength, key: "C360_Sketch_Line")
                case .C360_Sketch_BW(let strength):
                    return (strength: strength, key: "C360_Sketch_BW")
                case .C360_Sketch_Yellow(let strength):
                    return (strength: strength, key: "C360_Sketch_Yellow")
                case .C360_Sketch_Color(let strength):
                    return (strength: strength, key: "C360_Sketch_Color")
                case .C360_Sketch_ColorMul(let strength):
                    return (strength: strength, key: "C360_Sketch_ColorMul")
                case .C360_Sketch_Neon(let strength):
                    return (strength: strength, key: "C360_Sketch_Neon")
                case .C360_Sketch_WideLine(let strength):
                    return (strength: strength, key: "C360_Sketch_WideLine")
                case .C360_Sketch_LightColor(let strength):
                    return (strength: strength, key: "C360_Sketch_LightColor")
                case .C360_Sketch_SoftColor(let strength):
                    return (strength: strength, key: "C360_Sketch_SoftColor")
                case .C360_CartoonEX_Line(let strength):
                    return (strength: strength, key: "C360_CartoonEX_Line")
                case .C360_CartoonEX_Color(let strength):
                    return (strength: strength, key: "C360_CartoonEX_Color")
                case .C360_CartoonEX_BlockColor(let strength):
                    return (strength: strength, key: "C360_CartoonEX_BlockColor")
                case .C360_CartoonEX_Sweet(let strength):
                    return (strength: strength, key: "C360_CartoonEX_Sweet")
                case .C360_CartoonEX_Colorful(let strength):
                    return (strength: strength, key: "C360_CartoonEX_Colorful")
                case .C360_CartoonEX_Greenish(let strength):
                    return (strength: strength, key: "C360_CartoonEX_Greenish")
                case .C360_CartoonEX_Color2(let strength):
                    return (strength: strength, key: "C360_CartoonEX_Color2")
                case .C360_CartoonEX_RedLip(let strength):
                    return (strength: strength, key: "C360_CartoonEX_RedLip")
                case .C360_CartoonEX_NewOubama(let strength):
                    return (strength: strength, key: "C360_CartoonEX_NewOubama")
                case .C360_CartoonEX_NewBadge(let strength):
                    return (strength: strength, key: "C360_CartoonEX_NewBadge")
                case .C360_Retro_Decadent(let strength):
                    return (strength: strength, key: "C360_Retro_Decadent")
                case .C360_Retro_Hazy(let strength):
                    return (strength: strength, key: "C360_Retro_Hazy")
                case .C360_Retro_Rustic(let strength):
                    return (strength: strength, key: "C360_Retro_Rustic")
                case .C360_Retro_Recall(let strength):
                    return (strength: strength, key: "C360_Retro_Recall")
                case .C360_Retro_Blue(let strength):
                    return (strength: strength, key: "C360_Retro_Blue")
                case .C360_Retro_Turn(let strength):
                    return (strength: strength, key: "C360_Retro_Turn")
                case .C360_Retro_Yellow(let strength):
                    return (strength: strength, key: "C360_Retro_Yellow")
                case .C360_Retro_Greenish(let strength):
                    return (strength: strength, key: "C360_Retro_Greenish")
                case .C360_Retro_Blueish(let strength):
                    return (strength: strength, key: "C360_Retro_Blueish")
                case .C360_LOMO_Cyan(let strength):
                    return (strength: strength, key: "C360_LOMO_Cyan")
                case .C360_LOMO_Film(let strength):
                    return (strength: strength, key: "C360_LOMO_Film")
                case .C360_LOMO_Greenish(let strength):
                    return (strength: strength, key: "C360_LOMO_Greenish")
                case .C360_LOMO_Fashion(let strength):
                    return (strength: strength, key: "C360_LOMO_Fashion")
                case .C360_LOMO_Recall(let strength):
                    return (strength: strength, key: "C360_LOMO_Recall")
                case .C360_LOMO_Cold(let strength):
                    return (strength: strength, key: "C360_LOMO_Cold")
                case .C360_LOMO_Warm(let strength):
                    return (strength: strength, key: "C360_LOMO_Warm")
                case .C360_LOMO_Zest(let strength):
                    return (strength: strength, key: "C360_LOMO_Zest")
                case .C360_LOMO_Leaf(let strength):
                    return (strength: strength, key: "C360_LOMO_Leaf")
                case .E_119(let strength):
                    return (strength: strength, key: "E_119")
                case .E_120(let strength):
                    return (strength: strength, key: "E_120")
                case .E_121(let strength):
                    return (strength: strength, key: "E_121")
                case .E_122(let strength):
                    return (strength: strength, key: "E_122")
                case .E_123(let strength):
                    return (strength: strength, key: "E_123")
                case .E_124(let strength):
                    return (strength: strength, key: "E_124")
                case .E_112(let strength):
                    return (strength: strength, key: "E_112")
                case .E_113(let strength):
                    return (strength: strength, key: "E_113")
                case .E_114(let strength):
                    return (strength: strength, key: "E_114")
                case .E_115(let strength):
                    return (strength: strength, key: "E_115")
                case .E_116(let strength):
                    return (strength: strength, key: "E_116")
                case .E_117(let strength):
                    return (strength: strength, key: "E_117")
                case .E_118(let strength):
                    return (strength: strength, key: "E_118")
                case .C360_HDR_Soft(let strength):
                    return (strength: strength, key: "C360_HDR_Soft")
                case .C360_HDR_Vivid(let strength):
                    return (strength: strength, key: "C360_HDR_Vivid")
                case .C360_HDR_Enhance(let strength):
                    return (strength: strength, key: "C360_HDR_Enhance")
                case .C360_HDR_Shine(let strength):
                    return (strength: strength, key: "C360_HDR_Shine")
                case .C360_HDR_Storm(let strength):
                    return (strength: strength, key: "C360_HDR_Storm")
                case .C360_HDR_BW1(let strength):
                    return (strength: strength, key: "C360_HDR_BW1")
                case .C360_HDR_BW(let strength):
                    return (strength: strength, key: "C360_HDR_BW")
                case .C360_HDR_Stand(let strength):
                    return (strength: strength, key: "C360_HDR_Stand")
                case .C360_HDR_Strong(let strength):
                    return (strength: strength, key: "C360_HDR_Strong")
                case .C360_HDR_Natural(let strength):
                    return (strength: strength, key: "C360_HDR_Natural")
                case .C360_HDR_Lighting(let strength):
                    return (strength: strength, key: "C360_HDR_Lighting")
                case .C360_HDR_Night(let strength):
                    return (strength: strength, key: "C360_HDR_Night")
                case .C360_Colorful_rainbow(let strength):
                    return (strength: strength, key: "C360_Colorful_rainbow")
                case .C360_Colorful_Crystal(let strength):
                    return (strength: strength, key: "C360_Colorful_Crystal")
                case .C360_Colorful_Sky(let strength):
                    return (strength: strength, key: "C360_Colorful_Sky")
                case .C360_Colorful_Cloud(let strength):
                    return (strength: strength, key: "C360_Colorful_Cloud")
                case .C360_Colorful_Ripple(let strength):
                    return (strength: strength, key: "C360_Colorful_Ripple")
                case .C360_Colorful_Vivid(let strength):
                    return (strength: strength, key: "C360_Colorful_Vivid")
                case .C360_Colorful_Flow(let strength):
                    return (strength: strength, key: "C360_Colorful_Flow")
                case .C360_Colorful_Red(let strength):
                    return (strength: strength, key: "C360_Colorful_Red")
                case .C360_Colorful_Gold(let strength):
                    return (strength: strength, key: "C360_Colorful_Gold")
                case .C360_Colorful_Purple(let strength):
                    return (strength: strength, key: "C360_Colorful_Purple")
                case .C360_ShiftColor_Red1(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Red1")
                case .C360_ShiftColor_Red2(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Red2")
                case .C360_ShiftColor_Yellow1(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Yellow1")
                case .C360_ShiftColor_Green(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Green")
                case .C360_ShiftColor_Blue(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Blue")
                case .C360_ShiftColor_SkyBlue(let strength):
                    return (strength: strength, key: "C360_ShiftColor_SkyBlue")
                case .C360_ShiftColor_Yellow2(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Yellow2")
                case .C360_ShiftColor_Purple(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Purple")
                case .C360_ShiftColor_Summer(let strength):
                    return (strength: strength, key: "C360_ShiftColor_Summer")
                case .C360_BW_Normal(let strength):
                    return (strength: strength, key: "C360_BW_Normal")
                case .C360_BW_Enhance(let strength):
                    return (strength: strength, key: "C360_BW_Enhance")
                case .C360_BW_Strong(let strength):
                    return (strength: strength, key: "C360_BW_Strong")
                case .C360_BW_Storm(let strength):
                    return (strength: strength, key: "C360_BW_Storm")
                case .C360_BW_Art(let strength):
                    return (strength: strength, key: "C360_BW_Art")
                }
            }
        }
    }
    
    private static let APIKey = "59a7a0f37295551da9232d88"
    private static let SecretKey = "i7wDmunVEq5z21DrHLIyGws23NJwmfgFzwcykwb1"
    private static let APIDomain = "https://effectapi.camera360.com"
    
    private static func generateAccessToken(byURL url: String, body: String?) -> String? {
        
        var data = url + "\n"
        if let body = body {
            data += body
        }
        
        if let cKey = SecretKey.cStringUsingEncoding(NSUTF8StringEncoding), let cData = data.cStringUsingEncoding(NSUTF8StringEncoding) {
            var result = [CUnsignedChar](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
            CCHmac(
                CCHmacAlgorithm(kCCHmacAlgSHA1),
                cKey,
                Int(strlen(cKey)),
                cData,
                Int(strlen(cData)),
                &result
            )
            let hmacData = NSData(bytes: result, length: (Int(CC_SHA1_DIGEST_LENGTH)))
            let hmacBase64 = hmacData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
            return "Camera360 " + APIKey + ":" + String(hmacBase64).stringByReplacingOccurrencesOfString("+", withString: "-").stringByReplacingOccurrencesOfString("/", withString: "_")
        }
        
        return nil
        
    }
    
    private static func camera360Request(byPath path: String, method: Alamofire.Method, parameters: [String: String] = [:]) -> URLRequest? {
        
        if let url = URL(string: APIDomain + path) {
            
            var bodyList = [String]()
            for (k, v) in parameters {
                if let key = k.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()),
                    let value = v.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                    bodyList.append(key + "=" + value)
                }
            }
            
            let bodyString = bodyList.joinWithSeparator("&")
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = method.rawValue
            request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
            
            if let accessToken = generateAccessToken(byURL: path, body: bodyString) {
                request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            }
            
            return request
            
        }
        
        return nil
    }
    
    static func uploadToken(uploadOnly: Bool = false) -> Promise<Resource> {
        return Promise<Resource> { fulfill, reject in
            
            let path = "/uploadtoken?uploadOnly=" + (uploadOnly ? "1" : "0")
            
            if let request = camera360Request(
                byPath: path,
                method: .GET
                ) {
                
                Alamofire
                    .request(request)
                    .validate()
                    .responseJSON(completionHandler: { (response) in
                        switch response.result {
                        case .Success(let value):
                            if let uploadToken = Mapper<Resource>().map(JSONString: value) {
                                fulfill(uploadToken)
                            } else {
                                reject(Error.mappingError.error)
                            }
                        case .Failure(let error):
                            reject(error)
                        }
                    })
                
            } else {
                reject(Error.invalidRequst.error)
            }
        }
    }
    
    static func upload(image: UIImage, forResource resource: Resource, wtihFilter filter: Filter, rotateAngle: Int = 0, mirrorX: Int = 0, mirrorY: Int = 0) -> Promise<Result> {
        return Promise<Result> { fulfill, reject in
            
            if !resource.valid() {
                reject(Error.invalidResource.error)
                return
            }
            
            Alamofire.upload(
                .POST,
                resource.uphost!,
                headers : nil,
                multipartFormData: { multipartFormData in
                    
                    let addPostData = { (key: String, value: String) in
                        if let valueData = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                            multipartFormData.appendBodyPart(data: valueData, name : key)
                        }
                    }
                    
                    if let fileData = UIImageJPEGRepresentation(image, 1.0) {
                        multipartFormData.appendBodyPart(data: fileData, name: "file", fileName: "image.jpeg", mimeType: "image/jpeg")
                    }
                    
                    let (key, strength) = filter.values
                    
                    addPostData("key", resource.key!)
                    addPostData("token", resource.token!)
                    addPostData("x:filter", "\(key)")
                    addPostData("x:strength", "\(strength)")
                    addPostData("x:rotateAngle", "\(rotateAngle)")
                    addPostData("x:mirrorX", "\(mirrorX)")
                    addPostData("x:mirrorY", "\(mirrorY)")
                    
                },
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .Success(let request, _, _):
                        request.validate().responseJSON(completionHandler: { (response) in
                            switch response.result {
                            case .Success(let value):
                                if let result = Mapper<Result>().map(JSONString: value) {
                                    fulfill(result)
                                } else {
                                    reject(Error.mappingError.error)
                                }
                            case .Failure(let error):
                                reject(error)
                            }
                        })
                    case .Failure(let encodingError):
                        reject(encodingError)
                    }
                }
                
            )
            
        }
    }
    
    static func update(filter: Filter, rotateAngle: Int = 0, mirrorX: Int = 0, mirrorY: Int = 0, forResource resource: Resource) -> Promise<Result> {
        return Promise<Result> { fulfill, reject in
            
            if !resource.valid() {
                reject(Error.invalidResource.error)
                return
            }
            
            let path = "/pics/" + resource.key! + "/effects"
            let (key, strength) = filter.values
            
            if let request = camera360Request(
                byPath: path,
                method: .POST,
                parameters: [
                    "x:filter": "\(key)",
                    "x:strength": "\(strength)",
                    "x:rotateAngle": "\(rotateAngle)",
                    "x:mirrorX": "\(mirrorX)",
                    "x:mirrorY": "\(mirrorY)",
                ]) {
                
                Alamofire.request(request).validate()
                    .responseJSON(completionHandler: { (response) in
                        switch response.result {
                        case .Success(let value):
                            if let result = Mapper<Result>().map(JSONString: value) {
                                fulfill(result)
                            } else {
                                reject(Error.mappingError.error)
                            }
                        case .Failure(let error):
                            reject(error)
                        }
                    })
                
            } else {
                reject(Error.invalidRequst.error)
            }
        }
    }
    
    private enum Error {
        case mappingError
        case invalidResource
        case invalidRequst
        
        var error: NSError {
            switch self {
            case .mappingError:
                return NSError(domain: "Camera30", code: -1, userInfo: ["reason": "Map object fail"])
            case .invalidResource:
                return NSError(domain: "Camera30", code: -2, userInfo: ["reason": "Invalid resource"])
            case .invalidRequst:
                return NSError(domain: "Camera30", code: -2, userInfo: ["reason": "Invalid request"])
            }
        }
    }
    
    struct Resource: Mappable {
        
        private(set) var key: String?
        private(set) var uphost: String?
        private(set) var token: String?
        
        init?(map: Map) {
            
        }
        
        mutating func mapping(map: Map) {
            key <- map["key"]
            uphost <- map["uphost"]
            token <- map["token"]
        }
        
        func valid() -> Bool {
            return key != nil && uphost != nil && token != nil
        }
    }
    
    struct Result: Mappable {
        
        private(set) var url: String?
        
        init?(map: Map) {
            
        }
        
        mutating func mapping(map: Map) {
            url <- map["url"]
        }
        
        func valid() -> Bool {
            return url != nil
        }
    }
    
}
