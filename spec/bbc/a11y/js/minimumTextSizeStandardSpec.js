var standard = require('../../../../lib/bbc/a11y/js/standards/minimumTextSize/textCannotBeTooSmall');
var $ = require('jquery');
var expect = require('chai').expect;

describe('minimum text size standard', function() {
  it('ignores text nodes with parents with display: none', function() {
    $('<div style="display:none; font-size: 1px">Text!</div>').appendTo('body');
    var failures = [];
    var fail = function(failure) {
      failures.push(failure);
    }
    standard.validate($, fail);
    expect(failures).to.eql([]);
  });

  it('ignores comment nodes', function() {
    $('<div style="font-size: 1px"><!-- this is a comment --></div>').appendTo('body');
    var failures = [];
    var fail = function(failure) {
      failures.push(failure);
    }
    standard.validate($, fail);
    expect(failures).to.eql([]);
  });
});
