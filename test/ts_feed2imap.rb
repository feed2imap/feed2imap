#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'tc_cache'
require 'tc_channel_parse'
require 'tc_config'
require 'tc_converters_html2text'
require 'tc_converters_toutf8'
require 'tc_parser'
require 'tc_converters_text2html'
require 'tc_mail'
