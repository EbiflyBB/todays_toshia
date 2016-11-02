#-*- coding: utf-8 -*-
Plugin.create :today_toshia do
  toshia_user_id = 15926668
  on_appear do |ms|
    ms.each do |m|

      if Time.now - m[:created] > 10
        next
      end
      
      if m.message.to_s.include?('@todays_toshia ') then
        past_toshia = return_toshia(m.message.to_s)
        if past_toshia != nil then
          Service.primary.post(:message => "@#{m.user.to_s} #{past_toshia}", :replyto => m)
        end
      end

      if m.to_message.user.id == toshia_user_id
        #.mikutter/settingsまでしか取得できなかったのでくっつける
        set_dir = Environment::SETTINGDIR + "/today_toshia/"
        # ディレクトリtoday_toshiaを作成
        FileUtils.mkdir("#{set_dir}") unless FileTest.exist?("#{set_dir}")
        #月毎に保存したいので日付を取得
        what_date = Date.today
        date_month = "%02d" % ["#{what_date.month}"]
        date_day = "%02d" % ["#{what_date.day}"]
        #yyyymmという文字列を作成し、絶対パスにする
        create_filename = "#{set_dir}" + "#{what_date.year}#{date_month}"
        #としぁさんのscreen_name 比較用に改行いるっぽい
        now_toshia = "#{m.to_message.user[:name]}\n"

        #月またいだとかでファイルがなかったら取り敢えず作る
        #Winだと/r/nになってしまうらしいのでバイナリモード？
        File.open("#{create_filename}.dat","ab") do |file|
          file.close
        end

        prev_toshias = []
        #月毎だしそんなに肥大化しないハズなので簡潔にするため一気に読み込む
        #Winだと動かなかったけど文字コード指定したら動いた
        File.open("#{create_filename}.dat","rb:utf-8") do |file|
          prev_toshias = file.readlines
          file.close
        end
        #先月の名前を見てみる
        if prev_toshias == []
          prev_toshias = check_lastmonth(what_date.year, date_month, set_dir)
        end
        #書き込むかもしれないのでとりあえず要素数を取得
        File.open("#{create_filename}.dat", "a+b") do |file|
          prev_name_num = prev_toshias.size
          last_toshia = prev_toshias[prev_name_num - 1] || "   "
          #"日付 "を削除
          #仮にhoge = を下行に追加すると日付側がhogeに格納されるっぽい
          last_toshia.slice!(0, 3)

          #もし最後の行と違うかったら書き込む
          if now_toshia != last_toshia
            file.puts "#{date_day} #{now_toshia}"
            file.close
            Service.primary.post(:message => "#{last_toshia} ↓ 
#{m.to_message.user[:name]} \n#今日のとしぁ", :replyto => m)
          end
        end
      end
    end
  end

  def check_lastmonth(this_year, this_month, set_dir)
    if this_month == "01"
      this_month = "12"
      this_year = "%04d" % [(this_year.to_i) - 1 ]
    else
      this_month = "%02d" % [(this_month.to_i) - 1 ]
    end

    lastmonth_filename = "#{set_dir}" + "#{this_year.to_s}" + "#{this_month.to_s}"
    #先月の名前を読み込む
    lastmonth_toshias = []
#この時点で先月のファイルがないとエラーらしい
    if FileTest.exist?("#{lastmonth_filename}.dat")
      File.open("#{lastmonth_filename}.dat", "rb:utf-8") do |file|
        lastmonth_toshias = file.readlines
        file.close
      end
    else
        lastmonth_toshias = check_lastmonth(this_year, this_month, set_dir)      
    end

#もし先月のファイルすらなかったら再帰 動くかは知らない
    if lastmonth_toshias == []
      if this_year == "2015"
        return ["00 ておくれ としぁ"]
      else
        lastmonth_toshias = check_lastmonth(this_year, this_month, set_dir)
      end
    end

    #今月にする
    if this_month == "12"
      next_month = "01"
      next_year = "%04d" % [(this_year.to_i) + 1]
    else
      next_month = "%02d" % [(this_month.to_i) + 1]
      next_year = this_year.to_s
    end

    lastmonth_name_size = lastmonth_toshias.size
    lastmonth_finaltoshia = lastmonth_toshias[lastmonth_name_size - 1] || "   "
    lastmonth_finaltoshia.slice!(0, 3)

    File.open("#{set_dir}#{next_year}#{next_month}.dat", "a+b:utf-8") do |file|
      file.puts "00 #{lastmonth_finaltoshia}"
    end

    return ["00 #{lastmonth_finaltoshia}"]
  end

  def return_toshia(rep_str)
    require 'date'
    date_str = rep_str.slice(15..-1)

    begin
      days = Date.parse(date_str)
    rescue
      return nil
    end

    if days != nil then
      set_dir = Environment::SETTINGDIR + "/today_toshia/"

      filename = "#{set_dir}#{days.year}#{days.strftime("%m")}"
      prev_toshias = get_toshias(filename)

      search_result = nil
      while(days.strftime("%Y%m%d") != '20141130' )
        if (days + 1).day.to_i == 1 then
          filename = "#{set_dir}#{days.year}#{days.strftime("%m")}"
          prev_toshias = get_toshias(filename)

        end

        search_result = prev_toshias.find { |t| t.slice(0, 2) == days.strftime("%d") }
        days -= 1

        if  search_result != nil then
          break
        end
      end
      
      if search_result != nil then
        search_result.slice!(0, 3)
      end

      p search_result
      return search_result

    else
      return nil
    end
  end

  def get_toshias(filename)
    prev_toshias = []
  
      begin
        File.open("#{filename}.dat","rb:utf-8") do |file|
          prev_toshias = file.readlines
          file.close
        end
      rescue
      end
      
    return prev_toshias
  end
  
end
