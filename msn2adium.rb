#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'hpricot'
require 'cgi'

MSN_ACCOUNT="your account address @ msn messenger"
SELF_SCREEN_NAME_REGEXP=Regexp.new("^msn2adium")
MSN_LOG_DIR="#{ENV['HOME']}/Documents/Microsoft User Data/Microsoft Messenger History/Personal/#{MSN_ACCOUNT}"
ADIUM_LOG_DIR="#{ENV['HOME']}/Library/Application Support/Adium 2.0/Users/Default/Logs/MSN.#{MSN_ACCOUNT}"
TIMEZONE="+0900"

FILE_REGEXP=Regexp.new(".*Messenger ([0-9]+).([0-9]+).([0-9]+) (.*)\.htm$")
FIRST_REGEXP=Regexp.new("^To: (.*)Start Time: ([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2}) ([A-Z]{2}); End Time: ([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2}) ([A-Z]{2})$")
SENDER_REGEXP=Regexp.new("^(.*) says: \\\(([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2}) ([A-Z]{2})\\\)$")

errors = []

if File.exist?("#{MSN_LOG_DIR}")
  if File::ftype("#{MSN_LOG_DIR}") == "directory"
  else
    errors << "#{MSN_LOG_DIR} is not a directory."
  end
else
  errors << "#{MSN_LOG_DIR} not found."
end

if File.exist?("#{ADIUM_LOG_DIR}")
  if File::ftype("#{ADIUM_LOG_DIR}") == "directory"
  else
    errors << "#{ADIUM_LOG_DIR} is not a directory."
  end
else
  errors << "#{ADIUM_LOG_DIR} not found."
end

if errors.size > 0
  errors.each{|error|
    print "Error: #{error}\n"
  }
  exit
end

Dir::entries("#{MSN_LOG_DIR}").each{|buddy_account|
  errors = []
  if buddy_account =~ Regexp.new("^.*@.*$")
  else
    errors << "#{buddy_account} is not your buddy."
  end
  if File::ftype("#{MSN_LOG_DIR}/#{buddy_account}") == "directory"
  else
    errors << "#{MSN_LOG_DIR}/#{buddy_account} is not a directory."
  end
  if File.exist?("#{ADIUM_LOG_DIR}/#{buddy_account}")
    if File::ftype("#{ADIUM_LOG_DIR}/#{buddy_account}") == "directory"
    else
      errors << "#{ADIUM_LOG_DIR}/#{buddy_account} is not a directory."
    end
  else
    Dir::mkdir("#{ADIUM_LOG_DIR}/#{buddy_account}")
  end
  if errors.size == 0
    Dir::glob("#{MSN_LOG_DIR}/#{buddy_account}/Messenger [0-9.]* *@*.htm").each{|buddy_log_file|
      if buddy_log_file =~ FILE_REGEXP
        year=sprintf("20%02d", $3.to_i)
        month=sprintf("%02d", $1.to_i)
        day=sprintf("%02d", $2.to_i)
        date="#{year}/#{month}/#{day}"
      end
      doc =  Hpricot(open(buddy_log_file))
      log_name = ''
      sHour='00'
      sMinute='00'
      sSecond='00'
      eHour='00'
      eMinute='00'
      eSecond='00'
      mSender = ''
      mTime = ''
      mMessage = ''
      new_log = ''
      converting = false
      doc.search("p").each{|pelement|
        if pelement.inner_text =~ FIRST_REGEXP
          if converting == true
            new_log = new_log + '<event type="windowClosed" sender="'
            new_log = new_log + "#{MSN_ACCOUNT}"
            new_log = new_log + '" time="'
            new_log = new_log + "#{year}-#{month}-#{day}T#{eHour}:#{eMinute}:#{eSecond}#{TIMEZONE}"
            new_log = new_log + '"/>'
            new_log = new_log + "\n"
            new_log = new_log + '</chat>'
            new_log = new_log + "\n"
            Dir::mkdir("#{ADIUM_LOG_DIR}/#{buddy_account}/#{log_name}.chatlog")
            open("#{ADIUM_LOG_DIR}/#{buddy_account}/#{log_name}.chatlog/#{log_name}.xml", "w") do |f|
              f.write new_log.to_s
            end
          end
          converting = true
          sHour=sprintf("%02d", $2.to_i)
          sMinute=sprintf("%02d", $3.to_i)
          sSecond=sprintf("%02d", $4.to_i)
          sMid=$5
          if sMid == "PM"
            sHour = sprintf("%02d", sHour.to_i + 12)
          end
          eHour=sprintf("%02d", $6.to_i)
          eMinute=sprintf("%02d", $7.to_i)
          eSecond=sprintf("%02d", $8.to_i)
          eMid=$9
          if eMid == "PM"
            eHour = sprintf("%02d", eHour.to_i + 12)
          end
          log_name="#{buddy_account} (#{year}-#{month}-#{day}T#{sHour}.#{sMinute}.#{sSecond}#{TIMEZONE})"
          new_log = '<?xml version="1.0" encoding="UTF-8" ?>'
          new_log = new_log + "\n"
          new_log = new_log + '<chat xmlns="http://purl.org/net/ulf/ns/0.4-02" account="'
          new_log = new_log + "#{MSN_ACCOUNT}"
          new_log = new_log + '" service="MSN"><event type="windowOpened" sender="'
          new_log = new_log + "#{MSN_ACCOUNT}"
          new_log = new_log + '" time="'
          new_log = new_log + "#{year}-#{month}-#{day}T#{sHour}:#{sMinute}:#{sSecond}#{TIMEZONE}"
          new_log = new_log + '"/>'
          new_log = new_log + "\n"
        elsif pelement.inner_text =~ SENDER_REGEXP
          mSender=$1
          mHour=sprintf("%02d", $2.to_i)
          mMinute=sprintf("%02d", $3.to_i)
          mSecond=sprintf("%02d", $4.to_i)
          mMid=$5
          if mMid == "PM"
            mHour = sprintf("%02d", mHour.to_i + 12)
          end
          mTime="#{year}-#{month}-#{day}T#{mHour}:#{mMinute}:#{mSecond}#{TIMEZONE}"
        else
          mMessage=CGI.escapeHTML(pelement.inner_text).gsub(/\r\n|\r|\n/, "<br />")
          new_log = new_log + '<message sender="'
          if mSender =~ SELF_SCREEN_NAME_REGEXP
            new_log = new_log + "#{MSN_ACCOUNT}"
          else
            new_log = new_log + "#{buddy_account}"
          end
          new_log = new_log + '" time="'
          new_log = new_log + "#{year}-#{month}-#{day}T#{sHour}:#{sMinute}:#{sSecond}#{TIMEZONE}"
          new_log = new_log + '" alias="'
          new_log = new_log + "#{mSender}"
          new_log = new_log + '"><div><span style="font-family: Helvetica; font-size: 12pt;">'
          new_log = new_log + "#{mMessage}"
          new_log = new_log + '</span></div></message>'
          new_log = new_log + "\n"
        end
      }
      if converting == true
        new_log = new_log + '<event type="windowClosed" sender="'
        new_log = new_log + "#{MSN_ACCOUNT}"
        new_log = new_log + '" time="'
        new_log = new_log + "#{year}-#{month}-#{day}T#{eHour}:#{eMinute}:#{eSecond}#{TIMEZONE}"
        new_log = new_log + '"/>'
        new_log = new_log + "\n"
        new_log = new_log + '</chat>'
        new_log = new_log + "\n"
        Dir::mkdir("#{ADIUM_LOG_DIR}/#{buddy_account}/#{log_name}.chatlog")
        open("#{ADIUM_LOG_DIR}/#{buddy_account}/#{log_name}.chatlog/#{log_name}.xml", "w") do |f|
          f.write new_log.to_s
        end
      end
    }
  end
}

