# frozen_string_literal: true

require 'test_helper'

class HTML::Pipeline::TableOfContentsFilterTest < Minitest::Test
  TocFilter = HTML::Pipeline::TableOfContentsFilter

  TocPipeline =
    HTML::Pipeline.new [
      HTML::Pipeline::TableOfContentsFilter
    ]

  def toc(content) # rubocop:disable Minitest/TestMethodName
    result = {}
    TocPipeline.call(content, context: {}, result: result)
    result[:toc]
  end

  def test_anchors_are_added_properly
    orig = %(<h1>Ice cube</h1><p>Will swarm on any motherfucker in a blue uniform</p>)
    assert_includes TocFilter.call(orig).to_s, '<a id='
  end

  def test_custom_anchor_icons_added_properly
    orig = %(<h1>Ice cube</h1>)
    expected = %(<h1>\n<a id="ice-cube" class="anchor" href="#ice-cube" aria-hidden="true">#</a>Ice cube</h1>)

    assert_equal expected, TocFilter.call(orig, context: { anchor_icon: '#' }).to_s
  end

  def test_toc_list_added_properly
    orig = %(<h1>Ice cube</h1><p>Will swarm on any motherfucker in a blue uniform</p>)
    assert_includes toc(orig), %(<ul class="section-nav">\n<li><a href=")
  end

  def test_anchors_have_sane_names
    orig = %(<h1>Dr Dre</h1><h1>Ice Cube</h1><h1>Eazy-E</h1><h1>MC Ren</h1>)
    result = TocFilter.call(orig).to_s

    assert_includes result, '"dr-dre"'
    assert_includes result, '"ice-cube"'
    assert_includes result, '"eazy-e"'
    assert_includes result, '"mc-ren"'
  end

  def test_anchors_have_aria_hidden
    orig = '<h1>Straight Outta Compton</h1>'
    result = TocFilter.call(orig).to_s
    assert_includes result, 'aria-hidden="true"'
  end

  def test_toc_hrefs_have_sane_values
    orig = %(<h1>Dr Dre</h1><h1>Ice Cube</h1><h1>Eazy-E</h1><h1>MC Ren</h1>)
    toc = TocFilter.call(orig).to_s
    assert_includes toc, '"#dr-dre"'
    assert_includes toc, '"#ice-cube"'
    assert_includes toc, '"#eazy-e"'
    assert_includes toc, '"#mc-ren"'
  end

  def test_dupe_headers_have_unique_trailing_identifiers
    orig = %(<h1>Straight Outta Compton</h1>
             <h2>Dopeman</h2>
             <h3>Express Yourself</h3>
             <h1>Dopeman</h1>)

    result = TocFilter.call(orig).to_s

    assert_includes result, '"dopeman"'
    assert_includes result, '"dopeman-1"'
  end

  def test_dupe_headers_have_unique_toc_anchors
    orig = %(<h1>Straight Outta Compton</h1>
              <h2>Dopeman</h2>
              <h3>Express Yourself</h3>
              <h1>Dopeman</h1>)

    assert_includes toc(orig), '"#dopeman"'
    assert_includes toc(orig), '"#dopeman-1"'
  end

  def test_all_header_tags_are_found_when_adding_anchors
    orig = %(<h1>"Funky President" by James Brown</h1>
             <h2>"It's My Thing" by Marva Whitney</h2>
             <h3>"Boogie Back" by Roy Ayers</h3>
             <h4>"Feel Good" by Fancy</h4>
             <h5>"Funky Drummer" by James Brown</h5>
             <h6>"Ruthless Villain" by Eazy-E</h6>
             <h7>"Be Thankful for What You Got" by William DeVaughn</h7>)

    doc = TocFilter.call(orig)

    assert_equal 6, doc.search('a').size
  end

  def test_toc_outputs_escaped_html
    orig = %(<h1>&lt;img src="x" onerror="alert(42)"&gt;</h1>)

    refute_includes toc(orig), %(<img src="x" onerror="alert(42)">)
  end

  def test_toc_is_complete
    orig = %(<h1>"Funky President" by James Brown</h1>
              <h2>"It's My Thing" by Marva Whitney</h2>
              <h3>"Boogie Back" by Roy Ayers</h3>
              <h4>"Feel Good" by Fancy</h4>
              <h5>"Funky Drummer" by James Brown</h5>
              <h6>"Ruthless Villain" by Eazy-E</h6>
              <h7>"Be Thankful for What You Got" by William DeVaughn</h7>)

    expected = %(<ul class="section-nav">\n<li><a href="#funky-president-by-james-brown">&quot;Funky President&quot; by James Brown</a></li>\n<li><a href="#its-my-thing-by-marva-whitney">&quot;It&#39;s My Thing&quot; by Marva Whitney</a></li>\n<li><a href="#boogie-back-by-roy-ayers">&quot;Boogie Back&quot; by Roy Ayers</a></li>\n<li><a href="#feel-good-by-fancy">&quot;Feel Good&quot; by Fancy</a></li>\n<li><a href="#funky-drummer-by-james-brown">&quot;Funky Drummer&quot; by James Brown</a></li>\n<li><a href="#ruthless-villain-by-eazy-e">&quot;Ruthless Villain&quot; by Eazy-E</a></li>\n</ul>)

    assert_equal expected, toc(orig)
  end

  if RUBY_VERSION > '1.9' # not sure how to make this work on 1.8.7

    def test_anchors_with_utf8_characters
      orig = %(<h1>日本語</h1>
               <h1>Русский</h1)

      rendered_h1s = TocFilter.call(orig).search('h1').map(&:to_s)

      assert_equal "<h1>\n<a id=\"日本語\" class=\"anchor\" href=\"#%E6%97%A5%E6%9C%AC%E8%AA%9E\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>日本語</h1>",
                   rendered_h1s[0]
      assert_equal "<h1>\n<a id=\"Русский\" class=\"anchor\" href=\"#%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>Русский</h1>",
                   rendered_h1s[1]
    end

    def test_toc_with_utf8_characters
      orig = %(<h1>日本語</h1>
                <h1>Русский</h1)

      rendered_toc = Nokogiri::HTML::DocumentFragment.parse(toc(orig)).to_s

      expected = %(<ul class="section-nav">\n<li><a href="#%E6%97%A5%E6%9C%AC%E8%AA%9E">日本語</a></li>\n<li><a href="#%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9">Русский</a></li>\n</ul>)

      assert_equal expected, rendered_toc
    end
  end
end
