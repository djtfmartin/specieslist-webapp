%{--
  - Copyright (C) 2012 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
  --}%
<!doctype html>
<g:set var="bieUrl" value="${grailsApplication.config.bie.baseURL}"/>
<g:set var="collectoryUrl" value="${grailsApplication.config.collectory.baseURL}" />
<g:set var="maxDownload" value="${grailsApplication.config.downloadLimit}" />
<g:set var="userCanEditPermissions" value="${
    (speciesList.username == request.getUserPrincipal()?.attributes?.email || request.isUserInRole("ROLE_ADMIN"))
}" />
<g:set var="userCanEditData" value="${
    (   speciesList.username == request.getUserPrincipal()?.attributes?.email ||
        request.isUserInRole("ROLE_ADMIN") ||
        request.getUserPrincipal()?.attributes?.userid in speciesList.editors
    )
}" />
<html>
<head>
    %{--<gui:resources components="['dialog']"/>--}%
    <r:require modules="application, fancybox, baHashchange, amplify"/>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    %{--<link rel="stylesheet" href="${resource(dir:'css',file:'scrollableTable.css')}"/>--}%
    <script language="JavaScript" type="text/javascript" src="${resource(dir:'js',file:'facets.js')}"></script>
    <script language="JavaScript" type="text/javascript" src="${resource(dir:'js',file:'getQueryParam.js')}"></script>
    <script language="JavaScript" type="text/javascript" src="${resource(dir:'js',file:'jquery-ui-1.8.17.custom.min.js')}"></script>
    <script language="JavaScript" type="text/javascript" src="${resource(dir:'js',file:'jquery.doubleScroll.js')}"></script>
    <title>Species list items | ${grailsApplication.config.skin.orgNameLong}</title>
    <style type="text/css">
    #buttonDiv {display: none;}
    #refine {display:none;}
    </style>

    <script type="text/javascript">
    function init(){
        document.getElementById("buttonDiv").style.display = "block";
        document.getElementById("refine").style.display = "block";
    }
    $(document).ready(function(){
        init();

        // in mobile view toggle display of facets
        $('#toggleFacetDisplay').click(function() {
            $(this).find('i').toggleClass('icon-chevron-right icon-chevron-down');
            if ($('#accordion').is(':visible')) {
                $('#accordion').removeClass('overrideHide');
            } else {
                $('#accordion').addClass('overrideHide');
            }
        });

        // ba-hashchange plugin
        $(window).hashchange( function() {
            var storedView = amplify.store('view-state');
            var hash = location.hash ? location.hash : storedView ? storedView : "#list";
            amplify.store('view-state', hash); // store current hash in local storage (for pagination links)

            if (hash == '#grid') {
                $('#listView').slideUp();
                $('#gridView').slideDown();
                $('#listItemView .grid').addClass('disabled');
                $('#listItemView .list').removeClass('disabled');
            } else if (hash == '#list') {
                $('#gridView').slideUp();
                $('#listView').slideDown();
                $('#listItemView .list').addClass('disabled');
                $('#listItemView .grid').removeClass('disabled');
            } else if (storedView) {
                // no hash but stored value - use this
                location.hash = storedView;
            }
        });

        // Since the event is only triggered when the hash changes, we need to trigger
        // the event now, to handle the hash the page may have loaded with.
        $(window).hashchange();

        // download link
        $("#downloadLink").fancybox({
            'hideOnContentClick' : false,
            'hideOnOverlayClick': true,
            'showCloseButton': true,
            'titleShow' : false,
            'autoDimensions' : false,
            'width': 520,
            'height': 400,
            'padding': 10,
            'margin': 10,
            onCleanup: function() {
                $("label[for='reasonTypeId']").css("color","#444");
            }
        });

        // fancybox div for refining search with multiple facet values
        $(".multipleFacetsLink").fancybox({
            'hideOnContentClick' : false,
            'hideOnOverlayClick': true,
            'showCloseButton': true,
            'titleShow' : false,
            'transitionIn': 'elastic',
            'transitionOut': 'elastic',
            'speedIn': 400,
            'speedOut': 400,
            'scrolling': 'auto',
            'centerOnScroll': true,
            'autoDimensions' : false,
            'width': 560,
            'height': 560,
            'padding': 10,
            'margin': 10

        });

        // Add scroll bar to top and bottom of table
        $('.fwtable').doubleScroll();

        // Tooltip for link title
        $('#content a').not('.thumbImage').tooltip({placement: "bottom", html: true, delay: 200, container: "body"});

        // submit edit record changes via POST
        $("button.saveRecord").click(function() {
            var id = $(this).data("id");
            var modal = $(this).data("modal");
            var thisFormData = $("form#editForm_" + id).serializeArray();

            if (!$("form#editForm_" + id).find("#rawScientificName").val()) {
                alert("Required field: supplied name cannot be blank");
                return false;
            }

            $.post("${createLink(controller: "editor", action: 'editRecord')}", thisFormData, function(data, textStatus, jqXHR) {
                //console.log("data", data, "textStatus", textStatus,"jqXHR", jqXHR);
                $(modal).modal('hide');
                alert(jqXHR.responseText);
                window.location.reload(true);
            }).error(function(jqXHR, textStatus, error) {
                alert("An error occurred: " + error + " - " + jqXHR.responseText);
                $(modal).modal('hide');
            });
        });

        // create record via POST
        $("button#saveNewRecord").click(function() {
            var id = $(this).data("id");
            var modal = $(this).data("modal");
            var thisFormData = $("form#editForm_").serializeArray();

            if (!$("form#editForm_").find("#rawScientificName").val()) {
                alert("Required field: supplied name cannot be blank");
                return false;
            }
            //thisFormData.push({id: id});
            //console.log("thisFormData", id, thisFormData)
            $.post("${createLink(controller: "editor", action: 'createRecord')}", thisFormData, function(data, textStatus, jqXHR) {
                //console.log("data", data, "textStatus", textStatus,"jqXHR", jqXHR);
                $(modal).modal('hide');
                alert(jqXHR.responseText);
                window.location.reload(true);
            }).error(function(jqXHR, textStatus, error) {
                alert("An error occurred: " + error + " - " + jqXHR.responseText);
                $(modal).modal('hide');
            });
        });

        // submit delete record via GET
        $("button.deleteSpecies").click(function() {
            var id = $(this).data("id");
            var modal = $(this).data("modal");

            $.get("${createLink(controller: "editor", action: 'deleteRecord')}", {id: id}, function(data, textStatus, jqXHR) {
                $(modal).modal('hide');
                //console.log("data", data, "textStatus", textStatus,"jqXHR", jqXHR);
                alert(jqXHR.responseText + " - reloading page...");
                window.location.reload(true);
                //$('#modal').modal('hide');
            }).error(function(jqXHR, textStatus, error) {
                alert("An error occurred: " + error + " - " + jqXHR.responseText);
                $(modal).modal('hide');
            });
        });

        //console.log("owner = ${speciesList.username}");
        //console.log("logged in user = ${request.getUserPrincipal()?.attributes?.email}");

        // Toggle display of list meta data editing
        $("#edit-meta-button").click(function(el) {
            el.preventDefault();
            toggleEditMeta(!$("#edit-meta-div").is(':visible'));
        });

        // submit edit meta data
        $("#edit-meta-submit").click(function(el) {
            el.preventDefault();
            var $form = $(this).parents("form");
            var thisFormData = $($form).serializeArray();
            // serializeArray ignores unchecked checkboxes so explicitly send data for these
            thisFormData = thisFormData.concat(
                $($form).find('input[type=checkbox]:not(:checked)').map(
                    function() {
                        return {"name": this.name, "value": false}
                    }
                ).get()
            );

            //console.log("thisFormData", thisFormData);

            $.post("${createLink(controller: "editor", action: 'editSpeciesList')}", thisFormData, function(data, textStatus, jqXHR) {
                //console.log("data", data, "textStatus", textStatus,"jqXHR", jqXHR);
                alert(jqXHR.responseText);
                window.location.reload(true);
            }).error(function(jqXHR, textStatus, error) {
                alert("An error occurred: " + error + " - " + jqXHR.responseText);
                //$(modal).modal('hide');
            });
        });

        // toggle display of list info box
        $("#toggleListInfo").click(function(el) {
            el.preventDefault();
            $("#list-meta-data").slideToggle(!$("#list-meta-data").is(':visible'))
        });

        // catch click ion view record button (on each row)
        // extract values from main table and display in table inside modal popup
        $("a.viewRecordButton").click(function(el) {
            el.preventDefault();
            var recordId = $(this).data("id");
            viewRecordForId(recordId);
        });

        // mouse over affect on thumbnail images
        $('.imgCon').on('hover', function() {
            $(this).find('.brief, .detail').toggleClass('hide');
        });

    }); // end document ready

    function toggleEditMeta(showHide) {
        $("#edit-meta-div").slideToggle(showHide);
        //$("#edit-meta-button").hide();
        $("#show-meta-dl").slideToggle(!showHide);
    }

    function viewRecordForId(recordId) {
        // read header values from the table
        var headerRow = $("table#speciesListTable > thead th").not(".action");
        var headers = [];
        $(headerRow).each(function(i, el) {
            headers.push($(this).text());
        });
        // read species row values from the table
        var valueTds = $("tr#row_" + recordId + " > td").not(".action");
        var values = [];
        $(valueTds).each(function(i, el) {
            var val = $(this).html();
            if ($.type(val) === "string") {
                val = $.trim(val);
            }
            values.push(val);
        });
        //console.log("values", values.length, "headers", headers.length);
        //console.log("values & headers", headers, values);
        $("#viewRecord p.spinner").hide();
        $("#viewRecord tbody").html(""); // clear values
        $.each(headers, function(i, el) {
            var row = "<tr><td>"+el+"</td><td>"+values[i]+"</td></tr>";
            $("#viewRecord tbody").append(row);
        });
        $("#viewRecord table").show();
        $('#viewRecord').modal("show");
    }

//    function loadMultiFacets(facetName, displayName) {
//        console.log(facetName, displayName)
//        console.log("#div"+facetName,$("#div"+facetName).innerHTML)
//        $("div#dynamic").innerHTML=$("#div"+facetName).innerHTML;
//    }

    function downloadOccurrences(o){
        if(validateForm()){
            this.cancel();
            //downloadURL = $("#email").val();
            downloadURL = "${request.contextPath}/speciesList/occurrences/${params.id}${params.toQueryString()}&type=Download&email="+$("#email").val()+"&reasonTypeId="+$("#reasonTypeId").val()+"&file="+$("#filename").val();
            window.location =  downloadURL//"${request.contextPath}/speciesList/occurrences/${params.id}?type=Download&email=$('#email').val()&reasonTypeId=$(#reasonTypeId).val()&file=$('#filename').val()"
        }
    }
    function downloadFieldGuide(o){
        if(validateForm()){
            this.cancel();
            //alert(${params.toQueryString()})
            window.location = "${request.contextPath}/speciesList/fieldGuide/${params.id}${params.toQueryString()}"
        }

    }
    function downloadList(o){
         if(validateForm()){
             this.cancel();
             window.location = "${request.contextPath}/speciesListItem/downloadList/${params.id}${params.toQueryString()}&file="+$("#filename").val()
         }
    }
    function validateForm() {
        var isValid = false;
        var reasonId = $("#reasonTypeId option:selected").val();

        if (reasonId) {
            isValid = true;
        } else {
            $("#reasonTypeId").focus();
            $("label[for='reasonTypeId']").css("color","red");
            alert("Please select a \"download reason\" from the drop-down list");
        }

        return isValid;
    }

    function reloadWithMax(el) {
        var max = $(el).find(":selected").val();
        var params = {
            max: max,
            sort: "${params.sort}",
            order: "${params.order}",
            offset: "${params.offset?:0}"
        }
        var paramStr = jQuery.param(params);
        window.location.href = window.location.pathname + '?' + paramStr;
    }
</script>
</head>
<body class="yui-skin-sam nav-species">
<div id="content" class="container  ">
    <header id="page-header">

        <div class="inner row-fluid">
            <div id="breadcrumb" class="span12">
                <ol class="breadcrumb">
                    %{--<li><a href="http://www.ala.org.au">Home</a> <span class=" icon icon-arrow-right"></span></li>--}%
                    <li><a href="${request.contextPath}/public/speciesLists">Species lists</a> <span class="divider"><i class="fa fa-arrow-right"></i></span></li>
                    <li class="active">${speciesList?.listName?:"Species list items"}</li>
                </ol>
            </div>
        </div>
        <div class="row-fluid">
            <div class="span7">
                <h2>
                    Species List: <a href="${collectoryUrl}/public/show/${params.id}" title="view Date Resource page">${speciesList?.listName}</a>
                    &nbsp;&nbsp;
                    <div class="btn-group btn-group" id="listActionButtons">
                        <a href="#" id="toggleListInfo" class="btn btn-small"><i class="icon-info-sign "></i> List info</a>
                        <g:if test="${userCanEditPermissions}">
                            <a href="#" class="btn btn-small" data-remote="${createLink(controller: 'editor', action: 'editPermissions', id: params.id)}"
                               data-target="#modal" data-toggle="modal"><i class="icon-user "></i> Edit permissions</a>
                        </g:if>
                        <g:if test="${userCanEditData}">
                            <a href="#" class="btn btn-small" data-remote="${createLink(controller: 'editor', action: 'addRecordScreen', id: params.id)}"
                               data-target="#addRecord" data-toggle="modal"><i class="icon-plus-sign "></i> Add species</a>
                        </g:if>
                    </div>
                </h2>
            </div>
            <g:if test="${userCanEditPermissions}">
                <div class="modal hide fade" id="modal">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                        <h3 id="myModalLabel">Species list permissions</h3>
                    </div>
                    <div class="modal-body">
                        <p><img src="${resource(dir:'images',file:'spinner.gif')}" alt="spinner icon"/></p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                        <button class="btn btn-primary" id="saveEditors">Save changes</button>
                    </div>
                </div>
            </g:if>
            <g:if test="${userCanEditData}">
                <div class="modal hide fade" id="addRecord">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                        <h3>Add record values</h3>
                    </div>
                    <div class="modal-body">
                        <p><img src="${resource(dir:'images',file:'spinner.gif')}" alt="spinner icon"/></p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                        <button class="btn btn-primary" id="saveNewRecord" data-id="${speciesList.id}" data-modal="#addRecord">Save changes</button>
                    </div>
                </div>
            </g:if>
            <div class="span5 header-btns" id="buttonDiv">
                <span class="pull-right">
                    <a href="#download" class="btn btn-ala" title="View the download options for this species list." id="downloadLink">Download</a>

                    <a class="btn btn-ala" title="View occurrences for up to ${maxDownload} species on the list"
                       href="${request.contextPath}/speciesList/occurrences/${params.id}${params.toQueryString()}&type=Search">View occurrences records</a>

                    <a href="${request.contextPath}/speciesList/spatialPortal/${params.id}${params.toQueryString()}&type=Search" class="btn btn-ala" title="View the spatial portal." id="downloadLink">View in spatial portal</a>
                </span>
            </div>  <!-- rightfloat -->

            <div style="display:none">
                <g:render template="/download"/>
            </div>
        </div><!--inner-->
    </header>
    <div class="alert alert-info hide" id="list-meta-data">
        <button type="button" class="close" onclick="$(this).parent().slideUp()">&times;</button>
        <g:if test="${userCanEditPermissions}">
            <a href="#" class="btn btn-small" id="edit-meta-button"><i class="icon-pencil"></i> Edit</a>
        </g:if>
        <dl class="dl-horizontal" id="show-meta-dl">
            <dt>${message(code: 'speciesList.listName.label', default: 'List name')}</dt>
            <dd>${speciesList.listName?:'&nbsp;'}</dd>
            <dt>${message(code: 'speciesList.username.label', default: 'Owner')}</dt>
            <dd>${speciesList.fullName?:speciesList.username?:'&nbsp;'}</dd>
            <dt>${message(code: 'speciesList.listType.label', default: 'List type')}</dt>
            <dd>${speciesList.listType?.displayValue}</dd>
            <g:if test="${speciesList.description}">
                <dt>${message(code: 'speciesList.description.label', default: 'Description')}</dt>
                <dd>${speciesList.description}</dd>
            </g:if>
            <g:if test="${speciesList.url}">
                <dt>${message(code: 'speciesList.url.label', default: 'URL')}</dt>
                <dd><a href="${speciesList.url}" target="_blank">${speciesList.url}</a></dd>
            </g:if>
            <g:if test="${speciesList.wkt}">
                <dt>${message(code: 'speciesList.wkt.label', default: 'WKT vector')}</dt>
                <dd>${speciesList.wkt}</dd>
            </g:if>
            <dt>${message(code: 'speciesList.dateCreated.label', default: 'Date submitted')}</dt>
            <dd><g:formatDate format="yyyy-MM-dd" date="${speciesList.dateCreated?:0}"/><!-- ${speciesList.lastUpdated} --></dd>
            <dt>${message(code: 'speciesList.isPrivate.label', default: 'Is private')}</dt>
            <dd><g:formatBoolean boolean="${speciesList.isPrivate?:false}" true="Yes" false="No"/></dd>
            <dt>${message(code: 'speciesList.isBIE.label', default: 'Included in BIE')}</dt>
            <dd><g:formatBoolean boolean="${speciesList.isBIE?:false}" true="Yes" false="No"/></dd>
            <dt>${message(code: 'speciesList.isAuthoritative.label', default: 'Authoritative')}</dt>
            <dd><g:formatBoolean boolean="${speciesList.isAuthoritative?:false}" true="Yes" false="No"/></dd>
            <dt>${message(code: 'speciesList.isInvasive.label', default: 'Invasive')}</dt>
            <dd><g:formatBoolean boolean="${speciesList.isInvasive?:false}" true="Yes" false="No"/></dd>
            <dt>${message(code: 'speciesList.isThreatened.label', default: 'Threatened')}</dt>
            <dd><g:formatBoolean boolean="${speciesList.isThreatened?:false}" true="Yes" false="No"/></dd>
            <dt>${message(code: 'speciesList.isSDS.label', default: 'Part of the SDS')}</dt>
            <dd><g:formatBoolean boolean="${speciesList.isSDS?:false}" true="Yes" false="No"/></dd>
            <dt>${message(code: 'speciesList.region.label', default: 'Region')}</dt>
            <dd>${speciesList.region?:'Not provided'}</dd>
            <g:if test="${speciesList.isSDS}">
                <g:if test="${speciesList.authority}">
                    <dt>${message(code: 'speciesList.authority.label', default: 'SDS Authority')}</dt>
                    <dd>${speciesList.authority}</dd>
                </g:if>
                <g:if test="${speciesList.category}">
                    <dt>${message(code: 'speciesList.category.label', default: 'SDS Category')}</dt>
                    <dd>${speciesList.category}</dd>
                </g:if>
                <g:if test="${speciesList.generalisation}">
                    <dt>${message(code: 'speciesList.generalisation.label', default: 'SDS Coordinate Generalisation')}</dt>
                    <dd>${speciesList.generalisation}</dd>
                </g:if>
                <g:if test="${speciesList.sdsType}">
                    <dt>${message(code: 'speciesList.sdsType.label', default: 'SDS Type')}</dt>
                    <dd>${speciesList.sdsType}</dd>
                </g:if>
            </g:if>
            <g:if test="${speciesList.editors}">
                <dt>${message(code: 'speciesList.editors.label', default: 'List editors')}</dt>
                <dd>${speciesList.editors.collect{ sl.getFullNameForUserId(userId: it) }?.join(", ")}</dd>
            </g:if>
            <dt>${message(code: 'speciesList.metadata.label', default: 'Metadata link')}</dt>
            <dd><a href="${grailsApplication.config.collectory.baseURL}/public/show/${speciesList.dataResourceUid}">${grailsApplication.config.collectory.baseURL}/public/show/${speciesList.dataResourceUid}</a></dd>
        </dl>
        <g:if test="${userCanEditPermissions}">
            <div id="edit-meta-div" class="hide">
                <form class="form-horizontal" id="edit-meta-form">
                    <input type="hidden" name="id" value="${speciesList.id}" />
                    <div class="control-group">
                        <label class="control-label" for="listName">${message(code: 'speciesList.listName.label', default: 'List name')}</label>
                        <div class="controls">
                            <input type="text" name="listName" id="listName" class="input-xlarge" value="${speciesList.listName}" />
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label" for="owner">${message(code: 'speciesList.username.label', default: 'Owner')}</label>
                        <div class="controls">
                            <select name="owner" id="owner" class="input-xlarge">
                                <g:each in="${users}" var="userId"><option value="${userId}" ${(speciesList.username == userId) ? 'selected="selected"':''}><sl:getFullNameForUserId userId="${userId}" /></option></g:each>
                            </select>
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label" for="listType">${message(code: 'speciesList.listType.label', default: 'List type')}</label>
                        <div class="controls">
                            <select name="listType" id="listType" class="input-xlarge">
                                <g:each in="${au.org.ala.specieslist.ListType.values()}" var="type"><option value="${type.name()}" ${(speciesList.listType == type) ? 'selected="selected"':''}>${type.displayValue}</option></g:each>
                            </select>
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label" for="description">${message(code: 'speciesList.description.label', default: 'Description')}</label>
                        <div class="controls">
                            <textarea rows="3" name="description" id="description" class="input-block-level">${speciesList.description}</textarea>
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label" for="url">${message(code: 'speciesList.url.label', default: 'URL')}</label>
                        <div class="controls">
                            <input type="url" name="url" id="url" class="input-xlarge" value="${speciesList.url}" />
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label" for="description">${message(code: 'speciesList.wkt.label', default: 'WKT vector')}</label>
                        <div class="controls">
                            <textarea rows="3" name="wkt" id="wkt" class="input-block-level">${speciesList.wkt}</textarea>
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label" for="dateCreated">${message(code: 'speciesList.dateCreated.label', default: 'Date submitted')}</label>
                        <div class="controls">
                            <input type="date" name="dateCreated" id="dateCreated" data-date-format="yyyy-mm-dd" class="input-xlarge" value="<g:formatDate format="yyyy-MM-dd" date="${speciesList.dateCreated?:0}"/>" />
                            %{--<g:datePicker name="dateCreated" value="${speciesList.dateCreated}" precision="day" relativeYears="[-2..7]" class="input-small"/>--}%
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label" for="isPrivate">${message(code: 'speciesList.isPrivate.label', default: 'Is private')}</label>
                        <div class="controls">
                            <input type="checkbox" id="isPrivate" name="isPrivate" class="input-xlarge" value="true" data-value="${speciesList.isPrivate}" ${(speciesList.isPrivate == true) ? 'checked="checked"':''} />
                        </div>
                    </div>
                    <g:if test="${request.isUserInRole("ROLE_ADMIN")}">
                        <div class="control-group">
                            <label class="control-label" for="isBIE">${message(code: 'speciesList.isBIE.label', default: 'Included in BIE')}</label>
                            <div class="controls">
                                <input type="checkbox" id="isBIE" name="isBIE" class="input-xlarge" value="true" data-value="${speciesList.isBIE}" ${(speciesList.isBIE == true) ? 'checked="checked"':''} />
                            </div>
                        </div>
                        <div class="control-group">
                            <label class="control-label" for="isAuthoritative">${message(code:'speciesList.isAuthoritative.label', default: 'Authoritative')}</label>
                            <div class="controls">
                                <input type="checkbox" id="isAuthoritative" name="isAuthoritative" class="input-xlarge" value="true" data-value="${speciesList.isAuthoritative}" ${(speciesList.isAuthoritative == true) ? 'checked="checked"':''} />
                            </div>
                        </div>
                        <div class="control-group">
                            <label class="control-label" for="isInvasive">${message(code:'speciesList.isInvasive.label', default: 'Invasive')}</label>
                            <div class="controls">
                                <input type="checkbox" id="isInvasive" name="isInvasive" class="input-xlarge" value="true" data-value="${speciesList.isInvasive}" ${(speciesList.isInvasive == true) ? 'checked="checked"':''} />
                            </div>
                        </div>
                        <div class="control-group">
                            <label class="control-label" for="isThreatened">${message(code:'speciesList.isThreatened.label', default: 'Threatened')}</label>
                            <div class="controls">
                                <input type="checkbox" id="isThreatened" name="isThreatened" class="input-xlarge" value="true" data-value="${speciesList.isThreatened}" ${(speciesList.isThreatened == true) ? 'checked="checked"':''} />
                            </div>
                        </div>
                        <div class="control-group">
                            <label class="control-label" for="isSDS">${message(code: 'speciesList.isSDS.label', default: 'Part of the SDS')}</label>
                            <div class="controls">
                                <input type="checkbox" id="isSDS" name="isSDS" class="input-xlarge" value="true" data-value="${speciesList.isSDS}" ${(speciesList.isSDS == true) ? 'checked="checked"':''} />
                            </div>
                        </div>
                        <div class="control-group">
                            <label class="control-label" for="region">${message(code: 'speciesList.region.label', default: 'Region')}</label>
                            <div class="controls">
                                <input type="text" name="region" id="region" class="input-xlarge" value="${speciesList.region}" />
                            </div>
                        </div>
                        <g:if test="${speciesList.isSDS}">
                            <div class="control-group">
                                <label class="control-label" for="authority">${message(code: 'speciesList.authority.label', default: 'SDS Authority')}</label>
                                <div class="controls">
                                    <input type="text" name="authority" id="authority" class="input-xlarge" value="${speciesList.authority}" />
                                </div>
                            </div>
                            <div class="control-group">
                                <label class="control-label" for="category">${message(code: 'speciesList.category.label', default: 'SDS Category')}</label>
                                <div class="controls">
                                    <input type="text" name="category" id="category" class="input-xlarge" value="${speciesList.category}" />
                                </div>
                            </div>
                            <div class="control-group">
                                <label class="control-label" for="generalisation">${message(code: 'speciesList.generalisation.label', default: 'SDS Generalisation')}</label>
                                <div class="controls">
                                    <input type="text" name="generalisation" id="generalisation" class="input-xlarge" value="${speciesList.generalisation}" />
                                </div>
                            </div>
                            <div class="control-group">
                                <label class="control-label" for="sdsType">${message(code: 'speciesList.sdsType.label', default: 'SDS Type')}</label>
                                <div class="controls">
                                    <input type="text" name="sdsType" id="sdsType" class="input-xlarge" value="${speciesList.sdsType}" />
                                </div>
                            </div>
                        </g:if>
                    </g:if>
                    <div class="control-group">
                        <div class="controls">
                            <button type="submit" id="edit-meta-submit" class="btn btn-primary">Save</button>
                            <button class="btn" onclick="toggleEditMeta(false);return false;">Cancel</button>
                        </div>
                    </div>
                </form>
            </div>
        </g:if>
    </div>

<g:if test="${flash.message}">
    <div class="inner row-fluid">
        <div class="message alert alert-info"><b>Alert:</b> ${flash.message}</div>
    <div>
</g:if>

<div class="inner row-fluid">
    <div class="span3 well" id="facets-column">
        <div class="boxedZ attachedZ">
                <section class="meta">
                    <div class="matchStats">
                        <p>
                            <span class="count">${totalCount}</span>
                            Number of Taxa
                        </p>
                        <p>
                            <span class="count">${distinctCount}</span>
                            Distinct Species
                        </p>

                        <g:if test="${noMatchCount>0 && noMatchCount!=totalCount}">
                            <p>
                                <span class="count">${noMatchCount}</span>
                                <a href="?fq=guid:null${queryParams}" title="View unrecognised taxa">Unrecognised Taxa </a>
                            </p>
                        </g:if>

                    </div>
                </section>
                <section class="refine" id="refine">
                    <g:if test="${facets.size()>0 || params.fq}">
                        <h4 class="hidden-phone">Refine results</h4>
                        <h4 class="visible-phone">
                            <a href="#" id="toggleFacetDisplay"><i class="icon-chevron-right" id="facetIcon"></i>
                                Refine results</a>
                        </h4>
                        <div class="hidden-phone" id="accordion">
                            <g:set var="fqs" value="${params.list('fq')}" />
                            <g:if test="${fqs.size()>0&& fqs.get(0).length()>0}">
                                <div id="currentFilter">
                                    <p>
                                        <span class="FieldName">Current Filters</span>
                                    </p>
                                    <div id="currentFilters" class="subnavlist">
                                        <ul>
                                            <g:each in="${fqs}" var="fq">
                                                <g:if test="${fq.length() >0}">
                                                    <li>
                                                        <a href="${sl.removeFqHref(fqs: fqs, fq: fq)}" class="removeLink " title="Uncheck (remove filter)"><i class="icon-check"></i></a>
                                                        <g:message code="facet.${fq.replaceFirst("kvp ","")}" default="${fq.replaceFirst("kvp ","")}"/>
                                                    </li>
                                                </g:if>
                                            </g:each>
                                        </ul>
                                    </div>
                                </div>
                            </g:if>

                            <g:each in="${facets}" var="entry">
                                <g:if test="${entry.key == "listProperties"}">
                                    <g:each in="${facets.get("listProperties")}" var="value">
                                        <p>
                                            <span class="FieldName">${value.getKey()}</span>
                                        </p>
                                        <div id="facet-${value.getKey()}" class="subnavlist">
                                            <ul>
                                                <g:set var="i" value="${0}" />
                                                <g:set var="values" value="${value.getValue()}" />
                                                <g:while test="${i < 4 && i<values.size()}">
                                                    <g:set var="arr" value="${values.get(i)}" />
                                                    <li>
                                                        <a href="?fq=kvp ${arr[0]}:${arr[1]}${queryParams}">${arr[2]?:arr[1]}</a>  (${arr[3]})
                                                    </li>
                                                    <%i++%>
                                                </g:while>
                                                <g:if test="${values.size()>4}">
                                                    <div class="showHide">
                                                        <i class="icon icon-hand-right"></i>
                                                        <a href="#div${value.getKey().replaceAll(" " ,"_")}" class="multipleFacetsLinkZ" id="multi-${value.getKey()}"
                                                           role="button" data-toggle="modal"  title="See full list of values">choose more...</a>
                                                        <!-- modal popup for "choose more" link -->
                                                        <div id="div${value.getKey().replaceAll(" " ,"_")}" class="modal hide " tabindex="-1" role="dialog" aria-labelledby="multipleFacetsLabel" aria-hidden="true"><!-- BS modal div -->
                                                            <div class="modal-header">
                                                                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                                                <h3 class="multipleFacetsLabel">Refine your search</h3>
                                                            </div>
                                                            <div class="modal-body">
                                                                <table class="table table-bordered table-condensed table-striped scrollTable" style="width:100%;">
                                                                    <thead class="fixedHeader">
                                                                    <tr class="tableHead">
                                                                        <th class="indexCol" width="80%">${value.getKey()}</th>
                                                                        <th style="border-right-style: none;text-align: right;">Count</th>
                                                                    </tr>
                                                                    </thead>
                                                                    <tbody class="scrollContent">
                                                                    <g:each in="${value.getValue()}" var="arr">
                                                                        <tr>
                                                                            <td><a href="?fq=kvp ${arr[0]}:${arr[1]}${queryParams}">${arr[2]?:arr[1]} </a></td>
                                                                            <td style="text-align: right; border-right-style: none;">${arr[3]}</td>
                                                                        </tr>
                                                                    </g:each>
                                                                    </tbody>
                                                                </table>
                                                            </div>
                                                            <div class="modal-footer" style="text-align: left;">
                                                                <button class="btn btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;">Close</button>
                                                            </div>
                                                        </div>
                                                    </div><!-- invisible content div for facets -->
                                                </g:if>
                                            %{--</g:each>--}%
                                            </ul>
                                        </div>

                                    </g:each>
                                    <div style="display:none"><!-- fancybox popup div -->
                                        <div id="multipleFacets">
                                            <p>Refine your search</p>
                                            <div id="dynamic" class="tableContainer"></div>
                                        </div>
                                    </div>
                                </g:if>
                                <g:else>
                                    <p>
                                        <span class="FieldName">${entry.key}</span>
                                    </p>

                                    <div id="facet-${entry.key}" class="subnavlist">
                                        <ul>
                                            <g:set var="i" value="${0}" />
                                            <g:set var="values" value="${entry.value}" />
                                            <g:while test="${i < 4 && i<values.size()}">
                                                <g:set var="arr" value="${values.get(i)}" />
                                                <li>
                                                    <a href="?fq=${entry.key}:${arr[0]}${queryParams}">${arr[0]}</a>  (${arr[1]})
                                                </li>
                                                <%i++%>
                                            </g:while>
                                            <g:if test="${values.size()>4}">
                                                <div class="showHide">
                                                    <i class="icon icon-hand-right"></i> <a href="#div${entry.getKey().replaceAll(" " ,"_")}" class="multipleFacetsLinkZ" id="multi-${entry.getKey()}"
                                                            role="button" data-toggle="modal" title="See full list of values">choose more...</a>
                                                    <!-- modal popup for "choose more" link -->
                                                    <div id="div${entry.getKey().replaceAll(" " ,"_")}" class="modal hide " tabindex="-1" role="dialog" aria-labelledby="multipleFacetsLabel2" aria-hidden="true"><!-- BS modal div -->
                                                        <div class="modal-header">
                                                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                                            <h3 class="multipleFacetsLabel2">Refine your search</h3>
                                                        </div>
                                                        <div class="modal-body">
                                                            <table class="table table-bordered table-condensed table-striped scrollTable" style="width:100%;">
                                                                <thead class="fixedHeader">
                                                                <tr class="tableHead">
                                                                    <th width="80%">${entry.getKey()}</th>
                                                                    <th style="border-right-style: none;text-align: right;">Count</th>
                                                                </tr>
                                                                </thead>
                                                                <tbody class="scrollContent">
                                                                <g:each in="${entry.getValue()}" var="arr">
                                                                    <tr>
                                                                        <td><a href="?fq=${entry.key}:${arr[0]}${queryParams}">${arr[0]} </a></td>
                                                                        <td style="border-right-style: none;text-align: right;">${arr[1]}</td>
                                                                    </tr>
                                                                </g:each>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <div class="modal-footer" style="text-align: left;">
                                                            <button class="btn btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;">Close</button>
                                                        </div>
                                                    </div>
                                                </div><!-- invisible content div for facets -->
                                            </g:if>
                                        </ul>
                                    </div>
                                </g:else>
                            </g:each>
                        </div>
                    </g:if>
                </section>
            </div><!-- boxed attached -->
        </div> <!-- col narrow -->
        <div class="span9">
            <div id="listItemView" class="btn-group">
                <a class="btn btn-small list disabled" title="View as detailed list" href="#list"><i class="icon icon-th-list"></i> list</a>
                <a class="btn btn-small grid" title="View as thumbnail image grid" href="#grid"><i class="icon icon-th"></i> grid</a>
            </div>
            <div id="gridView" class="hide">
                <g:each var="result" in="${results}" status="i">
                    <g:set var="recId" value="${result.id}"/>
                    <g:set var="bieSpecies" value="${bieItems?.get(result.guid)}"/>
                    <g:set var="bieTitle">species page for <i>${result.rawScientificName}</i></g:set>
                    <div class="imgCon">
                        <a class="thumbImage viewRecordButton" rel="thumbs" title="click to view details" href="#viewRecord"
                                    data-id="${recId}"><img src="${bieSpecies?.get(0)?:g.createLink(uri:'/images/infobox_info_icon.png\" style=\"opacity:0.5')}" alt="thumbnail species image"/>
                            </a>
                            <g:if test="${true}">
                                <g:set var="displayName">
                                    <i><g:if test="${result.guid == null}">
                                        ${fieldValue(bean: result, field: "rawScientificName")}
                                    </g:if>
                                    <g:else>
                                        ${bieSpecies?.get(2)}
                                    </g:else></i>
                                </g:set>
                                <div class="meta brief">
                                    ${displayName}
                                </div>
                                <div class="meta detail hide">
                                    ${displayName}
                                    <g:if test="${bieSpecies?.get(3)}"> ${bieSpecies?.get(3)}</g:if>
                                    <g:if test="${bieSpecies?.get(1)}"><br>${bieSpecies?.get(1)}</g:if>
                                    %{--<div class="btn-group btn-group pull-right">--}%
                                    <div class="pull-right" style="display:inline-block; padding: 5px;">
                                        <a href="#viewRecord" class="viewRecordButton" title="view record" data-id="${recId}"><i class="icon-info-sign icon-white"></i></a>&nbsp;
                                        <g:if test="${userCanEditData}">
                                            <a href="#" title="edit" data-remote="${createLink(controller: 'editor', action: 'editRecordScreen', id: result.id)}"
                                               data-target="#editRecord_${recId}" data-toggle="modal" ><i class="icon-pencil icon-white"></i></a>&nbsp;
                                            <a href="#" title="delete" data-target="#deleteRecord_${recId}" data-toggle="modal"><i class="icon-trash icon-white"></i></a>&nbsp;
                                        </g:if>
                                    </div>
                                </div>
                            </g:if>
                        </a>
                    </div>

                </g:each>
            </div><!-- /#iconView -->
            <div id="listView" class="hide">
                <section class="double">
                    <div class="fwtable table-bordered" style="overflow:auto;width:100%;">
                        <table class="tableList table table-bordered table-striped" id="speciesListTable">
                            <thead>
                            <tr>
                                <th class="action">Action</th>
                                <th>Supplied Name</th>
                                <th>Scientific Name (matched)</th>
                                <th>Image</th>
                                <th>Author (matched)</th>
                                <th>Common Name (matched)</th>
                                <g:each in="${keys}" var="key">
                                    <th>${key}</th>
                                </g:each>
                            </tr>
                            </thead>
                            <tbody>
                            <g:each var="result" in="${results}" status="i">
                                <g:set var="recId" value="${result.id}"/>
                                <g:set var="bieSpecies" value="${bieItems?.get(result.guid)}"/>
                                <g:set var="bieTitle">species page for <i>${result.rawScientificName}</i></g:set>
                                <tr class="${(i % 2) == 0 ? 'odd' : 'even'}" id="row_${recId}">
                                    <td class="action">
                                        <div class="btn-group btn-group">
                                            <a class="btn btn-small viewRecordButton" href="#viewRecord" title="view record" data-id="${recId}"><i class="icon-info-sign"></i></a>
                                            <g:if test="${userCanEditData}">
                                            <a class="btn btn-small" href="#" title="edit" data-remote="${createLink(controller: 'editor', action: 'editRecordScreen', id: result.id)}"
                                                   data-target="#editRecord_${recId}" data-toggle="modal" ><i class="icon-pencil"></i></a>
                                                <a class="btn btn-small" href="#" title="delete" data-target="#deleteRecord_${recId}" data-toggle="modal"><i class="icon-trash"></i></a>
                                            </g:if>
                                        </div>

                                    </td>
                                    <td>
                                        ${fieldValue(bean: result, field: "rawScientificName")}
                                        <g:if test="${result.guid == null}">
                                            <br/>(unmatched - try <a href="http://google.com/search?q=${fieldValue(bean: result, field: "rawScientificName").trim()}" target="google" clas="btn btn-primary btn-mini">Google</a>,
                                            <a href="${grailsApplication.config.biocache.baseURL}/occurrences/search?q=${fieldValue(bean: result, field: "rawScientificName").trim()}" target="biocache" clas="btn btn-success btn-mini">Occurrences</a>)
                                        </g:if>
                                    </td>
                                    <td>
                                        <g:if test="${bieSpecies}">
                                            <a href="${bieUrl}/species/${result.guid}" title="${bieTitle}">${bieSpecies?.get(2)}</a>
                                        </g:if>
                                        <g:else>
                                            ${result.matchedName}
                                        </g:else>
                                    </td>
                                    <td id="img_${result.guid}">
                                        <g:if test="${bieSpecies && bieSpecies.get(0)}">
                                        <a href="${bieUrl}/species/${result.guid}" title="${bieTitle}"><img src="${bieSpecies?.get(0)}" class="smallSpeciesImage"/></a>
                                        </g:if>
                                    </td>
                                    <td>${bieSpecies?.get(3)}</td>
                                    <td id="cn_${result.guid}">${bieSpecies?.get(1)}</td>
                                    <g:each in="${keys}" var="key">
                                        <g:set var="kvp" value="${result.kvpValues.find {it.key == key}}" />
                                        <g:set var="val" value="${kvp?.vocabValue?:kvp?.value}" />
                                        <td class="kvp ${val?.length() > 35 ? 'scrollWidth':''}"><div>${val}</div></td>
                                    </g:each>
                                </tr>
                            </g:each>
                            </tbody>
                        </table>
                    </div>
                </section>
            </div> <!-- /#listView -->
            <g:if test="${params.max<totalCount}">
                <div class="searchWidgets">
                    Items per page:
                    <select id="maxItems" class="input-mini" onchange="reloadWithMax(this)">
                        <g:each in="${[10,25,50,100]}" var="max">
                            <option ${(params.max == max)?'selected="selected"':''}>${max}</option>
                        </g:each>
                    </select>
                </div>

                <div class="pagination listPagination" id="searchNavBar">
                    <g:if test="${params.fq}">
                        <g:paginate total="${totalCount}" action="list" id="${params.id}" params="${[fq: params.fq]}"/>
                    </g:if>
                    <g:else>
                        <g:paginate total="${totalCount}" action="list" id="${params.id}" />
                    </g:else>
                </div>
            </g:if>
            %{-- Output the BS modal divs (hidden until called) --}%
            <g:each var="result" in="${results}" status="i">
                <g:set var="recId" value="${result.id}"/>
                <div class="modal hide fade" id="viewRecord">
                    <div class="modal-header">
                        <button type="button" class="close" onclick="$('#viewRecord .modal-body').scrollTop(0);" data-dismiss="modal" aria-hidden="true">×</button>
                        <h3>View record details</h3>
                    </div>
                    <div class="modal-body">
                        <p class="spinner"><img src="${resource(dir:'images',file:'spinner.gif')}" alt="spinner icon"/></p>
                        <table class="table table-bordered table-condensed table-striped hide">
                            <thead><th>Field</th><th>Value</th></thead>
                            <tbody></tbody>
                        </table>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-primary hide" data-id="${recId}">Previous</button>
                        <button class="btn btn-primary hide" data-id="${recId}">Next</button>
                        <button class="btn" onclick="$('#viewRecord .modal-body').scrollTop(0);" data-dismiss="modal" aria-hidden="true">Close</button>
                    </div>
                </div>
                <g:if test="${userCanEditData}">
                    <div class="modal hide fade" id="editRecord_${recId}">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                            <h3>Edit record values</h3>
                        </div>
                        <div class="modal-body">
                            <p><img src="${resource(dir:'images',file:'spinner.gif')}" alt="spinner icon"/></p>
                        </div>
                        <div class="modal-footer">
                            <button class="btn" data-dismiss="modal" aria-hidden="true">Cancel</button>
                            <button class="btn btn-primary saveRecord" data-modal="#editRecord_${recId}" data-id="${recId}">Save changes</button>
                        </div>
                    </div>
                    <div class="modal hide fade" id="deleteRecord_${recId}">
                        <div class="modal-header">
                            <h3>Are you sure you want to delete this species record?</h3>
                        </div>
                        <div class="modal-body">
                            <p>This will permanently delete the data for species <i>${result.rawScientificName}</i></p>
                        </div>
                        <div class="modal-footer">
                            <button class="btn" data-dismiss="modal" aria-hidden="true">Cancel</button>
                            <button class="btn btn-primary deleteSpecies" data-modal="#deleteRecord_${recId}" data-id="${recId}">Delete</button>
                        </div>
                    </div>
                </g:if>
            </g:each>
        </div> <!-- .span9 -->
        %{--</div> <!-- results -->--}%
    </div>
</div> <!-- content div -->
%{--<script type="text/javascript">--}%
    %{--function loadMultiFacets(facetName, displayName) {--}%
        %{--console.log(facetName, displayName)--}%
        %{--console.log("#div"+facetName,$("#div"+facetName),$("#div"+facetName).innerHTML)--}%
        %{--$("div#dynamic").innerHTML=$("#div"+facetName).innerHTML;--}%
    %{--}--}%
%{--</script>--}%
</body>
</html>