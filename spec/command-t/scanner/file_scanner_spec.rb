# Copyright 2010-2013 Wincent Colaiuta. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'spec_helper'
require 'command-t/scanner/file_scanner'

describe CommandT::FileScanner do
  before do
    @dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'fixtures')
    @all_fixtures = %w(
      bar/abc bar/xyz baz bing foo/alpha/t1 foo/alpha/t2 foo/beta
    )
    @scanner = CommandT::FileScanner.new @dir

    stub(::VIM).evaluate(/expand\(.+\)/) { '0' }
    stub(::VIM).evaluate(/^&wildignore$/) { '' }
    stub(::VIM).command(/set wildignore=/) { '' }
  end

  describe 'paths method' do
    it 'returns a list of regular files' do
      @scanner.paths.should =~ @all_fixtures
    end
  end

  describe 'flush method' do
    it 'forces a rescan on next call to paths method' do
      first = @scanner.paths
      @scanner.flush
      @scanner.paths.object_id.should_not == first.object_id
    end
  end

  describe 'path= method' do
    it 'allows repeated applications of scanner at different paths' do
      @scanner.paths.should =~ @all_fixtures

      # drill down 1 level
      @scanner.path = File.join(@dir, 'foo')
      @scanner.paths.should =~ %w(alpha/t1 alpha/t2 beta)

      # and another
      @scanner.path = File.join(@dir, 'foo', 'alpha')
      @scanner.paths.should =~ %w(t1 t2)
    end
  end

  describe "'wildignore' exclusion" do
    it "calls on VIM's expand() function for pattern filtering when provided" do
      stub(::VIM).evaluate("exists(\"&wildignore\")") { 0 }
      stub(::VIM).evaluate(/^&wildignore$/) { '' }
      @scanner = CommandT::FileScanner.new @dir, { :wild_ignore => 'x' }
      mock(::VIM).evaluate(/expand\(.+\)/).times(10)
      @scanner.paths
    end

    it "calls on VIM's expand() function for pattern filtering when VIM has a wildignore" do
      stub(::VIM).evaluate("exists(\"&wildignore\")") { 1 }
      stub(::VIM).evaluate(/^&wildignore$/) { 'z' }
      @scanner = CommandT::FileScanner.new @dir
      mock(::VIM).evaluate(/expand\(.+\)/).times(10)
      @scanner.paths
    end

    it "does not call on VIM's expand() function when there is no wildignore" do
      stub(::VIM).evaluate("exists(\"&wildignore\")") { 0 }
      stub(::VIM).evaluate(/^&wildignore$/) { '' }
      @scanner = CommandT::FileScanner.new @dir, { :wild_ignore => nil }
      mock(::VIM).evaluate(/expand\(.+\)/).times(0)
      @scanner.paths
    end

    it "does not call on VIM's expand() function when wildignore is overridden" do
      stub(::VIM).evaluate("exists(\"&wildignore\")") { 1 }
      stub(::VIM).evaluate(/^&wildignore$/) { 'x' }
      @scanner = CommandT::FileScanner.new @dir, { :wild_ignore => '' }
      mock(::VIM).evaluate(/expand\(.+\)/).times(0)
      @scanner.paths
    end
  end
end
