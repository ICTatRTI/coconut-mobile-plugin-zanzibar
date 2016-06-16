(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.Plugin = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Case,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_(["shehias_high_risk", "shehias_received_irs"]).each(function(docId) {
  return Coconut.database.get(docId)["catch"](function(error) {
    return console.error(JSON.stringify(error));
  }).then(function(result) {
    Coconut[docId] = result;
    return console.log("Loaded " + docId);
  });
});

Utils.addOrUpdateDesignDoc(Utils.createDesignDoc("cases", function(doc) {
  if (doc.MalariaCaseID) {
    emit(doc.MalariaCaseID, null);
  }
  if (doc.caseid) {
    return emit(doc.caseid, null);
  }
}));

Utils.addOrUpdateDesignDoc(Utils.createDesignDoc("casesWithSummaryData", function(doc) {
  var date, lastTransfer, match;
  if (doc.MalariaCaseID) {
    date = doc.DateofPositiveResults || doc.lastModifiedAt;
    match = date.match(/^(\d\d).(\d\d).(2\d\d\d)/);
    if (match != null) {
      date = match[3] + "-" + match[2] + "-" + match[1];
    }
    if (doc.transferred != null) {
      lastTransfer = doc.transferred[doc.transferred.length - 1];
    }
    if (date.match(/^2\d\d\d\-\d\d-\d\d/)) {
      emit(date, [doc.MalariaCaseID, doc.question, doc.complete, lastTransfer]);
    }
  }
  if (doc.caseid) {
    if (document.transferred != null) {
      lastTransfer = doc.transferred[doc.transferred.length - 1];
    }
    if (doc.date.match(/^2\d\d\d\-\d\d-\d\d/)) {
      return emit(doc.date, [doc.caseid, "Facility Notification", null, lastTransfer]);
    }
  }
}));

Case = (function() {
  function Case(options) {
    this.createNeighborHouseholds = bind(this.createNeighborHouseholds, this);
    this.createHouseholdMembers = bind(this.createHouseholdMembers, this);
    this.createHousehold = bind(this.createHousehold, this);
    this.createFacility = bind(this.createFacility, this);
    this.createNextResult = bind(this.createNextResult, this);
    this.saveAndAddResultToCase = bind(this.saveAndAddResultToCase, this);
    this.spreadsheetRowString = bind(this.spreadsheetRowString, this);
    this.spreadsheetRow = bind(this.spreadsheetRow, this);
    this.daysFromSMSToCompleteHousehold = bind(this.daysFromSMSToCompleteHousehold, this);
    this.timeFromSMSToCompleteHousehold = bind(this.timeFromSMSToCompleteHousehold, this);
    this.timeFromFacilityToCompleteHousehold = bind(this.timeFromFacilityToCompleteHousehold, this);
    this.daysFromCaseNotificationToCompleteFacility = bind(this.daysFromCaseNotificationToCompleteFacility, this);
    this.timeFromCaseNotificationToCompleteFacility = bind(this.timeFromCaseNotificationToCompleteFacility, this);
    this.timeFromSMSToCaseNotification = bind(this.timeFromSMSToCaseNotification, this);
    this.moreThan48HoursSinceFacilityNotifed = bind(this.moreThan48HoursSinceFacilityNotifed, this);
    this.moreThan24HoursSinceFacilityNotifed = bind(this.moreThan24HoursSinceFacilityNotifed, this);
    this.hoursSinceFacilityNotified = bind(this.hoursSinceFacilityNotified, this);
    this.timeSinceFacilityNotified = bind(this.timeSinceFacilityNotified, this);
    this.timeFacilityNotified = bind(this.timeFacilityNotified, this);
    this.daysBetweenPositiveResultAndNotification = bind(this.daysBetweenPositiveResultAndNotification, this);
    this.fetchResults = bind(this.fetchResults, this);
    this.resultsAsArray = bind(this.resultsAsArray, this);
    this.hasCompleteNeighborHouseholdMembers = bind(this.hasCompleteNeighborHouseholdMembers, this);
    this.completeNeighborHouseholdMembers = bind(this.completeNeighborHouseholdMembers, this);
    this.completeNeighborHouseholds = bind(this.completeNeighborHouseholds, this);
    this.hasAdditionalPositiveCasesAtIndexHousehold = bind(this.hasAdditionalPositiveCasesAtIndexHousehold, this);
    this.hasCompleteIndexCaseHouseholdMembers = bind(this.hasCompleteIndexCaseHouseholdMembers, this);
    this.completeIndexCaseHouseholdMembers = bind(this.completeIndexCaseHouseholdMembers, this);
    this.followedUp = bind(this.followedUp, this);
    this.indexCaseHasNoTravelHistory = bind(this.indexCaseHasNoTravelHistory, this);
    this.indexCaseHasTravelHistory = bind(this.indexCaseHasTravelHistory, this);
    this.followedUpWithin48Hours = bind(this.followedUpWithin48Hours, this);
    this.notFollowedUpAfter48Hours = bind(this.notFollowedUpAfter48Hours, this);
    this.notCompleteFacilityAfter24Hours = bind(this.notCompleteFacilityAfter24Hours, this);
    this.hasCompleteFacility = bind(this.hasCompleteFacility, this);
    this.complete = bind(this.complete, this);
    this.questionStatus = bind(this.questionStatus, this);
    this.locationBy = bind(this.locationBy, this);
    this.highRiskShehia = bind(this.highRiskShehia, this);
    this.toJSON = bind(this.toJSON, this);
    this.fetch = bind(this.fetch, this);
    this.caseID = options != null ? options.caseID : void 0;
    if (options != null ? options.results : void 0) {
      this.loadFromResultDocs(options.results);
    }
  }

  Case.prototype.loadFromResultDocs = function(resultDocs) {
    var ref, ref1, userRequiresDeidentification;
    this.caseResults = resultDocs;
    this.questions = [];
    this["Household Members"] = [];
    this["Neighbor Households"] = [];
    userRequiresDeidentification = (((ref = Coconut.currentUser) != null ? ref.hasRole("reports") : void 0) || Coconut.currentUser === null) && !((ref1 = Coconut.currentUser) != null ? ref1.hasRole("admin") : void 0);
    return _.each(resultDocs, (function(_this) {
      return function(resultDoc) {
        var dateOfPositiveResults, day, dayMonthYearMatch, month, ref2, year;
        if (resultDoc.toJSON != null) {
          resultDoc = resultDoc.toJSON();
        }
        if (userRequiresDeidentification) {
          _.each(resultDoc, function(value, key) {
            if ((value != null) && _.contains(Coconut.identifyingAttributes, key)) {
              return resultDoc[key] = b64_sha1(value);
            }
          });
        }
        if (resultDoc.question) {
          if (_this.caseID == null) {
            _this.caseID = resultDoc["MalariaCaseID"];
          }
          if (_this.caseID !== resultDoc["MalariaCaseID"]) {
            throw "Inconsistent Case ID";
          }
          _this.questions.push(resultDoc.question);
          if (resultDoc.question === "Household Members") {
            return _this["Household Members"].push(resultDoc);
          } else if (resultDoc.question === "Household" && resultDoc.Reasonforvisitinghousehold === "Index Case Neighbors") {
            return _this["Neighbor Households"].push(resultDoc);
          } else {
            if (resultDoc.question === "Facility") {
              dateOfPositiveResults = resultDoc.DateofPositiveResults;
              if (dateOfPositiveResults != null) {
                dayMonthYearMatch = dateOfPositiveResults.match(/^(\d\d).(\d\d).(20\d\d)/);
                if (dayMonthYearMatch) {
                  ref2 = dayMonthYearMatch.slice(1), day = ref2[0], month = ref2[1], year = ref2[2];
                  if (day > 31 || month > 12) {
                    console.error("Invalid DateOfPositiveResults: " + _this);
                  } else {
                    resultDoc.DateofPositiveResults = year + "-" + month + "-" + day;
                  }
                }
              }
            }
            if (_this[resultDoc.question] != null) {
              if (_this[resultDoc.question].complete === "true" && (resultDoc.complete !== "true")) {
                console.log("Using the result marked as complete");
                return;
              } else if (_this[resultDoc.question].complete && resultDoc.complete) {
                console.warn("Duplicate complete entries for case: " + _this.caseID);
              }
            }
            return _this[resultDoc.question] = resultDoc;
          }
        } else {
          if (_this.caseID == null) {
            _this.caseID = resultDoc["caseid"];
          }
          if (_this.caseID !== resultDoc["caseid"]) {
            console.log(resultDoc);
            console.log(resultDocs);
            throw "Inconsistent Case ID. Working on " + _this.caseID + " but current doc has " + resultDoc["caseid"] + ": " + (JSON.stringify(resultDoc));
          }
          _this.questions.push("USSD Notification");
          return _this["USSD Notification"] = resultDoc;
        }
      };
    })(this));
  };

  Case.prototype.fetch = function(options) {
    if (!this.caseID) {
      console.error("No caseID to fetch data for");
      return;
    }
    return Coconut.database.query("cases/cases", {
      key: this.caseID,
      include_docs: true
    })["catch"](function(error) {
      return options != null ? options.error() : void 0;
    }).then((function(_this) {
      return function(result) {
        _this.loadFromResultDocs(_.pluck(result.rows, "doc"));
        return options != null ? options.success() : void 0;
      };
    })(this));
  };

  Case.prototype.toJSON = function() {
    var returnVal;
    returnVal = {};
    _.each(this.questions, (function(_this) {
      return function(question) {
        return returnVal[question] = _this[question];
      };
    })(this));
    return returnVal;
  };

  Case.prototype.deIdentify = function(result) {};

  Case.prototype.flatten = function(questions) {
    var returnVal;
    if (questions == null) {
      questions = this.questions;
    }
    returnVal = {};
    _.each(questions, (function(_this) {
      return function(question) {
        var type;
        type = question;
        return _.each(_this[question], function(value, field) {
          if (_.isObject(value)) {
            return _.each(value, function(arrayValue, arrayField) {
              return returnVal[question + "-" + field + ": " + arrayField] = arrayValue;
            });
          } else {
            return returnVal[question + ":" + field] = value;
          }
        });
      };
    })(this));
    return returnVal;
  };

  Case.prototype.LastModifiedAt = function() {
    return _.chain(this.toJSON()).map(function(question) {
      return question.lastModifiedAt;
    }).max(function(lastModifiedAt) {
      return lastModifiedAt != null ? lastModifiedAt.replace(/[- :]/g, "") : void 0;
    }).value();
  };

  Case.prototype.Questions = function() {
    return _.keys(this.toJSON()).join(", ");
  };

  Case.prototype.MalariaCaseID = function() {
    return this.caseID;
  };

  Case.prototype.user = function() {
    var ref, ref1, ref2, userId;
    return userId = ((ref = this.Household) != null ? ref.user : void 0) || ((ref1 = this.Facility) != null ? ref1.user : void 0) || ((ref2 = this["Case Notification"]) != null ? ref2.user : void 0);
  };

  Case.prototype.facility = function() {
    var ref, ref1;
    return ((ref = this["USSD Notification"]) != null ? ref.hf : void 0) || ((ref1 = this["Case Notification"]) != null ? ref1.FacilityName : void 0);
  };

  Case.prototype.validShehia = function() {
    var ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9;
    if (((ref = this.Household) != null ? ref.Shehia : void 0) && GeoHierarchy.findOneShehia(this.Household.Shehia)) {
      return (ref1 = this.Household) != null ? ref1.Shehia : void 0;
    } else if (((ref2 = this.Facility) != null ? ref2.Shehia : void 0) && GeoHierarchy.findOneShehia(this.Facility.Shehia)) {
      return (ref3 = this.Facility) != null ? ref3.Shehia : void 0;
    } else if (((ref4 = this["Case Notification"]) != null ? ref4.Shehia : void 0) && GeoHierarchy.findOneShehia((ref5 = this["Case Notification"]) != null ? ref5.Shehia : void 0)) {
      return (ref6 = this["Case Notification"]) != null ? ref6.Shehia : void 0;
    } else if (((ref7 = this["USSD Notification"]) != null ? ref7.shehia : void 0) && GeoHierarchy.findOneShehia((ref8 = this["USSD Notification"]) != null ? ref8.shehia : void 0)) {
      return (ref9 = this["USSD Notification"]) != null ? ref9.shehia : void 0;
    }
    return null;
  };

  Case.prototype.shehia = function() {
    var ref, ref1, ref2, returnVal;
    returnVal = this.validShehia();
    if (returnVal != null) {
      return returnVal;
    }
    console.warn("No valid shehia found for case: " + (this.MalariaCaseID()) + " result will be either null or unknown");
    return ((ref = this.Household) != null ? ref.Shehia : void 0) || ((ref1 = this.Facility) != null ? ref1.Shehia : void 0) || ((ref2 = this["USSD Notification"]) != null ? ref2.shehia : void 0);
  };

  Case.prototype.district = function() {
    var district, ref, ref1, ref2, shehia;
    shehia = this.validShehia();
    if (shehia != null) {
      return GeoHierarchy.findOneShehia(shehia).DISTRICT;
    } else {
      console.warn((this.MalariaCaseID()) + ": No valid shehia found, using district of reporting health facility (which may not be where the patient lives)");
      district = GeoHierarchy.swahiliDistrictName((ref = this["USSD Notification"]) != null ? ref.facility_district : void 0);
      if (_(GeoHierarchy.allDistricts()).include(district)) {
        return district;
      } else {
        console.warn((this.MalariaCaseID()) + ": The reported district (" + district + ") used for the reporting facility is not a valid district. Looking up the district for the health facility name.");
        district = GeoHierarchy.swahiliDistrictName(FacilityHierarchy.getDistrict((ref1 = this["USSD Notification"]) != null ? ref1.hf : void 0));
        if (_(GeoHierarchy.allDistricts()).include(district)) {
          return district;
        } else {
          console.warn((this.MalariaCaseID()) + ": The health facility name (" + ((ref2 = this["USSD Notification"]) != null ? ref2.hf : void 0) + ") is not valid. Giving up and returning UNKNOWN.");
          return "UNKNOWN";
        }
      }
    }
  };

  Case.prototype.highRiskShehia = function(date) {
    if (!date) {
      date = moment().startOf('year').format("YYYY-MM");
    }
    return _(Coconut.shehias_high_risk[date]).contains(this.shehia());
  };

  Case.prototype.locationBy = function(geographicLevel) {
    if (geographicLevel.match(/district/i)) {
      return this.district();
    }
    if (geographicLevel.match(/shehia/i)) {
      return this.validShehia();
    }
  };

  Case.prototype.possibleQuestions = function() {
    return ["Case Notification", "Facility", "Household", "Household Members"];
  };

  Case.prototype.questionStatus = function() {
    var result;
    result = {};
    _.each(this.possibleQuestions(), (function(_this) {
      return function(question) {
        var ref;
        if (question === "Household Members") {
          result["Household Members"] = true;
          return _.each(_this["Household Members"] != null, function(member) {
            if (member.complete === "false") {
              return result["Household Members"] = false;
            }
          });
        } else {
          return result[question] = ((ref = _this[question]) != null ? ref.complete : void 0) === "true";
        }
      };
    })(this));
    return result;
  };

  Case.prototype.complete = function() {
    return this.questionStatus()["Household Members"] === true;
  };

  Case.prototype.hasCompleteFacility = function() {
    var ref;
    return ((ref = this.Facility) != null ? ref.complete : void 0) === "true";
  };

  Case.prototype.notCompleteFacilityAfter24Hours = function() {
    return this.moreThan24HoursSinceFacilityNotifed() && !this.hasCompleteFacility();
  };

  Case.prototype.notFollowedUpAfter48Hours = function() {
    return this.moreThan48HoursSinceFacilityNotifed() && !this.followedUp();
  };

  Case.prototype.followedUpWithin48Hours = function() {
    return !this.notFollowedUpAfter48Hours();
  };

  Case.prototype.indexCaseHasTravelHistory = function() {
    var ref, ref1;
    return ((ref = this.Facility) != null ? (ref1 = ref.TravelledOvernightinpastmonth) != null ? ref1.match(/Yes/) : void 0 : void 0) || false;
  };

  Case.prototype.indexCaseHasNoTravelHistory = function() {
    return !this.indexCaseHasTravelHistory();
  };

  Case.prototype.followedUp = function() {
    var ref, ref1;
    return ((ref = this.Household) != null ? ref.complete : void 0) === "true" || ((ref1 = this.Facility) != null ? ref1.Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility : void 0) === "Yes";
  };

  Case.prototype.location = function(type) {
    var ref, ref1;
    return (ref = GeoHierarchy.findOneShehia((ref1 = this.toJSON()["Case Notification"]) != null ? ref1["FacilityName"] : void 0)) != null ? ref[type.toUpperCase()] : void 0;
  };

  Case.prototype.withinLocation = function(location) {
    return this.location(location.type) === location.name;
  };

  Case.prototype.completeIndexCaseHouseholdMembers = function() {
    return _(this["Household Members"]).filter((function(_this) {
      return function(householdMember) {
        return householdMember.HeadofHouseholdName === _this["Household"].HeadofHouseholdName && householdMember.complete === "true";
      };
    })(this));
  };

  Case.prototype.hasCompleteIndexCaseHouseholdMembers = function() {
    return this.completeIndexCaseHouseholdMembers().length > 0;
  };

  Case.prototype.positiveCasesAtIndexHousehold = function() {
    return _(this.completeIndexCaseHouseholdMembers()).filter(function(householdMember) {
      return householdMember.MalariaTestResult === "PF" || householdMember.MalariaTestResult === "Mixed";
    });
  };

  Case.prototype.hasAdditionalPositiveCasesAtIndexHousehold = function() {
    return this.positiveCasesAtIndexHousehold().length > 0;
  };

  Case.prototype.completeNeighborHouseholds = function() {
    return _(this["Neighbor Households"]).filter((function(_this) {
      return function(household) {
        return household.complete === "true";
      };
    })(this));
  };

  Case.prototype.completeNeighborHouseholdMembers = function() {
    return _(this["Household Members"]).filter((function(_this) {
      return function(householdMember) {
        return householdMember.HeadofHouseholdName !== _this["Household"].HeadofHouseholdName && householdMember.complete === "true";
      };
    })(this));
  };

  Case.prototype.hasCompleteNeighborHouseholdMembers = function() {
    return this.completeIndexCaseHouseholdMembers().length > 0;
  };

  Case.prototype.positiveCasesAtNeighborHouseholds = function() {
    return _(this.completeNeighborHouseholdMembers()).filter(function(householdMember) {
      return householdMember.MalariaTestResult === "PF" || householdMember.MalariaTestResult === "Mixed";
    });
  };

  Case.prototype.positiveCasesAtIndexHouseholdAndNeighborHouseholds = function() {
    return _(this["Household Members"]).filter((function(_this) {
      return function(householdMember) {
        return householdMember.MalariaTestResult === "PF" || householdMember.MalariaTestResult === "Mixed";
      };
    })(this));
  };

  Case.prototype.numberPositiveCasesAtIndexHouseholdAndNeighborHouseholds = function() {
    return this.positiveCasesAtIndexHouseholdAndNeighborHouseholds().length;
  };

  Case.prototype.numberHouseholdOrNeighborMembers = function() {
    return this["Household Members"].length;
  };

  Case.prototype.numberHouseholdOrNeighborMembersTested = function() {
    return _(this["Household Members"]).filter((function(_this) {
      return function(householdMember) {
        return householdMember.MalariaTestResult === "NPF";
      };
    })(this)).length;
  };

  Case.prototype.positiveCasesIncludingIndex = function() {
    if (this["Facility"]) {
      return this.positiveCasesAtIndexHouseholdAndNeighborHouseholds().concat(_.extend(this["Facility"], this["Household"]));
    } else if (this["USSD Notification"]) {
      return this.positiveCasesAtIndexHouseholdAndNeighborHouseholds().concat(_.extend(this["USSD Notification"], this["Household"], {
        MalariaCaseID: this.MalariaCaseID()
      }));
    }
  };

  Case.prototype.indexCasePatientName = function() {
    var ref, ref1, ref2;
    if (((ref = this["Facility"]) != null ? ref.complete : void 0) === "true") {
      return this["Facility"].FirstName + " " + this["Facility"].LastName;
    }
    if (this["USSD Notification"] != null) {
      return (ref1 = this["USSD Notification"]) != null ? ref1.name : void 0;
    }
    if (this["Case Notification"] != null) {
      return (ref2 = this["Case Notification"]) != null ? ref2.Name : void 0;
    }
  };

  Case.prototype.indexCaseDiagnosisDate = function() {
    var date, ref;
    if (((ref = this["Facility"]) != null ? ref.DateofPositiveResults : void 0) != null) {
      date = this["Facility"].DateofPositiveResults;
      if (date.match(/^20\d\d/)) {
        return moment(this["Facility"].DateofPositiveResults).format("YYYY-MM-DD");
      } else {
        return moment(this["Facility"].DateofPositiveResults, "DD-MM-YYYY").format("YYYY-MM-DD");
      }
    } else if (this["USSD Notification"] != null) {
      return moment(this["USSD Notification"].date).format("YYYY-MM-DD");
    }
  };

  Case.prototype.householdMembersDiagnosisDate = function() {
    var returnVal;
    returnVal = [];
    return _.each(this["Household Members"] != null, function(member) {
      if (member.MalariaTestResult === "PF" || member.MalariaTestResult === "Mixed") {
        return returnVal.push(member.lastModifiedAt);
      }
    });
  };

  Case.prototype.resultsAsArray = function() {
    return _.chain(this.possibleQuestions()).map((function(_this) {
      return function(question) {
        return _this[question];
      };
    })(this)).flatten().compact().value();
  };

  Case.prototype.fetchResults = function(options) {
    var count, results;
    results = _.map(this.resultsAsArray(), (function(_this) {
      return function(result) {
        var returnVal;
        returnVal = new Result();
        returnVal.id = result._id;
        return returnVal;
      };
    })(this));
    count = 0;
    _.each(results, function(result) {
      return result.fetch({
        success: function() {
          count += 1;
          if (count >= results.length) {
            return options.success(results);
          }
        }
      });
    });
    return results;
  };

  Case.prototype.updateCaseID = function(newCaseID) {
    return this.fetchResults({
      success: function(results) {
        return _.each(results, function(result) {
          if (result.attributes.MalariaCaseID == null) {
            throw "No MalariaCaseID";
          }
          return result.save({
            MalariaCaseID: newCaseID
          });
        });
      }
    });
  };

  Case.prototype.issuesRequiringCleaning = function() {
    var issues, questionTypes, ref, resultCount;
    resultCount = {};
    questionTypes = "USSD Notification, Case Notification, Facility, Household, Household Members".split(/, /);
    _.each(questionTypes, function(questionType) {
      return resultCount[questionType] = 0;
    });
    _.each(this.caseResults, function(result) {
      if (result.caseid != null) {
        resultCount["USSD Notification"]++;
      }
      if (result.question != null) {
        return resultCount[result.question]++;
      }
    });
    issues = [];
    _.each(questionTypes.slice(0, 4), function(questionType) {
      if (resultCount[questionType] > 1) {
        return issues.push(resultCount[questionType] + " " + questionType + "s");
      }
    });
    if (!this.followedUp()) {
      issues.push("Not followed up");
    }
    if (this.caseResults.length === 1) {
      issues.push("Orphaned result");
    }
    if (!((this["Case Notification"] != null) || ((ref = this["Case Notification"]) != null ? ref.length : void 0) === 0)) {
      issues.push("Missing case notification");
    }
    return issues;
  };

  Case.prototype.allResultsByQuestion = function() {
    var returnVal;
    returnVal = {};
    _.each("USSD Notification, Case Notification, Facility, Household".split(/, /), function(question) {
      return returnVal[question] = [];
    });
    _.each(this.caseResults, function(result) {
      if (result["question"] != null) {
        return returnVal[result["question"]].push(result);
      } else if (result.hf != null) {
        return returnVal["USSD Notification"].push(result);
      }
    });
    return returnVal;
  };

  Case.prototype.redundantResults = function() {
    var redundantResults;
    redundantResults = [];
    return _.each(this.allResultsByQuestion, function(results, question) {
      return console.log(_.sort(results, "createdAt"));
    });
  };

  Case.prototype.daysBetweenPositiveResultAndNotification = function() {
    var date, dateOfPositiveResults, notificationDate, ref;
    dateOfPositiveResults = ((ref = this["Facility"]) != null ? ref.DateofPositiveResults : void 0) != null ? (date = this["Facility"].DateofPositiveResults, date.match(/^20\d\d/) ? moment(this["Facility"].DateofPositiveResults).format("YYYY-MM-DD") : moment(this["Facility"].DateofPositiveResults, "DD-MM-YYYY").format("YYYY-MM-DD")) : void 0;
    notificationDate = this["USSD Notification"] != null ? this["USSD Notification"].date : void 0;
    if ((dateOfPositiveResults != null) && (notificationDate != null)) {
      return Math.abs(moment(dateOfPositiveResults).diff(notificationDate, 'days'));
    }
  };

  Case.prototype.timeFacilityNotified = function() {
    if (this["USSD Notification"] != null) {
      return this["USSD Notification"].date;
    } else {
      return null;
    }
  };

  Case.prototype.timeSinceFacilityNotified = function() {
    var timeFacilityNotified;
    timeFacilityNotified = this.timeFacilityNotified();
    if (timeFacilityNotified != null) {
      return moment().diff(timeFacilityNotified);
    } else {
      return null;
    }
  };

  Case.prototype.hoursSinceFacilityNotified = function() {
    var timeSinceFacilityNotified;
    timeSinceFacilityNotified = this.timeSinceFacilityNotified();
    if (timeSinceFacilityNotified != null) {
      return moment.duration(timeSinceFacilityNotified).asHours();
    } else {
      return null;
    }
  };

  Case.prototype.moreThan24HoursSinceFacilityNotifed = function() {
    return this.hoursSinceFacilityNotified() > 24;
  };

  Case.prototype.moreThan48HoursSinceFacilityNotifed = function() {
    return this.hoursSinceFacilityNotified() > 48;
  };

  Case.prototype.timeFromSMSToCaseNotification = function() {
    var ref, ref1;
    if ((this["Case Notification"] != null) && (this["USSD Notification"] != null)) {
      return moment((ref1 = this["Case Notification"]) != null ? ref1.createdAt : void 0).diff((ref = this["USSD Notification"]) != null ? ref.date : void 0);
    }
  };

  Case.prototype.timeFromCaseNotificationToCompleteFacility = function() {
    var ref, ref1;
    if (((ref = this["Facility"]) != null ? ref.complete : void 0) === "true" && (this["Case Notification"] != null)) {
      return moment(this["Facility"].lastModifiedAt.replace(/\+0\d:00/, "")).diff((ref1 = this["Case Notification"]) != null ? ref1.createdAt : void 0);
    }
  };

  Case.prototype.daysFromCaseNotificationToCompleteFacility = function() {
    var ref;
    if (((ref = this["Facility"]) != null ? ref.complete : void 0) === "true" && (this["Case Notification"] != null)) {
      return moment.duration(this.timeFromCaseNotificationToCompleteFacility()).asDays();
    }
  };

  Case.prototype.timeFromFacilityToCompleteHousehold = function() {
    var ref, ref1;
    if (((ref = this["Household"]) != null ? ref.complete : void 0) === "true" && (this["Facility"] != null)) {
      return moment(this["Household"].lastModifiedAt.replace(/\+0\d:00/, "")).diff((ref1 = this["Facility"]) != null ? ref1.lastModifiedAt : void 0);
    }
  };

  Case.prototype.timeFromSMSToCompleteHousehold = function() {
    var ref, ref1;
    if (((ref = this["Household"]) != null ? ref.complete : void 0) === "true" && (this["USSD Notification"] != null)) {
      return moment(this["Household"].lastModifiedAt.replace(/\+0\d:00/, "")).diff((ref1 = this["USSD Notification"]) != null ? ref1.date : void 0);
    }
  };

  Case.prototype.daysFromSMSToCompleteHousehold = function() {
    var ref;
    if (((ref = this["Household"]) != null ? ref.complete : void 0) === "true" && (this["USSD Notification"] != null)) {
      return moment.duration(this.timeFromSMSToCompleteHousehold()).asDays();
    }
  };

  Case.prototype.spreadsheetRow = function(question) {
    var spreadsheetRowObjectForResult;
    if (Coconut.spreadsheetHeader == null) {
      console.error("Must call loadSpreadsheetHeader at least once before calling spreadsheetRow");
    }
    spreadsheetRowObjectForResult = function(fields, result) {
      if (result != null) {
        return _(fields).map((function(_this) {
          return function(field) {
            if (result[field] != null) {
              if (_.contains(Coconut.identifyingAttributes, field)) {
                return b64_sha1(result[field]);
              } else {
                return result[field];
              }
            } else {
              return "";
            }
          };
        })(this));
      } else {
        return null;
      }
    };
    if (question === "Household Members") {
      return _(this[question]).map(function(householdMemberResult) {
        return spreadsheetRowObjectForResult(Coconut.spreadsheetHeader[question], householdMemberResult);
      });
    } else {
      return spreadsheetRowObjectForResult(Coconut.spreadsheetHeader[question], this[question]);
    }
  };

  Case.prototype.spreadsheetRowString = function(question) {
    var result;
    if (question === "Household Members") {
      return _(this.spreadsheetRow(question)).map(function(householdMembersRows) {
        var result;
        result = _(householdMembersRows).map(function(data) {
          return "\"" + data + "\"";
        }).join(",");
        if (result !== "") {
          return result += "--EOR--";
        }
      }).join("");
    } else {
      result = _(this.spreadsheetRow(question)).map(function(data) {
        return "\"" + data + "\"";
      }).join(",");
      if (result !== "") {
        return result += "--EOR--";
      }
    }
  };

  Case.prototype.saveAndAddResultToCase = function(result) {
    if (this[result.question] != null) {
      console.error(result.question + " already exists for:");
      console.error(this);
      return;
    }
    console.debug(result);
    return Coconut.database.post(result).then((function(_this) {
      return function(result) {
        console.log("saved");
        console.debug(result);
        _this.questions.push(result.question);
        _this[result.question] = result;
        console.debug(_this);
        console.debug(window.malariaCase);
        return Coconut.menuView.update();
      };
    })(this))["catch"](function(error) {
      return console.error(error);
    });
  };

  Case.prototype.createNextResult = function() {
    return this.fetch({
      error: function() {
        return console.error(error);
      },
      success: (function(_this) {
        return function() {
          var ref, ref1, ref2;
          if (_this["Household Members"] && _this["Household Members"].length > 0) {
            console.log("Household Members exists, no result created");
          } else if ((ref = _this.Household) != null ? ref.complete : void 0) {
            console.log("Creating Household members and neighbor households if necessary");
            _this.createHouseholdMembers();
            _this.createNeighborHouseholds();
          } else if ((ref1 = _this.Facility) != null ? ref1.complete : void 0) {
            console.log("Creating Household");
            _this.createHousehold();
          } else if ((ref2 = _this["Case Notification"]) != null ? ref2.complete : void 0) {
            console.log("Creating Facility");
            _this.createFacility();
          }
          return _.delay(Coconut.menuView.render, 500);
        };
      })(this)
    });
  };

  Case.prototype.createFacility = function() {
    return this.saveAndAddResultToCase({
      question: "Facility",
      MalariaCaseID: this.caseID,
      FacilityName: this.facility(),
      Shehia: this.shehia(),
      collection: "result",
      createdAt: moment(new Date()).format(Coconut.config.get("date_format")),
      lastModifiedAt: moment(new Date()).format(Coconut.config.get("date_format"))
    });
  };

  Case.prototype.createHousehold = function() {
    return this.saveAndAddResultToCase({
      question: "Household",
      Reasonforvisitinghousehold: "Index Case Household",
      MalariaCaseID: this.caseID,
      HeadofHouseholdName: this.Facility.HeadofHouseholdName,
      Shehia: this.shehia(),
      Village: this.Facility.Village,
      ShehaMjumbe: this.Facility.ShehaMjumbe,
      ContactMobilepatientrelative: this.Facility.ContactMobilepatientrelative,
      collection: "result",
      createdAt: moment(new Date()).format(Coconut.config.get("date_format")),
      lastModifiedAt: moment(new Date()).format(Coconut.config.get("date_format"))
    });
  };

  Case.prototype.createHouseholdMembers = function() {
    if (!_(this.questions).contains('Household Members')) {
      return _(this.Household.TotalNumberofResidentsintheHousehold - 1).times((function(_this) {
        return function() {
          var result;
          result = {
            question: "Household Members",
            MalariaCaseID: _this.caseID,
            HeadofHouseholdName: _this.Household.HeadofHouseholdName,
            collection: "result",
            createdAt: moment(new Date()).format(Coconut.config.get("date_format")),
            lastModifiedAt: moment(new Date()).format(Coconut.config.get("date_format"))
          };
          return Coconut.database.post(result).then(function() {
            _this.questions.push(result.question);
            if (!_this[result.questin]) {
              _this[result.question] = [];
            }
            _this[result.question].push(result);
            return Coconut.menuView.update();
          })["catch"](function(error) {
            return console.error(error);
          });
        };
      })(this));
    }
  };

  Case.prototype.createNeighborHouseholds = function() {
    if ((_(this.questions).filter(function(question) {
      return question === 'Household';
    })).length !== 1) {
      return _(this.Household.Numberofotherhouseholdswithin50stepsofindexcasehousehold).times((function(_this) {
        return function() {
          var result;
          result = {
            Reasonforvisitinghousehold: "Index Case Neighbors",
            question: "Household",
            MalariaCaseID: _this.result.get("MalariaCaseID"),
            Shehia: _this.result.get("Shehia"),
            Village: _this.result.get("Village"),
            ShehaMjumbe: _this.result.get("ShehaMjumbe"),
            collection: "result",
            createdAt: moment(new Date()).format(Coconut.config.get("date_format")),
            lastModifiedAt: moment(new Date()).format(Coconut.config.get("date_format"))
          };
          return Coconut.database.post(result).then(function() {
            return Coconut.menuView.update();
          })["catch"](function(error) {
            return console.error(error);
          });
        };
      })(this));
    }
  };

  return Case;

})();

Case.loadSpreadsheetHeader = function(options) {
  if (Coconut.spreadsheetHeader) {
    return options.success();
  } else {
    return Coconut.database.get("spreadsheet_header")["catch"](function(error) {
      console.error(error);
      return options != null ? options.error() : void 0;
    }).then((function(_this) {
      return function(result) {
        Coconut.spreadsheetHeader = result.fields;
        return options.success();
      };
    })(this));
  }
};

Case.updateCaseSpreadsheetDocs = function(options) {
  var caseSpreadsheetData, changeSequence, updateCaseSpreadsheetDocs;
  caseSpreadsheetData = {
    _id: "CaseSpreadsheetData"
  };
  changeSequence = 0;
  updateCaseSpreadsheetDocs = function(changeSequence, caseSpreadsheetData) {
    return Case.updateCaseSpreadsheetDocsSince({
      changeSequence: changeSequence,
      error: function(error) {
        console.log("Error updating CaseSpreadsheetData:");
        console.log(error);
        return typeof options.error === "function" ? options.error() : void 0;
      },
      success: function(numberCasesChanged, lastChangeSequenceProcessed) {
        console.log("Updated CaseSpreadsheetData");
        caseSpreadsheetData.lastChangeSequenceProcessed = lastChangeSequenceProcessed;
        console.log(caseSpreadsheetData);
        return Coconut.database.saveDoc(caseSpreadsheetData, {
          success: function() {
            console.log(numberCasesChanged);
            if (numberCasesChanged > 0) {
              return Case.updateCaseSpreadsheetDocs(options);
            } else {
              return options != null ? typeof options.success === "function" ? options.success() : void 0 : void 0;
            }
          }
        });
      }
    });
  };
  return Coconut.database.openDoc("CaseSpreadsheetData", {
    success: function(result) {
      caseSpreadsheetData = result;
      changeSequence = result.lastChangeSequenceProcessed;
      return updateCaseSpreadsheetDocs(changeSequence, caseSpreadsheetData);
    },
    error: function(error) {
      console.log("Couldn't find 'CaseSpreadsheetData' using defaults: changeSequence: " + changeSequence);
      return updateCaseSpreadsheetDocs(changeSequence, caseSpreadsheetData);
    }
  });
};

Case.updateCaseSpreadsheetDocsSince = function(options) {
  return Case.loadSpreadsheetHeader({
    success: function() {
      return $.ajax({
        url: "/" + (Coconut.config.database_name()) + "/_changes",
        dataType: "json",
        data: {
          since: options.changeSequence,
          include_docs: true,
          limit: 100000
        },
        error: (function(_this) {
          return function(error) {
            console.log("Error downloading changes after " + options.changeSequence + ":");
            console.log(error);
            return typeof options.error === "function" ? options.error(error) : void 0;
          };
        })(this),
        success: (function(_this) {
          return function(changes) {
            var changedCases, lastChangeSequence, ref;
            changedCases = _(changes.results).chain().map(function(change) {
              if ((change.doc.MalariaCaseID != null) && (change.doc.question != null)) {
                return change.doc.MalariaCaseID;
              }
            }).compact().uniq().value();
            lastChangeSequence = (ref = changes.results.pop()) != null ? ref.seq : void 0;
            return Case.updateSpreadsheetForCases({
              caseIDs: changedCases,
              error: function(error) {
                console.log("Error updating " + changedCases.length + " cases, lastChangeSequence: " + lastChangeSequence);
                return console.log(error);
              },
              success: function() {
                console.log("Updated " + changedCases.length + " cases, lastChangeSequence: " + lastChangeSequence);
                return options.success(changedCases.length, lastChangeSequence);
              }
            });
          };
        })(this)
      });
    }
  });
};

Case.updateSpreadsheetForCases = function(options) {
  var docsToSave, finished, questions;
  docsToSave = [];
  questions = "USSD Notification,Case Notification,Facility,Household,Household Members".split(",");
  if (options.caseIDs.length === 0) {
    options.success();
  }
  finished = _.after(options.caseIDs.length, function() {
    return Coconut.database.bulkSave({
      docs: docsToSave
    }, {
      error: function(error) {
        return console.log(error);
      },
      success: function() {
        return options.success();
      }
    });
  });
  return _(options.caseIDs).each(function(caseID) {
    var malariaCase;
    malariaCase = new Case({
      caseID: caseID
    });
    return malariaCase.fetch({
      error: function(error) {
        return console.log(error);
      },
      success: function() {
        var docId, spreadsheet_row_doc;
        docId = "spreadsheet_row_" + caseID;
        spreadsheet_row_doc = {
          _id: docId
        };
        return Coconut.database.openDoc(docId, {
          success: function(result) {
            spreadsheet_row_doc = result;
            _(questions).each(function(question) {
              return spreadsheet_row_doc[question] = malariaCase.spreadsheetRowString(question);
            });
            docsToSave.push(spreadsheet_row_doc);
            return finished();
          },
          error: function() {
            _(questions).each(function(question) {
              return spreadsheet_row_doc[question] = malariaCase.spreadsheetRowString(question);
            });
            docsToSave.push(spreadsheet_row_doc);
            return finished();
          }
        });
      }
    });
  });
};

module.exports = Case;


},{}],2:[function(require,module,exports){
var FacilityHierarchy,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

FacilityHierarchy = (function() {
  function FacilityHierarchy(options) {
    this.allPrivateFacilities = bind(this.allPrivateFacilities, this);
    this.facilityType = bind(this.facilityType, this);
    this.update = bind(this.update, this);
    this.numbers = bind(this.numbers, this);
    this.facilitiesForZone = bind(this.facilitiesForZone, this);
    this.facilitiesForDistrict = bind(this.facilitiesForDistrict, this);
    this.facilities = bind(this.facilities, this);
    this.getZone = bind(this.getZone, this);
    this.getDistrict = bind(this.getDistrict, this);
    this.allFacilities = bind(this.allFacilities, this);
    this.allDistricts = bind(this.allDistricts, this);
    Coconut.database.get("Facility Hierarchy").then((function(_this) {
      return function(result) {
        _this.hierarchy = result.hierarchy;
        return _this.databaseObject = result;
      };
    })(this))["catch"](function(error) {
      return console.error(error);
    });
  }

  FacilityHierarchy.prototype.allDistricts = function() {
    return _.keys(this.hierarchy).sort();
  };

  FacilityHierarchy.prototype.allFacilities = function() {
    return _.chain(this.hierarchy).values().flatten().pluck("facility").value();
  };

  FacilityHierarchy.prototype.getDistrict = function(facility) {
    var result;
    if (facility) {
      facility = facility.trim();
    }
    result = null;
    _.each(this.hierarchy, function(facilityData, district) {
      if (_.chain(facilityData).pluck("facility").contains(facility).value()) {
        return result = district;
      }
    });
    if (result) {
      return result;
    }
    _.each(this.hierarchy, function(facilityData, district) {
      if (_.chain(facilityData).pluck("aliases").flatten().compact().contains(facility).value()) {
        return result = district;
      }
    });
    return result;
  };

  FacilityHierarchy.prototype.getZone = function(facility) {
    var district, districtHierarchy, region;
    district = this.getDistrict(facility);
    districtHierarchy = GeoHierarchy.find(district, "DISTRICT");
    if (districtHierarchy.length === 1) {
      region = GeoHierarchy.find(district, "DISTRICT")[0].REGION;
      if (region.match(/PEMBA/)) {
        return "PEMBA";
      } else {
        return "UNGUJA";
      }
    }
    return null;
  };

  FacilityHierarchy.prototype.facilities = function(district) {
    return _.pluck(this.hierarchy[district], "facility");
  };

  FacilityHierarchy.prototype.facilitiesForDistrict = function(district) {
    return this.facilities(district);
  };

  FacilityHierarchy.prototype.facilitiesForZone = function(zone) {
    var districtsInZone;
    districtsInZone = GeoHierarchy.districtsForZone(zone);
    _.chain(districtsInZone).map((function(_this) {
      return function(district) {
        return _this.facilities(district);
      };
    })(this)).flatten().value();
    return this.facilities(district);
  };

  FacilityHierarchy.prototype.numbers = function(district, facility) {
    var foundFacility;
    foundFacility = _(this.hierarchy[district]).find(function(result) {
      return result.facility === facility;
    });
    return foundFacility["mobile_numbers"];
  };

  FacilityHierarchy.prototype.update = function(district, targetFacility, numbers, options) {
    var facilityIndex;
    console.log(numbers);
    facilityIndex = -1;
    _(this.hierarchy[district]).find(function(facility) {
      facilityIndex++;
      return facility['facility'] === targetFacility;
    });
    if (facilityIndex === -1) {
      this.hierarchy[district].push({
        facility: targetFacility,
        mobile_numbers: numbers
      });
    } else {
      this.hierarchy[district][facilityIndex] = {
        facility: targetFacility,
        mobile_numbers: numbers
      };
    }
    this.databaseObject.hierarchy = this.hierarchy;
    return Coconut.database.put(this.databaseObject)["catch"](error)(function() {
      return console.error(error);
    }).then(response)((function(_this) {
      return function() {
        _this.databaseObject._rev = response.rev;
        return options != null ? options.success() : void 0;
      };
    })(this));
  };

  FacilityHierarchy.prototype.facilityType = function(facilityName) {
    var result;
    result = null;
    _.each(this.hierarchy, function(facilities, district) {
      var facility;
      if (result === null) {
        facility = _.find(facilities, function(facility) {
          return facility.facility === facilityName;
        });
        if (facility) {
          return result = facility.type.toUpperCase();
        }
      }
    });
    return result;
  };

  FacilityHierarchy.prototype.allPrivateFacilities = function() {
    return _.chain(this.hierarchy).values().flatten().filter(function(facility) {
      return facility.type === "private";
    }).pluck("facility").value();
  };

  return FacilityHierarchy;

})();

module.exports = FacilityHierarchy;


},{}],3:[function(require,module,exports){
var GeoHierarchy, _,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_ = require('underscore');

GeoHierarchy = (function() {
  function GeoHierarchy(options) {
    this.update = bind(this.update, this);
    this.all = bind(this.all, this);
    this.allUniqueShehiaNames = bind(this.allUniqueShehiaNames, this);
    this.allShehias = bind(this.allShehias, this);
    this.allDistricts = bind(this.allDistricts, this);
    this.allRegions = bind(this.allRegions, this);
    this.findAllDistrictsFor = bind(this.findAllDistrictsFor, this);
    this.findAllShehiaNamesFor = bind(this.findAllShehiaNamesFor, this);
    this.validShehia = bind(this.validShehia, this);
    this.findOneShehia = bind(this.findOneShehia, this);
    this.findShehia = bind(this.findShehia, this);
    this.findAllDescendantsAtLevel = bind(this.findAllDescendantsAtLevel, this);
    this.findChildrenNames = bind(this.findChildrenNames, this);
    this.findAllForLevel = bind(this.findAllForLevel, this);
    this.find = bind(this.find, this);
    this.findInNodes = bind(this.findInNodes, this);
    this.englishDistrictName = bind(this.englishDistrictName, this);
    this.swahiliDistrictName = bind(this.swahiliDistrictName, this);
    this.levels = ["REGION", "DISTRICT", "SHEHIA"];
    Coconut.database.get("Geo Hierarchy")["catch"](function(error) {
      console.error("Error loading Geo Hierarchy:");
      console.error(error);
      return options.error(error);
    }).then((function(_this) {
      return function(result) {
        var addChildren, addLevelProperties;
        _this.hierarchy = result.hierarchy;
        _this.root = {
          parent: null
        };
        addLevelProperties = function(node) {
          var levelClimber;
          levelClimber = node;
          node[levelClimber.level] = levelClimber.name;
          while (levelClimber.parent !== null) {
            levelClimber = levelClimber.parent;
            node[levelClimber.level] = levelClimber.name;
          }
          return node;
        };
        addChildren = function(node, values, levelNumber) {
          var key, value;
          if (_(values).isArray()) {
            node.children = (function() {
              var i, len, results1;
              results1 = [];
              for (i = 0, len = values.length; i < len; i++) {
                value = values[i];
                result = {
                  parent: node,
                  level: this.levels[levelNumber],
                  name: value,
                  children: null
                };
                results1.push(result = addLevelProperties(result));
              }
              return results1;
            }).call(_this);
            return node;
          } else {
            node.children = (function() {
              var results1;
              results1 = [];
              for (key in values) {
                value = values[key];
                result = {
                  parent: node,
                  level: this.levels[levelNumber],
                  name: key
                };
                result = addLevelProperties(result);
                results1.push(addChildren(result, value, levelNumber + 1));
              }
              return results1;
            }).call(_this);
            return node;
          }
        };
        addChildren(_this.root, _this.hierarchy, 0);
        return Coconut.database.get("district_language_mapping")["catch"](function(error) {
          console.error("Error loading district_language_mapping:");
          console.error(error);
          return options.error(error);
        }).then(function(result) {
          _this.englishToSwahiliDistrictMapping = result.english_to_swahili;
          return options != null ? typeof options.success === "function" ? options.success() : void 0 : void 0;
        });
      };
    })(this));
  }

  GeoHierarchy.prototype.swahiliDistrictName = function(district) {
    return this.englishToSwahiliDistrictMapping[district] || district;
  };

  GeoHierarchy.prototype.englishDistrictName = function(district) {
    return _(this.englishToSwahiliDistrictMapping).invert()[district] || district;
  };

  GeoHierarchy.prototype.findInNodes = function(nodes, requiredProperties) {
    var node, results;
    results = _(nodes).where(requiredProperties);
    if (_(results).isEmpty()) {
      if (nodes != null) {
        results = (function() {
          var i, len, results1;
          results1 = [];
          for (i = 0, len = nodes.length; i < len; i++) {
            node = nodes[i];
            results1.push(this.findInNodes(node.children, requiredProperties));
          }
          return results1;
        }).call(this);
      }
      results = _.chain(results).flatten().compact().value();
      if (_(results).isEmpty()) {
        return [];
      }
    }
    return results;
  };

  GeoHierarchy.prototype.find = function(name, level) {
    return this.findInNodes(this.root.children, {
      name: name ? name.toUpperCase() : void 0,
      level: level ? level.toUpperCase() : void 0
    });
  };

  GeoHierarchy.prototype.findFirst = function(name, level) {
    var result;
    result = this.find(name, level);
    if (result != null) {
      return result[0];
    } else {
      return {};
    }
  };

  GeoHierarchy.prototype.findAllForLevel = function(level) {
    return this.findInNodes(this.root.children, {
      level: level
    });
  };

  GeoHierarchy.prototype.findChildrenNames = function(targetLevel, parentName) {
    var indexOfTargetLevel, nodeResult, parentLevel;
    indexOfTargetLevel = _(this.levels).indexOf(targetLevel);
    parentLevel = this.levels[indexOfTargetLevel - 1];
    nodeResult = this.findInNodes(this.root.children, {
      name: parentName,
      level: parentLevel
    });
    if (_(nodeResult).isEmpty()) {
      return [];
    }
    if (nodeResult.length > 2) {
      console.error("More than one match");
    }
    return _(nodeResult[0].children).pluck("name");
  };

  GeoHierarchy.prototype.findAllDescendantsAtLevel = function(name, sourceLevel, targetLevel) {
    var getLevelDescendants, sourceNode;
    getLevelDescendants = function(node) {
      var childNode;
      if (node.level === targetLevel) {
        return node;
      }
      return (function() {
        var i, len, ref, results1;
        ref = node.children;
        results1 = [];
        for (i = 0, len = ref.length; i < len; i++) {
          childNode = ref[i];
          results1.push(getLevelDescendants(childNode));
        }
        return results1;
      })();
    };
    sourceNode = this.find(name, sourceLevel);
    return _.flatten(getLevelDescendants(sourceNode[0]));
  };

  GeoHierarchy.prototype.findShehia = function(targetShehia) {
    return this.find(targetShehia, "SHEHIA");
  };

  GeoHierarchy.prototype.findOneShehia = function(targetShehia) {
    var shehia;
    shehia = this.findShehia(targetShehia);
    switch (shehia.length) {
      case 0:
        return null;
      case 1:
        return shehia[0];
      default:
        return void 0;
    }
  };

  GeoHierarchy.prototype.validShehia = function(shehia) {
    var ref;
    return ((ref = this.findShehia(shehia)) != null ? ref.length : void 0) > 0;
  };

  GeoHierarchy.prototype.findAllShehiaNamesFor = function(name, level) {
    return _.pluck(this.findAllDescendantsAtLevel(name, level, "SHEHIA"), "name");
  };

  GeoHierarchy.prototype.findAllDistrictsFor = function(name, level) {
    return _.pluck(this.findAllDescendantsAtLevel(name, level, "DISTRICT"), "name");
  };

  GeoHierarchy.prototype.allRegions = function() {
    return _.pluck(this.findAllForLevel("REGION"), "name");
  };

  GeoHierarchy.prototype.allDistricts = function() {
    return _.pluck(this.findAllForLevel("DISTRICT"), "name");
  };

  GeoHierarchy.prototype.allShehias = function() {
    return _.pluck(this.findAllForLevel("SHEHIA"), "name");
  };

  GeoHierarchy.prototype.allUniqueShehiaNames = function() {
    return _(_.pluck(this.findAllForLevel("SHEHIA"), "name")).uniq();
  };

  GeoHierarchy.prototype.all = function(geographicHierarchy) {
    return _.pluck(this.findAllForLevel(geographicHierarchy.toUpperCase()), "name");
  };

  GeoHierarchy.prototype.update = function(region, district, shehias) {
    var geoHierarchy;
    this.hierarchy[region][district] = shehias;
    geoHierarchy = new GeoHierarchy();
    return geoHierarchy.fetch({
      error: function(error) {
        return console.error(JSON.stringify(error));
      },
      success: (function(_this) {
        return function(result) {
          return geoHierarchy.save("hierarchy", _this.hierarchy, {
            error: function(error) {
              return console.error(JSON.stringify(error));
            },
            success: function() {
              Coconut.debug("GeoHierarchy saved");
              return this.load;
            }
          });
        };
      })(this)
    });
  };

  GeoHierarchy.getZoneForDistrict = function(district) {
    var districtHierarchy, region;
    districtHierarchy = this.find(district, "DISTRICT");
    if (districtHierarchy.length === 1) {
      region = this.find(district, "DISTRICT")[0].REGION;
      return this.getZoneForRegion(region);
    }
    return null;
  };

  GeoHierarchy.getZoneForRegion = function(region) {
    if (region.match(/PEMBA/)) {
      return "PEMBA";
    } else {
      return "UNGUJA";
    }
  };

  GeoHierarchy.districtsForZone = function(zone) {
    return _.chain(GeoHierarchy.allRegions()).map(function(region) {
      if (GeoHierarchy.getZoneForRegion(region) === zone) {
        return GeoHierarchy.findAllDistrictsFor(region, "REGION");
      }
    }).flatten().compact().value();
  };

  return GeoHierarchy;

})();

module.exports = GeoHierarchy;


},{"underscore":8}],4:[function(require,module,exports){
var HouseholdLocationSelectorView,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

HouseholdLocationSelectorView = (function(superClass) {
  extend(HouseholdLocationSelectorView, superClass);

  function HouseholdLocationSelectorView(targetLocationField) {
    this.targetLocationField = targetLocationField;
    this.updateTargetLocationField = bind(this.updateTargetLocationField, this);
    this.addLocation = bind(this.addLocation, this);
    this.remove = bind(this.remove, this);
    this.prefix = Math.floor(Math.random() * 1000);
    this.setElement($("<div style='padding-left:40px' class='travelLocations'> </div>"));
    this.targetLocationField.after(this.el);
    _(this.targetLocationField.val().split(/,/)).each((function(_this) {
      return function(location) {
        var entryPoint, locationName, locationSelector, ref;
        if (location.replace(/ *:* */, "") === "") {
          return;
        }
        ref = location.split(/: /), locationName = ref[0], entryPoint = ref[1];
        locationSelector = _this.addLocation();
        locationSelector.find("[name=travelLocationName]").val(locationName);
        return locationSelector.find("[value='" + entryPoint + "']").prop('checked', true);
      };
    })(this));
    if (this.$('.addLocation').length === 0) {
      this.$el.append(this.addLocationButton());
    }
  }

  HouseholdLocationSelectorView.prototype.events = {
    "change input[name=travelLocationName]": "updateTargetLocationField",
    "change input.radio": "updateTargetLocationField",
    "click button.addLocation": "addLocation",
    "click button.removeLocation": "remove"
  };

  HouseholdLocationSelectorView.prototype.addLocationButton = function() {
    return "<button type='button' style='position:static' class='addLocation mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'> Add location </button>";
  };

  HouseholdLocationSelectorView.prototype.removeLocationButton = function() {
    return "<button type='button' style='margin-top:10px;margin-bottom:10px;display:block;position:static' class='removeLocation mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>Remove location</button>";
  };

  HouseholdLocationSelectorView.prototype.remove = function(event) {
    $(event.target).closest(".travelLocation").remove();
    if (this.$('.addLocation').length === 0) {
      if (this.$('.addLocation').length === 0) {
        this.$el.append(this.addLocationButton());
      }
    }
    return this.updateTargetLocationField();
  };

  HouseholdLocationSelectorView.prototype.addLocation = function(event) {
    var travelLocationSelector, travelLocations;
    if (event) {
      $(event.target).closest("button.addLocation").remove();
    }
    this.prefix += 1;
    travelLocations = this.targetLocationField.siblings(".travelLocations");
    travelLocationSelector = $("<div class='travelLocation' id='" + this.prefix + "'> <label class='mdl-textfield__label' type='text' for='travelLocationName'>Location Name</label> <input class='mdl-textfield__input' name='travelLocationName' type='text'/> <label class='mdl-textfield__label' type='text' for='entry'>Entry Point</label> " + (_(["Ferry", "Informal Ferry", "Airport"]).map((function(_this) {
      return function(entryMethod, index) {
        return "<input class='radio entrymethod' type='radio' name='" + _this.prefix + "-entry' id='" + _this.prefix + "-" + index + "' value='" + entryMethod + "'/> <label class='mdl-nontextfield__label radio radio-option' for='" + _this.prefix + "-" + index + "'>" + entryMethod + "</label>";
      };
    })(this)).join("")) + " " + (this.removeLocationButton()) + " </div>");
    travelLocations.append(travelLocationSelector);
    return travelLocationSelector;
  };

  HouseholdLocationSelectorView.prototype.updateTargetLocationField = function() {
    var val;
    this.targetLocationField.val(val = _.chain(this.$el.find(".travelLocation")).map((function(_this) {
      return function(location) {
        var entryMethod, locationName;
        locationName = $(location).find("input[name='travelLocationName']").val();
        entryMethod = $(location).find("input.entrymethod:checked").val() || "";
        if (locationName) {
          if (_this.$el.find("button.addLocation").length === 0) {
            _this.$el.append(_this.addLocationButton());
          }
          return locationName + ": " + entryMethod;
        } else {
          return null;
        }
      };
    })(this)).compact().join(", ").value()).change();
    return this.targetLocationField.closest("div.mdl-textfield").addClass("is-dirty");
  };

  return HouseholdLocationSelectorView;

})(Backbone.View);

module.exports = HouseholdLocationSelectorView;


},{}],5:[function(require,module,exports){
(function (global){
var Sync, onStartup;

global.GeoHierarchy = new (require('./GeoHierarchy'))();

global.FacilityHierarchy = new (require('./FacilityHierarchy'))();

global.Case = require('./Case');

global.HouseholdLocationSelectorView = require('./HouseholdLocationSelectorView');

global.SummaryView = require('./SummaryView');

Sync = require('./Sync');

onStartup = function() {
  var originalResultsViewRender;
  Coconut.syncView.sync = new Sync();
  Coconut.cloudDatabase = new PouchDB(Coconut.config.cloud_url_with_credentials());
  Coconut.router.route(":database/summary", function() {
    if (Coconut.summaryView == null) {
      Coconut.summaryView = new SummaryView();
    }
    return Coconut.database.query("casesWithSummaryData", {
      descending: true,
      include_docs: false,
      limit: 100
    }, (function(_this) {
      return function(error, result) {
        if (error) {
          return console.error(JSON.stringify(error));
        } else {
          return Coconut.summaryView.render(result);
        }
      };
    })(this));
  });
  Coconut.router.route(":database/transfer/:caseID", function(caseID) {
    var caseResults;
    if (Coconut.currentUser) {
      $("#content").html("<h2> Select a user to transfer " + caseID + " to: </h2> <select id='users'> <option></option> </select> <br/> <button onClick='window.history.back()'>Cancel</button> <h3>Case Results to be transferred</h3> <div id='caseinfo'></div>");
      caseResults = [];
      Coconut.database.query("cases", {
        key: caseID,
        include_docs: true
      }, (function(_this) {
        return function(error, result) {
          if (error) {
            console.error(error);
          }
          caseResults = _.pluck(result.rows, "doc");
          Coconut.database.query("usersByDistrict", {}, function(error, result) {
            return $("#content select").append(_(result.rows).map(function(user) {
              if (user.key == null) {
                return "";
              }
              return "<option id='" + user.id + "'>" + user.key + "   " + (user.value.join("   ")) + "</option>";
            }).join(""));
          });
          return $("#caseinfo").html(_(caseResults).map(function(caseResult) {
            return "<pre> " + (JSON.stringify(caseResult, null, 2)) + " </pre>";
          }).join("<br/>"));
        };
      })(this));
      return $("select").change(function() {
        var user;
        user = $('select').find(":selected").text();
        if (confirm("Are you sure you want to transfer Case:" + caseID + " to " + user + "?")) {
          _(caseResults).each(function(caseResult) {
            Coconut.debug("Marking " + caseResult._id + " as transferred");
            if (caseResult.transferred == null) {
              caseResult.transferred = [];
            }
            return caseResult.transferred.push({
              from: Coconut.currentUser.get("_id"),
              to: $('select').find(":selected").attr("id"),
              time: moment().format("YYYY-MM-DD HH:mm"),
              notifiedViaSms: [],
              received: false
            });
          });
          return Coconut.cloudDatabase.bulkDocs({
            docs: caseResults
          })["catch"](function(error) {
            console.error("Could not save " + (JSON.stringify(caseResults)) + ":");
            return console.error(error);
          }).then(function() {
            return Coconut.router.navigate("", true);
          });
        }
      });
    }
  });
  Coconut.menuView.renderHeader = function() {
    var followup_url, incompleteResults, new_case_url, update_case_url;
    new_case_url = "#zanzibar/show/results/Case Notification";
    update_case_url = "#" + Coconut.databaseName + "/find/case";
    followup_url = "#" + Coconut.databaseName + "/followups";
    $(".mdl-layout__header-row").html((Coconut.questions.map(function(question) {
      var questionId, url;
      questionId = question.get("_id");
      url = "#zanzibar/show/results/" + questionId;
      return "<a style='padding-right:20px' class='drawer_question_set_link' href='" + url + "'>" + questionId + " <span id='incomplete_" + (question.safeLabel()) + "'></span></a> <!-- <a class='drawer_question_set_link' href='" + url + "'><i class='mdl-color-text--accent material-icons'>add</i></a> -->";
    }).join("")) + " <a style='padding-right:20px' class='drawer_question_set_link' href='#zanzibar/summary'>Summary</a> <a style='position:absolute; top:0px; right:0px;' class='mdl-navigation__link' href='#" + Coconut.databaseName + "/sync'><i class='mdl-color-text--accent material-icons'>sync</i>Sync</a>");
    incompleteResults = {};
    Coconut.questions.each(function(question) {
      return incompleteResults[question.get("_id")] = 0;
    });
    return Coconut.database.query("results/results", {
      include_docs: false
    }).then(function(result) {
      _(result.rows).each(function(row) {
        if (row.key[1] === false) {
          return incompleteResults[row.key[0]] += 1;
        }
      });
      return _(incompleteResults).each(function(amount, question) {
        return $("#incomplete_" + (question.replace(/ /g, ''))).html(amount);
      });
    })["catch"](function(error) {
      return console.error(error);
    });
  };
  Coconut.menuView.renderHeader();
  originalResultsViewRender = ResultsView.prototype.render;
  return ResultsView.prototype.render = function() {
    originalResultsViewRender.apply(this, arguments);
    return _.delay(function() {
      return $("[href=#not-complete-panel]")[0].click();
    }, 500);
  };
};

if (typeof StartPlugins === "undefined" || StartPlugins === null) {
  global.StartPlugins = [];
}

StartPlugins.push(onStartup);

module.exports = Plugin;


}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"./Case":1,"./FacilityHierarchy":2,"./GeoHierarchy":3,"./HouseholdLocationSelectorView":4,"./SummaryView":6,"./Sync":7}],6:[function(require,module,exports){
var SummaryView,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

SummaryView = (function(superClass) {
  extend(SummaryView, superClass);

  function SummaryView() {
    this.render = bind(this.render, this);
    return SummaryView.__super__.constructor.apply(this, arguments);
  }

  SummaryView.prototype.el = '#content';

  SummaryView.prototype.render = function(result) {
    this.$el.html("<style> table#summary td{ border: solid black 1px; } table#summary tr.even{ background-color: #CFC; } table#summary tr.odd{ background-color: #FFFFB2; } table.results th.header, table.results td{ font-size:150%; } .dataTables_wrapper .dataTables_length{ display: none; } .dataTables_filter input{ display:inline; width:300px; } a[role=button]{ background-color: white; margin-right:5px; -moz-border-radius: 1em; -webkit-border-radius: 1em; border: solid gray 1px; font-family: Helvetica,Arial,sans-serif; font-weight: bold; color: #222; text-shadow: 0 1px 0 #fff; -webkit-background-clip: padding-box; -moz-background-clip: padding; background-clip: padding-box; padding: .6em 20px; text-overflow: ellipsis; overflow: hidden; white-space: nowrap; position: relative; zoom: 1; } a[role=button].paginate_disabled_previous, a[role=button].paginate_disabled_next{ color:gray; } a.ui-btn{ display: inline-block; width: 300px; } .dataTables_info{ float:right; } .dataTables_paginate{ margin-bottom:20px; } </style> Cases on this tablet: <table id='summary'> <thead> <td>Date</td> <td>ID</td> <td>Type</td> <td>Complete</td> <td>Transfer</td> <td>Options</td> </thead> <tbody> " + (_.map(result.rows, function(row) {
      console.log(row);
      return result = "<tr> <td>" + row.key + "</td> <td><a class='button' href='#edit/result/" + row.id + "'>" + row.value[0] + "</a></td> <td>" + row.value[1] + "</td> <td>" + (row.value[2] || "false") + "</td> <td><small> <pre> " + (row.value[3] != null ? JSON.stringify(row.value[3], null, 2).replace(/({\n|\n}|\")/g, "") : "") + " </pre></small></td> <td> <a class='button' style='text-decoration:none' href='#zanzibar/transfer/" + row.value[0] + "'>Transfer</a></td> </tr>";
    }).join("")) + " </tbody>");
    return $("table").dataTable({
      aaSorting: [[0, "desc"]],
      iDisplayLength: 25
    });
  };

  return SummaryView;

})(Backbone.View);

module.exports = SummaryView;


},{}],7:[function(require,module,exports){
var Sync,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Sync = (function(superClass) {
  extend(Sync, superClass);

  function Sync() {
    this.transferCasesIn = bind(this.transferCasesIn, this);
    this.convertNotificationToCaseNotification = bind(this.convertNotificationToCaseNotification, this);
    this.replicateApplicationDocs = bind(this.replicateApplicationDocs, this);
    this.getFromCloud = bind(this.getFromCloud, this);
    this.log = bind(this.log, this);
    this.sendToCloud = bind(this.sendToCloud, this);
    this.checkForInternet = bind(this.checkForInternet, this);
    this.backgroundSync = bind(this.backgroundSync, this);
    this.last_get_time = bind(this.last_get_time, this);
    this.was_last_get_successful = bind(this.was_last_get_successful, this);
    this.last_send_time = bind(this.last_send_time, this);
    this.was_last_send_successful = bind(this.was_last_send_successful, this);
    this.last_send = bind(this.last_send, this);
    return Sync.__super__.constructor.apply(this, arguments);
  }

  Sync.prototype.initialize = function() {
    return this.set({
      _id: "SyncLog"
    });
  };

  Sync.prototype.target = function() {
    return Coconut.config.cloud_url();
  };

  Sync.prototype.last_send = function() {
    return this.get("last_send_result");
  };

  Sync.prototype.was_last_send_successful = function() {
    return !this.get("last_send_error") || false;
  };

  Sync.prototype.last_send_time = function() {
    var result;
    result = this.get("last_send_time");
    if (result) {
      return moment(this.get("last_send_time")).fromNow();
    } else {
      return "never";
    }
  };

  Sync.prototype.was_last_get_successful = function() {
    return this.get("last_get_success");
  };

  Sync.prototype.last_get_time = function() {
    var result;
    result = this.get("last_get_time");
    if (result) {
      return moment(this.get("last_get_time")).fromNow();
    } else {
      return "never";
    }
  };

  Sync.prototype.backgroundSync = function() {
    var minimumMinutesBetweenSync;
    if (this.lastSuccessfulSync == null) {
      this.lastSuccessfulSync = moment("2000-01-01");
    }
    console.log("backgroundSync called at " + (moment().toString()) + " lastSuccessfulSync was " + (this.lastSuccessfulSync.toString()) + "}");
    minimumMinutesBetweenSync = 15;
    _.delay(this.backgroundSync, minimumMinutesBetweenSync * 60 * 1000);
    return Coconut.questions.each((function(_this) {
      return function(question) {
        return Coconut.database.query("results", {
          startkey: [question.id, true, _this.lastSuccessfulSync.format(Coconut.config.get("date_format"))],
          endkey: [question.id, true, {}]
        }).then(function(result) {
          if (result.rows.length > 0 && moment().diff(_this.lastSuccessfulSync, 'minutes') > minimumMinutesBetweenSync) {
            console.log("Initiating background sync");
            $("div#log").hide();
            return _this.sendToCloud({
              completeResultsOnly: true,
              error: function(error) {
                console.log("Error: " + (JSON.stringify(error)));
                $("div#log").html("");
                return $("div#log").show();
              },
              success: function() {
                _this.lastSuccessfulSync = moment();
                $("div#log").html("");
                return $("div#log").show();
              }
            });
          } else {
            return console.log("No new results for " + question.id + " so not syncing");
          }
        });
      };
    })(this));
  };

  Sync.prototype.checkForInternet = function(options) {
    this.log("Checking for internet. (Is " + (Coconut.config.cloud_url()) + " is reachable?) Please wait.");
    return Coconut.cloudDatabase.info()["catch"]((function(_this) {
      return function(error) {
        _this.log("ERROR! " + (Coconut.config.cloud_url()) + " is not reachable. Do you have enough airtime? Are you on WIFI?  Either the internet is not working or the site is down: " + (JSON.stringify(error)));
        options.error();
        return _this.save({
          last_send_error: true
        });
      };
    })(this)).then((function(_this) {
      return function(result) {
        _this.log((Coconut.config.cloud_url()) + " is reachable, so internet is available.");
        return options.success();
      };
    })(this));
  };

  Sync.prototype.sendToCloud = function(options) {
    $("#status").html("Sending data...");
    return this.fetch({
      error: (function(_this) {
        return function(error) {
          return _this.log("Unable to fetch Sync doc: " + (JSON.stringify(error)));
        };
      })(this),
      success: (function(_this) {
        return function() {
          return _this.checkForInternet({
            error: function(error) {
              console.error("No internet");
              return options != null ? typeof options.error === "function" ? options.error(error) : void 0 : void 0;
            },
            success: function() {
              _this.log("Creating list of all results on the tablet. Please wait.");
              return Coconut.database.query("results")["catch"](function(error) {
                console.error(error);
                _this.log("Could not retrieve list of results: " + (JSON.stringify(error)));
                options.error();
                return _this.save({
                  last_send_error: true
                });
              }).then(function(result) {
                var resultIDs;
                resultIDs = (options.completeResultsOnly != null) && options.completeResultsOnly === true ? _.chain(result.rows).filter(function(row) {
                  return row.key[1] === true;
                }).pluck("id").value() : _.pluck(result.rows, "id");
                _this.log("Synchronizing " + resultIDs.length + " results. Please wait.");
                return Coconut.database.replicate.to(Coconut.config.cloud_url_with_credentials(), {
                  doc_ids: resultIDs
                }).on('complete', function(info) {
                  _this.log("Success! Send data finished: created, updated or deleted " + info.docs_written + " results on the server.");
                  _this.save({
                    last_send_result: result,
                    last_send_error: false,
                    last_send_time: new Date().getTime()
                  });
                  return options.success();
                }).on('error', function(error) {
                  console.error(error);
                  return options.error(error);
                });
              });
            }
          });
        };
      })(this)
    });
  };

  Sync.prototype.log = function(message) {
    return console.log(message);
  };

  Sync.prototype.getFromCloud = function(options) {
    console.debug(options);
    $("#status").html("Getting data...");
    return this.fetch({
      error: (function(_this) {
        return function(error) {
          return _this.log("Unable to fetch Sync doc: " + (JSON.stringify(error)));
        };
      })(this),
      success: (function(_this) {
        return function() {
          return _this.checkForInternet({
            error: function() {
              return typeof options.error === "function" ? options.error(error) : void 0;
            },
            success: function() {
              return _this.fetch({
                success: function() {
                  return _this.getNewNotifications({
                    success: function() {
                      _this.log("Updating users and forms. Please wait.");
                      return _this.replicateApplicationDocs({
                        error: function(error) {
                          $.couch.logout();
                          _this.log("ERROR updating application: " + (JSON.stringify(error)));
                          _this.save({
                            last_get_success: false
                          });
                          return options != null ? typeof options.error === "function" ? options.error(error) : void 0 : void 0;
                        },
                        success: function() {
                          return _this.transferCasesIn({
                            success: function() {
                              return _this.fetch({
                                error: function(error) {
                                  return _this.log("Unable to fetch Sync doc: " + (JSON.stringify(error)));
                                },
                                success: function() {
                                  _this.save({
                                    last_get_success: true,
                                    last_get_time: new Date().getTime()
                                  });
                                  console.debug(options);
                                  if (options != null) {
                                    if (typeof options.success === "function") {
                                      options.success();
                                    }
                                  }
                                  return _.delay(function() {
                                    return document.location.reload();
                                  }, 5000);
                                }
                              });
                            }
                          });
                        }
                      });
                    }
                  });
                }
              });
            }
          });
        };
      })(this)
    });
  };

  Sync.prototype.replicateApplicationDocs = function(options) {
    return this.checkForInternet({
      error: function(error) {
        return options != null ? typeof options.error === "function" ? options.error(error) : void 0 : void 0;
      },
      success: (function(_this) {
        return function() {
          _this.log("Getting list of application documents to replicate");
          return Coconut.cloudDatabase.query("docIDsForUpdating")["catch"](function(error) {
            return typeof options.error === "function" ? options.error(error) : void 0;
          }).then(function(result) {
            var doc_ids;
            doc_ids = _(result.rows).chain().pluck("id").without("_design/coconut").uniq().value();
            _this.log("Updating " + doc_ids.length + " docs <small>(users and forms: " + (doc_ids.join(', ')) + ")</small>. Please wait.");
            return Coconut.database.replicate.from(Coconut.config.cloud_url_with_credentials(), {
              doc_ids: doc_ids
            }).on('change', function(info) {
              return console.log(info);
            }).on('complete', function(info) {
              console.log("COMPLETE");
              console.log(info);
              return Coconut.syncPlugins({
                success: function() {
                  return options != null ? typeof options.success === "function" ? options.success() : void 0 : void 0;
                },
                error: function() {
                  return options != null ? typeof options.error === "function" ? options.error() : void 0 : void 0;
                }
              });
            }).on('error', function(error) {
              console.error(error);
              _this.log("Error while updating application documents: " + (JSON.stringify(error)));
              return typeof options.error === "function" ? options.error(error) : void 0;
            });
          });
        };
      })(this)
    });
  };

  Sync.prototype.getNewNotifications = function(options) {
    this.log("Looking for most recent Case Notification on tablet. Please wait.");
    return Coconut.database.query("rawNotificationsConvertedToCaseNotifications", {
      descending: true,
      include_docs: true,
      limit: 1
    })["catch"]((function(_this) {
      return function(error) {
        return _this.log("Unable to find the the most recent case notification: " + (JSON.stringify(error)));
      };
    })(this)).then((function(_this) {
      return function(result) {
        var dateToStartLooking, mostRecentNotification, ref, ref1;
        mostRecentNotification = (ref = result.rows) != null ? (ref1 = ref[0]) != null ? ref1.doc.date : void 0 : void 0;
        if ((mostRecentNotification != null) && moment(mostRecentNotification).isBefore((new moment).subtract(3, 'weeks'))) {
          dateToStartLooking = mostRecentNotification;
        } else {
          dateToStartLooking = (new moment).subtract(3, 'weeks').format(Coconut.config.get("date_format"));
        }
        return Coconut.database.get("district_language_mapping")["catch"](function(error) {
          return alert("Couldn't find english_to_swahili map: " + (JSON.stringify(result)));
        }).then(function(result) {
          var district_language_mapping;
          district_language_mapping = result.english_to_swahili;
          _this.log("Looking for USSD notifications without Case Notifications after " + dateToStartLooking + ". Please wait.");
          return Coconut.cloudDatabase.query("rawNotificationsNotConvertedToCaseNotifications", {
            include_docs: true,
            startkey: dateToStartLooking,
            skip: 1
          })["catch"](function(error) {
            return _this.log("ERROR, could not download USSD notifications: " + (JSON.stringify(error)));
          }).then(function(result) {
            var currentUserDistrict;
            currentUserDistrict = Coconut.currentUser.get("district");
            if (district_language_mapping[currentUserDistrict] != null) {
              currentUserDistrict = district_language_mapping[currentUserDistrict];
            }
            _this.log("Found " + result.rows.length + " USSD notifications. Filtering for USSD notifications for district:  " + currentUserDistrict + ". Please wait.");
            _.each(result.rows, function(row) {
              var districtForNotification, notification;
              notification = row.doc;
              districtForNotification = notification.facility_district;
              if (district_language_mapping[districtForNotification] != null) {
                districtForNotification = district_language_mapping[districtForNotification];
              }
              if (!_(GeoHierarchy.allDistricts()).contains(districtForNotification)) {
                _this.log(districtForNotification + " not valid district, trying to use health facility: " + notification.hf + " to identify district");
                if (FacilityHierarchy.getDistrict(notification.hf) != null) {
                  districtForNotification = FacilityHierarchy.getDistrict(notification.hf);
                  _this.log("Using district: " + districtForNotification + " indicated by health facility.");
                } else {
                  _this.log("Can't find a valid district for health facility: " + notification.hf);
                }
                if (!_(GeoHierarchy.allDistricts()).contains(districtForNotification)) {
                  _this.log(districtForNotification + " still not valid district, trying to use shehia name to identify district: " + notification.shehia);
                  if (GeoHierarchy.findOneShehia(notification.shehia) != null) {
                    districtForNotification = GeoHierarchy.findOneShehia(notification.shehia).DISTRCT;
                    _this.log("Using district: " + districtForNotification + " indicated by shehia.");
                  } else {
                    _this.log("Can't find a valid district using shehia for notification: " + (JSON.stringify(notification)) + ".");
                  }
                }
              }
              if (districtForNotification === currentUserDistrict) {
                if (confirm("Accept new case? Facility: " + notification.hf + ", Shehia: " + notification.shehia + ", Name: " + notification.name + ", ID: " + notification.caseid + ", date: " + notification.date + ". You may need to coordinate with another DMSO.")) {
                  _this.convertNotificationToCaseNotification(notification);
                  return _this.log("Case notification " + notification.caseid + ", accepted by " + (User.currentUser.username()));
                } else {
                  return _this.log("Case notification " + notification.caseid + ", not accepted by " + (User.currentUser.username()));
                }
              }
            });
            return typeof options.success === "function" ? options.success() : void 0;
          });
        });
      };
    })(this));
  };

  Sync.prototype.convertNotificationToCaseNotification = function(notification) {
    var result;
    result = new Result({
      question: "Case Notification",
      MalariaCaseID: notification.caseid,
      FacilityName: notification.hf,
      Shehia: notification.shehia,
      Name: notification.name
    });
    return result.save(null, {
      error: (function(_this) {
        return function(error) {
          return _this.log("Could not save " + (result.toJSON()) + ":  " + (JSON.stringify(error)));
        };
      })(this),
      success: (function(_this) {
        return function(error) {
          notification.hasCaseNotification = true;
          return $.couch.db(Coconut.config.database_name()).saveDoc(notification, {
            error: function(error) {
              return _this.log("Could not save notification " + (JSON.stringify(notification)) + " : " + (JSON.stringify(error)));
            },
            success: function() {
              var doc_ids;
              _this.log("Created new case notification " + (result.get("MalariaCaseID")) + " for patient " + (result.get("Name")) + " at " + (result.get("FacilityName")));
              doc_ids = [result.get("_id"), notification._id];
              return $.couch.replicate(Coconut.config.database_name(), Coconut.config.cloud_url_with_credentials(), {
                error: function(error) {
                  return _this.log("Error replicating " + doc_ids + " back to server: " + (JSON.stringify(error)));
                },
                success: function(result) {
                  _this.log("Sent docs: " + doc_ids);
                  return _this.save({
                    last_send_result: result,
                    last_send_error: false,
                    last_send_time: new Date().getTime()
                  });
                }
              }, {
                doc_ids: doc_ids
              });
            }
          });
        };
      })(this)
    });
  };

  Sync.prototype.transferCasesIn = function(options) {
    $("#status").html("Checking for transfer cases...");
    this.log("Checking cloud server for cases transferred to " + (Coconut.currentUser.username()));
    return Coconut.cloudDatabase.query("resultsAndNotificationsNotReceivedByTargetUser", {
      include_docs: true,
      key: Coconut.currentUser.get("_id")
    })["catch"]((function(_this) {
      return function(error) {
        _this.log("Could not retrieve list of resultsAndNotificationsNotReceivedByTargetUser for " + (Coconut.currentUser.get("_id")));
        _this.log(error);
        console.error(error);
        if (options != null) {
          options.error(error);
        }
        return _this.save({
          last_send_error: true
        });
      };
    })(this)).then((function(_this) {
      return function(result) {
        var caseSuccessHandler, cases;
        cases = {};
        _(result.rows).each(function(row) {
          var caseId;
          caseId = row.value[1];
          if (!cases[caseId]) {
            cases[caseId] = [];
          }
          return cases[caseId].push(row.doc);
        });
        caseSuccessHandler = _.after(_(cases).size(), options != null ? options.success : void 0);
        if (_(cases).isEmpty()) {
          _this.log("No cases to transfer.");
          caseSuccessHandler();
        }
        return _(cases).each(function(resultDocs) {
          var caseId, malariaCase, resultsSuccessHandler;
          malariaCase = new Case();
          malariaCase.loadFromResultDocs(resultDocs);
          caseId = malariaCase.MalariaCaseID();
          if (!confirm("Accept transfer case " + caseId + " " + (malariaCase.indexCasePatientName()) + " from facility " + (malariaCase.facility()) + " in " + (malariaCase.district()) + "?")) {
            return caseSuccessHandler();
          } else {
            resultsSuccessHandler = _.after(resultDocs.length, caseSuccessHandler());
            return _(resultDocs).each(function(resultDoc) {
              resultDoc.transferred[resultDoc.transferred.length - 1].received = true;
              return $.couch.db(Coconut.config.database_name()).saveDoc(resultDoc, {
                error: function(error) {
                  return _this.log("ERROR: " + caseId + ": " + (resultDoc.question || "Notification") + " could not be saved on tablet: " + (JSON.stringify(error)));
                },
                success: function(success) {
                  _this.log(caseId + ": " + (resultDoc.question || "Notification") + " saved on tablet");
                  return $.couch.replicate(Coconut.config.database_name(), Coconut.config.cloud_url_with_credentials(), {
                    success: function() {
                      _this.log(caseId + ": " + (resultDoc.question || "Notification") + " marked as received in cloud");
                      return resultsSuccessHandler();
                    },
                    error: function(error) {
                      return _this.log("ERROR: " + caseId + ": " + (resultDoc.question || "Notification") + " could not be marked as received in cloud. In case of conflict report to ZaMEP, otherwise press Get Data again. " + (JSON.stringify(error)));
                    }
                  }, {
                    doc_ids: [resultDoc._id]
                  });
                }
              });
            });
          }
        });
      };
    })(this));
  };

  return Sync;

})(Backbone.Model);

module.exports = Sync;


},{}],8:[function(require,module,exports){
//     Underscore.js 1.8.3
//     http://underscorejs.org
//     (c) 2009-2015 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
//     Underscore may be freely distributed under the MIT license.

(function() {

  // Baseline setup
  // --------------

  // Establish the root object, `window` in the browser, or `exports` on the server.
  var root = this;

  // Save the previous value of the `_` variable.
  var previousUnderscore = root._;

  // Save bytes in the minified (but not gzipped) version:
  var ArrayProto = Array.prototype, ObjProto = Object.prototype, FuncProto = Function.prototype;

  // Create quick reference variables for speed access to core prototypes.
  var
    push             = ArrayProto.push,
    slice            = ArrayProto.slice,
    toString         = ObjProto.toString,
    hasOwnProperty   = ObjProto.hasOwnProperty;

  // All **ECMAScript 5** native function implementations that we hope to use
  // are declared here.
  var
    nativeIsArray      = Array.isArray,
    nativeKeys         = Object.keys,
    nativeBind         = FuncProto.bind,
    nativeCreate       = Object.create;

  // Naked function reference for surrogate-prototype-swapping.
  var Ctor = function(){};

  // Create a safe reference to the Underscore object for use below.
  var _ = function(obj) {
    if (obj instanceof _) return obj;
    if (!(this instanceof _)) return new _(obj);
    this._wrapped = obj;
  };

  // Export the Underscore object for **Node.js**, with
  // backwards-compatibility for the old `require()` API. If we're in
  // the browser, add `_` as a global object.
  if (typeof exports !== 'undefined') {
    if (typeof module !== 'undefined' && module.exports) {
      exports = module.exports = _;
    }
    exports._ = _;
  } else {
    root._ = _;
  }

  // Current version.
  _.VERSION = '1.8.3';

  // Internal function that returns an efficient (for current engines) version
  // of the passed-in callback, to be repeatedly applied in other Underscore
  // functions.
  var optimizeCb = function(func, context, argCount) {
    if (context === void 0) return func;
    switch (argCount == null ? 3 : argCount) {
      case 1: return function(value) {
        return func.call(context, value);
      };
      case 2: return function(value, other) {
        return func.call(context, value, other);
      };
      case 3: return function(value, index, collection) {
        return func.call(context, value, index, collection);
      };
      case 4: return function(accumulator, value, index, collection) {
        return func.call(context, accumulator, value, index, collection);
      };
    }
    return function() {
      return func.apply(context, arguments);
    };
  };

  // A mostly-internal function to generate callbacks that can be applied
  // to each element in a collection, returning the desired result — either
  // identity, an arbitrary callback, a property matcher, or a property accessor.
  var cb = function(value, context, argCount) {
    if (value == null) return _.identity;
    if (_.isFunction(value)) return optimizeCb(value, context, argCount);
    if (_.isObject(value)) return _.matcher(value);
    return _.property(value);
  };
  _.iteratee = function(value, context) {
    return cb(value, context, Infinity);
  };

  // An internal function for creating assigner functions.
  var createAssigner = function(keysFunc, undefinedOnly) {
    return function(obj) {
      var length = arguments.length;
      if (length < 2 || obj == null) return obj;
      for (var index = 1; index < length; index++) {
        var source = arguments[index],
            keys = keysFunc(source),
            l = keys.length;
        for (var i = 0; i < l; i++) {
          var key = keys[i];
          if (!undefinedOnly || obj[key] === void 0) obj[key] = source[key];
        }
      }
      return obj;
    };
  };

  // An internal function for creating a new object that inherits from another.
  var baseCreate = function(prototype) {
    if (!_.isObject(prototype)) return {};
    if (nativeCreate) return nativeCreate(prototype);
    Ctor.prototype = prototype;
    var result = new Ctor;
    Ctor.prototype = null;
    return result;
  };

  var property = function(key) {
    return function(obj) {
      return obj == null ? void 0 : obj[key];
    };
  };

  // Helper for collection methods to determine whether a collection
  // should be iterated as an array or as an object
  // Related: http://people.mozilla.org/~jorendorff/es6-draft.html#sec-tolength
  // Avoids a very nasty iOS 8 JIT bug on ARM-64. #2094
  var MAX_ARRAY_INDEX = Math.pow(2, 53) - 1;
  var getLength = property('length');
  var isArrayLike = function(collection) {
    var length = getLength(collection);
    return typeof length == 'number' && length >= 0 && length <= MAX_ARRAY_INDEX;
  };

  // Collection Functions
  // --------------------

  // The cornerstone, an `each` implementation, aka `forEach`.
  // Handles raw objects in addition to array-likes. Treats all
  // sparse array-likes as if they were dense.
  _.each = _.forEach = function(obj, iteratee, context) {
    iteratee = optimizeCb(iteratee, context);
    var i, length;
    if (isArrayLike(obj)) {
      for (i = 0, length = obj.length; i < length; i++) {
        iteratee(obj[i], i, obj);
      }
    } else {
      var keys = _.keys(obj);
      for (i = 0, length = keys.length; i < length; i++) {
        iteratee(obj[keys[i]], keys[i], obj);
      }
    }
    return obj;
  };

  // Return the results of applying the iteratee to each element.
  _.map = _.collect = function(obj, iteratee, context) {
    iteratee = cb(iteratee, context);
    var keys = !isArrayLike(obj) && _.keys(obj),
        length = (keys || obj).length,
        results = Array(length);
    for (var index = 0; index < length; index++) {
      var currentKey = keys ? keys[index] : index;
      results[index] = iteratee(obj[currentKey], currentKey, obj);
    }
    return results;
  };

  // Create a reducing function iterating left or right.
  function createReduce(dir) {
    // Optimized iterator function as using arguments.length
    // in the main function will deoptimize the, see #1991.
    function iterator(obj, iteratee, memo, keys, index, length) {
      for (; index >= 0 && index < length; index += dir) {
        var currentKey = keys ? keys[index] : index;
        memo = iteratee(memo, obj[currentKey], currentKey, obj);
      }
      return memo;
    }

    return function(obj, iteratee, memo, context) {
      iteratee = optimizeCb(iteratee, context, 4);
      var keys = !isArrayLike(obj) && _.keys(obj),
          length = (keys || obj).length,
          index = dir > 0 ? 0 : length - 1;
      // Determine the initial value if none is provided.
      if (arguments.length < 3) {
        memo = obj[keys ? keys[index] : index];
        index += dir;
      }
      return iterator(obj, iteratee, memo, keys, index, length);
    };
  }

  // **Reduce** builds up a single result from a list of values, aka `inject`,
  // or `foldl`.
  _.reduce = _.foldl = _.inject = createReduce(1);

  // The right-associative version of reduce, also known as `foldr`.
  _.reduceRight = _.foldr = createReduce(-1);

  // Return the first value which passes a truth test. Aliased as `detect`.
  _.find = _.detect = function(obj, predicate, context) {
    var key;
    if (isArrayLike(obj)) {
      key = _.findIndex(obj, predicate, context);
    } else {
      key = _.findKey(obj, predicate, context);
    }
    if (key !== void 0 && key !== -1) return obj[key];
  };

  // Return all the elements that pass a truth test.
  // Aliased as `select`.
  _.filter = _.select = function(obj, predicate, context) {
    var results = [];
    predicate = cb(predicate, context);
    _.each(obj, function(value, index, list) {
      if (predicate(value, index, list)) results.push(value);
    });
    return results;
  };

  // Return all the elements for which a truth test fails.
  _.reject = function(obj, predicate, context) {
    return _.filter(obj, _.negate(cb(predicate)), context);
  };

  // Determine whether all of the elements match a truth test.
  // Aliased as `all`.
  _.every = _.all = function(obj, predicate, context) {
    predicate = cb(predicate, context);
    var keys = !isArrayLike(obj) && _.keys(obj),
        length = (keys || obj).length;
    for (var index = 0; index < length; index++) {
      var currentKey = keys ? keys[index] : index;
      if (!predicate(obj[currentKey], currentKey, obj)) return false;
    }
    return true;
  };

  // Determine if at least one element in the object matches a truth test.
  // Aliased as `any`.
  _.some = _.any = function(obj, predicate, context) {
    predicate = cb(predicate, context);
    var keys = !isArrayLike(obj) && _.keys(obj),
        length = (keys || obj).length;
    for (var index = 0; index < length; index++) {
      var currentKey = keys ? keys[index] : index;
      if (predicate(obj[currentKey], currentKey, obj)) return true;
    }
    return false;
  };

  // Determine if the array or object contains a given item (using `===`).
  // Aliased as `includes` and `include`.
  _.contains = _.includes = _.include = function(obj, item, fromIndex, guard) {
    if (!isArrayLike(obj)) obj = _.values(obj);
    if (typeof fromIndex != 'number' || guard) fromIndex = 0;
    return _.indexOf(obj, item, fromIndex) >= 0;
  };

  // Invoke a method (with arguments) on every item in a collection.
  _.invoke = function(obj, method) {
    var args = slice.call(arguments, 2);
    var isFunc = _.isFunction(method);
    return _.map(obj, function(value) {
      var func = isFunc ? method : value[method];
      return func == null ? func : func.apply(value, args);
    });
  };

  // Convenience version of a common use case of `map`: fetching a property.
  _.pluck = function(obj, key) {
    return _.map(obj, _.property(key));
  };

  // Convenience version of a common use case of `filter`: selecting only objects
  // containing specific `key:value` pairs.
  _.where = function(obj, attrs) {
    return _.filter(obj, _.matcher(attrs));
  };

  // Convenience version of a common use case of `find`: getting the first object
  // containing specific `key:value` pairs.
  _.findWhere = function(obj, attrs) {
    return _.find(obj, _.matcher(attrs));
  };

  // Return the maximum element (or element-based computation).
  _.max = function(obj, iteratee, context) {
    var result = -Infinity, lastComputed = -Infinity,
        value, computed;
    if (iteratee == null && obj != null) {
      obj = isArrayLike(obj) ? obj : _.values(obj);
      for (var i = 0, length = obj.length; i < length; i++) {
        value = obj[i];
        if (value > result) {
          result = value;
        }
      }
    } else {
      iteratee = cb(iteratee, context);
      _.each(obj, function(value, index, list) {
        computed = iteratee(value, index, list);
        if (computed > lastComputed || computed === -Infinity && result === -Infinity) {
          result = value;
          lastComputed = computed;
        }
      });
    }
    return result;
  };

  // Return the minimum element (or element-based computation).
  _.min = function(obj, iteratee, context) {
    var result = Infinity, lastComputed = Infinity,
        value, computed;
    if (iteratee == null && obj != null) {
      obj = isArrayLike(obj) ? obj : _.values(obj);
      for (var i = 0, length = obj.length; i < length; i++) {
        value = obj[i];
        if (value < result) {
          result = value;
        }
      }
    } else {
      iteratee = cb(iteratee, context);
      _.each(obj, function(value, index, list) {
        computed = iteratee(value, index, list);
        if (computed < lastComputed || computed === Infinity && result === Infinity) {
          result = value;
          lastComputed = computed;
        }
      });
    }
    return result;
  };

  // Shuffle a collection, using the modern version of the
  // [Fisher-Yates shuffle](http://en.wikipedia.org/wiki/Fisher–Yates_shuffle).
  _.shuffle = function(obj) {
    var set = isArrayLike(obj) ? obj : _.values(obj);
    var length = set.length;
    var shuffled = Array(length);
    for (var index = 0, rand; index < length; index++) {
      rand = _.random(0, index);
      if (rand !== index) shuffled[index] = shuffled[rand];
      shuffled[rand] = set[index];
    }
    return shuffled;
  };

  // Sample **n** random values from a collection.
  // If **n** is not specified, returns a single random element.
  // The internal `guard` argument allows it to work with `map`.
  _.sample = function(obj, n, guard) {
    if (n == null || guard) {
      if (!isArrayLike(obj)) obj = _.values(obj);
      return obj[_.random(obj.length - 1)];
    }
    return _.shuffle(obj).slice(0, Math.max(0, n));
  };

  // Sort the object's values by a criterion produced by an iteratee.
  _.sortBy = function(obj, iteratee, context) {
    iteratee = cb(iteratee, context);
    return _.pluck(_.map(obj, function(value, index, list) {
      return {
        value: value,
        index: index,
        criteria: iteratee(value, index, list)
      };
    }).sort(function(left, right) {
      var a = left.criteria;
      var b = right.criteria;
      if (a !== b) {
        if (a > b || a === void 0) return 1;
        if (a < b || b === void 0) return -1;
      }
      return left.index - right.index;
    }), 'value');
  };

  // An internal function used for aggregate "group by" operations.
  var group = function(behavior) {
    return function(obj, iteratee, context) {
      var result = {};
      iteratee = cb(iteratee, context);
      _.each(obj, function(value, index) {
        var key = iteratee(value, index, obj);
        behavior(result, value, key);
      });
      return result;
    };
  };

  // Groups the object's values by a criterion. Pass either a string attribute
  // to group by, or a function that returns the criterion.
  _.groupBy = group(function(result, value, key) {
    if (_.has(result, key)) result[key].push(value); else result[key] = [value];
  });

  // Indexes the object's values by a criterion, similar to `groupBy`, but for
  // when you know that your index values will be unique.
  _.indexBy = group(function(result, value, key) {
    result[key] = value;
  });

  // Counts instances of an object that group by a certain criterion. Pass
  // either a string attribute to count by, or a function that returns the
  // criterion.
  _.countBy = group(function(result, value, key) {
    if (_.has(result, key)) result[key]++; else result[key] = 1;
  });

  // Safely create a real, live array from anything iterable.
  _.toArray = function(obj) {
    if (!obj) return [];
    if (_.isArray(obj)) return slice.call(obj);
    if (isArrayLike(obj)) return _.map(obj, _.identity);
    return _.values(obj);
  };

  // Return the number of elements in an object.
  _.size = function(obj) {
    if (obj == null) return 0;
    return isArrayLike(obj) ? obj.length : _.keys(obj).length;
  };

  // Split a collection into two arrays: one whose elements all satisfy the given
  // predicate, and one whose elements all do not satisfy the predicate.
  _.partition = function(obj, predicate, context) {
    predicate = cb(predicate, context);
    var pass = [], fail = [];
    _.each(obj, function(value, key, obj) {
      (predicate(value, key, obj) ? pass : fail).push(value);
    });
    return [pass, fail];
  };

  // Array Functions
  // ---------------

  // Get the first element of an array. Passing **n** will return the first N
  // values in the array. Aliased as `head` and `take`. The **guard** check
  // allows it to work with `_.map`.
  _.first = _.head = _.take = function(array, n, guard) {
    if (array == null) return void 0;
    if (n == null || guard) return array[0];
    return _.initial(array, array.length - n);
  };

  // Returns everything but the last entry of the array. Especially useful on
  // the arguments object. Passing **n** will return all the values in
  // the array, excluding the last N.
  _.initial = function(array, n, guard) {
    return slice.call(array, 0, Math.max(0, array.length - (n == null || guard ? 1 : n)));
  };

  // Get the last element of an array. Passing **n** will return the last N
  // values in the array.
  _.last = function(array, n, guard) {
    if (array == null) return void 0;
    if (n == null || guard) return array[array.length - 1];
    return _.rest(array, Math.max(0, array.length - n));
  };

  // Returns everything but the first entry of the array. Aliased as `tail` and `drop`.
  // Especially useful on the arguments object. Passing an **n** will return
  // the rest N values in the array.
  _.rest = _.tail = _.drop = function(array, n, guard) {
    return slice.call(array, n == null || guard ? 1 : n);
  };

  // Trim out all falsy values from an array.
  _.compact = function(array) {
    return _.filter(array, _.identity);
  };

  // Internal implementation of a recursive `flatten` function.
  var flatten = function(input, shallow, strict, startIndex) {
    var output = [], idx = 0;
    for (var i = startIndex || 0, length = getLength(input); i < length; i++) {
      var value = input[i];
      if (isArrayLike(value) && (_.isArray(value) || _.isArguments(value))) {
        //flatten current level of array or arguments object
        if (!shallow) value = flatten(value, shallow, strict);
        var j = 0, len = value.length;
        output.length += len;
        while (j < len) {
          output[idx++] = value[j++];
        }
      } else if (!strict) {
        output[idx++] = value;
      }
    }
    return output;
  };

  // Flatten out an array, either recursively (by default), or just one level.
  _.flatten = function(array, shallow) {
    return flatten(array, shallow, false);
  };

  // Return a version of the array that does not contain the specified value(s).
  _.without = function(array) {
    return _.difference(array, slice.call(arguments, 1));
  };

  // Produce a duplicate-free version of the array. If the array has already
  // been sorted, you have the option of using a faster algorithm.
  // Aliased as `unique`.
  _.uniq = _.unique = function(array, isSorted, iteratee, context) {
    if (!_.isBoolean(isSorted)) {
      context = iteratee;
      iteratee = isSorted;
      isSorted = false;
    }
    if (iteratee != null) iteratee = cb(iteratee, context);
    var result = [];
    var seen = [];
    for (var i = 0, length = getLength(array); i < length; i++) {
      var value = array[i],
          computed = iteratee ? iteratee(value, i, array) : value;
      if (isSorted) {
        if (!i || seen !== computed) result.push(value);
        seen = computed;
      } else if (iteratee) {
        if (!_.contains(seen, computed)) {
          seen.push(computed);
          result.push(value);
        }
      } else if (!_.contains(result, value)) {
        result.push(value);
      }
    }
    return result;
  };

  // Produce an array that contains the union: each distinct element from all of
  // the passed-in arrays.
  _.union = function() {
    return _.uniq(flatten(arguments, true, true));
  };

  // Produce an array that contains every item shared between all the
  // passed-in arrays.
  _.intersection = function(array) {
    var result = [];
    var argsLength = arguments.length;
    for (var i = 0, length = getLength(array); i < length; i++) {
      var item = array[i];
      if (_.contains(result, item)) continue;
      for (var j = 1; j < argsLength; j++) {
        if (!_.contains(arguments[j], item)) break;
      }
      if (j === argsLength) result.push(item);
    }
    return result;
  };

  // Take the difference between one array and a number of other arrays.
  // Only the elements present in just the first array will remain.
  _.difference = function(array) {
    var rest = flatten(arguments, true, true, 1);
    return _.filter(array, function(value){
      return !_.contains(rest, value);
    });
  };

  // Zip together multiple lists into a single array -- elements that share
  // an index go together.
  _.zip = function() {
    return _.unzip(arguments);
  };

  // Complement of _.zip. Unzip accepts an array of arrays and groups
  // each array's elements on shared indices
  _.unzip = function(array) {
    var length = array && _.max(array, getLength).length || 0;
    var result = Array(length);

    for (var index = 0; index < length; index++) {
      result[index] = _.pluck(array, index);
    }
    return result;
  };

  // Converts lists into objects. Pass either a single array of `[key, value]`
  // pairs, or two parallel arrays of the same length -- one of keys, and one of
  // the corresponding values.
  _.object = function(list, values) {
    var result = {};
    for (var i = 0, length = getLength(list); i < length; i++) {
      if (values) {
        result[list[i]] = values[i];
      } else {
        result[list[i][0]] = list[i][1];
      }
    }
    return result;
  };

  // Generator function to create the findIndex and findLastIndex functions
  function createPredicateIndexFinder(dir) {
    return function(array, predicate, context) {
      predicate = cb(predicate, context);
      var length = getLength(array);
      var index = dir > 0 ? 0 : length - 1;
      for (; index >= 0 && index < length; index += dir) {
        if (predicate(array[index], index, array)) return index;
      }
      return -1;
    };
  }

  // Returns the first index on an array-like that passes a predicate test
  _.findIndex = createPredicateIndexFinder(1);
  _.findLastIndex = createPredicateIndexFinder(-1);

  // Use a comparator function to figure out the smallest index at which
  // an object should be inserted so as to maintain order. Uses binary search.
  _.sortedIndex = function(array, obj, iteratee, context) {
    iteratee = cb(iteratee, context, 1);
    var value = iteratee(obj);
    var low = 0, high = getLength(array);
    while (low < high) {
      var mid = Math.floor((low + high) / 2);
      if (iteratee(array[mid]) < value) low = mid + 1; else high = mid;
    }
    return low;
  };

  // Generator function to create the indexOf and lastIndexOf functions
  function createIndexFinder(dir, predicateFind, sortedIndex) {
    return function(array, item, idx) {
      var i = 0, length = getLength(array);
      if (typeof idx == 'number') {
        if (dir > 0) {
            i = idx >= 0 ? idx : Math.max(idx + length, i);
        } else {
            length = idx >= 0 ? Math.min(idx + 1, length) : idx + length + 1;
        }
      } else if (sortedIndex && idx && length) {
        idx = sortedIndex(array, item);
        return array[idx] === item ? idx : -1;
      }
      if (item !== item) {
        idx = predicateFind(slice.call(array, i, length), _.isNaN);
        return idx >= 0 ? idx + i : -1;
      }
      for (idx = dir > 0 ? i : length - 1; idx >= 0 && idx < length; idx += dir) {
        if (array[idx] === item) return idx;
      }
      return -1;
    };
  }

  // Return the position of the first occurrence of an item in an array,
  // or -1 if the item is not included in the array.
  // If the array is large and already in sort order, pass `true`
  // for **isSorted** to use binary search.
  _.indexOf = createIndexFinder(1, _.findIndex, _.sortedIndex);
  _.lastIndexOf = createIndexFinder(-1, _.findLastIndex);

  // Generate an integer Array containing an arithmetic progression. A port of
  // the native Python `range()` function. See
  // [the Python documentation](http://docs.python.org/library/functions.html#range).
  _.range = function(start, stop, step) {
    if (stop == null) {
      stop = start || 0;
      start = 0;
    }
    step = step || 1;

    var length = Math.max(Math.ceil((stop - start) / step), 0);
    var range = Array(length);

    for (var idx = 0; idx < length; idx++, start += step) {
      range[idx] = start;
    }

    return range;
  };

  // Function (ahem) Functions
  // ------------------

  // Determines whether to execute a function as a constructor
  // or a normal function with the provided arguments
  var executeBound = function(sourceFunc, boundFunc, context, callingContext, args) {
    if (!(callingContext instanceof boundFunc)) return sourceFunc.apply(context, args);
    var self = baseCreate(sourceFunc.prototype);
    var result = sourceFunc.apply(self, args);
    if (_.isObject(result)) return result;
    return self;
  };

  // Create a function bound to a given object (assigning `this`, and arguments,
  // optionally). Delegates to **ECMAScript 5**'s native `Function.bind` if
  // available.
  _.bind = function(func, context) {
    if (nativeBind && func.bind === nativeBind) return nativeBind.apply(func, slice.call(arguments, 1));
    if (!_.isFunction(func)) throw new TypeError('Bind must be called on a function');
    var args = slice.call(arguments, 2);
    var bound = function() {
      return executeBound(func, bound, context, this, args.concat(slice.call(arguments)));
    };
    return bound;
  };

  // Partially apply a function by creating a version that has had some of its
  // arguments pre-filled, without changing its dynamic `this` context. _ acts
  // as a placeholder, allowing any combination of arguments to be pre-filled.
  _.partial = function(func) {
    var boundArgs = slice.call(arguments, 1);
    var bound = function() {
      var position = 0, length = boundArgs.length;
      var args = Array(length);
      for (var i = 0; i < length; i++) {
        args[i] = boundArgs[i] === _ ? arguments[position++] : boundArgs[i];
      }
      while (position < arguments.length) args.push(arguments[position++]);
      return executeBound(func, bound, this, this, args);
    };
    return bound;
  };

  // Bind a number of an object's methods to that object. Remaining arguments
  // are the method names to be bound. Useful for ensuring that all callbacks
  // defined on an object belong to it.
  _.bindAll = function(obj) {
    var i, length = arguments.length, key;
    if (length <= 1) throw new Error('bindAll must be passed function names');
    for (i = 1; i < length; i++) {
      key = arguments[i];
      obj[key] = _.bind(obj[key], obj);
    }
    return obj;
  };

  // Memoize an expensive function by storing its results.
  _.memoize = function(func, hasher) {
    var memoize = function(key) {
      var cache = memoize.cache;
      var address = '' + (hasher ? hasher.apply(this, arguments) : key);
      if (!_.has(cache, address)) cache[address] = func.apply(this, arguments);
      return cache[address];
    };
    memoize.cache = {};
    return memoize;
  };

  // Delays a function for the given number of milliseconds, and then calls
  // it with the arguments supplied.
  _.delay = function(func, wait) {
    var args = slice.call(arguments, 2);
    return setTimeout(function(){
      return func.apply(null, args);
    }, wait);
  };

  // Defers a function, scheduling it to run after the current call stack has
  // cleared.
  _.defer = _.partial(_.delay, _, 1);

  // Returns a function, that, when invoked, will only be triggered at most once
  // during a given window of time. Normally, the throttled function will run
  // as much as it can, without ever going more than once per `wait` duration;
  // but if you'd like to disable the execution on the leading edge, pass
  // `{leading: false}`. To disable execution on the trailing edge, ditto.
  _.throttle = function(func, wait, options) {
    var context, args, result;
    var timeout = null;
    var previous = 0;
    if (!options) options = {};
    var later = function() {
      previous = options.leading === false ? 0 : _.now();
      timeout = null;
      result = func.apply(context, args);
      if (!timeout) context = args = null;
    };
    return function() {
      var now = _.now();
      if (!previous && options.leading === false) previous = now;
      var remaining = wait - (now - previous);
      context = this;
      args = arguments;
      if (remaining <= 0 || remaining > wait) {
        if (timeout) {
          clearTimeout(timeout);
          timeout = null;
        }
        previous = now;
        result = func.apply(context, args);
        if (!timeout) context = args = null;
      } else if (!timeout && options.trailing !== false) {
        timeout = setTimeout(later, remaining);
      }
      return result;
    };
  };

  // Returns a function, that, as long as it continues to be invoked, will not
  // be triggered. The function will be called after it stops being called for
  // N milliseconds. If `immediate` is passed, trigger the function on the
  // leading edge, instead of the trailing.
  _.debounce = function(func, wait, immediate) {
    var timeout, args, context, timestamp, result;

    var later = function() {
      var last = _.now() - timestamp;

      if (last < wait && last >= 0) {
        timeout = setTimeout(later, wait - last);
      } else {
        timeout = null;
        if (!immediate) {
          result = func.apply(context, args);
          if (!timeout) context = args = null;
        }
      }
    };

    return function() {
      context = this;
      args = arguments;
      timestamp = _.now();
      var callNow = immediate && !timeout;
      if (!timeout) timeout = setTimeout(later, wait);
      if (callNow) {
        result = func.apply(context, args);
        context = args = null;
      }

      return result;
    };
  };

  // Returns the first function passed as an argument to the second,
  // allowing you to adjust arguments, run code before and after, and
  // conditionally execute the original function.
  _.wrap = function(func, wrapper) {
    return _.partial(wrapper, func);
  };

  // Returns a negated version of the passed-in predicate.
  _.negate = function(predicate) {
    return function() {
      return !predicate.apply(this, arguments);
    };
  };

  // Returns a function that is the composition of a list of functions, each
  // consuming the return value of the function that follows.
  _.compose = function() {
    var args = arguments;
    var start = args.length - 1;
    return function() {
      var i = start;
      var result = args[start].apply(this, arguments);
      while (i--) result = args[i].call(this, result);
      return result;
    };
  };

  // Returns a function that will only be executed on and after the Nth call.
  _.after = function(times, func) {
    return function() {
      if (--times < 1) {
        return func.apply(this, arguments);
      }
    };
  };

  // Returns a function that will only be executed up to (but not including) the Nth call.
  _.before = function(times, func) {
    var memo;
    return function() {
      if (--times > 0) {
        memo = func.apply(this, arguments);
      }
      if (times <= 1) func = null;
      return memo;
    };
  };

  // Returns a function that will be executed at most one time, no matter how
  // often you call it. Useful for lazy initialization.
  _.once = _.partial(_.before, 2);

  // Object Functions
  // ----------------

  // Keys in IE < 9 that won't be iterated by `for key in ...` and thus missed.
  var hasEnumBug = !{toString: null}.propertyIsEnumerable('toString');
  var nonEnumerableProps = ['valueOf', 'isPrototypeOf', 'toString',
                      'propertyIsEnumerable', 'hasOwnProperty', 'toLocaleString'];

  function collectNonEnumProps(obj, keys) {
    var nonEnumIdx = nonEnumerableProps.length;
    var constructor = obj.constructor;
    var proto = (_.isFunction(constructor) && constructor.prototype) || ObjProto;

    // Constructor is a special case.
    var prop = 'constructor';
    if (_.has(obj, prop) && !_.contains(keys, prop)) keys.push(prop);

    while (nonEnumIdx--) {
      prop = nonEnumerableProps[nonEnumIdx];
      if (prop in obj && obj[prop] !== proto[prop] && !_.contains(keys, prop)) {
        keys.push(prop);
      }
    }
  }

  // Retrieve the names of an object's own properties.
  // Delegates to **ECMAScript 5**'s native `Object.keys`
  _.keys = function(obj) {
    if (!_.isObject(obj)) return [];
    if (nativeKeys) return nativeKeys(obj);
    var keys = [];
    for (var key in obj) if (_.has(obj, key)) keys.push(key);
    // Ahem, IE < 9.
    if (hasEnumBug) collectNonEnumProps(obj, keys);
    return keys;
  };

  // Retrieve all the property names of an object.
  _.allKeys = function(obj) {
    if (!_.isObject(obj)) return [];
    var keys = [];
    for (var key in obj) keys.push(key);
    // Ahem, IE < 9.
    if (hasEnumBug) collectNonEnumProps(obj, keys);
    return keys;
  };

  // Retrieve the values of an object's properties.
  _.values = function(obj) {
    var keys = _.keys(obj);
    var length = keys.length;
    var values = Array(length);
    for (var i = 0; i < length; i++) {
      values[i] = obj[keys[i]];
    }
    return values;
  };

  // Returns the results of applying the iteratee to each element of the object
  // In contrast to _.map it returns an object
  _.mapObject = function(obj, iteratee, context) {
    iteratee = cb(iteratee, context);
    var keys =  _.keys(obj),
          length = keys.length,
          results = {},
          currentKey;
      for (var index = 0; index < length; index++) {
        currentKey = keys[index];
        results[currentKey] = iteratee(obj[currentKey], currentKey, obj);
      }
      return results;
  };

  // Convert an object into a list of `[key, value]` pairs.
  _.pairs = function(obj) {
    var keys = _.keys(obj);
    var length = keys.length;
    var pairs = Array(length);
    for (var i = 0; i < length; i++) {
      pairs[i] = [keys[i], obj[keys[i]]];
    }
    return pairs;
  };

  // Invert the keys and values of an object. The values must be serializable.
  _.invert = function(obj) {
    var result = {};
    var keys = _.keys(obj);
    for (var i = 0, length = keys.length; i < length; i++) {
      result[obj[keys[i]]] = keys[i];
    }
    return result;
  };

  // Return a sorted list of the function names available on the object.
  // Aliased as `methods`
  _.functions = _.methods = function(obj) {
    var names = [];
    for (var key in obj) {
      if (_.isFunction(obj[key])) names.push(key);
    }
    return names.sort();
  };

  // Extend a given object with all the properties in passed-in object(s).
  _.extend = createAssigner(_.allKeys);

  // Assigns a given object with all the own properties in the passed-in object(s)
  // (https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Object/assign)
  _.extendOwn = _.assign = createAssigner(_.keys);

  // Returns the first key on an object that passes a predicate test
  _.findKey = function(obj, predicate, context) {
    predicate = cb(predicate, context);
    var keys = _.keys(obj), key;
    for (var i = 0, length = keys.length; i < length; i++) {
      key = keys[i];
      if (predicate(obj[key], key, obj)) return key;
    }
  };

  // Return a copy of the object only containing the whitelisted properties.
  _.pick = function(object, oiteratee, context) {
    var result = {}, obj = object, iteratee, keys;
    if (obj == null) return result;
    if (_.isFunction(oiteratee)) {
      keys = _.allKeys(obj);
      iteratee = optimizeCb(oiteratee, context);
    } else {
      keys = flatten(arguments, false, false, 1);
      iteratee = function(value, key, obj) { return key in obj; };
      obj = Object(obj);
    }
    for (var i = 0, length = keys.length; i < length; i++) {
      var key = keys[i];
      var value = obj[key];
      if (iteratee(value, key, obj)) result[key] = value;
    }
    return result;
  };

   // Return a copy of the object without the blacklisted properties.
  _.omit = function(obj, iteratee, context) {
    if (_.isFunction(iteratee)) {
      iteratee = _.negate(iteratee);
    } else {
      var keys = _.map(flatten(arguments, false, false, 1), String);
      iteratee = function(value, key) {
        return !_.contains(keys, key);
      };
    }
    return _.pick(obj, iteratee, context);
  };

  // Fill in a given object with default properties.
  _.defaults = createAssigner(_.allKeys, true);

  // Creates an object that inherits from the given prototype object.
  // If additional properties are provided then they will be added to the
  // created object.
  _.create = function(prototype, props) {
    var result = baseCreate(prototype);
    if (props) _.extendOwn(result, props);
    return result;
  };

  // Create a (shallow-cloned) duplicate of an object.
  _.clone = function(obj) {
    if (!_.isObject(obj)) return obj;
    return _.isArray(obj) ? obj.slice() : _.extend({}, obj);
  };

  // Invokes interceptor with the obj, and then returns obj.
  // The primary purpose of this method is to "tap into" a method chain, in
  // order to perform operations on intermediate results within the chain.
  _.tap = function(obj, interceptor) {
    interceptor(obj);
    return obj;
  };

  // Returns whether an object has a given set of `key:value` pairs.
  _.isMatch = function(object, attrs) {
    var keys = _.keys(attrs), length = keys.length;
    if (object == null) return !length;
    var obj = Object(object);
    for (var i = 0; i < length; i++) {
      var key = keys[i];
      if (attrs[key] !== obj[key] || !(key in obj)) return false;
    }
    return true;
  };


  // Internal recursive comparison function for `isEqual`.
  var eq = function(a, b, aStack, bStack) {
    // Identical objects are equal. `0 === -0`, but they aren't identical.
    // See the [Harmony `egal` proposal](http://wiki.ecmascript.org/doku.php?id=harmony:egal).
    if (a === b) return a !== 0 || 1 / a === 1 / b;
    // A strict comparison is necessary because `null == undefined`.
    if (a == null || b == null) return a === b;
    // Unwrap any wrapped objects.
    if (a instanceof _) a = a._wrapped;
    if (b instanceof _) b = b._wrapped;
    // Compare `[[Class]]` names.
    var className = toString.call(a);
    if (className !== toString.call(b)) return false;
    switch (className) {
      // Strings, numbers, regular expressions, dates, and booleans are compared by value.
      case '[object RegExp]':
      // RegExps are coerced to strings for comparison (Note: '' + /a/i === '/a/i')
      case '[object String]':
        // Primitives and their corresponding object wrappers are equivalent; thus, `"5"` is
        // equivalent to `new String("5")`.
        return '' + a === '' + b;
      case '[object Number]':
        // `NaN`s are equivalent, but non-reflexive.
        // Object(NaN) is equivalent to NaN
        if (+a !== +a) return +b !== +b;
        // An `egal` comparison is performed for other numeric values.
        return +a === 0 ? 1 / +a === 1 / b : +a === +b;
      case '[object Date]':
      case '[object Boolean]':
        // Coerce dates and booleans to numeric primitive values. Dates are compared by their
        // millisecond representations. Note that invalid dates with millisecond representations
        // of `NaN` are not equivalent.
        return +a === +b;
    }

    var areArrays = className === '[object Array]';
    if (!areArrays) {
      if (typeof a != 'object' || typeof b != 'object') return false;

      // Objects with different constructors are not equivalent, but `Object`s or `Array`s
      // from different frames are.
      var aCtor = a.constructor, bCtor = b.constructor;
      if (aCtor !== bCtor && !(_.isFunction(aCtor) && aCtor instanceof aCtor &&
                               _.isFunction(bCtor) && bCtor instanceof bCtor)
                          && ('constructor' in a && 'constructor' in b)) {
        return false;
      }
    }
    // Assume equality for cyclic structures. The algorithm for detecting cyclic
    // structures is adapted from ES 5.1 section 15.12.3, abstract operation `JO`.

    // Initializing stack of traversed objects.
    // It's done here since we only need them for objects and arrays comparison.
    aStack = aStack || [];
    bStack = bStack || [];
    var length = aStack.length;
    while (length--) {
      // Linear search. Performance is inversely proportional to the number of
      // unique nested structures.
      if (aStack[length] === a) return bStack[length] === b;
    }

    // Add the first object to the stack of traversed objects.
    aStack.push(a);
    bStack.push(b);

    // Recursively compare objects and arrays.
    if (areArrays) {
      // Compare array lengths to determine if a deep comparison is necessary.
      length = a.length;
      if (length !== b.length) return false;
      // Deep compare the contents, ignoring non-numeric properties.
      while (length--) {
        if (!eq(a[length], b[length], aStack, bStack)) return false;
      }
    } else {
      // Deep compare objects.
      var keys = _.keys(a), key;
      length = keys.length;
      // Ensure that both objects contain the same number of properties before comparing deep equality.
      if (_.keys(b).length !== length) return false;
      while (length--) {
        // Deep compare each member
        key = keys[length];
        if (!(_.has(b, key) && eq(a[key], b[key], aStack, bStack))) return false;
      }
    }
    // Remove the first object from the stack of traversed objects.
    aStack.pop();
    bStack.pop();
    return true;
  };

  // Perform a deep comparison to check if two objects are equal.
  _.isEqual = function(a, b) {
    return eq(a, b);
  };

  // Is a given array, string, or object empty?
  // An "empty" object has no enumerable own-properties.
  _.isEmpty = function(obj) {
    if (obj == null) return true;
    if (isArrayLike(obj) && (_.isArray(obj) || _.isString(obj) || _.isArguments(obj))) return obj.length === 0;
    return _.keys(obj).length === 0;
  };

  // Is a given value a DOM element?
  _.isElement = function(obj) {
    return !!(obj && obj.nodeType === 1);
  };

  // Is a given value an array?
  // Delegates to ECMA5's native Array.isArray
  _.isArray = nativeIsArray || function(obj) {
    return toString.call(obj) === '[object Array]';
  };

  // Is a given variable an object?
  _.isObject = function(obj) {
    var type = typeof obj;
    return type === 'function' || type === 'object' && !!obj;
  };

  // Add some isType methods: isArguments, isFunction, isString, isNumber, isDate, isRegExp, isError.
  _.each(['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp', 'Error'], function(name) {
    _['is' + name] = function(obj) {
      return toString.call(obj) === '[object ' + name + ']';
    };
  });

  // Define a fallback version of the method in browsers (ahem, IE < 9), where
  // there isn't any inspectable "Arguments" type.
  if (!_.isArguments(arguments)) {
    _.isArguments = function(obj) {
      return _.has(obj, 'callee');
    };
  }

  // Optimize `isFunction` if appropriate. Work around some typeof bugs in old v8,
  // IE 11 (#1621), and in Safari 8 (#1929).
  if (typeof /./ != 'function' && typeof Int8Array != 'object') {
    _.isFunction = function(obj) {
      return typeof obj == 'function' || false;
    };
  }

  // Is a given object a finite number?
  _.isFinite = function(obj) {
    return isFinite(obj) && !isNaN(parseFloat(obj));
  };

  // Is the given value `NaN`? (NaN is the only number which does not equal itself).
  _.isNaN = function(obj) {
    return _.isNumber(obj) && obj !== +obj;
  };

  // Is a given value a boolean?
  _.isBoolean = function(obj) {
    return obj === true || obj === false || toString.call(obj) === '[object Boolean]';
  };

  // Is a given value equal to null?
  _.isNull = function(obj) {
    return obj === null;
  };

  // Is a given variable undefined?
  _.isUndefined = function(obj) {
    return obj === void 0;
  };

  // Shortcut function for checking if an object has a given property directly
  // on itself (in other words, not on a prototype).
  _.has = function(obj, key) {
    return obj != null && hasOwnProperty.call(obj, key);
  };

  // Utility Functions
  // -----------------

  // Run Underscore.js in *noConflict* mode, returning the `_` variable to its
  // previous owner. Returns a reference to the Underscore object.
  _.noConflict = function() {
    root._ = previousUnderscore;
    return this;
  };

  // Keep the identity function around for default iteratees.
  _.identity = function(value) {
    return value;
  };

  // Predicate-generating functions. Often useful outside of Underscore.
  _.constant = function(value) {
    return function() {
      return value;
    };
  };

  _.noop = function(){};

  _.property = property;

  // Generates a function for a given object that returns a given property.
  _.propertyOf = function(obj) {
    return obj == null ? function(){} : function(key) {
      return obj[key];
    };
  };

  // Returns a predicate for checking whether an object has a given set of
  // `key:value` pairs.
  _.matcher = _.matches = function(attrs) {
    attrs = _.extendOwn({}, attrs);
    return function(obj) {
      return _.isMatch(obj, attrs);
    };
  };

  // Run a function **n** times.
  _.times = function(n, iteratee, context) {
    var accum = Array(Math.max(0, n));
    iteratee = optimizeCb(iteratee, context, 1);
    for (var i = 0; i < n; i++) accum[i] = iteratee(i);
    return accum;
  };

  // Return a random integer between min and max (inclusive).
  _.random = function(min, max) {
    if (max == null) {
      max = min;
      min = 0;
    }
    return min + Math.floor(Math.random() * (max - min + 1));
  };

  // A (possibly faster) way to get the current timestamp as an integer.
  _.now = Date.now || function() {
    return new Date().getTime();
  };

   // List of HTML entities for escaping.
  var escapeMap = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '`': '&#x60;'
  };
  var unescapeMap = _.invert(escapeMap);

  // Functions for escaping and unescaping strings to/from HTML interpolation.
  var createEscaper = function(map) {
    var escaper = function(match) {
      return map[match];
    };
    // Regexes for identifying a key that needs to be escaped
    var source = '(?:' + _.keys(map).join('|') + ')';
    var testRegexp = RegExp(source);
    var replaceRegexp = RegExp(source, 'g');
    return function(string) {
      string = string == null ? '' : '' + string;
      return testRegexp.test(string) ? string.replace(replaceRegexp, escaper) : string;
    };
  };
  _.escape = createEscaper(escapeMap);
  _.unescape = createEscaper(unescapeMap);

  // If the value of the named `property` is a function then invoke it with the
  // `object` as context; otherwise, return it.
  _.result = function(object, property, fallback) {
    var value = object == null ? void 0 : object[property];
    if (value === void 0) {
      value = fallback;
    }
    return _.isFunction(value) ? value.call(object) : value;
  };

  // Generate a unique integer id (unique within the entire client session).
  // Useful for temporary DOM ids.
  var idCounter = 0;
  _.uniqueId = function(prefix) {
    var id = ++idCounter + '';
    return prefix ? prefix + id : id;
  };

  // By default, Underscore uses ERB-style template delimiters, change the
  // following template settings to use alternative delimiters.
  _.templateSettings = {
    evaluate    : /<%([\s\S]+?)%>/g,
    interpolate : /<%=([\s\S]+?)%>/g,
    escape      : /<%-([\s\S]+?)%>/g
  };

  // When customizing `templateSettings`, if you don't want to define an
  // interpolation, evaluation or escaping regex, we need one that is
  // guaranteed not to match.
  var noMatch = /(.)^/;

  // Certain characters need to be escaped so that they can be put into a
  // string literal.
  var escapes = {
    "'":      "'",
    '\\':     '\\',
    '\r':     'r',
    '\n':     'n',
    '\u2028': 'u2028',
    '\u2029': 'u2029'
  };

  var escaper = /\\|'|\r|\n|\u2028|\u2029/g;

  var escapeChar = function(match) {
    return '\\' + escapes[match];
  };

  // JavaScript micro-templating, similar to John Resig's implementation.
  // Underscore templating handles arbitrary delimiters, preserves whitespace,
  // and correctly escapes quotes within interpolated code.
  // NB: `oldSettings` only exists for backwards compatibility.
  _.template = function(text, settings, oldSettings) {
    if (!settings && oldSettings) settings = oldSettings;
    settings = _.defaults({}, settings, _.templateSettings);

    // Combine delimiters into one regular expression via alternation.
    var matcher = RegExp([
      (settings.escape || noMatch).source,
      (settings.interpolate || noMatch).source,
      (settings.evaluate || noMatch).source
    ].join('|') + '|$', 'g');

    // Compile the template source, escaping string literals appropriately.
    var index = 0;
    var source = "__p+='";
    text.replace(matcher, function(match, escape, interpolate, evaluate, offset) {
      source += text.slice(index, offset).replace(escaper, escapeChar);
      index = offset + match.length;

      if (escape) {
        source += "'+\n((__t=(" + escape + "))==null?'':_.escape(__t))+\n'";
      } else if (interpolate) {
        source += "'+\n((__t=(" + interpolate + "))==null?'':__t)+\n'";
      } else if (evaluate) {
        source += "';\n" + evaluate + "\n__p+='";
      }

      // Adobe VMs need the match returned to produce the correct offest.
      return match;
    });
    source += "';\n";

    // If a variable is not specified, place data values in local scope.
    if (!settings.variable) source = 'with(obj||{}){\n' + source + '}\n';

    source = "var __t,__p='',__j=Array.prototype.join," +
      "print=function(){__p+=__j.call(arguments,'');};\n" +
      source + 'return __p;\n';

    try {
      var render = new Function(settings.variable || 'obj', '_', source);
    } catch (e) {
      e.source = source;
      throw e;
    }

    var template = function(data) {
      return render.call(this, data, _);
    };

    // Provide the compiled source as a convenience for precompilation.
    var argument = settings.variable || 'obj';
    template.source = 'function(' + argument + '){\n' + source + '}';

    return template;
  };

  // Add a "chain" function. Start chaining a wrapped Underscore object.
  _.chain = function(obj) {
    var instance = _(obj);
    instance._chain = true;
    return instance;
  };

  // OOP
  // ---------------
  // If Underscore is called as a function, it returns a wrapped object that
  // can be used OO-style. This wrapper holds altered versions of all the
  // underscore functions. Wrapped objects may be chained.

  // Helper function to continue chaining intermediate results.
  var result = function(instance, obj) {
    return instance._chain ? _(obj).chain() : obj;
  };

  // Add your own custom functions to the Underscore object.
  _.mixin = function(obj) {
    _.each(_.functions(obj), function(name) {
      var func = _[name] = obj[name];
      _.prototype[name] = function() {
        var args = [this._wrapped];
        push.apply(args, arguments);
        return result(this, func.apply(_, args));
      };
    });
  };

  // Add all of the Underscore functions to the wrapper object.
  _.mixin(_);

  // Add all mutator Array functions to the wrapper.
  _.each(['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], function(name) {
    var method = ArrayProto[name];
    _.prototype[name] = function() {
      var obj = this._wrapped;
      method.apply(obj, arguments);
      if ((name === 'shift' || name === 'splice') && obj.length === 0) delete obj[0];
      return result(this, obj);
    };
  });

  // Add all accessor Array functions to the wrapper.
  _.each(['concat', 'join', 'slice'], function(name) {
    var method = ArrayProto[name];
    _.prototype[name] = function() {
      return result(this, method.apply(this._wrapped, arguments));
    };
  });

  // Extracts the result from a wrapped and chained object.
  _.prototype.value = function() {
    return this._wrapped;
  };

  // Provide unwrapping proxy for some methods used in engine operations
  // such as arithmetic and JSON stringification.
  _.prototype.valueOf = _.prototype.toJSON = _.prototype.value;

  _.prototype.toString = function() {
    return '' + this._wrapped;
  };

  // AMD registration happens at the end for compatibility with AMD loaders
  // that may not enforce next-turn semantics on modules. Even though general
  // practice for AMD registration is to be anonymous, underscore registers
  // as a named module because, like jQuery, it is a base library that is
  // popular enough to be bundled in a third party lib, but not be part of
  // an AMD load request. Those cases could generate an error when an
  // anonymous define() is called outside of a loader request.
  if (typeof define === 'function' && define.amd) {
    define('underscore', [], function() {
      return _;
    });
  }
}.call(this));

},{}]},{},[5])(5)
});