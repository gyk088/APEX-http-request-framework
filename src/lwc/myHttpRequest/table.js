"use strict";
function vTable(config) {
    this.config = config;
    this.filters = {};
    this.sortASC = true;
    this.selectedIndexes = [];
    this.fIndex = 0;
    this.scrollTop = 0;
    this.lIndex = this.config.numberOfVisibleRows;

    if (this.config.node) {
      this.init()
    }
  }

vTable.prototype.init = function(node, data) {
  this.config.node = this.config.node || node;
  this.selectIndex = NaN;

  if (!this.config.node) {
    console.error('vTable: undefined parent DOM element')
    return;
  }

  if (Array.isArray(data)) {
    var i = 0;
    this.config.data = data.map(function(d) {
      return {
        ...d,
        _vTableId: i++,
      }
    })

    this._fullData = this.config.data;
  } else {
    this.config.data = []
    this._fullData = []
  }

  this._createWrapper();
  this._createTable();
  this._createHeaderWrapper();
  this._createHeader();
  this._createHeaderRow();
  this._createHeaderRowCell();
  this._createHeaderRowFilterCell();
  this._initScroll();
  this._createBody();
  this._createBodyRow();
  this._ifnoData();
  this._createFooter();

  this._bind();

  this.config.node.appendChild(this.wrapper);

  if (this._loading) {
    this.loadingStart();
  }
}

vTable.prototype.getRowCount = function() {
  return this.config.data.length;
}

vTable.prototype.setData = function(data) {
  this.destroy();
  this.init(false, data);
}

vTable.prototype.addData = function(data) {
  var i = this._fullData.length;
  data = data.map(function(d) {
    return {
      ...d,
      _vTableId: i++,
    }
  });

  this._fullData = [...this._fullData, ...data];

  this._filter();
}

vTable.prototype.destroy = function() {
  if (this.config.node) {
    this.config.node.innerHTML = '';
  }
}

vTable.prototype.selectAll = function() {
  this.bodyRowArr.forEach(el => {
    el.classList.remove("myVTable_body_row_active");
    el.classList.add("myVTable_body_row_active");
  });

  const $this = this;
  this.selectedIndexes = [];
  this.config.data.forEach(function(d) {
    $this.selectedIndexes.push(d._vTableId);
  })

  return this.config.data;
}

vTable.prototype.removeSelection = function() {
  this.bodyRowArr.forEach(el => {
    el.classList.remove("myVTable_body_row_active");
  });

  this.selectedIndexes = [];
}

vTable.prototype.loadingStart = function() {
  this._loading = true;
  const div = document.createElement("div");
  div.classList.add('myVTable_no_loading');
  div.style.height = '100%';
  const innerDiv = document.createElement("div");
  div.appendChild(innerDiv);
  const text = this.config.loading || 'Loading...';
  innerDiv.innerHTML = text;
  this.tbody.appendChild(div);
}

vTable.prototype.loadingStop = function() {
  this._loading = false;
  this.reRender();
}

vTable.prototype.setFooterContent = function(content) {
  if (this.footerContent) {
    this.contentForFooter = content;
    this.footerContent = this.footerContent;
    this.footerContent.innerHTML = content
  }
}

vTable.prototype.reRender = function() {
  this.scrollWrapper.remove()
  this._initScroll();
  this._createBody();
  this._createBodyRow();
  this._createBody();
  this._createTable();
  this._ifnoData();

  this.tbody.appendChild(this.fragment);
  this.table.appendChild(this.tbody);
  this.scrollWrapper.appendChild(this.tableWrapper);
  this.scrollWrapper.scrollTop = this.scrollTop;

  if (this.config.footer && this.footerWrapper) {
    this.footerWrapper.remove();
    this._createFooter();
    this.wrapper.appendChild(this.footerWrapper);
    this.wrapper.insertBefore(this.scrollWrapper, this.footerWrapper);
  } else {
    this.wrapper.appendChild(this.scrollWrapper);
  }
  this.scrollWrapper.scrollTop = this.scrollTop;

  if (this._loading) {
    this.loadingStart();
  }
}

vTable.prototype._initScroll = function() {
  this.fullHeight = this.config.data.length * parseInt(this.config.rowHeight);
  this.tableHeight = parseInt(this.config.rowHeight) * this.config.numberOfVisibleRows;
  const scroller = document.createElement("div");
  scroller.style.opacity = 0;
  scroller.style.position = "absolute";
  scroller.style.top = 0;
  scroller.style.left = 0;
  scroller.style.width = "1px";
  scroller.style.height = this.fullHeight + 'px';
  this.scrollWrapper = document.createElement("div");
  this.scrollWrapper.classList.add('myVTable_body_wrapper');
  this.scrollWrapper.style.position = "relative";
  this.scrollWrapper.style.height = this.config.height || this.tableHeight + 'px';
  this.scrollWrapper.appendChild(scroller);
  this.scrollWrapper.addEventListener('scroll', this._onscroll.bind(this));
  this.scrollWrapper.style.overflowY = 'auto';
}

vTable.prototype._onscroll = function(e) {
  this.scrollTop = e.target.scrollTop;
  window.clearTimeout(this.timer);
  const $this = this;
  if (this._loading) return;
  this.timer = setTimeout(function(){
    const rowHeight = parseInt($this.config.rowHeight);

    $this.fIndex = parseInt($this.scrollTop / rowHeight);
    $this.lIndex = $this.fIndex + $this.config.numberOfVisibleRows;

    if ($this.lIndex > $this.config.data.length) {
      $this.lIndex = $this.config.data.length;
    } else {
      $this.stopScrolling = false;
    }

    if ($this.stopScrolling) return;

    const fragment = document.createDocumentFragment();
    $this.bodyRowArr = [];
    var lastRow;
    for (let i = $this.fIndex; i < $this.lIndex; i++) {
      const row = $this._createRow(i);
      if (!row) continue;
      fragment.appendChild(row);
      $this.bodyRowArr.push(row);
      lastRow = row;
    }
    $this.tbody.innerHTML = '';
    $this.tbody.appendChild(fragment);

    if ($this.lIndex === $this.config.data.length) {
      $this.stopScrolling = true;
      if ($this.config.next) {
        $this.config.next($this.config.data[$this.config.data.length - 1])
      }
    }
  }, 10)
}

vTable.prototype._bind = function() {
  this.headerCellArr.forEach(cell => {
    this.headerRow.appendChild(cell);
  });

  this.tbody.appendChild(this.fragment);
  this.header.appendChild(this.headerRow);
  this.header.appendChild(this.headerRowFilter);
  this.table.appendChild(this.tbody);
  this.scrollWrapper.appendChild(this.tableWrapper);
  this.headerWrapper.appendChild(this.header);
  this.wrapper.appendChild(this.headerWrapper);

  if (this.config.footer) {
    this.wrapper.appendChild(this.footerWrapper);
    this.wrapper.insertBefore(this.scrollWrapper, this.footerWrapper);
  } else {
    this.wrapper.appendChild(this.scrollWrapper);
  }
}

vTable.prototype._createWrapper = function() {
  this.wrapper = document.createElement("div");
  this.wrapper.classList.add('myVTable_wrapper');
}

vTable.prototype._createHeaderWrapper = function() {
  this.headerWrapper = document.createElement("div");
  this.headerWrapper.classList.add('myVTable_header_wrapper');
}

vTable.prototype._createFooter = function() {
  if (this.config.footer) {
    this.footerWrapper = document.createElement("div");
    this.footerWrapper.classList.add('myVTable_footer_wrapper');
    this.footerWrapper.style.height = parseInt(this.config.footer.height)
      ? parseInt(this.config.footer.height) + 'px' : parseInt(this.config.rowHeight) + 'px';

    this.footerContent = document.createElement("div");
    this.footerContent.classList.add('myVTable_footer_content');
    const content = this.contentForFooter || this.config.footer.content;
    this.footerContent.innerHTML = content ? content : '';
    this.footerWrapper.appendChild(this.footerContent);
  }
}

vTable.prototype._createTable = function() {
  this.tableWrapper = document.createElement("div");
  this.tableWrapper.classList.add('myVTable_table_wrapper');
  this.tableWrapper.style.position = 'sticky';
  this.tableWrapper.style.top = 0;
  this.table = document.createElement("table");
  this.table.classList.add('myVTable_table');
  this.tableWrapper.appendChild(this.table)
}

vTable.prototype._createHeader = function() {
  this.header = document.createElement("table");
  this.header.classList.add('myVTable_header');
}

vTable.prototype._createHeaderRow = function() {
  this.headerRow = document.createElement("tr");
  this.headerRow.classList.add('myVTable_header_row');
}

vTable.prototype._createHeaderRowCell = function() {
  this.headerCellArr = [];

  if (Array.isArray(this.config.header)) {
    this.config.header.forEach(d => {
        const cell = document.createElement("th");
        cell.classList.add('myVTable_header_row_cell');

        if (d.width) {
          cell.style.width = d.width
        }

        const $this = this;

        const div = document.createElement("div");
        div.classList.add('myVTable_header_row_cell_div');
        div.innerText = d.title ? d.title : '' ;

        const divSortWrapper = document.createElement("div");
        divSortWrapper.classList.add('myVTable_header_row_cell_wrapper');
        divSortWrapper.appendChild(div);
        if (d.sort) {
          divSortWrapper.style.display = 'flex';
          divSortWrapper.style.justifyContent = 'center';
          divSortWrapper.style.alignItems = 'center';
          const arrow = document.createElement("div");
          cell.classList.add('myVTable_header_row_cell_sort');
          cell.addEventListener('click', function() {
            $this.loadingStart();
            setTimeout(function() {
              $this._sort(d.key);
              $this.loadingStop();
              $this.headerCellArr.forEach(el => {
                el.classList.remove("myVTable_header_row_cell_sort_asc");
                el.classList.remove("myVTable_header_row_cell_sort_desc");
              });

              if ($this.sortASC) {
                cell.classList.add('myVTable_header_row_cell_sort_asc');
              } else {
                cell.classList.add('myVTable_header_row_cell_sort_desc');
              }

            }, 0)
          });
        }

        cell.appendChild(divSortWrapper);

        this.headerCellArr.push(cell);
    })
  }
}

vTable.prototype._createHeaderRowFilterCell = function() {
  this.headerRowFilter = document.createElement("tr");
  this.headerRowFilter.classList.add('myVTable_header_row_filter');
  this.headerCellFilterArr = [];
  this.headerCellDivFilterArr = [];
  var hasFilter = false;
  this.config.header.forEach(d => {
    if (d.filter) hasFilter = true;
  })

  if (!hasFilter) return;

  this.config.header.forEach(d => {
      const cell = document.createElement("th");
      cell.classList.add('myVTable_header_row_cell_filter');

      if (d.width) {
        cell.style.width = d.width
      }

      if (d.filter) {
        const div = document.createElement("div");
        div.classList.add('myVTable_header_row_cell_div_filter');
        const input = this._createHeaderRowInput(d);
        div.appendChild(input);
        cell.appendChild(div);
        this.headerCellDivFilterArr.push(div);
      }

      this.headerCellFilterArr.push(cell);
      this.headerRowFilter.appendChild(cell);
  })
}

vTable.prototype._createHeaderRowInput = function(headerElement) {
  const input = document.createElement("input");
  input.type = "text";
  input.className = "myVTable_header_row_cell_input_filter";
  input.style.width = '80%';
  const $this = this;
  input.addEventListener('keyup', function(e) {
    $this._filter(e.target.value, headerElement.key)
  });

  return input;
}

vTable.prototype._filter = function(searchStr, key) {
  if (key) {
    this.filters[key] = searchStr ? searchStr.toString().toUpperCase() : null;
  }

  const visibleData = [];
  this._fullData.forEach(d => {
      var add = true;
      for (const filterKey in this.filters) {
        if (this.filters[filterKey]) {
          const cellVal = d[filterKey].toString().toUpperCase();
          if (!cellVal.includes(this.filters[filterKey])) {
            add = false;
          }
        }
      }

      if (add) {
        visibleData.push(d)
      }
  })

  this._renderFilteredData(visibleData);
}

vTable.prototype._sort = function(key) {
  this.sortASC = !this.sortASC;

  if (this.sortASC) {
    this.config.data.sort(function(a, b) {
      if (a[key] > b[key]) return 1;
      if (a[key] < b[key]) return -1;
      return 0;
    });
  } else {
    this.config.data.sort(function(a, b) {
      if (a[key] < b[key]) return 1;
      if (a[key] > b[key]) return -1;
      return 0;
    });
  }

  this._renderFilteredData(this.config.data);
};

vTable.prototype._renderFilteredData = function (visibleData) {
  this.config.data = visibleData;
  this.reRender();
}

vTable.prototype._ifnoData = function() {
  if(!this.config.data || !this.config.data.length) {
    const div = document.createElement("div");
    div.classList.add('myVTable_no_data');
    div.style.height = this.config.height || this.tableHeight + 'px';
    const innerDiv = document.createElement("div");
    div.appendChild(innerDiv);
    const text = this.config.noDataText || 'There is no data';
    innerDiv.innerHTML = text;
    this.tbody.innerHTML = '';
    this.tbody.appendChild(div);
  }
}

vTable.prototype._createBody = function() {
  this.tbody = document.createElement("tbody");
  this.tbody.classList.add('myVTable_body');
}

vTable.prototype._createBodyRow = function() {
  this.bodyRowArr = [];
  this.bodyCellArr = [];
  this.bodyCellDivArr = [];
  this.fragment = document.createDocumentFragment();
  if (Array.isArray(this.config.data)) {
    for (let i = this.fIndex; i < this.lIndex; i++ ) {
      const row = this._createRow(i);
      if (!row) continue;
      this.fragment.appendChild(row);
      this.bodyRowArr.push(row);
    }
  }
}

vTable.prototype._createRow = function(index) {
  if (!this.config.data[index]) return;

  const row = document.createElement("tr");
  row.classList.add('myVTable_body_row');
  row.style.height = this.config.rowHeight + 'px';

  if (Array.isArray(this.config.header)) {
    this.config.header.forEach(hd => {
      const cell = document.createElement("th");
      const div = document.createElement("div");

      if (hd.width) {
        cell.style.width = hd.width;
      }

      cell.classList.add('myVTable_body_cell');
      div.classList.add('myVTable_body_cell_div');
      const template = hd.template ? hd.template(this.config.data[index], index) : this.config.data[index][hd.key];
      div.innerHTML = template;

      cell.appendChild(div);
      row.appendChild(cell);

      this.bodyCellArr.push(cell);
      this.bodyCellDivArr.push(div);
    })
  }

  if (Array.isArray(this.selectedIndexes) && this.selectedIndexes.includes(this.config.data[index]._vTableId)) {
    row.classList.add('myVTable_body_row_active');
  }

  this._addRowActions(row, index);

  return row;
}

vTable.prototype._addRowActions = function(row, index) {
  const $this = this;
  if (this.config.onRowClick) {
    row.addEventListener('click', function() {
      if ($this.config.multiSelect) {
        $this._rowMultiSelect($this.config.onRowClick, row, index);
      } else {
        $this._rowSelect($this.config.onRowClick, row, index);
      }
    });
  }
  if (this.config.onRowDblClick) {
    row.addEventListener('dblclick', function() {
      if ($this.config.multiSelect) {
        $this._rowMultiSelect($this.config.onRowDblClick, row, index);
      } else {
        $this._rowSelect($this.config.onRowDblClick, row, index);
      }
    });
  }
}

vTable.prototype._rowSelect = function(action, row, index) {
  this.selectedIndexes = []
  this.selectedIndexes.push(this.config.data[index]._vTableId);
  this.bodyRowArr.forEach(el => el.classList.remove("myVTable_body_row_active"));
  row.classList.add('myVTable_body_row_active');
  action(this.config.data[index], index);
}

vTable.prototype._rowMultiSelect = function(action, row, index) {
  const isSelected = row.classList.toggle('myVTable_body_row_active');
  if (isSelected) {
    this.selectedIndexes.push(this.config.data[index]._vTableId);
  } else {
    this.selectedIndexes = this.selectedIndexes.filter(key => key != this.config.data[index]._vTableId);
  }

  action(this.config.data[index], index, isSelected);
}

export default vTable;