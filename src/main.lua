-- text_style_copier.lua
-- DaVinci Resolve 20 用 TEXT+ スタイルコピーツール
-- フォント・サイズ・カラー・位置などを一括変更する
--
-- 使い方:
--   ワークスペース > スクリプト > Utility > text_style_copier

--------------------------------------------------------------------------------
-- Globals (DaVinci Resolve Lua 実行環境で自動定義)
--   resolve  : ResolveAPI
--   fu       : FusionApp  (UIManager を持つ)
--   bmd      : BlackmagicDesign モジュール
--------------------------------------------------------------------------------

local ui   = fu.UIManager
local disp = bmd.UIDispatcher(ui)

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local copiedStyle = nil  -- コピーしたスタイル (Lua table)

--------------------------------------------------------------------------------
-- TEXT+ から読み書きするプロパティ定義
-- id    : Fusion input の ID
-- label : UIログ用の日本語ラベル
--------------------------------------------------------------------------------

-- コピー対象の TEXT+ プロパティ (許可リスト方式)
-- ダンプで取得した実際の入力 ID に基づく
-- StyledText・内部設定・userdata は除外
local ALLOWED_INPUTS = {
    -- フォント基本
    Font = true, Style = true, Size = true,
    AdvancedFontControls = true, FontFeatures = true,
    StylisticSet = true, UseFontKerning = true,
    UseLigatures = true, SplitLigatures = true,
    ForceMonospaced = true, FitCharacters = true,

    -- テキスト装飾
    Underline = true, UnderlinePosition = true, Strikeout = true,

    -- 文字間・行間
    CharacterSpacing = true, CharacterSpacingClone = true,
    LineSpacing = true, LineSpacingClone = true,
    WordSpacing = true, TabSpacing = true,
    Tab = true,
    Tab1Alignment = true, Tab1Position = true,
    Tab2Alignment = true, Tab2Position = true,
    Tab3Alignment = true, Tab3Position = true,
    Tab4Alignment = true, Tab4Position = true,
    Tab5Alignment = true, Tab5Position = true,
    Tab6Alignment = true, Tab6Position = true,
    Tab7Alignment = true, Tab7Position = true,
    Tab8Alignment = true, Tab8Position = true,

    -- 文字変形
    CharacterAngleX = true, CharacterAngleY = true, CharacterAngleZ = true,
    CharacterOffset = true, CharacterOffsetZ = true,
    CharacterPivot = true, CharacterPivotZ = true,
    CharacterRotationOrder = true,
    CharacterShearX = true, CharacterShearY = true,
    CharacterSizeX = true, CharacterSizeY = true,

    -- ワード変形
    WordAngleX = true, WordAngleY = true, WordAngleZ = true,
    WordOffset = true, WordOffsetZ = true,
    WordPivot = true, WordPivotZ = true,
    WordRotationOrder = true,
    WordShearX = true, WordShearY = true,
    WordSizeX = true, WordSizeY = true,

    -- ライン変形
    LineAngleX = true, LineAngleY = true, LineAngleZ = true,
    LineDirection = true,
    LineOffset = true, LineOffsetZ = true,
    LinePivot = true, LinePivotZ = true,
    LineRotationOrder = true,
    LineShearX = true, LineShearY = true,
    LineSizeX = true, LineSizeY = true,

    -- 位置・回転
    Center = true, CenterZ = true, CenterBias = true,
    CenterOnBaseOfFirstLine = true,
    AngleX = true, AngleY = true, AngleZ = true,
    RotationOrder = true,

    -- レイアウト
    Layout = true, LayoutType = true, LayoutRotation = true,
    LayoutSize = true, LayoutWidth = true, LayoutHeight = true,
    Direction = true, ReadingDirection = true, Orientation = true,
    Perspective = true, PositionOnPath = true,
    Scroll = true, ScrollPosition = true,
    Wrap = true,
    AdaptCharacterWidthToAngle = true, AdaptWordWidthToAngle = true,

    -- 揃え
    HorizontalLeftCenterRight = true,
    HorizontalJustificationNew = true,
    HorizontalJustificationLeft = true,
    HorizontalJustificationCenter = true,
    HorizontalJustificationRight = true,
    HorizontallyJustified = true,
    VerticalTopCenterBottom = true,
    VerticalJustification = true,
    VerticalJustificationNew = true,
    VerticalJustificationTop = true,
    VerticalJustificationCenter = true,
    VerticalJustificationBottom = true,
    VerticallyJustified = true,

    -- カラー (グローバル)
    Alpha = true, Red = true, Green = true, Blue = true,

    -- カラー (要素1: テキスト)
    Alpha1 = true, Alpha1Clone = true,
    Red1 = true, Red1Clone = true,
    Green1 = true, Green1Clone = true,
    Blue1 = true, Blue1Clone = true,

    -- カラー (要素3: シャドウ等)
    Alpha3 = true, Red3 = true, Green3 = true, Blue3 = true,

    -- シェーディング要素 有効/無効 (1-8)
    Enabled1 = true, Enabled2 = true, Enabled3 = true, Enabled4 = true,
    Enabled5 = true, Enabled6 = true, Enabled7 = true, Enabled8 = true,

    -- シェーディング要素 名前 (1-8)
    Name1 = true, Name2 = true, Name3 = true, Name4 = true,
    Name5 = true, Name6 = true, Name7 = true, Name8 = true,

    -- シェーディング制御
    ShadingElements = true, SortShadingElements = true,
    Select = true, SelectElement = true,

    -- 要素1 プロパティ
    Level1 = true, Type1 = true, Position1 = true, PriorityBack1 = true,
    Properties1 = true,
    ElementShape1 = true, ElementSeparator1 = true, ElementSpacer1 = true,
    Thickness1 = true, ColorBrush1 = true, ColorFile1 = true,
    Opacity1 = true,
    Softness1 = true, SoftnessX1 = true, SoftnessY1 = true,
    SoftnessBlend1 = true, SoftnessGlow1 = true, SoftnessOnFillColorToo1 = true,
    JoinStyle1 = true, LineStyle1 = true, MiterLimit1 = true,
    Round1 = true, Overlap1 = true,
    CleanIntersections1 = true, OutsideOnly1 = true,
    Offset1 = true, OffsetZ1 = true,
    Pivot1 = true, PivotZ1 = true, PivotNest1 = true,
    Rotation1 = true, Shear1 = true,
    ShearX1 = true, ShearY1 = true,
    Size1 = true, SizeX1 = true, SizeY1 = true,
    AngleX1 = true, AngleY1 = true, AngleZ1 = true,
    ExtendHorizontal1 = true, ExtendVertical1 = true,
    AdaptThicknessToPerspective1 = true,
    ImageShadingEdges1 = true, ImageShadingSampling1 = true, ImageSource1 = true,
    ShadingMapping1 = true, ShadingMappingAngle1 = true,
    ShadingMappingAspect1 = true, ShadingMappingLevel1 = true,
    ShadingMappingSize1 = true, ShadingMappingSpacer1 = true,

    -- 要素3 プロパティ
    Level3 = true, Type3 = true, Position3 = true, PriorityBack3 = true,
    Properties3 = true,
    ElementShape3 = true, ElementSeparator3 = true, ElementSpacer3 = true,
    Thickness3 = true, ColorBrush3 = true, ColorFile3 = true,
    Opacity3 = true,
    Softness3 = true, SoftnessX3 = true, SoftnessY3 = true,
    SoftnessBlend3 = true, SoftnessGlow3 = true, SoftnessOnFillColorToo3 = true,
    JoinStyle3 = true, LineStyle3 = true, MiterLimit3 = true,
    Round3 = true, Overlap3 = true,
    CleanIntersections3 = true, OutsideOnly3 = true,
    Offset3 = true, OffsetZ3 = true,
    Pivot3 = true, PivotZ3 = true, PivotNest3 = true,
    Rotation3 = true, Shear3 = true,
    ShearX3 = true, ShearY3 = true,
    Size3 = true, SizeX3 = true, SizeY3 = true,
    AngleX3 = true, AngleY3 = true, AngleZ3 = true,
    ExtendHorizontal3 = true, ExtendVertical3 = true,
    AdaptThicknessToPerspective3 = true,
    ImageShadingEdges3 = true, ImageShadingSampling3 = true, ImageSource3 = true,
    ShadingMapping3 = true, ShadingMappingAngle3 = true,
    ShadingMappingAspect3 = true, ShadingMappingLevel3 = true,
    ShadingMappingSize3 = true, ShadingMappingSpacer3 = true,

    -- 変形タブ
    SelectTransform = true,
    TransformPivot = true, TransformRotation = true,
    TransformShear = true, TransformSize = true, TransformTransform = true,

    -- カーニング・配置
    ManualFontKerning = true, ManualFontPlacement = true,
    KerningSeparator = true,

    -- その他
    Background = true, Depth = true,
    LayerSpacer = true, TextText = true,
    Blank2 = true, Blank5 = true,
}

--------------------------------------------------------------------------------
-- Helper: 値を見やすい文字列に変換 (ログ表示用)
--------------------------------------------------------------------------------

local function fmt_val(v)
    if type(v) == "table" then
        local parts = {}
        for k, x in pairs(v) do
            local num = tonumber(x)
            if num then
                parts[#parts + 1] = tostring(k) .. "=" .. string.format("%.3f", num)
            else
                parts[#parts + 1] = tostring(k) .. "=" .. tostring(x)
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

--------------------------------------------------------------------------------
-- Helper: Resolve コンテキスト取得
--------------------------------------------------------------------------------

local function get_context()
    if not resolve then return nil, nil, "Resolve が利用できません" end
    local pm = resolve:GetProjectManager()
    if not pm then return nil, nil, "ProjectManager 取得失敗" end
    local proj = pm:GetCurrentProject()
    if not proj then return nil, nil, "プロジェクトが開かれていません" end
    local tl = proj:GetCurrentTimeline()
    if not tl then return nil, nil, "タイムラインがありません" end
    return proj, tl, nil
end

--------------------------------------------------------------------------------
-- Helper: プロジェクトの FPS 取得
--------------------------------------------------------------------------------

local function get_fps(proj)
    local v = proj:GetSetting("timelineFrameRate")
    return tonumber(v) or 24
end

--------------------------------------------------------------------------------
-- Helper: タイムコード文字列 → 絶対フレーム番号
-- "HH:MM:SS:FF" および "HH:MM:SS;FF" (Drop Frame) に対応
--------------------------------------------------------------------------------

local function tc_to_frames(tc, fps)
    -- HH:MM:SS:FF または HH:MM:SS.FF
    local h, m, s, f = tc:match("^(%d+):(%d+):(%d+)[:%.](%d+)$")
    if not h then
        -- Drop Frame セミコロン区切り
        h, m, s, f = tc:match("^(%d+):(%d+):(%d+);(%d+)$")
    end
    if not h then
        return nil, "タイムコード形式エラー: " .. tostring(tc)
    end
    local frames = math.floor(
        (tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)) * fps
        + tonumber(f)
    )
    return frames, nil
end

--------------------------------------------------------------------------------
-- Helper: タイムライン開始タイムコードをフレーム数に変換
--------------------------------------------------------------------------------

local function timeline_start_frames(tl, fps)
    local tc = tl:GetStartTimecode()
    if not tc then return 0 end
    local f, _ = tc_to_frames(tc, fps)
    return f or 0
end

--------------------------------------------------------------------------------
-- Helper: 指定トラックの再生ヘッド位置にあるクリップを探す
-- frame がクリップの [Start, End) 範囲内なら一致とみなす
-- 絶対フレームと相対フレームの両方を試行する
--------------------------------------------------------------------------------

local function find_clip_at_frame(tl, track_idx, abs_frame, rel_frame)
    local items = tl:GetItemListInTrack("video", track_idx)
    if not items then return nil, "トラックにクリップがありません" end

    -- まず絶対フレームで検索
    for _, item in ipairs(items) do
        local s = item:GetStart()
        local e = item:GetEnd()
        if s <= abs_frame and abs_frame < e then
            return item, nil
        end
    end
    -- 次に相対フレームで検索
    for _, item in ipairs(items) do
        local s = item:GetStart()
        local e = item:GetEnd()
        if s <= rel_frame and rel_frame < e then
            return item, nil
        end
    end

    -- 見つからない場合、デバッグ用にクリップ一覧を返す
    local dbg = {}
    for i, item in ipairs(items) do
        local s = item:GetStart()
        local e = item:GetEnd()
        dbg[#dbg + 1] = string.format(
            "  clip%d: start=%s end=%s name=%s",
            i, tostring(s), tostring(e), item:GetName() or "?")
        if i >= 8 then
            dbg[#dbg + 1] = string.format("  ... 他 %d 件", #items - 8)
            break
        end
    end
    local detail = string.format(
        "abs_frame=%d, rel_frame=%d, clips=%d\n%s",
        abs_frame, rel_frame, #items, table.concat(dbg, "\n"))
    return nil, detail
end

--------------------------------------------------------------------------------
-- Helper: タイムラインアイテムから TextPlus ツールと Comp を取得
--------------------------------------------------------------------------------

local function find_textplus(item)
    if item:GetFusionCompCount() == 0 then return nil, nil end
    local comp = item:GetFusionCompByIndex(1)
    if not comp then return nil, nil end
    local tools = comp:GetToolList(false, "TextPlus")
    if not tools then return nil, nil end
    for _, tool in pairs(tools) do
        return tool, comp  -- 最初に見つかった TextPlus を使用
    end
    return nil, nil
end

--------------------------------------------------------------------------------
-- Helper: スタイル読み取り
--------------------------------------------------------------------------------

local function read_style(tool)
    local style = {}
    local log_lines = {}
    local count = 0
    for id, _ in pairs(ALLOWED_INPUTS) do
        local ok, v = pcall(function()
            return tool:GetInput(id, 0)
        end)
        if ok and v ~= nil then
            style[id] = v
            count = count + 1
            log_lines[#log_lines + 1] = "  ✓ " .. id .. " = " .. fmt_val(v)
        end
    end
    table.sort(log_lines)
    local summary = string.format("  (%d 個のプロパティを取得)", count)
    return style, summary .. "\n" .. table.concat(log_lines, "\n")
end

--------------------------------------------------------------------------------
-- Helper: TEXT+ の全入力 ID をダンプ (デバッグ用)
--------------------------------------------------------------------------------

local function dump_all_inputs(tool)
    local lines = {}
    local inputs = tool:GetInputList()
    if not inputs then
        return "入力一覧を取得できませんでした"
    end
    -- 入力を ID でソートするために一旦配列に集める
    local entries = {}
    for _, inp in pairs(inputs) do
        local attrs = inp:GetAttrs()
        local id = attrs and attrs.INPS_ID
        if id then
            local ok, v = pcall(function()
                return tool:GetInput(id, 0)
            end)
            local vstr = (ok and v ~= nil) and fmt_val(v) or "(nil)"
            local vtype = (ok and v ~= nil) and type(v) or "?"
            entries[#entries + 1] = string.format("%s [%s] = %s", id, vtype, vstr)
        end
    end
    table.sort(entries)
    return table.concat(entries, "\n")
end

--------------------------------------------------------------------------------
-- Helper: スタイル適用
-- comp:Lock()/Unlock() で変更をバッチ化し、pcall で安全に実行
--------------------------------------------------------------------------------

local function apply_style(tool, comp, style)
    local log_lines = {}
    local ok_count = 0
    local fail_count = 0
    comp:Lock()
    local function do_apply()
        for id, val in pairs(style) do
            local ok, err = pcall(function()
                tool:SetInput(id, val, 0)
            end)
            if ok then
                ok_count = ok_count + 1
            else
                fail_count = fail_count + 1
                log_lines[#log_lines + 1] = "    ✗ " .. id
                    .. " (" .. tostring(err) .. ")"
            end
        end
    end
    local ok, err = pcall(do_apply)
    comp:Unlock()
    if not ok then
        log_lines[#log_lines + 1] = "    [エラー] " .. tostring(err)
    end
    local summary = string.format("    %d 適用 / %d 失敗", ok_count, fail_count)
    if #log_lines > 0 then
        return summary .. "\n" .. table.concat(log_lines, "\n")
    end
    return summary
end

--------------------------------------------------------------------------------
-- Helper: ビデオトラック名リスト取得
--------------------------------------------------------------------------------

local function get_track_names(tl)
    local names = {}
    local count = tl:GetTrackCount("video")
    for i = 1, count do
        local name = tl:GetTrackName("video", i)
        names[#names + 1] = string.format("V%d  %s", i, name or "")
    end
    return names
end

--------------------------------------------------------------------------------
-- UI 定義
--------------------------------------------------------------------------------

local win = disp:AddWindow({
    ID = "TxtStyleCopier",
    WindowTitle = "TEXT+ スタイルコピーツール",
    Geometry = {120, 120, 480, 460},

    ui:VGroup{
        ID   = "root",
        Spacing = 8,

        -- ---- コピー元 ----
        ui:Label{ Text = "■ コピー元 TEXT+" },

        ui:HGroup{
            Spacing = 4,
            ui:Label{   Text = "ソーストラック:", MinimumSize = {130, 0} },
            ui:ComboBox{ ID = "srcTrack" },
        },
        ui:Label{ Text = "再生ヘッド位置の TEXT+ を自動取得します", Alignment = { AlignHCenter = true } },
        ui:HGroup{
            Spacing = 4,
            ui:Button{ ID = "btnCopy",    Text = "スタイルをコピー (再生ヘッド位置)" },
            ui:Button{ ID = "btnRefresh", Text = "↻ トラック更新", MinimumSize = {110, 0} },
        },

        ui:Label{ Text = "" },  -- スペーサー

        -- ---- コピー先 ----
        ui:Label{ Text = "■ コピー先トラック" },

        ui:HGroup{
            Spacing = 4,
            ui:Label{    Text = "ターゲットトラック:", MinimumSize = {130, 0} },
            ui:ComboBox{ ID = "dstTrack" },
        },
        ui:HGroup{
            ui:Button{
                ID      = "btnApply",
                Text    = "スタイルを適用",
                Enabled = false,
            },
        },

        ui:Label{ Text = "" },  -- スペーサー

        -- ---- ログ ----
        ui:Label{ Text = "ログ:" },
        ui:TextEdit{
            ID       = "logBox",
            ReadOnly = true,
            Weight   = 1,
        },
    },
})

--------------------------------------------------------------------------------
-- ログ操作
--------------------------------------------------------------------------------

local function log_set(msg)
    win:Find("logBox").PlainText = msg
end

local function log_append(msg)
    local box = win:Find("logBox")
    local cur = box.PlainText
    box.PlainText = (cur == "") and msg or (cur .. "\n" .. msg)
end

--------------------------------------------------------------------------------
-- トラックコンボボックスの初期化
--------------------------------------------------------------------------------

local function populate_tracks()
    local _, tl, err = get_context()
    local src = win:Find("srcTrack")
    local dst = win:Find("dstTrack")
    src:Clear()
    dst:Clear()
    if err then
        log_append("[エラー] " .. err)
        return
    end
    local names = get_track_names(tl)
    for _, n in ipairs(names) do
        src:AddItem(n)
        dst:AddItem(n)
    end
    log_append("[情報] " .. #names .. " トラックを読み込みました")
end

--------------------------------------------------------------------------------
-- イベントハンドラ: トラック更新ボタン
--------------------------------------------------------------------------------

win.On.btnRefresh.Clicked = function(_ev)
    populate_tracks()
end

--------------------------------------------------------------------------------
-- Helper: 確認ダイアログ
--------------------------------------------------------------------------------

local function confirm_dialog(title, message)
    local dlg = disp:AddWindow({
        ID = "ConfirmDlg",
        WindowTitle = title,
        Geometry = {200, 200, 400, 140},
        ui:VGroup{
            Spacing = 8,
            ui:Label{ Text = message, Alignment = { AlignHCenter = true }, WordWrap = true },
            ui:HGroup{
                Spacing = 8,
                ui:Button{ ID = "btnYes", Text = "はい" },
                ui:Button{ ID = "btnNo",  Text = "キャンセル" },
            },
        },
    })
    local result = false
    dlg.On.btnYes.Clicked = function() result = true; disp:ExitLoop() end
    dlg.On.btnNo.Clicked  = function() result = false; disp:ExitLoop() end
    dlg.On.ConfirmDlg.Close = function() result = false; disp:ExitLoop() end
    dlg:Show()
    disp:RunLoop()
    dlg:Hide()
    return result
end

--------------------------------------------------------------------------------
-- イベントハンドラ: スタイルをコピー
--------------------------------------------------------------------------------

win.On.btnCopy.Clicked = function(_ev)
    copiedStyle = nil
    win:Find("btnApply").Enabled = false

    local proj, tl, err = get_context()
    if err then log_append("[エラー] " .. err); return end

    local src_idx = win:Find("srcTrack").CurrentIndex + 1

    -- 再生ヘッドのタイムコードを自動取得
    local cur_tc = tl:GetCurrentTimecode()
    if not cur_tc or cur_tc == "" then
        log_append("[エラー] 再生ヘッドのタイムコードを取得できませんでした")
        return
    end

    local fps   = get_fps(proj)
    local abs_f, tc_err = tc_to_frames(cur_tc, fps)
    if tc_err then log_append("[エラー] " .. tc_err); return end

    local start_f = timeline_start_frames(tl, fps)
    local rel_f   = abs_f - start_f

    local item, dbg = find_clip_at_frame(tl, src_idx, abs_f, rel_f)
    if not item then
        log_append(string.format(
            "[エラー] 再生ヘッド (TC=%s) の位置にクリップが見つかりません (track=V%d)\nfps=%s, %s",
            cur_tc, src_idx, tostring(fps), dbg or ""))
        return
    end

    local tool, _comp = find_textplus(item)
    if not tool then
        log_append("[エラー] TEXT+ が見つかりません: " .. (item:GetName() or "不明"))
        return
    end

    local style, details = read_style(tool)
    copiedStyle = style
    win:Find("btnApply").Enabled = true

    log_set(string.format(
        "[OK] コピー完了: %s (再生ヘッド TC=%s)\n%s",
        item:GetName() or "?", cur_tc, details))
end

--------------------------------------------------------------------------------
-- イベントハンドラ: スタイルを適用
--------------------------------------------------------------------------------

win.On.btnApply.Clicked = function(_ev)
    if not copiedStyle then
        log_append("[エラー] コピーされたスタイルがありません")
        return
    end

    local _, tl, err = get_context()
    if err then log_append("[エラー] " .. err); return end

    local dst_idx = win:Find("dstTrack").CurrentIndex + 1
    local items   = tl:GetItemListInTrack("video", dst_idx)
    if not items then
        log_append("[エラー] クリップ一覧の取得に失敗しました")
        return
    end

    -- TEXT+ の件数をカウント
    local textplus_count = 0
    for _, item in ipairs(items) do
        local tool, _ = find_textplus(item)
        if tool then textplus_count = textplus_count + 1 end
    end

    if textplus_count == 0 then
        log_append("[エラー] ターゲットトラックにTEXT+がありません")
        return
    end

    -- 確認ダイアログ
    local track_name = tl:GetTrackName("video", dst_idx) or ""
    local msg = string.format(
        "V%d (%s) の TEXT+ %d 件にスタイルを適用します。\nよろしいですか？",
        dst_idx, track_name, textplus_count)
    if not confirm_dialog("スタイル適用の確認", msg) then
        log_append("[情報] キャンセルされました")
        return
    end

    local applied = 0
    local skipped = 0
    local result_lines = {}

    -- 適用ボタンを無効化して処理中表示
    win:Find("btnApply").Enabled = false
    win:Find("btnApply").Text = "適用中..."
    log_set(string.format("[処理中] 0 / %d ...", textplus_count))

    for _, item in ipairs(items) do
        local tool, comp = find_textplus(item)
        if tool then
            local details = apply_style(tool, comp, copiedStyle)
            applied = applied + 1
            result_lines[#result_lines + 1] = string.format(
                "  適用: %s\n%s", item:GetName() or "?", details)
        else
            skipped = skipped + 1
        end
    end

    win:Find("btnApply").Text = "スタイルを適用"
    win:Find("btnApply").Enabled = true

    local summary = string.format(
        "[完了] %d件に適用 / %d件スキップ (TEXT+以外)",
        applied, skipped)
    log_set(summary .. "\n" .. table.concat(result_lines, "\n"))
end

--------------------------------------------------------------------------------
-- イベントハンドラ: ウィンドウを閉じる
--------------------------------------------------------------------------------

win.On.TxtStyleCopier.Close = function(_ev)
    disp:ExitLoop()
end

--------------------------------------------------------------------------------
-- 起動
--------------------------------------------------------------------------------

populate_tracks()
win:Show()
disp:RunLoop()
win:Hide()
